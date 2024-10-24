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

    pub fn xRotation(angle: FLOAT) MatrixPrimitive {
        const rad = math.degreesToRadians(angle);
        const c = math.cos(rad);
        const s = math.sin(rad);
        return [_][4]FLOAT{
            [4]FLOAT{ 1, 0, 0, 0 },
            [4]FLOAT{ 0, c, s, 0 },
            [4]FLOAT{ 0, -s, c, 0 },
            [4]FLOAT{ 0, 0, 0, 1 }
        };
    }

    pub fn zRotation(angle: FLOAT) MatrixPrimitive {
        const rad = math.degreesToRadians(angle);
        const c = math.cos(rad);
        const s = math.sin(rad);
        return [_][4]FLOAT{
            [4]FLOAT{ c, s, 0, 0 },
            [4]FLOAT{ -s, c, 0, 0 },
            [4]FLOAT{ 0, 0, 1, 0 },
            [4]FLOAT{ 0, 0, 0, 1 }
        };
    }

    pub fn perspective(
        fov: FLOAT,
        aspect: FLOAT,
        near: FLOAT,
        far: FLOAT
    ) MatrixPrimitive {
        const f = math.tan(math.degreesToRadians(fov) / 2);
        return [_][4]FLOAT{
            [4]FLOAT{ 1.0 / (aspect * f), 0, 0, 0 },
            [4]FLOAT{ 0, 1.0 / f, 0, 0 },
            [4]FLOAT{ 0, 0, -1.0 * ((far + near) / (far - near)), -2.0 * ((far * near) / (far - near)) },
            [4]FLOAT{ 0, 0, -1, 0 }
        };
    }

    pub fn eql(
        a: MatrixPrimitive,
        b: MatrixPrimitive
    ) bool {
        if (a[0][0] != b[0][0]) return false;
        if (a[0][1] != b[0][1]) return false;
        if (a[2][0] != b[2][0]) return false;
        if (a[2][1] != b[2][1]) return false;
        if (a[2][2] != b[2][2]) return false;
        if (a[2][3] != b[2][3]) return false;
        return true;
    }

    pub fn product(
        a: MatrixPrimitive,
        b: MatrixPrimitive
    ) MatrixPrimitive {
        return [_][4]FLOAT{
            [4]FLOAT{
                b[0][0] * a[0][0] + b[0][1] * a[1][0] + b[0][2] * b[2][0] + b[0][3] * a[3][0],
                b[0][0] * a[0][1] + b[0][1] * a[1][1] + b[0][2] * b[2][1] + b[0][3] * a[3][1],
                b[0][0] * a[0][2] + b[0][1] * a[1][2] + b[0][2] * b[2][2] + b[0][3] * a[3][2],
                b[0][0] * a[0][3] + b[0][1] * a[1][3] + b[0][2] * b[2][3] + b[0][3] * a[3][3]
            },
            [4]FLOAT{
                b[1][0] * a[0][0] + b[1][1] * a[1][0] + b[1][2] * b[2][0] + b[1][3] * a[3][0],
                b[1][0] * a[0][1] + b[1][1] * a[1][1] + b[1][2] * b[2][1] + b[1][3] * a[3][1],
                b[1][0] * a[0][2] + b[1][1] * a[1][2] + b[1][2] * b[2][2] + b[1][3] * a[3][2],
                b[1][0] * a[0][3] + b[1][1] * a[1][3] + b[1][2] * b[2][3] + b[1][3] * a[3][3]
            },
            [4]FLOAT{
                b[2][0] * a[0][0] + b[2][1] * a[1][0] + b[2][2] * a[2][0] + b[2][3] * a[3][0],
                b[2][0] * a[0][1] + b[2][1] * a[1][1] + b[2][2] * a[2][1] + b[2][3] * a[3][1],
                b[2][0] * a[0][2] + b[2][1] * a[1][2] + b[2][2] * a[2][2] + b[2][3] * a[3][2],
                b[2][0] * a[0][3] + b[2][1] * a[1][3] + b[2][2] * a[2][3] + b[2][3] * a[3][3],
            },
            [4]FLOAT{
                b[3][0] * a[0][0] + b[3][1] * a[1][0] + b[3][2] * b[2][0] + b[3][3] * a[3][0],
                b[3][0] * a[0][1] + b[3][1] * a[1][1] + b[3][2] * b[2][1] + b[3][3] * a[3][1],
                b[3][0] * a[0][2] + b[3][1] * a[1][2] + b[3][2] * b[2][2] + b[3][3] * a[3][2],
                b[3][0] * a[0][3] + b[3][1] * a[1][3] + b[3][2] * b[2][3] + b[3][3] * a[3][3],
            }
        };
    }
};
