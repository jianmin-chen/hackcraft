const std = @import("std");

const Build = std.Build;

pub fn build(b: *Build) !void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const main = b.addExecutable(.{
        .name = "site",
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = optimize
    });

    b.installArtifact(main);

    const run_exe = b.addRunArtifact(main);
    const run_step = b.step("run", "Run");
    run_step.dependOn(&run_exe.step);
}
