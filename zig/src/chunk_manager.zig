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

const vertex_shader = Chunk.vertex_shader;
const fragment_shader = Chunk.fragment_shader;

const Float = math.types.Float;
const PermutationTable = math.noise.PermutationTable;

const Vec3 = math.vector.Vec3(Float); 
const Vec3Primitive = Vec3.Primitive; 

const Coord = block.Coord;
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

chunk_shader: Shader,

pub fn init(
    allocator: Allocator,
    permutations: PermutationTable,
    initial_spawn: Vec3Primitive,
    render_radius: usize
) !Self {
    const self: Self = .{
        .allocator = allocator,

        .permutations = permutations,

        .chunks = AutoHashMap(CoordPrimitive, *Chunk).init(allocator),
        .paint_chunks = ArrayList(*Chunk).init(allocator),
        .update_chunks = ArrayList(*Chunk).init(allocator),

        .render_chunks = AutoHashMap(CoordPrimitive, *Chunk).init(allocator),
        .render_radius = render_radius,

        .chunk_shader = try Shader.compile(vertex_shader, fragment_shader)
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
    _ = in_chunk;

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

    self.chunk_shader.deinit();
}

pub fn addChunk(self: *Self, position: CoordPrimitive) !*Chunk {
    std.debug.assert(self.chunks.get(position) == null);
    const chunk = try self.allocator.create(Chunk);
    chunk.* = Chunk.init(.{.position = position});
    try self.chunks.put(position, chunk);
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