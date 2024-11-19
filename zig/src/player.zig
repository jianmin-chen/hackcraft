const c = @cImport({
    @cInclude("GLFW/glfw3.h");
});
const std = @import("std");
const math = @import("math");
const Float = math.types.Float;

const Matrix = math.matrix.Matrix;
const MatrixPrimitive = math.matrix.MatrixPrimitive;

const Vec3 = math.vector.Vec3(Float);
const Vec3Primitive = Vec3.Primitive;

const Self = @This();

position: Vec3Primitive,
head: Vec3Primitive,
camera: Vec3Primitive,
direction: Vec3Primitive,

yaw: Float = 90.0, // We start in the center of the unit circle.
pitch: Float = 0.0,

speed: Float,

pub fn view(self: *Self) MatrixPrimitive {
    return Matrix.lookAt(self.position, Vec3.sum(self.position, self.direction), Vec3.UP);
}

pub fn update(self: *Self, dt: Float) void {
    _ = self;
    _ = dt;
}

pub fn move(self: *Self, velocity: Vec3Primitive) void {
    self.position = Vec3.sum(self.position, velocity);
    self.camera = Vec3.sum(self.position, self.head);
}

pub fn rotate(self: *Self, delta_yaw: Float, delta_pitch: Float) void {
    self.yaw += delta_yaw;
    self.pitch += delta_pitch;

    if (self.pitch > 89.9) self.pitch = 89.9;
    if (self.pitch < -89.9) self.pitch = -89.9;

    const yaw = std.math.degreesToRadians(self.yaw);
    const pitch = std.math.degreesToRadians(self.pitch);

    self.direction = Vec3.normalize(
        Vec3Primitive{
            std.math.cos(yaw) * std.math.cos(pitch),
            std.math.sin(pitch),
            std.math.sin(yaw) * std.math.cos(pitch)
        }
    );
}