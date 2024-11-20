// Use FreeType to render a font atlas and corresponding JSON file.
// This doesn't handle surrogate pairs, which means no emojis, for example.
// We also don't do any packing.
//
// We use the standard JSON library. Unfortunately it's not well documented (yet!),
// so I used type coercion as the easiest way to get it working.
//
// You can also use this like:
// 
// const atlas_gen = @import("atlas_gen.zig");
// ...
// const ft = try atlas_gen.setup();
// defer std.debug.assert(atlas_gen.cleanup(ft) == 0);
// const options: atlas_gen.Options = .{};
// const characters: try atlas_gen.fontAtlas(allocator, ft, options);
// defer characters.dienit();
// // Load texture from options.input_path, and use that in conjunction with `characters`.

const c = @cImport({
    @cInclude("ft.h");
    @cInclude("stb_image_write.h");
});
const std = @import("std");
const math = @import("math");
const Character = @import("character.zig");

const Allocator = std.mem.Allocator;
const ArrayList = std.ArrayList;
const json = std.json;

const Float = math.types.Float;

const Characters = Character.Characters;

pub const Options = struct {
    const Self = @This();

    font_size: c_uint = 14,
    input_path: []const u8,
    output_path: ?[]const u8 = null,
    output_json_path: ?[]const u8 = null,
    codepoint_ranges: ArrayList([2]u21),
    num_codepoints: usize = 0,

    const OptionError = error{InvalidArg, InvalidOption};

    fn process(self: *Self, opt_arg: []const u8, arg: []const u8) OptionError!void {
        if (std.mem.eql(u8, opt_arg, "--size")) {
            self.font_size = std.fmt.parseInt(c_uint, arg, 10) catch return OptionError.InvalidArg;
        } else if (std.mem.eql(u8, opt_arg, "--output")) {
            if (self.output_path != null) return OptionError.InvalidOption;
            self.output_path = arg;
        } else if (std.mem.eql(u8, opt_arg, "--json-output")) {
            if (self.output_path != null) return OptionError.InvalidOption;
            self.output_json_path = arg;
        } else return OptionError.InvalidOption;
    }

    fn processArgs(allocator: Allocator) !Self {
        var args = try std.process.argsWithAllocator(allocator);
        defer args.deinit();
        _ = args.next();

        if (args.next()) |path| {
            var options: Self = .{
                .input_path = path,
                .codepoint_ranges = ArrayList([2]u21).init(allocator)
            };
            errdefer options.deinit();

            while (args.next()) |opt_arg| {
                const arg = args.next() orelse return OptionError.InvalidOption;
                try options.process(opt_arg, arg);
            }

            options.output_path = options.output_path orelse "atlas.png";
            options.output_json_path = options.output_json_path orelse "atlas.json";
            if (options.codepoint_ranges.items.len == 0) try options.codepoint_ranges.append([2]u21{65, 127});

            for (options.codepoint_ranges.items) |range| options.num_codepoints += range[1] - range[0];

            return options;
        }

        return OptionError.InvalidArg;
    }

    fn deinit(self: *Self) void {
        self.codepoint_ranges.deinit();
    }
};

pub const Error = error{
    // Related to font file loading and usage.
    InvalidFont,
    InvalidCharacter,

    // Related to allocating output data.
    OutOfMemory,

    // Related to writing output data.
    AtlasWriteError,
    JSONWriteError
};

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer std.debug.assert(gpa.deinit() == .ok);

    const allocator = gpa.allocator();

    var options = Options.processArgs(allocator) catch {
        std.debug.print("Usage: atlas_gen [path] --size [size=14] --output [output=./atlas.png] --json-output [json-output=./atlas.json]\n", .{});
        return;
    };
    defer options.deinit();

    const ft = setup() catch {
        std.debug.print("Unable to initialize FreeType.\n", .{});
        return;
    };
    defer std.debug.assert(cleanup(ft) == 0);

    var characters = fontAtlas(allocator, ft, options) catch |err| {
        switch (err) {
            .InvalidFont => std.debug.print("Unable to load {s}.\n", .{options.input_path}),
            .InvalidCharacter => std.debug.print("{s} does not support provided Unicode range(s).\n", .{options.input_path}),
            .OutOfMemory => std.debug.print("Unable to allocate memory for generating font atlas.\n", .{}),
            .AtlasWriteError => std.debug.print("Unable to create font atlas.\n", .{}),
            .JSONWriteError => std.debug.print("Unable to create font atlas descriptor.\n", .{})
        }
        return;
    };
    characters.deinit();
}

pub fn setup() !c.FT_Library {
    var ft_library: c.FT_Library = undefined;
    if (c.FT_Init_FreeType(&ft_library) != 0) return error.SetupError;
    return ft_library;
}

pub fn cleanup(ft: c.FT_Library) c_int {
    return c.FT_Done_FreeType(ft);
}

fn fontAtlas(allocator: Allocator, ft: c.FT_Library, options: Options) Error!Characters {
    var face_ptr: c.FT_Face = undefined;
    if (c.FT_New_Face(ft, @ptrCast(options.input_path), 0, &face_ptr) != 0) return Error.InvalidFont;
    if (c.FT_Set_Pixel_Sizes(face_ptr, 0, options.font_size) != 0) return Error.InvalidFont;

    const face = face_ptr.*;
    var atlas_size: usize = 1;

    // Calculate approximate atlas size, to a power of two (for mipmapping).
    // FreeType stores font sizes in 26.6 fractional pixel format = 1/64.
    const size = face.size.*;
    const max_dimensions = 
        (1 + (size.metrics.height >> 6)) *
            @as(c_long, @intFromFloat(
                @ceil(@sqrt(@as(Float, @floatFromInt(options.num_codepoints))))
            ));
    while (atlas_size < max_dimensions) atlas_size <<= 1;

    const atlas = allocator.alloc(u8, atlas_size * atlas_size) catch return Error.OutOfMemory;
    defer allocator.free(atlas);

    var characters = Characters.init(allocator) catch return Error.OutOfMemory;
    errdefer characters.deinit();

    for (options.codepoint_ranges.items) |codepoint_range| {
        var x: usize = 0;
        var y: usize = 0;

        for (codepoint_range[0]..codepoint_range[1]) |i| {
            if (c.FT_Load_Char(face_ptr, i, c.FT_LOAD_RENDER) != 0) return Error.InvalidCharacter;

            const glyph = face.glyph.*;

            if (x + glyph.bitmap.width >= atlas_size) {
                const glyph_size = face.size.*;
                x = 0;
                y += @intCast(1 + (glyph_size.metrics.height >> 6));
            }

            for (0..glyph.bitmap.rows) |row| {
                for (0..glyph.bitmap.width) |col| {
                    const xpos = x + col;
                    const ypos = y + row;
                    atlas[ypos * atlas_size + xpos] = 
                        glyph.bitmap.buffer[row * @as(usize, @intCast(glyph.bitmap.pitch)) + col];
                }
            }

            const codepoint: u21 = @intCast(i);
            const codepoint_length = std.unicode.utf8CodepointSequenceLength(codepoint) catch return Error.InvalidCharacter;
            const character: Character = .{
                .grapheme = allocator.alloc(u8, codepoint_length) catch return Error.OutOfMemory,
                .top = @floatFromInt(x),
                .left = @floatFromInt(y),
                .width = @floatFromInt(glyph.bitmap.width),
                .height = @floatFromInt(glyph.bitmap.rows),
                .bearing_x = @floatFromInt(glyph.bitmap_left),
                .bearing_y = @floatFromInt(glyph.bitmap_top),
                .advance_x = glyph.advance.x >> 6,
                .advance_y = glyph.advance.y >> 6
            };
            _ = std.unicode.utf8Encode(codepoint, character.grapheme) catch return Error.InvalidCharacter;
            characters.map.put(allocator, character.grapheme, character) catch return Error.OutOfMemory;

            x += glyph.bitmap.width + 1;
        }
    }

    if (options.output_path) |output_path| {
        var png = allocator.alloc(u8, atlas_size * atlas_size * 4) catch return Error.OutOfMemory;
        defer allocator.free(png);
        for (0..atlas_size * atlas_size) |i| {
            png[i * 4] = atlas[i];
            png[i * 4 + 1] = atlas[i];
            png[i * 4 + 2] = atlas[i];
            png[i * 4 + 3] = 0xff;
        }
        if (
            c.stbi_write_png(
                @ptrCast(output_path),
                @intCast(atlas_size),
                @intCast(atlas_size),
                4,
                @ptrCast(&png[0]),
                @intCast(atlas_size * 4)
            ) == 0
        ) return Error.AtlasWriteError;
    }

    if (options.output_json_path) |output_json_path| {
        var json_output = ArrayList(u8).init(allocator);
        defer json_output.deinit();
        const as_json: *json.ArrayHashMap(Character) = @ptrCast(&characters.map);
        json.stringify(&as_json, .{}, json_output.writer()) catch return Error.JSONWriteError;

        if (std.fs.path.isAbsolute(output_json_path)) {
            const file = std.fs.createFileAbsolute(output_json_path, .{}) catch return Error.JSONWriteError;
            defer file.close();
            _ = file.write(json_output.items) catch return Error.JSONWriteError; 
        } else {
            const file = std.fs.cwd().createFile(output_json_path, .{}) catch return Error.JSONWriteError;
            defer file.close();
            _ = file.write(json_output.items) catch return Error.JSONWriteError;
        }
    }

    return characters;
}