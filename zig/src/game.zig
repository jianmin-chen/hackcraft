const c = @cImport({
    @cInclude("glad/glad.h");
    @cInclude("GLFW/glfw3.h");
});
const std = @import("std");
const math = @import("math");
const CHUNK_LENGTH = @import("chunk.zig").CHUNK_LENGTH;
const ChunkManager = @import("chunk_manager.zig");
const Player = @import("player.zig");
const Input = @import("input.zig");

const Allocator = std.mem.Allocator;
const AutoHashMap = std.AutoHashMap;

const Float = math.types.Float;
const Matrix = math.matrix.Matrix;
const MatrixPrimitive = math.matrix.MatrixPrimitive;
const Vec3Primitive = math.vector.Vec3Primitive;
const noise = math.noise;

const Self = @This();

pub const Options = struct {
    internal_debug: bool = true,
    debug: bool = true,

    // Values for randomness.
    seed: u64 = 2,
    permutation: noise.PermutationTable = undefined,

    initial_width: c_int = 1024,
    initial_height: c_int = 768,

    fov: Float = 45,
    near: Float = 0.1,
    far: Float = 144,

    mouse_sensitivity: Float = 0.1,

    spawn_player: Player = .{
        .position = Vec3Primitive{0, 15, 0},
        .head = Vec3Primitive{0, 16, 0},
        .camera = Vec3Primitive{0, 16, 0},
        .target = Vec3Primitive{0, 0, 144},

        .speed = 5,
    },

    pub fn default() Options {
        var options: Options = .{};
        options.permutation = noise.permutations(options.seed);
        return options;
    }

    // pub fn from(path: []const u8) !Self {}
};

allocator: Allocator,
options: Options,

window: ?*c.GLFWwindow,
width: c_int,
height: c_int,

player: Player,
chunks: ChunkManager,
input: Input,

pub fn init(allocator: Allocator, options: Options) Self {
    if (c.glfwInit() == c.GL_FALSE) @panic("Unable to initialize GLFW");
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
        @panic("Unable to open window through GLFW");
    }
    c.glfwMakeContextCurrent(window);

    if (
        c.gladLoadGLLoader(
            @ptrCast(&c.glfwGetProcAddress)
        ) == c.GL_FALSE
    ) @panic("Unable to locate OpenGL API pointers with glad");

    // c.glEnable(c.GL_CULL_FACE);
    if (options.internal_debug) 
        c.glPolygonMode(c.GL_FRONT_AND_BACK, c.GL_LINE);

    return .{
        .allocator = allocator,
        .options = options,

        .window = window,
        .width = options.initial_width,
        .height = options.initial_height,

        .player = options.spawn_player,
        .chunks = ChunkManager.init(allocator, options.permutation, options.far / CHUNK_LENGTH),
        .input = .{
            .keys = AutoHashMap(c_int, bool).init(allocator),
            .mouse = .{
                // Start out in the center of the screen.
                .last_x = @as(Float, @floatFromInt(options.initial_width)) / 2,
                .last_y = @as(Float, @floatFromInt(options.initial_height)) / 2,
                .sensitivity = options.mouse_sensitivity
            }
        }
    };
}

pub fn deinit(self: *Self) void {
    c.glfwTerminate();
    self.chunks.deinit();
    self.input.deinit();
}

pub fn loop(self: *Self) !void {
    try self.chunks.addChunk();

    self.adjustPerspective();
    const view_location = self.chunks.chunk_shader.uniform("view");

    var prev = c.glfwGetTime();
    var elapsed: f64 = 0;
    var frames: usize = 0;
    while (c.glfwWindowShouldClose(self.window) == c.GL_FALSE) {
        c.glClearColor(0.0, 0.0, 0.0, 1.0);
        c.glClear(c.GL_COLOR_BUFFER_BIT);

        const timestamp = c.glfwGetTime();
        const dt = timestamp - prev;
        prev = timestamp;

        if (self.options.debug) {
            frames += 1;
            elapsed += dt;
            if (elapsed >= 1.0) {
                if (self.options.internal_debug) std.debug.print("{d} fps\n", .{frames});
                frames = 0;
                elapsed = 0;
            }
        }

        self.player.update(@floatCast(dt));
        const camera = self.player.view();
        const view = Matrix.inverse(camera);
        c.glUniformMatrix4fv(view_location, 1, c.GL_FALSE, @ptrCast(&view[0]));

        self.chunks.update();

        self.chunks.render();

        c.glfwSwapBuffers(self.window);
        c.glfwPollEvents();
    }
}

pub fn resize(self: *Self, resize_width: c_int, resize_height: c_int) void {
    c.glViewport(0, 0, resize_width, resize_height);
    self.width = resize_width;
    self.height = resize_height;
    self.adjustPerspective();
}

fn adjustPerspective(self: *Self) void {
    const perspective = Matrix.perspective(
        self.options.fov,
        @as(Float, @floatFromInt(self.width)) / @as(Float, @floatFromInt(self.height)),
        self.options.near,
        self.options.far
    );
    c.glUniformMatrix4fv(self.chunks.chunk_shader.uniform("perspective"), 1, c.GL_FALSE, @ptrCast(&perspective[0]));
}

pub fn keyInput(self: *Self, key: c_int, action: c_int) void {
    if (action == c.GLFW_REPEAT) return;
    self.input.keys.put(key, if (action == c.GLFW_RELEASE) false else true) catch {
        @panic("Unable to read key");
    };
    self.player.move(self.input.keys);
}

pub fn mouseInput(self: *Self, x: Float, y: Float) void {
    if (self.input.mouse.x == null or self.input.mouse.y == null) {
        self.input.mouse.last_x = x;
        self.input.mouse.last_y = y;
    } else {
        self.input.mouse.last_x = self.input.mouse.x;
        self.input.mouse.last_y = self.input.mouse.y;
    }
    self.input.mouse.x = x;
    self.input.mouse.y = y;

    // self.player.rotate(self.input.mouse);
}