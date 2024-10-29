const std = @import("std");
const Element = @import("element.zig");

const Allocator = std.mem.Allocator;
const ArrayList = std.ArrayList;

pub const TableOfContents = struct {
    allocator: Allocator,
    slugs: ArrayList([]const u8),
    values: ArrayList([]const u8),
    mutate: bool = true,

    const Self = @This();

    pub fn init(allocator: Allocator) Self {
        return .{
            .allocator = allocator,
            .slugs = ArrayList([]const u8).init(allocator),
            .values = ArrayList([]const u8).init(allocator),
        };
    }
};
