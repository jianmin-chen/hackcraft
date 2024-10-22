const c = @cImport({
    @cInclude("glad/glad.h");
    @cInclude("GLFW/glfw3.h");
});
const std = @import("std");

pub const VERTICES: []c.GLfloat = []c.GLfloat{
    
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