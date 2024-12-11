const std = @import("std");
const Float = @import("math").types.Float;

const Allocator = std.mem.Allocator;
const json = std.json;

const Self = @This();

grapheme: []u8,
top: Float,
left: Float,
width: Float,
height: Float,
bearing_x: Float,
bearing_y: Float,
advance_x: c_long,
advance_y: c_long