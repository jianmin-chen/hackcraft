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
pub const VERTICES_PER_FACE = 6;
pub const FACE_SIZE = VERTEX_SIZE * VERTICES_PER_FACE;
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
            const n = math.noise.fbm2D(@floatFromInt(x), @floatFromInt(z), permutations, .{});
            const elevation: usize = @intFromFloat(@max(1, std.math.floor(n * CHUNK_LENGTH)));
            for (1..elevation) |y| {
                self.get(x_offset, CHUNK_LENGTH - y, z_offset).active = false;
                // self.blocks[z_offset * CHUNK_LENGTH + (CHUNK_LENGTH - y) * CHUNK_LENGTH + x_offset].active = false;
            }
        }
    } 
}

pub fn get(self: *Self, x: usize, y: usize, z: usize) *Block {
    std.debug.assert(x < CHUNK_LENGTH and y < CHUNK_LENGTH and z < CHUNK_LENGTH);
    return &self.blocks[z * CHUNK_LENGTH * CHUNK_LENGTH + y * CHUNK_LENGTH + x];
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
        const neighbor = self.get(@intCast(coord[0]), @intCast(coord[1]), @intCast(coord[2]));
        if (neighbor.active) try neighbors.put(coord, neighbor.*);
    }
    return neighbors;
}

// Build set of vertices.
//
// Here we also perform some chunk optimizations.
// There are some we haven't done, including greedy meshing and level of detail.
pub fn npaint(self: *Self) !void {
    self.total_vertices = 0;
    // var buffer = [_]Float{0} ** BUFFER_SIZE;
    for (0..CHUNK_SIZE) |i| {
        const block = self.blocks[i];
        
        // If a block isn't active, skip.
        if (!block.active) continue;
    }
}

// Rebuild entire set of vertices on change.
//
// Here we also perform some chunk optimizations.
// There are some we haven't done, including greedy meshing and level of detail.
pub fn paint(self: *Self) !void {
    self.total_vertices = 0;
    var buffer = [_]Float{0} ** BUFFER_SIZE;
    for (0..CHUNK_LENGTH) |z| {
        for (0..CHUNK_LENGTH) |x| {
            for (0..CHUNK_LENGTH - 1) |y| {
                const block = self.get(x, CHUNK_LENGTH - y - 1, z);
                
                // If a block isn't active, skip.
                if (!block.active) continue;

                var should_render: bool = false;
                const offset = CoordPrimitive{@intCast(x), @intCast(CHUNK_LENGTH - y - 1), @intCast(z)};
                var faces: Faces = .{};
                var neighbors = try self.block_neighbors(offset);
                defer neighbors.deinit();

                // If a block is on the outer edge of a chunk and is active, it gets rendered.
                // We don't do face merging between chunks but if chunks are optimized, this shouldn't matter much.
                //
                // Else, don't render cubes that have neighbors that are all active,
                // regardless of whether or not they're being rendered.
                if (neighbors.count() != 26) {
                    should_render = true;
                }

                if (should_render) {
                    // Determine faces to render by checking the neighbors of faces;
                    // this is basically merging the faces.
                    if (neighbors.get(Coord.sum(offset, CoordPrimitive{0, 0, -1})) != null)
                        faces.front = false;
                    if (neighbors.get(Coord.sum(offset, CoordPrimitive{0, 0, 1})) != null)
                        faces.back = false;
                    if (neighbors.get(Coord.sum(offset, CoordPrimitive{0, 1, 0})) != null)
                        faces.top = false;
                    if (neighbors.get(Coord.sum(offset, CoordPrimitive{0, -1, 0})) != null)
                        faces.bottom = false;
                    if (neighbors.get(Coord.sum(offset, CoordPrimitive{-1, 0, 0})) != null)
                        faces.left = false;
                    if (neighbors.get(Coord.sum(offset, CoordPrimitive{1, 0, 0})) != null)
                        faces.right = false;
                    const base_vertex = Coord.sum(Coord.scalarProduct(self.position, CHUNK_LENGTH), offset);
                    self.paint_block(&buffer, base_vertex, faces);
                } else break;
            }
        }
    }
    c.glBindBuffer(c.GL_ARRAY_BUFFER, self.vbo);
    c.glBufferData(
        c.GL_ARRAY_BUFFER,
        @intCast(@sizeOf(Float) * VERTEX_SIZE * self.total_vertices),
        @ptrCast(&buffer[0]),
        c.GL_DYNAMIC_DRAW
    );
}

pub fn paint_block(
    self: *Self,
    buffer: *[BUFFER_SIZE]Float,
    base_vertex: CoordPrimitive,
    faces: Faces
) void {
    if (faces.front) self.paint_face(buffer, base_vertex, Block.FRONT);
    if (faces.back) self.paint_face(buffer, base_vertex, Block.BACK);
    if (faces.top) self.paint_face(buffer, base_vertex, Block.TOP);
    if (faces.bottom) self.paint_face(buffer, base_vertex, Block.BOTTOM);
    if (faces.left) self.paint_face(buffer, base_vertex, Block.LEFT);
    if (faces.right) self.paint_face(buffer, base_vertex, Block.RIGHT);
}

pub fn paint_face(
    self: *Self,
    buffer: *[BUFFER_SIZE]Float,
    base_vertex: CoordPrimitive,
    face: [VERTICES_PER_FACE]CoordPrimitive
) void {
    self.total_vertices += VERTICES_PER_FACE;
    var buffer_offset = self.total_vertices * VERTEX_SIZE;
    for (face) |v| {
        const vertex = Coord.sum(base_vertex, v);
        for (vertex, 0..) |axis, i| buffer[buffer_offset + i] = @floatFromInt(axis);
        buffer_offset += VERTEX_SIZE;
    }
}

pub fn render(self: *Self, flags: struct {
    mode: c.GLenum = c.GL_TRIANGLES
}) void {
    c.glBindVertexArray(self.vao);
    c.glDrawArrays(
        flags.mode,
        0,
        @intCast(self.total_vertices)
    );
}