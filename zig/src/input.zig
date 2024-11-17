const std = @import("std");
const Float = @import("math").types.Float;

const Self = @This();

pub const Keys = std.AutoHashMap(c_int, bool);

pub const Mouse = struct {
    last_x: ?Float,
    last_y: ?Float,
    x: ?Float = null,
    y: ?Float = null,
    sensitivity: Float
};

keys: Keys = undefined,
mouse: Mouse,

pub fn deinit(self: *Self) void {
    self.keys.deinit();
}

// Since the mouse will disappear,
// let's have a crosshair in the center of the screen.
//
// Ours renders a semi-transparent circle.
pub const crosshair_vertex = 
    \\
;

pub const crosshair_fragment =
    \\
;

pub fn renderCrosshair() void {

}