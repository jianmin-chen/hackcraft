const c = @cImport({
    @cInclude("glad/glad.h");
    @cInclude("GLFW/glfw3.h");
});
const std = @import("std");

// All the possible vertices of a 1x1x1 base cube at (0, 0, 0).
pub const VERTICES = [_]c.GLfloat{
    0, 0, 0, // 0
    1, 0, 0, // 1
    0, 1, 0, // 2 
    1, 1, 0, // 3
    0, 0, 1, // 4
    1, 0, 1, // 5
    0, 1, 1, // 6
    1, 1, 1  // 7
};

// How the base cube should be rendered by glDrawElements
pub const EDGES = [_]c.GLuint{
    1, 2, 0, 1, 3, 2, // Front
    5, 6, 4, 5, 7, 6, // Back
    
    7, 2, 3, 7, 6, 2, // Top
    // 5, 0, 1, 5, 4, 0, // Bottom
    // 4, 2, 0, 4, 6, 2, // Left
    // 5, 3, 1, 5, 7, 3   // Right
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