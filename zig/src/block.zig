const c = @cImport({
    @cInclude("glad/glad.h");
});
const std = @import("std");
const math = @import("math");

const Float = math.types.Float;

pub const Coord = math.vector.Vec3(isize);
pub const CoordPrimitive = Coord.Primitive;

// All the possible faces and their associated vertices
// of a 1x1 base cube at (0, 0, 0).
pub const FRONT = [_]CoordPrimitive{
    CoordPrimitive{0, 0, 0},
    CoordPrimitive{1, 0, 0},
    CoordPrimitive{1, 1, 0},
    CoordPrimitive{0, 0, 0},
    CoordPrimitive{1, 1, 0},
    CoordPrimitive{0, 1, 0}
};

pub const BACK = [_]CoordPrimitive{
    CoordPrimitive{0, 0, 1},
    CoordPrimitive{1, 0, 1},
    CoordPrimitive{1, 1, 1},
    CoordPrimitive{0, 0, 1},
    CoordPrimitive{1, 1, 1},
    CoordPrimitive{0, 1, 1}
};

pub const TOP = [_]CoordPrimitive{
    CoordPrimitive{0, 1, 0},
    CoordPrimitive{1, 1, 0},
    CoordPrimitive{1, 1, 1},
    CoordPrimitive{0, 1, 0},
    CoordPrimitive{1, 1, 1}, 
    CoordPrimitive{0, 1, 1} 
};

pub const BOTTOM = [_]CoordPrimitive{
    CoordPrimitive{0, 0, 0},
    CoordPrimitive{1, 0, 0},
    CoordPrimitive{1, 0, 1},
    CoordPrimitive{0, 0, 0},
    CoordPrimitive{1, 0, 1}, 
    CoordPrimitive{0, 0, 1}
};

pub const LEFT = [_]CoordPrimitive{
    CoordPrimitive{0, 0, 0},
    CoordPrimitive{0, 0, 1},
    CoordPrimitive{0, 1, 1}, 
    CoordPrimitive{0, 0, 0},
    CoordPrimitive{0, 1, 1},
    CoordPrimitive{0, 1, 0}   
};

pub const RIGHT = [_]CoordPrimitive{
    CoordPrimitive{1, 0, 0},
    CoordPrimitive{1, 0, 1},
    CoordPrimitive{1, 1, 1},
    CoordPrimitive{1, 0, 0},
    CoordPrimitive{1, 1, 1},
    CoordPrimitive{1, 1, 0}
};

pub const BlockKind = enum(u8) {
    grass = 2,
    _
};

const Self = @This();

kind: BlockKind = .grass,
active: bool = true,
render: bool = true,

pub fn init() Self {
    return .{};
}