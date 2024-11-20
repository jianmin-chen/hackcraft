const std = @import("std");

const Build = std.Build;

pub fn build(b: *Build) !void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const main = b.addExecutable(.{
        .name = "hackcraft",
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = optimize
    });

    const math = b.addModule("math", .{
        .root_source_file = b.path("src/math/root.zig"),
    });

    const shader = b.addModule("shader", .{
        .root_source_file = b.path("src/module/shader.zig"),
    });

    shader.addIncludePath(b.path("./deps"));

    const atlas_gen = b.addExecutable(.{
        .name = "atlas_gen",
        .root_source_file = b.path("src/module/atlas_gen.zig"),
        .target = target,
        .optimize = optimize
    });

    atlas_gen.root_module.addImport("math", math);

    atlas_gen.addIncludePath(Build.LazyPath{.cwd_relative = "/opt/homebrew/Cellar/freetype/2.13.3/include/freetype2/"});
    atlas_gen.addLibraryPath(Build.LazyPath{.cwd_relative = "/opt/homebrew/Cellar/freetype/2.13.3/lib"});

    atlas_gen.addIncludePath(b.path("./deps"));
    atlas_gen.addCSourceFile(.{
        .file = b.path("./deps/stb.c"),
        .flags = &.{}
    });

    atlas_gen.linkSystemLibrary("freetype");
    
    b.installArtifact(atlas_gen);

    main.root_module.addImport("math", math);
    main.root_module.addImport("shader", shader);

    main.addIncludePath(Build.LazyPath{ .cwd_relative = "/opt/homebrew/Cellar/glfw/3.4/include" });
    main.addLibraryPath(Build.LazyPath{ .cwd_relative = "/opt/homebrew/Cellar/glfw/3.4/lib" });

    main.addIncludePath(b.path("./deps"));
    main.addCSourceFile(.{
        .file = b.path("./deps/glad.c"),
        .flags = &.{}
    });
    main.addCSourceFile(.{
        .file = b.path("./deps/stb.c"),
        .flags = &.{}
    });

    main.linkFramework("OpenGL");
    main.linkSystemLibrary("glfw");

    b.installArtifact(main);

    const run_exe = b.addRunArtifact(main);
    const run_step = b.step("run", "Run");
    run_step.dependOn(&run_exe.step);
}
