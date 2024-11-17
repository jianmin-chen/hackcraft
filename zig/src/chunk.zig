const c = @cImport({
    @cInclude("glad/glad.h");
});
const std = @import("std");
const math = @import("math");
const Block = @import("block.zig");

const Allocator = std.mem.Allocator;
const ArrayList = std.ArrayList;

const Float = math.types.Float;

pub const CHUNK_LENGTH = 36;
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
    \\uniform mat4 perspective;
    \\uniform mat4 view;
    \\uniform float chunk_dimension;
    \\
    \\void main() {
    \\  mat4 transform = perspective * view;
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

noise_applied: bool = false,

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
    var initial_buffer = [_]Float{@floatFromInt(self.x), @floatFromInt(self.y), @floatFromInt(self.z)} ++ [_]Float{0} ** CHUNK_SIZE;
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

pub fn noise(self: *Self, permutations: math.noise.PermutationTable) void {
    self.noise_applied = true;
    const range_x: usize = @intCast(self.x);
    const range_z: usize = @intCast(self.z);
    for (range_x * CHUNK_LENGTH..range_x * CHUNK_LENGTH + CHUNK_LENGTH) |x| {
        for (range_z * CHUNK_LENGTH..range_z * CHUNK_LENGTH + CHUNK_LENGTH) |z| {
            // Noise is between [0, 1].
            const n = (math.noise.fbm2D(@floatFromInt(x), @floatFromInt(z), permutations, .{}) + 1) * 0.5;
            const elevation: usize = @intFromFloat(std.math.floor(n * CHUNK_LENGTH));
            std.debug.print("{d}\n", .{elevation});
            for (0..elevation) |y| {
                // Now trim off blocks until trimmed off blocks = elevation.
                self.blocks[z * CHUNK_LENGTH + (CHUNK_LENGTH - y) * CHUNK_LENGTH + x].active = false;
            }
        }
    }
}

// Rebuild entire set of vertices.
// More performance-consuming than update().
pub fn paint(self: *Self) void {
    _ = self;
    // var buffer = [_]Float{@floatFromInt(self.x), @floatFromInt(self.y), @floatFromInt(self.z)} ++ [_]Float{0} ** CHUNK_SIZE;
    // for (0..CHUNK_SIZE) |index| {
    //     if (self.blocks[index].active) {
    //         buffer[index] = @floatFromInt(index);
    //     } else buffer[index] = -1;
    // }
    // const range_x: usize = @intCast(self.x);
    // const range_y: usize = @intCast(self.y);
    // const range_z: usize = @intCast(self.z);
    // var i: usize = 0;
    // for (range_x * CHUNK_LENGTH..range_x * CHUNK_LENGTH + CHUNK_LENGTH) |x| {
    //     for (range_y * CHUNK_LENGTH..range_y * CHUNK_LENGTH + CHUNK_LENGTH) |y| {
    //         for (range_z * CHUNK_LENGTH..range_z * CHUNK_LENGTH + CHUNK_LENGTH) |z| {
    //             if (self.blocks[z * CHUNK_LENGTH + (CHUNK_LENGTH - y) * CHUNK_LENGTH + x].active) {
    //                 buffer[i] = @floatFromInt(i);
    //             } else buffer[i] = -1;
    //             i += 1;
    //         }
    //     }
    // }
        
    // c.glBindBuffer(c.GL_ARRAY_BUFFER, self.vbo);
    // c.glBufferData(
    //     c.GL_ARRAY_BUFFER,
    //     @sizeOf(Float) * (OFFSET_SIZE + CHUNK_SIZE),
    //     @ptrCast(&buffer[0]),
    //     c.GL_DYNAMIC_DRAW
    // );
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
    c.glDrawElementsInstanced(
        flags.mode,
        @intCast(Block.EDGES.len),
        c.GL_UNSIGNED_INT,
        null,
        CHUNK_SIZE
    );
}
