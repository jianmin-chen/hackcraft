const constants = @import("constants.zig");
const math = @import("std").math;

const FLOAT = constants.FLOAT;

pub const MatrixPrimitive = [4][4]FLOAT;

pub const Matrix = struct {
    pub fn identity() MatrixPrimitive {
        return [_][4]FLOAT{
            [4]FLOAT{ 1, 0, 0, 0 },
            [4]FLOAT{ 0, 1, 0, 0 },
            [4]FLOAT{ 0, 0, 1, 0 },
            [4]FLOAT{ 0, 0, 0, 1 }
        };
    }

    pub fn perspective(
        fov: FLOAT,
        aspect: FLOAT,
        near: FLOAT,
        far: FLOAT
    ) [4][4]FLOAT {
        const f = math.tan(math.degreesToRadians(fov) / 2);
        return [_][4]FLOAT{
            [4]FLOAT{ 1.0 / (aspect * f), 0, 0, 0 },
            [4]FLOAT{ 0, 1.0 / f, 0, 0 },
            [4]FLOAT{ 0, 0, (-1.0 * (far + near)) / (far - near), (-2.0 * far * near) / (far - near) },
            [4]FLOAT{ 0, 0, -1, 0 }
        };
    }
};