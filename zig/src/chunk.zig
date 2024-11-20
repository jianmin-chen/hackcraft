const c = @cImport({
    @cInclude("glad/glad.h");
});
const std = @import("std");
const math = @import("math");
const Block = @import("block.zig");

const Allocator = std.mem.Allocator;
const ArrayList = std.ArrayList;
const AutoHashMap = std.AutoHashMap;

const Float = math.types.Float;

const Coord = Block.Coord;
const CoordPrimitive = Block.CoordPrimitive;

const Self = @This();

pub const CHUNK_LENGTH = 16;
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

const Faces = struct {
    front: bool = true,
    back: bool = true,
    top: bool = true,
    bottom: bool = true,
    left: bool = true,
    right: bool = true
};

allocator: Allocator,
vao: c_uint,
vbo: c_uint,

noise_applied: bool = false,
position: CoordPrimitive,

blocks: [CHUNK_SIZE]Block,
total_vertices: usize = 0,

pub fn init(
    allocator: Allocator,
    options: struct {
        position: CoordPrimitive = CoordPrimitive{0, 0, 0}
    }
) Self {
    var vao: c_uint = undefined;
    var vbo: c_uint = undefined;

    c.glGenVertexArrays(1, &vao);
    c.glGenBuffers(1, &vbo);

    c.glBindVertexArray(vao);

    c.glBindBuffer(c.GL_ARRAY_BUFFER, vbo);

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
    
    return .{
        .allocator = allocator,
        .vao = vao,
        .vbo = vbo,
        .position = options.position,
        .blocks = [_]Block{Block.init()} ** CHUNK_SIZE
    };
}

pub fn deinit(self: *Self) void {
    c.glDeleteBuffers(1, &self.vbo);
    c.glDeleteBuffers(1, &self.vbo);
    c.glDeleteVertexArrays(1, &self.vao);
}

pub fn noise(self: *Self, permutations: math.noise.PermutationTable) void {
    self.noise_applied = true;
    for (0..CHUNK_LENGTH) |z_offset| {
        for (0..CHUNK_LENGTH) |x_offset| {
            const z: isize = self.position[2] * CHUNK_LENGTH + @as(isize, @intCast(z_offset));
            const x: isize = self.position[0] * CHUNK_LENGTH + @as(isize, @intCast(x_offset));
            const n = (math.noise.fbm2D(@floatFromInt(x), @floatFromInt(z), permutations, .{}) + 1) * 0.5;
            const elevation: usize = @intFromFloat(std.math.floor(n * CHUNK_LENGTH));
            std.debug.print("{d}\n", .{elevation});
            for (0..elevation) |y| {
                self.blocks[z_offset * CHUNK_LENGTH + (CHUNK_LENGTH - y) * CHUNK_LENGTH + x_offset].active = false;
            }
        }
    }
}

pub fn get(self: *Self, x: usize, y: usize, z: usize, filter_active: bool) ?Block {
    const block = self.blocks[z * CHUNK_LENGTH + y * CHUNK_LENGTH + x];
    if (!block.active and filter_active) return null;
    return block;
}

pub fn block_neighbors(self: *Self, block: CoordPrimitive) !AutoHashMap(CoordPrimitive, Block) {
    var neighbors = AutoHashMap(CoordPrimitive, Block).init(self.allocator);
    const neighbor_coords: [26]CoordPrimitive = [_]CoordPrimitive{
        Coord.sum(block, CoordPrimitive{-1, -1, 1}),
        Coord.sum(block, CoordPrimitive{0, -1, 1}),
        Coord.sum(block, CoordPrimitive{1, -1, 1}),

        Coord.sum(block, CoordPrimitive{-1, -1, 0}),
        Coord.sum(block, CoordPrimitive{0, -1, 0}),
        Coord.sum(block, CoordPrimitive{1, -1, 0}),

        Coord.sum(block, CoordPrimitive{-1, -1, -1}),
        Coord.sum(block, CoordPrimitive{0, -1, -1}),
        Coord.sum(block, CoordPrimitive{1, -1, -1}),

        Coord.sum(block, CoordPrimitive{-1, 0, 1}),
        Coord.sum(block, CoordPrimitive{0, 0, 1}),
        Coord.sum(block, CoordPrimitive{1, 0, 1}),

        Coord.sum(block, CoordPrimitive{-1, 0, 0}),
        Coord.sum(block, CoordPrimitive{1, 0, 0}),

        Coord.sum(block, CoordPrimitive{-1, 0, -1}),
        Coord.sum(block, CoordPrimitive{0, 0, -1}),
        Coord.sum(block, CoordPrimitive{1, 0, -1}),

        Coord.sum(block, CoordPrimitive{-1, 1, 1}),
        Coord.sum(block, CoordPrimitive{0, 1, 1}),
        Coord.sum(block, CoordPrimitive{1, 1, 1}),

        Coord.sum(block, CoordPrimitive{-1, 1, 0}),
        Coord.sum(block, CoordPrimitive{0, 1, 0}),
        Coord.sum(block, CoordPrimitive{1, 1, 0}),

        Coord.sum(block, CoordPrimitive{-1, 1, -1}),
        Coord.sum(block, CoordPrimitive{0, 1, -1}),
        Coord.sum(block, CoordPrimitive{1, 1, -1})
    };

    for (neighbor_coords) |coord| {
        if (
            coord[0] < 0 or coord[1] < 0 or coord[2] < 0 or
            coord[0] > CHUNK_LENGTH - 1 or coord[1] > CHUNK_LENGTH - 1 or coord[2] > CHUNK_LENGTH - 1
        ) continue;
        const neighbor = self.get(@intCast(coord[0]), @intCast(coord[1]), @intCast(coord[2]), true);
        if (neighbor) |value| try neighbors.put(coord, value);
    }

    return neighbors;
}

// Rebuild entire set of vertices.
// More performance-consuming than update().
// 
// Here we also perform some chunk optimizations.
// There are some we haven't done, including greedy meshing and level of detail.
pub fn paint(self: *Self) !void {
    self.total_vertices = 0;
    var buffer = [_]Float{0} ** BUFFER_SIZE;
    for (0..CHUNK_LENGTH) |z| {
        for (0..CHUNK_LENGTH) |y| {
            for (0..CHUNK_LENGTH) |x| {
                const block = self.get(x, y, z, true);

                // If a block isn't active, skip.
                if (block == null) continue;

                var should_render: bool = false;
                const offset = CoordPrimitive{@intCast(x), @intCast(y), @intCast(z)};
                const faces: Faces = .{};
                var neighbors = try self.block_neighbors(offset);
                defer neighbors.deinit();

                // If a block is on the outer edge of a chunk and is active, it gets rendered.
                // We don't do face merging between chunks but if chunks are optimized, this shouldn't matter much.
                //
                // Else, don't render cubes that have neighbors that are all active,
                // regardless of whether or not they're being rendered.
                if (x == 0 or y == 0 or z == 0 or x == CHUNK_LENGTH - 1 or y == CHUNK_LENGTH - 1 or z == CHUNK_LENGTH - 1) {
                    // std.debug.print("rendered: {d}\n", .{offset});
                    should_render = true;
                } else if (neighbors.count() != 26) should_render = true;

                if (should_render) {
                    // Determine faces to render by checking the neighbors of faces;
                    // this is basically merging the faces.
                    // if (neighbors.get(Coord.sum(offset, CoordPrimitive{-1, 0, 0})) != null) 
                    //     faces.left = false;
                    // if (neighbors.get(Coord.sum(offset, CoordPrimitive{1, 0, 0})) != null)
                    //     faces.right = false;
                    self.paint_block(&buffer, offset, faces);
                }
            }
        }
    }
    c.glBindBuffer(c.GL_ARRAY_BUFFER, self.vbo);
    c.glBufferData(
        c.GL_ARRAY_BUFFER,
        @sizeOf(Float) * BUFFER_SIZE,
        @ptrCast(&buffer[0]),
        c.GL_DYNAMIC_DRAW
    );
}

pub fn paint_block(
    self: *Self,
    buffer: *[BUFFER_SIZE]Float,
    offset: CoordPrimitive,
    faces: Faces
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

// Repaint only changed blocks and their neighbors.
// Since we're changing a sub buffer and not repainting the entire chunk,
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