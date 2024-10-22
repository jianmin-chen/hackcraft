const c = @cImport({
	@cInclude("glad/glad.h");
	@cInclude("GLFW/glfw3.h");
});
const std = @import("std");
const ChunkManager = @import("chunk_manager.zig");

const Allocator = std.mem.Allocator;

const INITIAL_WIDTH: c_int = 1200;
const INITIAL_HEIGHT: c_int = 800;

pub fn main() !void {
	var gpa = std.heap.GeneralPurposeAllocator(.{}){};
	defer std.debug.assert(gpa.deinit() == .ok);

	const allocator = gpa.allocator();

	if (c.glfwInit() == c.GL_FALSE)
		return error.InitializationError;
	c.glfwWindowHint(c.GLFW_CONTEXT_VERSION_MAJOR, 3);
	c.glfwWindowHint(c.GLFW_CONTEXT_VERSION_MINOR, 3);
	if (comptime @import("builtin").os.tag == .macos)
		c.glfwWindowHint(c.GLFW_OPENGL_FORWARD_COMPAT, c.GL_TRUE);
	
	const window = c.glfwCreateWindow(
		INITIAL_WIDTH,
		INITIAL_HEIGHT,
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

	var chunks = ChunkManager.init(allocator);
	defer chunks.deinit();

	while (c.glfwWindowShouldClose(window) == c.GL_FALSE) {
		c.glClearColor(0.0, 0.0, 0.0, 1.0);
		c.glClear(c.GL_COLOR_BUFFER_BIT);

		c.glfwSwapBuffers(window);
		c.glfwPollEvents();
	}

	c.glfwTerminate();
}

fn resize(window: ?*c.GLFWwindow, width: c_int, height: c_int) callconv(.C) void {
	_ = window;
	c.glViewport(0, 0, width, height);
}