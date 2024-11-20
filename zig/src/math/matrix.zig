const types = @import("types.zig");
const math = @import("std").math;
const vector = @import("vector.zig");

const Float = types.Float;

pub const MatrixPrimitive = [4][4]Float;

const Vec3 = vector.Vec3(Float);
const Vec3Primitive = Vec3.Primitive;

pub const Matrix = struct {
    pub fn identity(options: struct {
        fill: Float = 1
    }) MatrixPrimitive {
        return [_][4]Float{
            [4]Float{ options.fill, 0, 0, 0 },
            [4]Float{ 0, options.fill, 0, 0 },
            [4]Float{ 0, 0, options.fill, 0 },
            [4]Float{ 0, 0, 0, options.fill }
        };
    }

    pub fn translation(x: Float, y: Float, z: Float) MatrixPrimitive {
        return [_][4]Float{
            [4]Float{ 1, 0, 0, 0 },
            [4]Float{ 0, 1, 0, 0 },
            [4]Float{ 0, 0, 1, 0 },
            [4]Float{ x, y, z, 1 }
        };
    }

    pub fn xRotation(angle: Float) MatrixPrimitive {
        const rad = math.degreesToRadians(angle);
        const c = math.cos(rad);
        const s = math.sin(rad);
        return [_][4]Float{
            [4]Float{ 1, 0, 0, 0 },
            [4]Float{ 0, c, s, 0 },
            [4]Float{ 0, -s, c, 0 },
            [4]Float{ 0, 0, 0, 1 }
        };
    }

    pub fn yRotation(angle: Float) MatrixPrimitive {
        const rad = math.degreesToRadians(angle);
        const c = math.cos(rad);
        const s = math.sin(rad);
        return [_][4]Float{
            [4]Float{ c, 0, -s, 0 },
            [4]Float{ 0, 1, 0, 0 },
            [4]Float{ s, 0, c, 0 },
            [4]Float{ 0, 0, 0, 1 }
        };
    }

    pub fn zRotation(angle: Float) MatrixPrimitive {
        const rad = math.degreesToRadians(angle);
        const c = math.cos(rad);
        const s = math.sin(rad);
        return [_][4]Float{
            [4]Float{ c, s, 0, 0 },
            [4]Float{ -s, c, 0, 0 },
            [4]Float{ 0, 0, 1, 0 },
            [4]Float{ 0, 0, 0, 1 }
        };
    }

    pub fn orthographic(

    ) MatrixPrimitive {}

    pub fn perspective(
        fov: Float,
        aspect: Float,
        near: Float,
        far: Float
    ) MatrixPrimitive {
        const f = math.tan(math.degreesToRadians(fov) / 2);
        return [_][4]Float{
            [4]Float{ 1 / (aspect * f), 0, 0, 0 },
            [4]Float{ 0, 1 / f, 0, 0 },
            [4]Float{ 0, 0, -1 * (far + near) / (far - near), -1 },
            [4]Float{ 0, 0, -1 * (2.0 * far * near) / (far - near), 0 }
        };
    }

    pub fn lookAt(
        camera: Vec3Primitive,
        target: Vec3Primitive,
        up: Vec3Primitive
    ) MatrixPrimitive {
        const z_axis = Vec3.normalize(Vec3.difference(camera, target));
        const x_axis = Vec3.normalize(Vec3.cross(up, z_axis));
        const y_axis = Vec3.normalize(Vec3.cross(z_axis, x_axis));

        return [_][4]Float{
            [4]Float{ x_axis[0], x_axis[1], x_axis[2], 0 },
            [4]Float{ y_axis[0], y_axis[1], y_axis[2], 0 },
            [4]Float{ z_axis[0], z_axis[1], z_axis[2], 0 },
            [4]Float{ camera[0], camera[1], camera[2], 1 }
        };
    }

    pub fn inverse(a: MatrixPrimitive) MatrixPrimitive {
        const tmp_0  = a[2][2] * a[3][3];
        const tmp_1  = a[3][2] * a[2][3];
        const tmp_2  = a[1][2] * a[3][3];
        const tmp_3  = a[3][2] * a[1][3];
        const tmp_4  = a[1][2] * a[2][3];
        const tmp_5  = a[2][2] * a[1][3];
        const tmp_6  = a[0][2] * a[3][3];
        const tmp_7  = a[3][2] * a[0][3];
        const tmp_8  = a[0][2] * a[2][3];
        const tmp_9  = a[2][2] * a[0][3];
        const tmp_10 = a[0][2] * a[1][3];
        const tmp_11 = a[1][2] * a[0][3];
        const tmp_12 = a[2][0] * a[3][1];
        const tmp_13 = a[3][0] * a[2][1];
        const tmp_14 = a[1][0] * a[3][1];
        const tmp_15 = a[3][0] * a[1][1];
        const tmp_16 = a[1][0] * a[2][1];
        const tmp_17 = a[2][0] * a[1][1];
        const tmp_18 = a[0][0] * a[3][1];
        const tmp_19 = a[3][0] * a[0][1];
        const tmp_20 = a[0][0] * a[2][1];
        const tmp_21 = a[2][0] * a[0][1];
        const tmp_22 = a[0][0] * a[1][1];
        const tmp_23 = a[1][0] * a[0][1];

        const t0 = (tmp_0 * a[1][1] + tmp_3 * a[2][1] + tmp_4 * a[3][1]) -
            (tmp_1 * a[1][1] + tmp_2 * a[2][1] + tmp_5 * a[3][1]);
        const t1 = (tmp_1 * a[0][1] + tmp_6 * a[2][1] + tmp_9 * a[3][1]) -
            (tmp_0 * a[0][1] + tmp_7 * a[2][1] + tmp_8 * a[3][1]);
        const t2 = (tmp_2 * a[0][1] + tmp_7 * a[1][1] + tmp_10 * a[3][1]) -
            (tmp_3 * a[0][1] + tmp_6 * a[1][1] + tmp_11 * a[3][1]);
        const t3 = (tmp_5 * a[0][1] + tmp_8 * a[1][1] + tmp_11 * a[2][1]) -
            (tmp_4 * a[0][1] + tmp_9 * a[1][1] + tmp_10 * a[2][1]);

        const d = 1.0 / (a[0][0] * t0 + a[1][0] * t1 + a[2][0] * t2 + a[3][0] * t3);

        return [_][4]Float{
            [4]Float{ d * t0, d * t1, d * t2, d * t3 },
            [4]Float{
                d * ((tmp_1 * a[1][0] + tmp_2 * a[2][0] + tmp_5 * a[3][0]) -
                        (tmp_0 * a[1][0] + tmp_3 * a[2][0] + tmp_4 * a[3][0])),
                d * ((tmp_0 * a[0][0] + tmp_7 * a[2][0] + tmp_8 * a[3][0]) -
                        (tmp_1 * a[0][0] + tmp_6 * a[2][0] + tmp_9 * a[3][0])),
                d * ((tmp_3 * a[0][0] + tmp_6 * a[1][0] + tmp_11 * a[3][0]) -
                        (tmp_2 * a[0][0] + tmp_7 * a[1][0] + tmp_10 * a[3][0])),
                d * ((tmp_4 * a[0][0] + tmp_9 * a[1][0] + tmp_10 * a[2][0]) -
                        (tmp_5 * a[0][0] + tmp_8 * a[1][0] + tmp_11 * a[2][0]))
            },
            [4]Float{
                d * ((tmp_12 * a[1][3] + tmp_15 * a[2][3] + tmp_16 * a[3][3]) -
                        (tmp_13 * a[1][3] + tmp_14 * a[2][3] + tmp_17 * a[3][3])),
                d * ((tmp_13 * a[0][3] + tmp_18 * a[2][3] + tmp_21 * a[3][3]) -
                        (tmp_12 * a[0][3] + tmp_19 * a[2][3] + tmp_20 * a[3][3])),
                d * ((tmp_14 * a[0][3] + tmp_19 * a[1][3] + tmp_22 * a[3][3]) -
                        (tmp_15 * a[0][3] + tmp_18 * a[1][3] + tmp_23 * a[3][3])),
                d * ((tmp_17 * a[0][3] + tmp_20 * a[1][3] + tmp_23 * a[2][3]) -
                        (tmp_16 * a[0][3] + tmp_21 * a[1][3] + tmp_22 * a[2][3]))
            },
            [4]Float{
                d * ((tmp_14 * a[2][2] + tmp_17 * a[3][2] + tmp_13 * a[1][2]) -
                        (tmp_16 * a[3][2] + tmp_12 * a[1][2] + tmp_15 * a[2][2])),
                d * ((tmp_20 * a[3][2] + tmp_12 * a[0][2] + tmp_19 * a[2][2]) -
                        (tmp_18 * a[2][2] + tmp_21 * a[3][2] + tmp_13 * a[0][2])),
                d * ((tmp_18 * a[1][2] + tmp_23 * a[3][2] + tmp_15 * a[0][2]) -
                        (tmp_22 * a[3][2] + tmp_14 * a[0][2] + tmp_19 * a[1][2])),
                d * ((tmp_22 * a[2][2] + tmp_16 * a[0][2] + tmp_21 * a[1][2]) -
                        (tmp_20 * a[1][2] + tmp_23 * a[2][2] + tmp_17 * a[0][2]))
            }
        };
    }

    pub fn product(
        a: MatrixPrimitive,
        b: MatrixPrimitive
    ) MatrixPrimitive {
        return [_][4]Float{
            [4]Float{
                b[0][0] * a[0][0] + b[0][1] * a[1][0] + b[0][2] * a[2][0] + b[0][3] * a[3][0],
                b[0][0] * a[0][1] + b[0][1] * a[1][1] + b[0][2] * a[2][1] + b[0][3] * a[3][1],
                b[0][0] * a[0][2] + b[0][1] * a[1][2] + b[0][2] * a[2][2] + b[0][3] * a[3][2],
                b[0][0] * a[0][3] + b[0][1] * a[1][3] + b[0][2] * a[2][3] + b[0][3] * a[3][3]
            },
            [4]Float{
                b[1][0] * a[0][0] + b[1][1] * a[1][0] + b[1][2] * a[2][0] + b[1][3] * a[3][0],
                b[1][0] * a[0][1] + b[1][1] * a[1][1] + b[1][2] * a[2][1] + b[1][3] * a[3][1],
                b[1][0] * a[0][2] + b[1][1] * a[1][2] + b[1][2] * a[2][2] + b[1][3] * a[3][2],
                b[1][0] * a[0][3] + b[1][1] * a[1][3] + b[1][2] * a[2][3] + b[1][3] * a[3][3]
            },
            [4]Float{
                b[2][0] * a[0][0] + b[2][1] * a[1][0] + b[2][2] * a[2][0] + b[2][3] * a[3][0],
                b[2][0] * a[0][1] + b[2][1] * a[1][1] + b[2][2] * a[2][1] + b[2][3] * a[3][1],
                b[2][0] * a[0][2] + b[2][1] * a[1][2] + b[2][2] * a[2][2] + b[2][3] * a[3][2],
                b[2][0] * a[0][3] + b[2][1] * a[1][3] + b[2][2] * a[2][3] + b[2][3] * a[3][3]
            },
            [4]Float{
                b[3][0] * a[0][0] + b[3][1] * a[1][0] + b[3][2] * a[2][0] + b[3][3] * a[3][0],
                b[3][0] * a[0][1] + b[3][1] * a[1][1] + b[3][2] * a[2][1] + b[3][3] * a[3][1],
                b[3][0] * a[0][2] + b[3][1] * a[1][2] + b[3][2] * a[2][2] + b[3][3] * a[3][2],
                b[3][0] * a[0][3] + b[3][1] * a[1][3] + b[3][2] * a[2][3] + b[3][3] * a[3][3]
            }
        };
    }
};
