// Use FreeType to render a font atlas
// from a atlas and a corresponding JSON file.
// 
// We don't do any packing.

const c = @cImport({
    @cInclude("ft.h");
    @cInclude("stb_image_write.h");
});
const std = @import("std");
const math = @import("math");

const Allocator = std.mem.Allocator;
const ArrayList = std.ArrayList;

const Float = math.types.Float;

// Serialize and deserialize JSON from this.
pub const Character = struct {
    grapheme: []u8,
    top: Float,
    left: Float,
    width: Float,
    height: Float,
    bearing_x: Float,
    bearing_y: Float,
    advance_x: c_long,
    advance_y: c_long
};

const Options = struct {
    const Self = @This();

    allocator: Allocator,

    font_size: c_uint = 14,
    input_path: []const u8,
    output_path: ?[]const u8 = null,
    output_json_path: ?[]const u8 = null,
    glyph_ranges: ArrayList([2]u21),
    num_glyphs: usize = 0,

    const Error = error{InvalidArg, InvalidOption};

    fn process(self: *Self, opt_arg: []const u8, arg: []const u8) !void {
        if (std.mem.eql(u8, opt_arg, "--size")) {
            self.font_size = std.fmt.parseInt(c_uint, arg, 10) catch return Error.InvalidArg;
        } else if (std.mem.eql(u8, opt_arg, "--output")) {
            if (self.output_path != null) return Error.InvalidOption;
            self.output_path = arg;
        } else if (std.mem.eql(u8, opt_arg, "--json-output")) {
            if (self.output_json_path != null) return Error.InvalidOption;
            self.output_json_path = arg;
        } else return Error.InvalidOption;
    }

    fn processArgs(allocator: Allocator) !Self {
        var args = try std.process.argsWithAllocator(allocator);
        defer args.deinit();
        _ = args.next();
        if (args.next()) |path| {
            var options: Self = .{
                .allocator = allocator,
                .input_path = path,
                .glyph_ranges = ArrayList([2]u21).init(allocator)
            };

            while (args.next()) |opt_arg| {
                const arg = args.next() orelse return Error.InvalidOption;
                try options.process(opt_arg, arg);
            }

            if (options.output_path == null) options.output_path = "atlas.png";
            if (options.output_json_path == null) options.output_json_path = "atlas.json";
            if (options.glyph_ranges.items.len == 0) try options.glyph_ranges.append([2]u21{65, 127});

            for (options.glyph_ranges.items) |range| {
                options.num_glyphs += range[1] - range[0];
            }

            return options;
        }
        return Error.InvalidArg;
    }

    fn deinit(self: *Self) void {
        self.glyph_ranges.deinit();
    }
};

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer std.debug.assert(gpa.deinit() == .ok);

    const allocator = gpa.allocator();

    var options = Options.processArgs(allocator) catch {
        std.debug.print("Usage: atlas_gen [path] --size [size=14] --output [output=.] --json-output [json-output=.]", .{});
        return;
    };
    defer options.deinit();

    var ft_library: c.FT_Library = undefined;
    if (c.FT_Init_FreeType(&ft_library) != 0) @panic("Unable to initialize FreeType.");
    defer std.debug.assert(c.FT_Done_FreeType(ft_library) == 0);

    std.debug.print("{s} {s} {s} {d}\n", .{options.input_path, options.output_path orelse unreachable, options.output_json_path orelse unreachable, options.font_size});

    var face: c.FT_Face = undefined;
    if (c.FT_New_Face(ft_library, @ptrCast(options.input_path), 0, &face) == 0) std.debug.panic("Unable to load {s}.", .{options.input_path});

    try fontAtlas(allocator, face, options);
}

fn fontAtlas(allocator: Allocator, face_ptr: c.FT_Face, options: Options) !void {
    if (c.FT_Set_Pixel_Sizes(face_ptr, 0, options.font_size) != 0) @panic("Unable to set font size.");

    const face = face_ptr.*;
    var atlas_size: usize = 0;

    // Calculate approximate atlas size, to a power of two (for mipmapping).
    // FreeType stores font sizes in 26.6 fractional pixel format = 1/64.
    const size = face.size.*;
    const max_dimensions = 
        (1 + (size.metrics.height >> 6)) *
            @as(c_long, @intFromFloat(
                @ceil(@sqrt(@as(Float, @floatFromInt(options.num_glyphs))))
            ));
    while (atlas_size < max_dimensions) atlas_size <<= 1;

    _ = allocator;
    // var atlas = try allocator.alloc(u8, atlas_size * atlas_size);
    // defer allocator.free(atlas);

    // for (options.glyph_ranges.items) |glyph_range| {
    //     var x: usize = 0;
    //     var y: usize = 0;

    //     for (glyph_range[0]..glyph_range[1]) |i| {
    //         if (c.FT_Load_Char(face_ptr, i, c.FT_LOAD_RENDER) != 0) {
    //             std.debug.print("Unable to load {any}.\n", .{i});
    //             continue;
    //         }

    //         const glyph = face.glyph.*;

    //         if (x + glyph.bitmap.width >= atlas_size) {
    //             const glyph_size = face.size.*;
    //             x = 0;
    //             y += @intCast(1 + (glyph_size.metrics.height >> 6));
    //         }

    //         for (0..glyph.bitmap.rows) |row| {
    //             for (0..glyph.bitmap.width) |col| {
    //                 const xpos = x + col;
    //                 const ypos = y + row;
    //                 atlas[ypos * atlas_size + xpos] =
    //                     glyph.bitmap.buffer[row * @as(usize, @intCast(glyph.bitmap.pitch)) + col];
    //             }
    //         }

    //         x += glyph.bitmap.width + 1;
    //     }
    // }

    // var png: []u8 = try allocator.alloc(u8, atlas_size * atlas_size * 4);
    // defer allocator.free(png);
    // for (0..atlas_size * atlas_size) |i| {
    //     png[i * 4] = atlas[i];
    //     png[i * 4 + 1] = atlas[i];
    //     png[i * 4 + 2] = atlas[i];
    //     png[i * 4 + 3] = 0xff;
    // }
    // if (
    //     c.stbi_write_png(
    //         @ptrCast(options.output_path.?),
    //         @intCast(atlas_size),
    //         @intCast(atlas_size),
    //         4,
    //         @ptrCast(&png[0]),
    //         @intCast(atlas_size * 4)
    //     ) == 0
    // ) @panic("Unable to write output to font atlas.");
}