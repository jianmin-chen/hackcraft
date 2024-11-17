// Manage all the chunks,
// namely for optimizing when to call render().

const c = @cImport({
    @cInclude("glad/glad.h");
});
const std = @import("std");
const block = @import("block.zig");
const math = @import("math");
const Chunk = @import("chunk.zig");
const Shader = @import("shader.zig");

const Allocator = std.mem.Allocator;
const ArrayList = std.ArrayList;
const assert = std.debug.assert;

const Float = math.types.Float;
const PermutationTable = math.noise.PermutationTable;

const BASE = block.VERTICES;
const INDICES = block.EDGES;

const CHUNK_LENGTH = Chunk.CHUNK_LENGTH;

const vertex = Chunk.vertex;
const fragment = Chunk.fragment;

const Self = @This();

allocator: Allocator,

permutations: PermutationTable,

// Chunks is the entire chunk cache,
// while the other ones filter out 
// for a specific purpose.
chunks: ArrayList(*Chunk),
paint_chunks: ArrayList(*Chunk),
update_chunks: ArrayList(*Chunk),

render_chunks: ArrayList(*Chunk),
render_radius: Float,

base_vbo: c_uint,
ebo: c_uint,

chunk_shader: Shader,

pub fn init(
    allocator: Allocator, 
    permutations: PermutationTable, 
    render_radius: Float
) Self {
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

    var chunk_shader = try Shader.compile(vertex, fragment);

    c.glUniform1f(
        chunk_shader.uniform("chunk_dimension"),
        CHUNK_LENGTH
    );

    return .{
        .allocator = allocator,

        .permutations = permutations,

        .chunks = ArrayList(*Chunk).init(allocator),
        .paint_chunks = ArrayList(*Chunk).init(allocator),
        .update_chunks = ArrayList(*Chunk).init(allocator), 

        .render_chunks = ArrayList(*Chunk).init(allocator),
        .render_radius = render_radius,

        .base_vbo = base_vbo,
        .ebo = ebo,

        .chunk_shader = chunk_shader
    };
}

pub fn deinit(self: *Self) void {
    for (self.chunks.items) |chunk| {
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

pub fn addChunk(self: *Self) !void {
    const chunk = try self.allocator.create(Chunk);
    chunk.* = Chunk.init(self.ebo, self.base_vbo, .{});
    chunk.noise(self.permutations);
    chunk.paint();
    try self.chunks.append(chunk);
    try self.paint_chunks.append(chunk);
    try self.render_chunks.append(chunk);
}

pub fn update(self: *Self) void {
    while (self.paint_chunks.items.len != 0) {
        const chunk = self.paint_chunks.orderedRemove(0);
        chunk.paint();
    } 
}

pub fn render(self: *Self) void {
    self.chunk_shader.use();
    for (self.render_chunks.items) |chunk| chunk.render(.{});
}