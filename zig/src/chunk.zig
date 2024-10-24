const c = @cImport({
    @cInclude("glad/glad.h");
    @cInclude("GLFW/glfw3.h");
});
const std = @import("std");
const Block = @import("block.zig");

const Allocator = std.mem.Allocator;

pub const CHUNK_SIZE = 16;

pub const vertex = 
    \\#version 330 core
    \\
    \\layout (location = 0) in vec3 base;
    \\
    \\uniform mat4 projection;
    \\
    \\out float z;
    \\
    \\void main() {
    \\  gl_Position = projection * vec4(base, 1.0);
    \\  z = base.z;
    \\}
;

pub const fragment = 
    \\#version 330 core
    \\
    \\in float z;
    \\
    \\out vec4 out_color;
    \\
    \\void main() {
    \\  out_color = vec4(z == 0.0 ? 1.0 : 0.0, 1.0, 1.0, 1.0); 
    \\}
;

const Self = @This();

blocks: [CHUNK_SIZE * CHUNK_SIZE]Block,
size: usize = CHUNK_SIZE * CHUNK_SIZE,

vao: c_uint,
vbo: c_uint,

x: isize = 0,
y: isize = 0,
z: isize = 0,

pub fn init(ebo: c_uint, base_vbo: c_uint) Self {
    var vao: c_uint = undefined;
    var vbo: c_uint = undefined;

    c.glGenVertexArrays(1, &vao);
    c.glGenBuffers(1, &vbo);

    const self: Self = .{
        .blocks = [_]Block{Block.init()} ** CHUNK_SIZE ** CHUNK_SIZE,
        .vao = vao,
        .vbo = vbo,
    };

    c.glBindVertexArray(vao);

    c.glBindBuffer(c.GL_ARRAY_BUFFER, base_vbo);
    c.glVertexAttribPointer(
        0,
        3,
        c.GL_FLOAT,
        c.GL_FALSE,
        3 * @sizeOf(c.GLfloat),
        null
    );
    c.glEnableVertexAttribArray(0);

    c.glBindBuffer(c.GL_ELEMENT_ARRAY_BUFFER, ebo);

    return self;
}

pub fn deinit(self: *Self) void {
    c.glDeleteVertexArrays(1, &self.vao);
}

pub fn render(self: *Self) void {
    c.glBindVertexArray(self.vao);
    c.glDrawElements(
        c.GL_TRIANGLES,
        @intCast(Block.EDGES.len),
        c.GL_UNSIGNED_INT,
        null
    );
}
