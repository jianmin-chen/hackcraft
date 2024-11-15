const c = @cImport({
    @cInclude("glad/glad.h");
    @cInclude("GLFW/glfw3.h");
});
const std = @import("std");
const math = @import("math");
const ChunkManager = @import("chunk_manager.zig");
const Player = @import("player.zig");
const Input = @import("input.zig");

const Allocator = std.mem.Allocator;
const AutoHashMap = std.AutoHashMap;

const Float = math.types.Float;
const Matrix = math.Matrix;
const MatrixPrimitive = math.MatrixPrimitive;
const Vec3Primitive = math.Vec3Primitive;

var options: Options = .{};
var input: Input = undefined;
var player: Player = undefined;
var dt: f64 = 0;

const Options = struct {
    debug: bool = true,

    initial_width: c_int = 1000,
    initial_height: c_int = 700,

    width: c_int = 1024,
    height: c_int = 768,

    fov: Float = 45,
    near: Float = 0.1,
    far: Float = 100,
    perspective: MatrixPrimitive = undefined,

    mouse_sensitivity: Float = 0.1,

    initial_player: Player = .{
        .position = Vec3Primitive{0, 0, 0},
        .head = Vec3Primitive{0, 1, 0},
        .camera = Vec3Primitive{0, 1, 0},
        .target = Vec3Primitive{0, 0, 144},

        .speed = 2.5,
        .view_distance = 144
    },

    const Self = @This();

    pub fn adjustPerspective(self: *Self) void {
        self.perspective = Matrix.perspective(
            self.fov,
            @as(Float, @floatFromInt(self.width)) / @as(Float, @floatFromInt(self.height)),
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
    if (options.debug) 
         c.glPolygonMode(c.GL_FRONT_AND_BACK, c.GL_LINE);

    player = options.initial_player;

    input = .{
        .keys = AutoHashMap(c_int, bool).init(allocator),
        .mouse = .{
            // Start out in the center of the screen.
            .last_x = @as(Float, @floatFromInt(options.width)) / 2,
            .last_y = @as(Float, @floatFromInt(options.height)) / 2,
            .sensitivity = options.mouse_sensitivity
        }
    };
    defer input.deinit();
    c.glfwSetInputMode(window, c.GLFW_CURSOR, c.GLFW_CURSOR_DISABLED);
    _ = c.glfwSetKeyCallback(window, updateKeys);
    _ = c.glfwSetCursorPosCallback(window, updateMouse);

    var chunks = ChunkManager.init(allocator);
    defer chunks.deinit();

    try chunks.addChunk();
    // try chunks.addChunk();

    options.adjustPerspective();
    c.glUniformMatrix4fv(
        chunks.chunk_shader.uniform("projection"),
        1,
        c.GL_FALSE,
        @ptrCast(&options.perspective[0])
    );

    const view_location = chunks.chunk_shader.uniform("view");

    var prev = c.glfwGetTime();
    var accum: f64 = 0;
    var frames: usize = 0;
    while (c.glfwWindowShouldClose(window) == c.GL_FALSE) {
        c.glClearColor(0.0, 0.0, 0.0, 1.0);
        c.glClear(c.GL_COLOR_BUFFER_BIT);

        const timestamp = c.glfwGetTime();
        dt = timestamp - prev;
        prev = timestamp;

        if (options.debug) {
            frames += 1;
            accum += dt;
            if (accum >= 1.0) {
                std.debug.print("{d} fps\n",  .{frames});
                frames = 0;
                accum = 0;
            }
        }

        chunks.update();

        const camera = player.view();
        const view = Matrix.inverse(camera);
        c.glUniformMatrix4fv(
            view_location,
            1,
            c.GL_FALSE,
            @ptrCast(&view[0])
        );
        
        chunks.render();
        player.update(@floatCast(dt), &input);

        c.glfwSwapBuffers(window);
        c.glfwPollEvents();
    }

    c.glfwTerminate();
}

fn resize(_: ?*c.GLFWwindow, width: c_int, height: c_int) callconv(.C) void {
    c.glViewport(0, 0, width, height);
    options.width = width;
    options.height = height;
}

fn updateKeys(_: ?*c.GLFWwindow, key: c_int, _: c_int, action: c_int, _: c_int) callconv(.C) void {
    input.keys.put(key, if (action == c.GLFW_RELEASE) false else true) catch {
        @panic("Unable to read key");
    };
}

fn updateMouse(_: ?*c.GLFWwindow, x: f64, y: f64) callconv(.C) void {
    if (input.mouse.first) {
        input.mouse.last_x = @floatCast(x);
        input.mouse.last_y = @floatCast(y);
        input.mouse.first = false;
    }
    input.mouse.last_x = input.mouse.x;
    input.mouse.last_y = input.mouse.y;
    input.mouse.x = @floatCast(x);
    input.mouse.y = @floatCast(y);
}