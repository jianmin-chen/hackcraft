// Manage all the chunks,
// namely for optimizing when to call render().

const c = @cImport({
    @cInclude("glad/glad.h");
});
const std = @import("std");
const block = @import("block.zig");
const Chunk = @import("chunk.zig");
const math = @import("math");
const Shader = @import("shader.zig");

const Allocator = std.mem.Allocator;
const ArrayList = std.ArrayList;
const AutoHashMap = std.AutoHashMap;
const assert = std.debug.assert;

const BASE = block.VERTICES;
const INDICES = block.EDGES;

const CHUNK_LENGTH = Chunk.CHUNK_LENGTH;

const chunk_vertex = Chunk.vertex;
const chunk_fragment = Chunk.fragment;

const Float = math.types.Float;
const PermutationTable = math.noise.PermutationTable;

const Vec3 = math.vector.Vec3(Float); 
const Vec3Primitive = Vec3.Primitive; 

const Coord = math.vector.Vec3(isize);
const CoordPrimitive = Coord.Primitive;

const Self = @This();

allocator: Allocator,

permutations: PermutationTable,

// Chunks is the entire chunk cache,
// while the other ones filter out
// for a specific purpose.
chunks: AutoHashMap(CoordPrimitive, *Chunk),
paint_chunks: ArrayList(*Chunk),
update_chunks: ArrayList(*Chunk),

render_chunks: AutoHashMap(CoordPrimitive, *Chunk),
render_radius: usize,

base_vbo: c_uint,
ebo: c_uint,

chunk_shader: Shader,

pub fn init(
    allocator: Allocator,
    permutations: PermutationTable,
    initial_spawn: Vec3Primitive,
    render_radius: usize
) !Self {
    var base_vbo: c_uint = undefined;
    var ebo: c_uint = undefined;

    c.glGenBuffers(1, &base_vbo);
    c.glBindBuffer(c.GL_ARRAY_BUFFER, base_vbo);
    c.glBufferData(
        c.GL_ARRAY_BUFFER,
        @sizeOf(Float) * BASE.len,
        @ptrCast(&BASE[0]),
        c.GL_STATIC_DRAW
    );

    c.glGenBuffers(1, &ebo);
    c.glBindBuffer(c.GL_ELEMENT_ARRAY_BUFFER, ebo);
    c.glBufferData(
        c.GL_ELEMENT_ARRAY_BUFFER,
        @sizeOf(c.GLuint) * INDICES.len,
        @ptrCast(&INDICES[0]),
        c.GL_STATIC_DRAW
    );

    var chunk_shader = try Shader.compile(chunk_vertex, chunk_fragment);

    c.glUniform1f(
        chunk_shader.uniform("chunk_dimension"),
        CHUNK_LENGTH
    );

    var self: Self = .{
        .allocator = allocator,

        .permutations = permutations,

        .chunks = AutoHashMap(CoordPrimitive, *Chunk).init(allocator),
        .paint_chunks = ArrayList(*Chunk).init(allocator),
        .update_chunks = ArrayList(*Chunk).init(allocator),

        .render_chunks = AutoHashMap(CoordPrimitive, *Chunk).init(allocator),
        .render_radius = render_radius,

        .base_vbo = base_vbo,
        .ebo = ebo,

        .chunk_shader = chunk_shader
    };

    // Set up initial render list based on the spawn point.
    // This is what Minecraft is doing during the loading screen
    // you get when you create a new world - it shows
    // the chunks being rendered in a radius around the spawn point.
    const in_chunk = CoordPrimitive{
        @intFromFloat(std.math.floor(initial_spawn[0])),
        @intFromFloat(std.math.floor(initial_spawn[1])),
        @intFromFloat(std.math.floor(initial_spawn[2]))
    };
    try self.render_chunks.put(in_chunk, try self.addChunk(in_chunk));
    for (1..self.render_radius + 1) |r| {
        const y_distance = CoordPrimitive{
            0,
            -1 * @as(isize, @intCast(r)),
            0
        };

        // Place middle top and bottom chunks.
        // const top_middle = Coord.sum(in_chunk, CoordPrimitive{0, -1 * radius, 0});
        // const bottom_middle = Coord.sum(in_chunk, CoordPrimitive{0, 1 * radius, 0});
        // try self.render_chunks.put(top_middle, try self.addChunk(top_middle));
        // try self.render_chunks.put(bottom_middle, try self.addChunk(bottom_middle));

        // Rest of top and bottom.
        for (0..r + 1) |z_spread| {
            const z: isize = @intCast(z_spread);
            for (0..r + 1) |x_spread| {
                const x: isize = @intCast(x_spread);

                const top_left = Coord.sum(y_distance, CoordPrimitive{-1 * x, 0, -1 * z});
                const top_right = Coord.sum(y_distance, CoordPrimitive{x, 0, z});

                try self.render_chunks.put(top_left, try self.addChunk(top_left));
                if (!Coord.equals(top_left, top_right)) try self.render_chunks.put(top_right, try self.addChunk(top_right));
            }
            std.debug.print("\n", .{});
        }
    }

    return self;
}

pub fn deinit(self: *Self) void {
    var chunks = self.chunks.iterator();
    while (chunks.next()) |entry| {
        const chunk = entry.value_ptr.*;
        chunk.deinit();
        self.allocator.destroy(chunk);
    }
    self.chunks.deinit();

    self.paint_chunks.deinit();
    self.update_chunks.deinit();
    self.render_chunks.deinit();

    c.glDeleteBuffers(1, &self.ebo);
    c.glDeleteBuffers(1, &self.base_vbo);

    self.chunk_shader.deinit();
}

pub fn addChunk(self: *Self, position: CoordPrimitive) !*Chunk {
    std.debug.assert(self.chunks.get(position) == null);
    const chunk = try self.allocator.create(Chunk);
    chunk.* = Chunk.init(self.ebo, self.base_vbo, .{.x = position[0], .y = position[1], .z = position[2]});
    try self.chunks.put(position, chunk);
    chunk.paint();
    return chunk;
}

pub fn update(self: *Self, max_time: Float) void {
    _ = self;
    _ = max_time;
}

pub fn render(self: *Self) void {
    self.chunk_shader.use();
    var chunks = self.render_chunks.valueIterator();
    while (chunks.next()) |chunk_ptr| {
        const chunk = chunk_ptr.*;
        chunk.render(.{});
    }
}