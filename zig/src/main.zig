const c = @cImport({
    @cInclude("glad/glad.h");
    @cInclude("GLFW/glfw3.h");
});
const std = @import("std");
const math = @import("math");
const ChunkManager = @import("chunk_manager.zig");

const Allocator = std.mem.Allocator;

const Matrix = math.Matrix;
const MatrixPrimitive = math.MatrixPrimitive;
const FLOAT = math.constants.FLOAT;

const Options = struct {
    debug: bool = true,

    initial_width: c_int = 1000,
    initial_height: c_int = 700,

    width: c_int = 1000,
    height: c_int = 700,

    fov: FLOAT = 45,
    near: FLOAT = 0.1,
    far: FLOAT = 100,
    perspective: MatrixPrimitive = undefined,

    const Self = @This();

    pub fn adjustPerspective(self: *Self) void {
        self.perspective = Matrix.perspective(
            self.fov,
            @as(FLOAT, @floatFromInt(self.width)) / @as(FLOAT, @floatFromInt(self.height)),
            self.near,
            self.far
        );
    }

    // pub fn from(path: []const u8) !Self {
    // }
};

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer std.debug.assert(gpa.deinit() == .ok);

    const allocator = gpa.allocator();

    var options = Options{};

    if (c.glfwInit() == c.GL_FALSE)
        return error.InitializationError;
    c.glfwWindowHint(c.GLFW_CONTEXT_VERSION_MAJOR, 3);
    c.glfwWindowHint(c.GLFW_CONTEXT_VERSION_MINOR, 3);
    if (comptime @import("builtin").os.tag == .macos)
        c.glfwWindowHint(c.GLFW_OPENGL_FORWARD_COMPAT, c.GL_TRUE);

    const window = c.glfwCreateWindow(
        options.initial_width,
        options.initial_height,
        "Hackcraft",
        null,
        null
    );
    if (window == null) {
        c.glfwTerminate();
        return error.InitializationError;
    }
    c.glfwMakeContextCurrent(window);
    _ = c.glfwSetFramebufferSizeCallback(window, resize);

    if (
        c.gladLoadGLLoader(
            @ptrCast(&c.glfwGetProcAddress)
        ) == c.GL_FALSE
    ) return error.InitializationError;

    // c.glEnable(c.GL_CULL_FACE);

    var chunks = ChunkManager.init(allocator);
    defer chunks.deinit();

    try chunks.addChunk();

    options.adjustPerspective();
    std.debug.print("{d}\n", .{options.perspective});
    c.glUniformMatrix4fv(
        chunks.chunk_shader.uniform("projection"),
        1,
        c.GL_FALSE,
        @ptrCast(&options.perspective[0])
    );

    var x: FLOAT = 0;

    var prev = c.glfwGetTime();
    while (c.glfwWindowShouldClose(window) == c.GL_FALSE) {
        c.glClearColor(0.0, 0.0, 0.0, 1.0);
        c.glClear(c.GL_COLOR_BUFFER_BIT);

        const timestamp = c.glfwGetTime();
        const dt = timestamp - prev;
        prev = timestamp;

        if (options.debug) {
            std.debug.print("{d}\n", .{dt});
        }

        x += @floatCast(60 * dt);
        c.glUniformMatrix4fv(
            chunks.chunk_shader.uniform("projection"),
            1,
            c.GL_FALSE,
            @ptrCast(&Matrix.product(options.perspective, Matrix.zRotation(x))[0])
        );

        c.glPolygonMode(c.GL_FRONT_AND_BACK, c.GL_LINE);
        chunks.render();

        c.glfwSwapBuffers(window);
        c.glfwPollEvents();
    }

    c.glfwTerminate();
}

pub fn resize(window: ?*c.GLFWwindow, width: c_int, height: c_int) callconv(.C) void {
    _ = window;
    c.glViewport(0, 0, width, height);
}