const std = @import("std");
const Float = @import("math").types.Float;

const Allocator = std.mem.Allocator;

const Self = @This();

pub const Characters = struct {
    allocator: Allocator,
    map: std.array_hash_map.StringArrayHashMapUnmanaged(Self),

    pub fn init(allocator: Allocator) !Characters {
        return .{
            .allocator = allocator,
            .map = try std.array_hash_map.StringArrayHashMapUnmanaged(Self).init(allocator, &[0][]const u8{}, &[0]Self{})
        };
    }

    pub fn deinit(self: *Characters) void {
        for (self.map.values()) |character| self.allocator.free(character.grapheme);
        self.map.deinit(self.allocator);
    }
};

grapheme: []u8,
top: Float,
left: Float,
width: Float,
height: Float,
bearing_x: Float,
bearing_y: Float,
advance_x: c_long,
advance_y: c_long
