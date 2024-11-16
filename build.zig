const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    // Config whisper
    const whisper_build_dir = b.path("whisper.cpp/build");
    const whisper_mkdir_cmd = b.addSystemCommand(&.{ "mkdir", "-p", whisper_build_dir.getPath(b) });
    const whisper_configure = b.addSystemCommand(&.{ "cmake", "-B", whisper_build_dir.getPath(b), "-S", "whisper.cpp", "-DCMAKE_BUILD_TYPE=Release", "-DBUILD_SHARED_LIBS=OFF", "-DGGML_METAL_EMBED_LIBRARY=OFF", "-DGGML_METAL=OFF", "-DGGML_OPENMP=OFF" });
    whisper_configure.step.dependOn(&whisper_mkdir_cmd.step);

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
    const libsnd_build_dir = b.path("libsndfile/build");
    const libsnd_mkdir_cmd = b.addSystemCommand(&.{ "mkdir", "-p", libsnd_build_dir.getPath(b) });
    const libsnd_configure = b.addSystemCommand(&.{ "cmake", "-B", libsnd_build_dir.getPath(b), "-S", "libsndfile", "-DCMAKE_BUILD_TYPE=Release", "-DBUILD_SHARED_LIBS=OFF", "-DENABLE_EXTERNAL_LIBS=OFF", "-DENABLE_MPEG=OFF" });
    libsnd_configure.step.dependOn(&libsnd_mkdir_cmd.step);

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
    exe.addIncludePath(b.path("whisper.cpp/include"));
    exe.addIncludePath(b.path("whisper.cpp/ggml/include"));

    // Add libsndfile include path
    exe.addIncludePath(b.path("libsndfile/include"));

    if (target.result.isDarwin()) {
        exe.linkFramework("Foundation");
        exe.linkFramework("Accelerate");
        exe.linkFramework("Metal");
    }

    // Link whisper
    exe.addLibraryPath(b.path("whisper.cpp"));
    exe.addObjectFile(b.path("whisper.cpp/build/ggml/src/libggml.a"));
    exe.addObjectFile(b.path("whisper.cpp/build/src/libwhisper.a"));

    // Link libsndfile
    exe.addLibraryPath(b.path("libsndfile"));
    exe.addObjectFile(b.path("libsndfile/build/libsndfile.a"));

    // exe.linkLibC();
    exe.linkLibCpp();

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
