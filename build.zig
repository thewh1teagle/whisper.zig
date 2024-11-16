const std = @import("std");

pub fn build(b: *std.Build) !void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    // Config whisper
    const whisper_build_dir = b.path("lib/whisper.cpp/build");
    std.fs.cwd().makeDir("lib/whisper.cpp/build") catch {};
    const whisper_configure = b.addSystemCommand(&.{ "cmake", "-B", whisper_build_dir.getPath(b), "-S", "lib/whisper.cpp", "-DCMAKE_BUILD_TYPE=Release", "-DBUILD_SHARED_LIBS=OFF", "-DGGML_METAL_EMBED_LIBRARY=OFF", "-DGGML_METAL=OFF", "-DGGML_OPENMP=OFF", "-DWHISPER_BUILD_EXAMPLES=OFF", "-DWHISPER_BUILD_TESTS=OFF" });

    // Build whisper
    const whisper_build = b.addSystemCommand(&.{
        "cmake",
        "--build",
        whisper_build_dir.getPath(b),
        "--config",
        "Release",
    });
    whisper_build.step.dependOn(&whisper_configure.step);

    // Config libsndfile
    const libsnd_build_dir = b.path("lib/libsndfile/build");
    std.fs.cwd().makeDir("lib/libsndfile/build") catch {};
    const libsnd_configure = b.addSystemCommand(&.{ "cmake", "-B", libsnd_build_dir.getPath(b), "-S", "lib/libsndfile", "-DCMAKE_BUILD_TYPE=Release", "-DBUILD_SHARED_LIBS=OFF", "-DENABLE_EXTERNAL_LIBS=OFF", "-DENABLE_MPEG=OFF" });

    // Build whisper
    const libsnd_build = b.addSystemCommand(&.{
        "cmake",
        "--build",
        libsnd_build_dir.getPath(b),
        "--config",
        "Release",
    });
    libsnd_build.step.dependOn(&libsnd_configure.step);

    const exe = b.addExecutable(.{
        .name = "whisper.zig",
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = optimize,
    });
    // Add whisper include path
    exe.addIncludePath(b.path("lib/whisper.cpp/src"));
    exe.addIncludePath(b.path("lib/whisper.cpp/src/include"));
    exe.addIncludePath(b.path("lib/whisper.cpp/include"));
    exe.addIncludePath(b.path("lib/whisper.cpp/ggml/include"));

    // Add libsndfile include path
    exe.addIncludePath(b.path("lib/libsndfile/include"));

    if (target.result.isDarwin()) {
        exe.linkFramework("Foundation");
        exe.linkFramework("Accelerate");
        exe.linkFramework("Metal");
    }

    // Link whisper
    exe.addLibraryPath(b.path("lib/whisper.cpp/build/src"));
    // Windows
    exe.addLibraryPath(b.path("lib/whisper.cpp/build/src/Release"));
    exe.linkSystemLibrary("whisper");

    exe.addLibraryPath(b.path("lib/whisper.cpp/build/ggml/src"));
    // Windows
    exe.addLibraryPath(b.path("lib/whisper.cpp/build/ggml/src/Release"));
    exe.linkSystemLibrary("ggml");

    // Link libsndfile
    exe.addLibraryPath(b.path("lib/libsndfile/build"));
    exe.addLibraryPath(b.path("lib/libsndfile/build/Release"));
    exe.linkSystemLibrary("sndfile");

    exe.linkLibCpp();
    exe.linkLibC();

    exe.step.dependOn(&libsnd_build.step);
    exe.step.dependOn(&whisper_build.step);

    b.installArtifact(exe);
    const run_cmd = b.addRunArtifact(exe);
    run_cmd.step.dependOn(b.getInstallStep());
    if (b.args) |args| {
        run_cmd.addArgs(args);
    }
    const run_step = b.step("run", "Run the app");
    run_step.dependOn(&run_cmd.step);
}
