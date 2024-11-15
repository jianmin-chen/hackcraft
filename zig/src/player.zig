const math = @import("math");

const Float = math.types.Float;

const Matrix = math.Matrix;
const MatrixPrimitive = math.MatrixPrimitive;

const Vec3Primitive = math.Vec3Primitive;
const Vec3 = math.Vec3;

const Self = @This();

const VIEW_DISTANCE: Float = 144; 

position: Vec3Primitive = Vec3Primitive{ 0, 0, 0 },
camera: Vec3Primitive = Vec3Primitive{ 0, 0, -10 },

yaw: Float = 0,
pitch: Float = 0,

pub fn view(self: *Self) MatrixPrimitive {
    const target = Vec3Primitive{
        self.position[0],
        self.position[1],
        self.position[2]
    };

    return Matrix.lookAt(
        self.camera, 
        target, 
        Vec3Primitive{ 0, 1, 0 }
    );
}