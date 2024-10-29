const c = @cImport({
    @cInclude("glad/glad.h");
    @cInclude("GLFW/glfw3.h");
});
const std = @import("std");

// All the possible vertices of a 1x1 base cube at (0, 0, 0).
pub const VERTICES = [_]c.GLfloat{
    0, 0, 0,
    1, 0, 0,
    0, 1, 0,
    1, 1, 0,
    0, 0, 1,
    1, 0, 1,
    0, 1, 1,
    1, 1, 1
};

// How the base cube should be rendered by glDrawElements
pub const EDGES = [_]c.GLuint{
    0, 1, 3, 0, 3, 2, // Front
    4, 5, 7, 4, 7, 6, // Back
    2, 3, 7, 2, 7, 6, // Top
    0, 1, 5, 0, 5, 4, // Bottom
    0, 4, 6, 0, 6, 2, // Left
    1, 5, 7, 1, 7, 3  // Right
};

pub const BlockKind = enum(u8) {
    grass = 2,
    _
};

const Self = @This();

kind: BlockKind = .grass,
active: bool = true,

pub fn init() Self {
    return .{};
}