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
		.target = target,
		.optimize = optimize
	});

	math.addIncludePath(Build.LazyPath{ .cwd_relative = "/opt/homebrew/Cellar/glfw/3.4/include" });
	math.addLibraryPath(Build.LazyPath{ .cwd_relative = "/opt/homebrew/Cellar/glfw/3.4/lib" });

	math.addIncludePath(Build.LazyPath{ .cwd_relative = "./deps" });

	math.linkFramework("OpenGL", .{});
	math.linkSystemLibrary("glfw", .{});

	main.root_module.addImport("math", math);

	main.addIncludePath(Build.LazyPath{ .cwd_relative = "/opt/homebrew/Cellar/glfw/3.4/include" });
	main.addLibraryPath(Build.LazyPath{ .cwd_relative = "/opt/homebrew/Cellar/glfw/3.4/lib" });

	main.addIncludePath(Build.LazyPath{ .cwd_relative = "./deps" });
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
