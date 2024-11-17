const c = @cImport({
    @cInclude("GLFW/glfw3.h");
});
const std = @import("std");
const math = @import("math");
const input = @import("input.zig");

const Float = math.types.Float;

const Matrix = math.matrix.Matrix;
const MatrixPrimitive = math.matrix.MatrixPrimitive;

const Vec3 = math.vector.Vec3;
const Vec3Primitive = math.vector.Vec3Primitive;

const Keys = input.Keys;
const Mouse = input.Mouse;

const Self = @This();

position: Vec3Primitive,
head: Vec3Primitive,
camera: Vec3Primitive,
target: Vec3Primitive,

yaw: Float = 0,
pitch: Float = 0,

velocity: Vec3Primitive = Vec3Primitive{0, 0, 0},
speed: Float,

pub fn view(self: *Self) MatrixPrimitive {
    return Matrix.lookAt(self.camera, self.target, Vec3Primitive{0, 1, 0});
}

pub fn update(self: *Self, dt: Float) void {
    const adjusted_velocity = Vec3.scalarProduct(self.velocity, dt);
    self.position = Vec3.sum(self.position, adjusted_velocity);
    self.camera = Vec3.sum(self.position, self.head);
}

pub fn move(self: *Self, keys: Keys) void {
    if (keys.get(c.GLFW_KEY_W) orelse false) {
        self.velocity[2] = self.speed;
    } else if (keys.get(c.GLFW_KEY_S) orelse false) {
        self.velocity[2] = -self.speed;
    } else self.velocity[2] = 0;

    if (keys.get(c.GLFW_KEY_A) orelse false) {

    } else if (keys.get(c.GLFW_KEY_D) orelse false) {

    } else self.velocity[0] = 0;
}

pub fn rotate(self: *Self, mouse: Mouse) void {
    const x_offset = mouse.x.? - mouse.last_x.?;
    const y_offset = mouse.y.? - mouse.last_y.?;

    self.yaw += x_offset * mouse.sensitivity;
    self.pitch += y_offset * mouse.sensitivity;

    std.debug.print("{d}\n", .{self.pitch});

    const yaw = std.math.degreesToRadians(self.yaw);
    const pitch = std.math.degreesToRadians(self.pitch);

    self.target = Vec3.normalize(Vec3Primitive{
        std.math.cos(yaw) * std.math.cos(pitch),
        std.math.sin(pitch),
        std.math.sin(yaw) * std.math.cos(pitch)
    });
}