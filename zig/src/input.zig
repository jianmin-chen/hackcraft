const std = @import("std");
const Float = @import("math").types.Float;

const AutoHashMap = std.AutoHashMap;

const Self = @This();

keys: AutoHashMap(c_int, bool) = undefined,
mouse: struct {
    first: bool = true,
    last_x: Float,
    last_y: Float,
    x: Float = 0,
    y: Float = 0,
    sensitivity: Float 
},

pub fn deinit(self: *Self) void {
    self.keys.deinit();
}

// Mouse is always centered.
// Draw a crosshair in the center.