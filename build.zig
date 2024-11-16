const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    // CMake configuration step
    const cmake_build_dir = b.path("whisper.cpp/build");
    const mkdir_cmd = b.addSystemCommand(&.{ "mkdir", "-p", cmake_build_dir.getPath(b) });
    const cmake_configure = b.addSystemCommand(&.{ "cmake", "-B", cmake_build_dir.getPath(b), "-S", "whisper.cpp", "-DCMAKE_BUILD_TYPE=Release", "-DBUILD_SHARED_LIBS=OFF", "-DGGML_METAL_EMBED_LIBRARY=ON", "-DGGML_METAL=OFF", "-DGGML_OPENMP=OFF" });
    cmake_configure.step.dependOn(&mkdir_cmd.step);

    const cmake_build = b.addSystemCommand(&.{
        "cmake",
        "--build",
        cmake_build_dir.getPath(b),
        "--config",
        "Release",
    });
    cmake_build.step.dependOn(&cmake_configure.step);

    const exe = b.addExecutable(.{
        .name = "whisper.zig",
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = optimize,
    });
    exe.addIncludePath(b.path("whisper.cpp/include"));
    exe.addIncludePath(b.path("whisper.cpp/ggml/include"));

    if (target.result.isDarwin()) {
        exe.linkFramework("Foundation");
        exe.linkFramework("Accelerate");
    }
    exe.addLibraryPath(b.path("whisper.cpp"));
    exe.addObjectFile(b.path("whisper.cpp/build/ggml/src/libggml.a"));

    exe.addObjectFile(b.path("whisper.cpp/build/src/libwhisper.a"));

    // exe.linkLibC();
    exe.linkLibCpp();

    exe.step.dependOn(&cmake_build.step);

    b.installArtifact(exe);
    const run_cmd = b.addRunArtifact(exe);
    run_cmd.step.dependOn(b.getInstallStep());
    if (b.args) |args| {
        run_cmd.addArgs(args);
    }
    const run_step = b.step("run", "Run the app");
    run_step.dependOn(&run_cmd.step);
}
