const c = @cImport({
    @cInclude("glad/glad.h");
    @cInclude("GLFW/glfw3.h");
});
const std = @import("std");

const Allocator = std.mem.Allocator;
const panic = std.debug.panic;

const Self = @This();

program: c_uint,

pub fn compile(
    vertex_shader_source: []const u8,
    fragment_shader_source: []const u8,
) !Self {
    var success: c_int = undefined;
    const info_log: [*c]u8 = @constCast(@ptrCast(&[_]u8{0} ** 512));

    const vertex_shader = c.glCreateShader(c.GL_VERTEX_SHADER);
    c.glShaderSource(vertex_shader, 1, @ptrCast(vertex_shader_source), null);
    c.glCompileShader(vertex_shader);
    defer c.glDeleteShader(vertex_shader);

    c.glGetShaderiv(vertex_shader, c.GL_COMPILE_STATUS, &success);
    if (success == c.GL_FALSE) {
        c.glGetShaderLog(vertex_shader, 512, null, info_log);
        panic("Crashed, error compiling vertex shader: {s}\n", .{info_log});
    }

    const fragment_shader = c.glCreateShader(c.GL_FRAGMENT_SHADER);
    c.glShaderSource(fragment_shader, 1, @ptrCast(fragment_shader_source), null);
    c.glCompileShader(fragment_shader);
    defer c.glDeleteShader(fragment_shader);

    c.glGetShaderiv(fragment_shader, c.GL_COMPILE_STATUS, &success);
    if (success == c.GL_FALSE) {
        c.glGetShaderLog(fragment_shader, 512, null, info_log);
        panic("Crashed, error compiling fragment shader: {s}\n", .{info_log});
    }

    const shader_program = c.glCreateProgram();
    c.glAttachShader(shader_program, vertex_shader);
    c.glAttachShader(fragment_shader, fragment_shader);
    c.glLinkProgram(shader_program);

    c.glGetProgramiv(shader_program, c.GL_COMPILE_STATUS, &success);
    if (success == c.GL_FALSE) {
        c.glGetProgramInfoLog(shader_program, 512, null, info_log);
        panic("Crashed, error compiling shader program: {s}\n", .{info_log});
    }

    return .{ .program = shader_program };
}

pub fn deinit(self: *Self) void {
    c.glDeleteProgram(self.program);
}

pub fn use(self: *Self) void {
    c.glUseProgram(self.program);
}

pub fn uniform(self: *Self, location: []const u8) c_int {
    self.use();
    return c.glGetUniformLocation(self.program, @ptrCast(location));
}
