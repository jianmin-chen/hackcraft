// Manage all the chunks,
// namely for optimizing when to call render().

const c = @cImport({
    @cInclude("glad/glad.h");
    @cInclude("GLFW/glfw3.h");
});
const std = @import("std");
const Chunk = @import("chunk.zig");

const Allocator = std.mem.Allocator;
const ArrayList = std.ArrayList;

const Self = @This();

allocator: Allocator,
chunks: ArrayList(*Chunk),

ebo: c_uint,
base_vbo: c_uint,

pub fn init(allocator: Allocator) Self {
    var ebo: c_uint = undefined;
    var base_vbo: c_uint = undefined;

    c.glGenBuffers(1, &ebo);

    c.glGenBuffers(1, &base_vbo);

    return .{
        .allocator = allocator,
        .chunks = ArrayList(*Chunk).init(allocator),

        .ebo = ebo,
        .base_vbo = base_vbo
    };
}

pub fn deinit(self: *Self) void {
    for (self.chunks.items) |chunk| {
        chunk.deinit();
    }
    self.chunks.deinit();

    c.glDeleteBuffers(1, &self.ebo);
    c.glDeleteBuffers(1, &self.base_vbo);
}
