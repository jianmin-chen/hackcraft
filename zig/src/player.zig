const c = @cImport({
    @cInclude("GLFW/glfw3.h");
});
const std = @import("std");
const math = @import("math");
const Input = @import("input.zig");

const AutoHashMap = std.AutoHashMap;

const Float = math.types.Float;

const Matrix = math.Matrix;
const MatrixPrimitive = math.MatrixPrimitive;

const Vec3Primitive = math.Vec3Primitive;
const Vec3 = math.Vec3;

const Self = @This();

position: Vec3Primitive,
head: Vec3Primitive,
camera: Vec3Primitive,
target: Vec3Primitive,

yaw: Float = 0,
pitch: Float = 0,

speed: Float,
view_distance: Float,

pub fn view(self: *Self) MatrixPrimitive {
    return Matrix.lookAt(
        self.camera, 
        Vec3.sum(self.position, self.target),
        Vec3Primitive{0, 1, 0}
    );
}

pub fn update(self: *Self, dt: Float, input: *const Input) void {
    const adjusted_speed = self.speed * dt;

    if (input.keys.get(c.GLFW_KEY_W) orelse false) {
        self.position[2] += adjusted_speed;
    } else if (input.keys.get(c.GLFW_KEY_S) orelse false) {
        self.position[2] -= adjusted_speed;
    }

    const x_offset = input.mouse.x - input.mouse.last_x;
    const y_offset = input.mouse.y - input.mouse.last_y;

    self.yaw += x_offset * input.mouse.sensitivity;
    self.pitch += y_offset * input.mouse.sensitivity;

    if (self.pitch > 89) self.pitch = 89;
    if (self.pitch < 89) self.pitch = 89;

    self.camera = Vec3.sum(self.position, self.head);

    const yaw = std.math.degreesToRadians(self.yaw);
    const pitch = std.math.degreesToRadians(self.pitch);

    self.target = Vec3.normalize(Vec3Primitive{
        std.math.cos(yaw) * std.math.cos(pitch),
        std.math.sin(pitch),
        std.math.sin(yaw) * std.math.cos(pitch)
    });
}