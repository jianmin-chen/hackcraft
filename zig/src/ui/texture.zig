const c = @cImport({
    @cInclude("stb_image.h");
});
const std = @import("std");

const Self = @This();

const Error = error{LoadError};

width: c_int = undefined,
height: c_int = undefined,
nr_channels: c_int = undefined,

data: []u8 = undefined,

pub fn from(path: []const u8) Error!Self {
    var self: Self = .{};
    const c_data = c.stbi_load(@ptrCast(path), &self.width, &self.height, &self.nr_channels, 0);
    if (c_data == null) return Error.LoadError;
    self.data = c_data[0..@intCast(self.width * self.height * self.nr_channels)];
    return self;
}

pub fn deinit(self: *Self) void {
    c.stbi_image_free(@ptrCast(self.data));
}