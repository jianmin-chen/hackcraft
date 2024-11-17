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

    // No input callbacks are handled by Game,
    // so we need to pass them in instead.
    // c.glfwSetInputMode(@ptrCast(game.window), c.GLFW_CURSOR, c.GLFW_CURSOR_DISABLED);
    _ = c.glfwSetKeyCallback(@ptrCast(game.window), updateKeys);
    _ = c.glfwSetCursorPosCallback(@ptrCast(game.window), updateMouse);

    try game.loop();
}

fn updateKeys(_: ?*c.GLFWwindow, key: c_int, _: c_int, action: c_int, _: c_int) callconv(.C) void {
    game.keyInput(key, action);
}

fn updateMouse(_: ?*c.GLFWwindow, x: f64, y: f64) callconv(.C) void {
    game.mouseInput(@floatCast(x), @floatCast(y)); 
}