const c = @cImport({
    @cInclude("glad/glad.h");
    @cInclude("GLFW/glfw3.h");
});
const std = @import("std");
const math = @import("math");
const Block = @import("block.zig");

const Allocator = std.mem.Allocator;
const ArrayList = std.ArrayList;

const FLOAT = math.types.FLOAT;

pub const CHUNK_LENGTH = 16;
pub const CHUNK_SIZE = CHUNK_LENGTH * CHUNK_LENGTH * CHUNK_LENGTH;

pub const OFFSET_SIZE = 3;
pub const INDEX_SIZE = 1;
pub const INSTANCE_SIZE = OFFSET_SIZE + INDEX_SIZE;

pub const vertex = 
    \\#version 330 core
    \\
    \\layout (location = 0) in vec3 base;
    \\layout (location = 1) in vec3 offset;
    \\layout (location = 2) in float index;
    \\
    \\uniform mat4 projection;
    \\uniform mat4 view;
    \\uniform mat4 model;
    \\
    \\void main() {
    \\  if (index == -1.0) {
    \\      // block isn't active,
    \\      // discard by attaching value that will be clipped.
    \\      gl_Position = vec4(-2.0, 0, 0, 1.0); 
    \\  }
    \\  mat4 mvp = projection * view * model;
    \\  gl_Position = mvp * vec4(base, 1.0);
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

x: isize = 0,
y: isize = 0,
z: isize = 0,

pub fn init(ebo: c_uint, base_vbo: c_uint) Self {
    var vao: c_uint = undefined;
    var vbo: c_uint = undefined;

    c.glGenVertexArrays(1, &vao);
    c.glGenBuffers(1, &vbo);

    const self: Self = .{
        .blocks = [_]Block{Block.init()} ** CHUNK_SIZE,
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

    c.glBindBuffer(c.GL_ARRAY_BUFFER, vbo);
    c.glBufferData(
        c.GL_ARRAY_BUFFER,
        @sizeOf(c.GLfloat) * CHUNK_SIZE * INSTANCE_SIZE,
        null,
        c.GL_DYNAMIC_DRAW
    );

    // Offset of entire chunk. 
    c.glVertexAttribPointer(
        1,
        3,
        c.GL_FLOAT,
        c.GL_FALSE,
        3 * @sizeOf(c.GLfloat),
        null
    );
    c.glEnableVertexAttribArray(1);
    c.glVertexAttribDivisor(1, 1);

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
    c.glDrawElements(
        c.GL_TRIANGLES,
        @intCast(Block.EDGES.len),
        c.GL_UNSIGNED_INT,
        null
    );
}
