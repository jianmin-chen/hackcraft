const c = @cImport({
    @cInclude("glad/glad.h");
    @cInclude("GLFW/glfw3.h");
});
const std = @import("std");

// All the possible vertices of a 1x1x1 base cube at (0, 0, 0).
pub const VERTICES = [_]c.GLfloat{
    -0.5, -0.5, -3.5, 
         0.5,  0.5, -3.5,
         0.5,  0.5, -3.5,
         0.5, -0.5, -3.5,
        -0.5,  0.5, -3.5,
        -0.5, -0.5, -3.5,

        -0.5, -0.5,  -2.5,
         0.5, -0.5,  -2.5,
         0.5,  0.5,  -2.5,
         0.5,  0.5,  -2.5,
        -0.5,  0.5,  -2.5,
        -0.5, -0.5,  -2.5,

        -0.5,  0.5,  -2.5,
        -0.5,  0.5, -3.5,
        -0.5, -0.5, -3.5,
        -0.5, -0.5, -3.5,
        -0.5, -0.5,  -2.5,
        -0.5,  0.5,  -2.5,

         0.5,  0.5,  -2.5,
         0.5,  0.5, -3.5,
         0.5, -0.5, -3.5,
         0.5, -0.5, -3.5,
         0.5, -0.5,  -2.5,
         0.5,  0.5,  -2.5,

        -0.5, -0.5, -3.5,
         0.5, -0.5, -3.5,
         0.5, -0.5,  -2.5,
         0.5, -0.5,  -2.5,
        -0.5, -0.5,  -2.5,
        -0.5, -0.5, -3.5,

        -0.5,  0.5, -3.5,
         0.5,  0.5, -3.5,
         0.5,  0.5,  -2.5,
         0.5,  0.5,  -2.5,
        -0.5,  0.5,  -2.5,
        -0.5,  0.5, -3.5
};

// How the base cube should be rendered by glDrawElements
pub const EDGES = [_]c.GLuint{
    0, 1, 3, 0, 3, 2, // Front
    4, 5, 7, 4, 7, 6, // Back
    2, 3, 7, 2, 7, 6, // Top
    0, 1, 5, 0, 5, 4, // Bottom
    6, 2, 0, 6, 0, 4, // Left
    7, 3, 1, 7, 1, 5  // Right
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