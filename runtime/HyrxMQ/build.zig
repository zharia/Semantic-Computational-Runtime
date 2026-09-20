const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    // WASM module build.
    const wasm = b.addSharedLibrary(.{
        .name = "hyrx",
        .root_source_file = b.path("src/hyrx_wasm.c"),
        .target = target,
        .optimize = optimize,
        .single_threaded = true,
    });

    wasm.addIncludePath(b.path("src"));
    wasm.linkLibC();

    // WASM-specific flags.
    wasm.entry = .{ .symbol_name = "_start" };

    // Export all hyrx_* functions.
    wasm.root_module.addCMacro("_HYRX_WASM", "1");

    b.installArtifact(wasm);

    // Also build a static library for native testing.
    const native = b.addStaticLibrary(.{
        .name = "hyrx_native",
        .root_source_file = b.path("src/hyrx_wasm.c"),
        .target = b.standardTargetOptions(.{}),
        .optimize = optimize,
    });
    native.addIncludePath(b.path("src"));
    native.linkLibC();
    b.installArtifact(native);

    // Native test binary.
    const test_exe = b.addExecutable(.{
        .name = "hyrx_test",
        .root_source_file = b.path("src/test_hyrx.c"),
        .target = b.standardTargetOptions(.{}),
        .optimize = optimize,
    });
    test_exe.addIncludePath(b.path("src"));
    test_exe.linkLibC();
    b.installArtifact(test_exe);

    const run_test = b.addRunArtifact(test_exe);
    const test_step = b.step("test", "Run native tests");
    test_step.dependOn(&run_test.step);
}
