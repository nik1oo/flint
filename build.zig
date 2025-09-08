const std = @import("std");
pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});
    const mod = b.addModule("flint", .{ .root_source_file = b.path("src/root.zig"), .target = target });
    const exe = b.addExecutable(.{ .name = "Example", .root_module = b.createModule(.{ .root_source_file = b.path("src/example.zig"), .target = target, .optimize = optimize, .imports = &.{
        .{ .name = "flint", .module = mod } } }) });
    exe.linkSystemLibrary("user32");
    exe.linkSystemLibrary("gdi32");
    exe.linkSystemLibrary("kernel32");
    exe.linkSystemLibrary("comdlg32");
    exe.linkSystemLibrary("shell32");
    exe.linkSystemLibrary("shlwapi");
    exe.linkSystemLibrary("opengl32");
    exe.linkLibC();
    b.installArtifact(exe);
    const run_step = b.step("run", "Run the app");
    const run_cmd = b.addRunArtifact(exe);
    run_step.dependOn(&run_cmd.step);
    run_cmd.step.dependOn(b.getInstallStep()); }