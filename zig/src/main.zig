const c = @cImport({
    @cInclude("GLFW/glfw3.h");
});
const std = @import("std");
const Game = @import("game.zig");

const Options = Game.Options;

var game: Game = undefined;

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer std.debug.assert(gpa.deinit() == .ok);

    const allocator = gpa.allocator();
    game = Game.init(allocator, Options.default());
    defer game.deinit();

    c.glfwSetInputMode(@ptrCast(game.window), c.GLFW_CURSOR, c.GLFW_CURSOR_DISABLED);
    _ = c.glfwSetCursorPosCallback(@ptrCast(game.window), updateMouse);

    try game.loop();
}

fn updateMouse(_: ?*c.GLFWwindow, x: f64, y: f64) callconv(.C) void {
    game.mouseInput(@floatCast(x), @floatCast(y));
}