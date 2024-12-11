// Draws a circular crosshair
// to represent the mouse.
const c = @cImport({
    @cInclude("glad/glad.h");
});
const math = @import("math");

const Float = math.types.Float;

const Self = @This();

pub const vertex = 
    \\#version 330 core
    \\
    \\layout (location = 0) in vec2 vertex;
    \\
    \\uniform mat4 perspective;
    \\
    \\void main() {
    \\  gl_Position = perspective * vec4(vertex, 0.0, 1.0); 
    \\}
;

pub const fragment = 
    \\#version 330 core
    \\
    \\out vec4 out_color;
    \\
    \\float circle(vec2 p, float r) {
    \\  return length(p) - r;
    \\}
    \\
    \\void main() {
    \\  out_color = vec4(1.0, 1.0, 1.0, 1.0);
    \\}
;

vao: c_uint,
vbo: c_uint,

pub fn setup(size: usize) Self {
    var vao: c_uint = undefined;
    var vbo: c_uint = undefined;

    c.glGenVertexArrays(1, &vao);
    c.glGenVertexArrays(1, &vbo);

    c.glBindVertexArray(vao);

    const vertices = [_]Float{};
    _ = vertices;
    _ = size; 

    return .{
        .vao = vao,
        .vbo = vbo
    };
}

pub fn deinit(self: *Self) void {
    c.glDeleteVertexArrays(self.vao);
}

pub fn render(self: *Self) void {
    c.glBindVertexArray(self.vao);
    c.glDrawArrays(
        c.GL_TRIANGLES,
        0,
        6
    );
}