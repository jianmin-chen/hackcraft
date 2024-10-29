const math = @import("math");

const Coord = math.types.Coord;
const FLOAT = math.types.FLOAT;

const Matrix = math.Matrix;
const MatrixPrimitive = math.MatrixPrimitive;

const Vec3Primitive = math.Vec3Primitive;
const Vec3 = math.Vec3;

const Self = @This();

const VIEW_DISTANCE: FLOAT = 144; 

position: Vec3Primitive = Vec3Primitive{ 0, 0, 0 },
camera: Vec3Primitive = Vec3Primitive{ -3, 0, 0 },

yaw: FLOAT = 0,
pitch: FLOAT = 0,

pub fn cameraMatrix(self: *Self) MatrixPrimitive {
    return Matrix.translation(
        self.camera[0],
        self.camera[1],
        self.camera[2]
    );
}

pub fn view(self: *Self) MatrixPrimitive {
    const target = Vec3Primitive{
        self.position[0] + VIEW_DISTANCE,
        self.position[1],
        self.position[2]
    };

    return Matrix.lookAt(
        self.camera, 
        target, 
        Vec3Primitive{ 0, 1, 0 }
    );
}