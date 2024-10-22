const math = @import("std").math;

pub const MatrixPrimitive = [4][4]f64;

pub const Matrix = struct {
    pub fn identity() MatrixPrimitive {
        return [_][4]f64{
            [4]f64{ 1, 0, 0, 0 },
            [4]f64{ 0, 1, 0, 0 },
            [4]f64{ 0, 0, 1, 0 },
            [4]f64{ 0, 0, 0, 1 }
        };
    }

    pub fn perspective(
        fov: f64,
        aspect: f64,
        near: f64,
        far: f64
    ) MatrixPrimitive {
        const f = math.tan(math.pi * 0.5 - 0.5 * math.degreesToRadians(fov));
        const range_inv = 1.0 / (near - far);
        return [_][4]f64{
            [4]f64{ f / aspect, 0, 0, 0 },
            [4]f64{ 0, f, 0, 0 },
            [4]f64{ 0, 0, (near + far) * range_inv, -1 },
            [4]f64{ 0, 0, near * far * range_inv * 2, 0 }
        };
    }
};