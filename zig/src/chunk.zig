const c = @cImport({
    @cInclude("glad/glad.h");
});
const std = @import("std");
const math = @import("math");
const Block = @import("block.zig");

const Allocator = std.mem.Allocator;
const ArrayList = std.ArrayList;

const Float = math.types.Float;

pub const CHUNK_LENGTH = 4;
pub const CHUNK_SIZE = CHUNK_LENGTH * CHUNK_LENGTH * CHUNK_LENGTH;

// Convenience constants for those reading the source code.
// Also makes it easy to reason about and debug.
pub const VERTEX_SIZE = 3;
pub const OFFSET_SIZE = 3;
pub const INDEX_SIZE = 1;
pub const INSTANCE_SIZE = OFFSET_SIZE + INDEX_SIZE;

// There are a couple of optimizations
// that I wanted to make but decided against it
// due to the purpose of this codebase, like:
//
// * Packing values where possible into a uint
pub const vertex = 
    \\#version 330 core
    \\
    \\layout (location = 0) in vec3 base;
    \\layout (location = 1) in vec3 chunk;
    \\layout (location = 2) in float block;
    \\
    \\uniform mat4 projection;
    \\uniform mat4 view;
    \\uniform float chunk_dimension;
    \\
    \\void main() {
    \\  mat4 transform = projection * view;
    \\  // If block == -1.0, it's essentially turned off.
    \\  // Give vertex shader a point that will be clipped.
    \\  gl_Position = block == -1.0 ? vec4(-2.0) :
    \\                  transform * vec4(base + chunk * chunk_dimension + 
    \\                      vec3(
    \\                          mod(block, chunk_dimension),
    \\                          mod(floor(block / chunk_dimension), chunk_dimension),
    \\                          floor(block / (chunk_dimension * chunk_dimension))
    \\                      ), 1.0);
    \\}
;

pub const fragment = 
    \\#version 330 core
    \\
    \\out vec4 out_color;
    \\
    \\void main() {
    \\  out_color = vec4(1.0, 1.0, 1.0, 1.0); 
    \\}
;

const Self = @This();

blocks: [CHUNK_SIZE]Block,
size: usize = CHUNK_SIZE,

vao: c_uint,
vbo: c_uint,

x: isize,
y: isize,
z: isize,

pub fn init(
    ebo: c_uint, 
    base_vbo: c_uint, 
    options: struct {
        x: isize = 0,
        y: isize = 0,
        z: isize = 0
    }
) Self {
    var vao: c_uint = undefined;
    var vbo: c_uint = undefined;

    c.glGenVertexArrays(1, &vao);
    c.glGenBuffers(1, &vbo);

    const self: Self = .{
        .blocks = [_]Block{Block.init()} ** CHUNK_SIZE,
        .vao = vao,
        .vbo = vbo,

        .x = options.x,
        .y = options.y,
        .z = options.z
    };

    c.glBindVertexArray(vao);

    c.glBindBuffer(c.GL_ARRAY_BUFFER, base_vbo);
    c.glVertexAttribPointer(
        0,
        3,
        c.GL_FLOAT,
        c.GL_FALSE,
        3 * @sizeOf(Float),
        null
    );
    c.glEnableVertexAttribArray(0);

    // Initial buffer will contain
    // chunk x, y, z which is instanced; and
    // every index up to CHUNK_SIZE.
    var initial_buffer = 
        [_]Float{ @floatFromInt(self.x), @floatFromInt(self.y), @floatFromInt(self.z) } ++ [_]Float{0} ** CHUNK_SIZE;
    for (0..CHUNK_SIZE) |index| initial_buffer[index + 3] = @floatFromInt(index);
    std.debug.assert(initial_buffer.len == OFFSET_SIZE + CHUNK_SIZE);

    c.glBindBuffer(c.GL_ARRAY_BUFFER, vbo);
    c.glBufferData(
        c.GL_ARRAY_BUFFER,
        @sizeOf(Float) * (OFFSET_SIZE + CHUNK_SIZE),
        @ptrCast(&initial_buffer[0]),
        c.GL_DYNAMIC_DRAW
    );

    // Offset of entire chunk, instanced.
    // Changes once.
    c.glVertexAttribPointer(
        1,
        OFFSET_SIZE,
        c.GL_FLOAT,
        c.GL_FALSE,
        @sizeOf(Float) * (OFFSET_SIZE + INDEX_SIZE * CHUNK_SIZE),
        null
    );
    c.glEnableVertexAttribArray(1);
    c.glVertexAttribDivisor(1, CHUNK_SIZE);

    // Block index.
    // We start from zero for the bottom left,
    // and work our way up to CHUNK_SIZE - 1.
    const index_offset: *const anyopaque = @ptrFromInt(OFFSET_SIZE * @sizeOf(Float));
    c.glVertexAttribPointer(
        2,
        INDEX_SIZE,
        c.GL_FLOAT,
        c.GL_FALSE,
        @sizeOf(Float) * INDEX_SIZE,
        index_offset
    );
    c.glEnableVertexAttribArray(2);
    c.glVertexAttribDivisor(2, 1);

    c.glBindBuffer(c.GL_ELEMENT_ARRAY_BUFFER, ebo);

    return self;
}

pub fn deinit(self: *Self) void {
    c.glDeleteVertexArrays(1, &self.vao);
}

pub fn paint(self: *Self) void {
    // Rebuild entire set of vertices.
    // More performance-consuming than update().
    _ = self;
}

pub fn update(self: *Self) void {
    // Rebuild only changed blocks.
    // Since we're changing a sub buffer
    // and not repainting the entire chunk,
    // this is a cheaper operation than paint().
    _ = self;
} 

pub fn render(self: *Self) void {
    c.glBindVertexArray(self.vao);
    c.glDrawElementsInstanced(
        c.GL_TRIANGLES,
        @intCast(Block.EDGES.len),
        c.GL_UNSIGNED_INT,
        null,
        CHUNK_SIZE
    );
}
