const types = @import("types.zig");
const math = @import("std").math;

const EPSILON = types.EPSILON;
const Float = types.Float;

pub const Vec3Primitive = [3]Float;

pub const Vec3 = struct {
    pub fn length(a: Vec3Primitive) Float {
        return math.sqrt(
            a[0] * a[0] + 
            a[1] * a[1] + 
            a[2] * a[2]
        );
    }

    pub fn normalize(a: Vec3Primitive) Vec3Primitive {
        const len = Vec3.length(a);
        if (len > EPSILON) 
            return Vec3Primitive{
                a[0] / len,
                a[1] / len,
                a[2] / len
            };
        return [3]Float{ 0, 0, 0 };
    }

    pub fn scalarSum(a: Vec3Primitive, n: Float) Vec3Primitive {
        return Vec3Primitive{
            a[0] + n,
            a[1] + n,
            a[2] + n
        };
    }

    pub fn sum(a: Vec3Primitive, b: Vec3Primitive) Vec3Primitive {
        return Vec3Primitive{
            a[0] + b[0],
            a[1] + b[1],
            a[2] + b[2]
        };
    }

    pub fn difference(a: Vec3Primitive, b: Vec3Primitive) Vec3Primitive {
        return Vec3Primitive{
            a[0] - b[0],
            a[1] - b[1],
            a[2] - b[2]
        };
    }

    pub fn cross(a: Vec3Primitive, b: Vec3Primitive) Vec3Primitive {
        return Vec3Primitive{
            a[1] * b[2] - a[2] * b[1],
            a[2] * b[0] - a[0] * b[2],
            a[0] * b[1] - a[1] * b[0]
        };
    }
};
