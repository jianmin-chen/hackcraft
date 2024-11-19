// There are a couple of optimizations we can do.
// Whether or not a cube is active can affect whether or not it shows up,
// but a cube may not be rendered even if it is active.
//
// In order:
// * If a cube isn't active, skip.
// * If a cube is on the outer edge of a chunk and is active, it gets rendred.
//   We don't do face merging between chunks but if chunks are optimized, this shouldn't be an issues.
// * Don't render cubes that have neighbors that are all active,
//   regardless of whether or not they're being rendered.
// * Determine indices of vertices to render by checking the neighbors of faces;
//   this is basically merging the faces.
//
// There are other optimizations you could do, including
// greedy meshing and level of detail.

const c = @cImport({
    @cInclude("glad/glad.h");
});
const std = @import("std");
const math = @import("math");
const Block = @import("block.zig");

const Allocator = std.mem.Allocator;
const ArrayList = std.ArrayList;

const Float = math.types.Float;

const Coord = Block.Coord;
const CoordPrimitive = Block.CoordPrimitive;

pub const CHUNK_LENGTH = 3;
pub const CHUNK_SIZE = CHUNK_LENGTH * CHUNK_LENGTH * CHUNK_LENGTH;

// Convenience constants to make it easy to reason about and debug.
pub const VERTEX_SIZE = 3;
pub const INSTANCE_SIZE = VERTEX_SIZE;
pub const FACE_SIZE = VERTEX_SIZE * 6;
pub const CUBE_SIZE = FACE_SIZE * 6;
pub const BUFFER_SIZE = CHUNK_SIZE * CUBE_SIZE;

pub const vertex_shader = 
    \\#version 330 core
    \\
    \\layout (location = 0) in vec3 vertex; 
    \\
    \\uniform mat4 perspective;
    \\uniform mat4 view;
    \\
    \\void main() {
    \\  mat4 transform = perspective * view;
    \\  gl_Position = transform * vec4(vertex, 1.0);
    \\}
;

pub const fragment_shader = 
    \\#version 330 core
    \\
    \\out vec4 out_color;
    \\
    \\void main() {
    \\  out_color = vec4(1.0, 1.0, 1.0, 1.0);
    \\}
;

const Self = @This();

noise_applied: bool = false,
position: CoordPrimitive,

blocks: [CHUNK_SIZE]Block,
total_vertices: usize = 0,

vao: c_uint,
vbo: c_uint,

pub fn init(
    options: struct {
        position: CoordPrimitive = CoordPrimitive{0, 0, 0}
    }
) Self {
    var vao: c_uint = undefined;
    var vbo: c_uint = undefined;

    c.glGenVertexArrays(1, &vao);
    c.glGenBuffers(1, &vbo);

    var self: Self = .{
        .blocks = [_]Block{Block.init()} ** CHUNK_SIZE,
        .vao = vao,
        .vbo = vbo,
        .position = options.position
    };

    c.glBindVertexArray(vao);

    c.glBindBuffer(c.GL_ARRAY_BUFFER, vbo);
    self.paint();

    // Vertex.
    c.glVertexAttribPointer(
        0,
        VERTEX_SIZE,
        c.GL_FLOAT,
        c.GL_FALSE,
        @sizeOf(Float) * INSTANCE_SIZE,
        null
    );
    c.glEnableVertexAttribArray(0);
    
    return self;
}

pub fn deinit(self: *Self) void {
    c.glDeleteBuffers(1, &self.vbo);
    c.glDeleteBuffers(1, &self.vbo);
    c.glDeleteVertexArrays(1, &self.vao);
}

// Return block at (x, y, z).
pub fn get(self: *Self, x: usize, y: usize, z: usize) Block {
    return self.blocks[z * CHUNK_LENGTH + y * CHUNK_LENGTH + x];
}

// Rebuild entire set of vertices.
// More performance-consuming than update().
pub fn paint(self: *Self) void {
    self.total_vertices = 0;
    var buffer = [_]Float{0} ** BUFFER_SIZE;
    for (0..CHUNK_LENGTH) |z| {
        for (0..CHUNK_LENGTH) |y| {
            for (0..CHUNK_LENGTH) |x| {
                const offset = CoordPrimitive{@intCast(x), @intCast(y), @intCast(z)};
                const should_render: bool = true;
                if (should_render) self.paint_block(&buffer, offset, .{});
            }
        }
    }
    // std.debug.print("{d}\n", .{buffer});
    c.glBindBuffer(c.GL_ARRAY_BUFFER, self.vbo);
    c.glBufferData(
        c.GL_ARRAY_BUFFER,
        @sizeOf(Float) * BUFFER_SIZE,
        @ptrCast(&buffer[0]),
        c.GL_DYNAMIC_DRAW
    );
}

// Helper function for paint() for painting individual blocks.
pub fn paint_block(
    self: *Self,
    buffer: *[BUFFER_SIZE]Float,
    offset: CoordPrimitive,
    faces: struct {
        front: bool = true,
        back: bool = true,
        top: bool = true,
        bottom: bool = true,
        left: bool = true,
        right: bool = true
    }
) void {
    const base = Coord.sum(self.position, offset);
    var buffer_offset: usize = @as(
        usize,
        @intCast(
            (offset[0] * CUBE_SIZE) +
            (offset[1] * CHUNK_LENGTH * CUBE_SIZE) +
            (offset[2] * CHUNK_LENGTH * CHUNK_LENGTH * CUBE_SIZE)
        )
    );
    std.debug.print("{d} {d}\n", .{base, buffer_offset});
    if (faces.front) {
        self.total_vertices += FACE_SIZE;
        for (Block.FRONT) |v| {
            const vertex = Coord.sum(base, v);
            for (vertex, 0..) |axis, i| buffer[buffer_offset + i] = @floatFromInt(axis);
            buffer_offset += VERTEX_SIZE;
        }
    } 
    if (faces.back) {
        self.total_vertices += FACE_SIZE;
        for (Block.BACK) |v| {
            const vertex = Coord.sum(base, v);
            for (vertex, 0..) |axis, i| buffer[buffer_offset + i] = @floatFromInt(axis);
            buffer_offset += VERTEX_SIZE;
        }
    }
    if (faces.top) {
        self.total_vertices += FACE_SIZE;
        for (Block.TOP) |v| {
            const vertex = Coord.sum(base, v);
            for (vertex, 0..) |axis, i| buffer[buffer_offset + i] = @floatFromInt(axis);
            buffer_offset += VERTEX_SIZE;
        }
    }
    if (faces.bottom) {
        self.total_vertices += FACE_SIZE;
        for (Block.BOTTOM) |v| {
            const vertex = Coord.sum(base, v);
            for (vertex, 0..) |axis, i| buffer[buffer_offset + i] = @floatFromInt(axis);
            buffer_offset += VERTEX_SIZE;
        }
    }
    if (faces.left) {
        self.total_vertices += FACE_SIZE;
        for (Block.LEFT) |v| {
            const vertex = Coord.sum(base, v);
            for (vertex, 0..) |axis, i| buffer[buffer_offset + i] = @floatFromInt(axis);
            buffer_offset += VERTEX_SIZE;
        }
    }
    if (faces.right) {
        self.total_vertices += FACE_SIZE;
        for (Block.RIGHT) |v| {
            const vertex = Coord.sum(base, v);
            for (vertex, 0..) |axis, i| buffer[buffer_offset + i] = @floatFromInt(axis);
            buffer_offset += VERTEX_SIZE;
        }
    }
}

// Rebuild only changed blocks.
// Since we're changing a sub buffer
// and not repainting the entire chunk,
// this is a cheaper operation than paint().
pub fn update(self: *Self) void {
    _ = self;
}

pub fn render(self: *Self, flags: struct {
    mode: c.GLenum = c.GL_TRIANGLES
}) void {
    c.glBindVertexArray(self.vao);
    c.glDrawArrays(
        flags.mode,
        0,
        @intCast(self.total_vertices),
    );
}