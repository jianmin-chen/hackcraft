const c = @cImport({
    @cInclude("glad/glad.h");
    @cInclude("GLFW/glfw3.h");
});
const std = @import("std");
const math = @import("math");
const CHUNK_LENGTH = @import("chunk.zig").CHUNK_LENGTH;
const ChunkManager = @import("chunk_manager.zig");
const Player = @import("player.zig");

const Allocator = std.mem.Allocator;
const AutoHashMap = std.AutoHashMap;

const Float = math.types.Float;
const Matrix = math.matrix.Matrix;
const MatrixPrimitive = math.matrix.MatrixPrimitive;
const Vec3 = math.vector.Vec3(Float); 
const Vec3Primitive = Vec3.Primitive;
const noise = math.noise;

const Self = @This();

pub const Options = struct {
    internal_debug: bool = true,
    debug: bool = true,

    // Values for randomness.
    seed: u64 = 12493874,
    permutation: noise.PermutationTable = undefined,

    initial_width: c_int = 1024,
    initial_height: c_int = 768,

    fov: Float = 45,
    near: Float = 0.1,
    far: Float = 144,

    mouse_sensitivity: Float = 0.1,

    spawn_player: Player = .{
        .position = Vec3Primitive{0, 0, 0},
        .head = Vec3Primitive{0, 2, 0},
        .camera = Vec3Primitive{0, 0, 0},
        .direction = Vec3Primitive{0, 0, 1},
        
        .speed = 2.5
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

dt: f64 = 0,

player: Player,
chunks: ChunkManager,
mouse: struct {
    last_x: Float = 0,
    last_y: Float = 0,
    x: ?Float = null,
    y: ?Float = null
},

pub fn init(allocator: Allocator, options: Options) !Self {
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
        .chunks = try ChunkManager.init(
            allocator,
            options.permutation,
            options.spawn_player.position,
            @intFromFloat(options.far / CHUNK_LENGTH)   
        ),
        .mouse = .{}
    };
}

pub fn deinit(self: *Self) void {
    c.glfwTerminate();
    self.chunks.deinit();
}

pub fn loop(self: *Self) !void {
    self.adjustPerspective();
    const view_location = self.chunks.chunk_shader.uniform("view");

    var prev: f64 = 0;
    var elapsed: f64 = 0;
    var frames: usize = 0;
    while (c.glfwWindowShouldClose(self.window) == c.GL_FALSE) {
        c.glClearColor(0.0, 0.0, 0.0, 1.0);
        c.glClear(c.GL_COLOR_BUFFER_BIT);

        const timestamp = c.glfwGetTime();
        self.dt = timestamp - prev;
        prev = timestamp;

        if (self.options.debug) {
            frames += 1;
            elapsed += self.dt;
            if (elapsed >= 1.0) {
                // if (self.options.internal_debug) std.debug.print("{d} fps\n", .{frames});
                frames = 0;
                elapsed = 0;
            }
        }
        
        self.keyInput();

        self.player.update(@floatCast(self.dt));
        const camera = self.player.view();
        const view = Matrix.inverse(camera);
        c.glUniformMatrix4fv(view_location, 1, c.GL_FALSE, @ptrCast(&view[0]));

        self.chunks.update(@floatCast(self.dt));

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

pub fn keyInput(self: *Self) void {
    const dt: Float = @floatCast(self.dt);
    const speed = self.player.speed * dt;

    // TODO: Right now this affects the direction the player moves towards.
    // In Minecraft, the player typically moves consistently along one axis,
    // the z-axis (similar to how A/S move along the x-axis.)
    //
    // Will be implemented once gravity is implemented.
    if (c.glfwGetKey(self.window, c.GLFW_KEY_W) == c.GLFW_PRESS) {
        self.player.move(Vec3.scalarProduct(self.player.direction, speed));
    } else if (c.glfwGetKey(self.window, c.GLFW_KEY_S) == c.GLFW_PRESS) {
        self.player.move(Vec3.scalarProduct(self.player.direction, -1 * speed));
    } 

    const x_axis = Vec3.normalize(Vec3.cross(self.player.direction, Vec3.UP));
    if (c.glfwGetKey(self.window, c.GLFW_KEY_A) == c.GLFW_PRESS) {
        self.player.move(Vec3.scalarProduct(x_axis, -1 * speed));
    } else if (c.glfwGetKey(self.window, c.GLFW_KEY_D) == c.GLFW_PRESS) {
        self.player.move(Vec3.scalarProduct(x_axis, speed));
    }

    if (c.glfwGetKey(self.window, c.GLFW_KEY_SPACE) == c.GLFW_PRESS) {
        self.player.move(Vec3.scalarProduct(Vec3.UP, 1 * speed));
    }
}

pub fn mouseInput(self: *Self, x: Float, y: Float) void {
    if (self.mouse.x == null or self.mouse.y == null) {
        self.mouse.last_x = x;
        self.mouse.last_y = y;
    } else {
        self.mouse.last_x = self.mouse.x.?;
        self.mouse.last_y = self.mouse.y.?;
    }
    self.mouse.x = x;
    self.mouse.y = y;

    const dx = (self.mouse.x.? - self.mouse.last_x) * self.options.mouse_sensitivity;
    const dy = (self.mouse.last_y - self.mouse.y.?) * self.options.mouse_sensitivity;

    self.player.rotate(dx, dy);
}