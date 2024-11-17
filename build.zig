const std = @import("std");

pub fn build(b: *std.Build) !void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    // rootpath from zig-package (zig GLOBAL_CACHE_DIR)
    const whisperLazyPath = b.dependency("whisper", .{}).path("");
    const sndFileLazyPath = b.dependency("libsndfile", .{}).path("");

    // =============== Whisper library ====================
    const whisper_build = buildWhisper(b, .{
        .target = target,
        .optimize = optimize,
        .dep_path = whisperLazyPath,
    });

    // =============== SNDFile library ====================
    const sndfile_build = buildSNDFile(b, .{
        .target = target,
        .optimize = optimize,
        .dep_path = sndFileLazyPath,
    });

    // =============== Main executable ====================
    const exe = b.addExecutable(.{
        .name = "whisper.zig",
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = optimize,
    });
    // Add whisper include path (abspath)
    exe.addIncludePath(.{
        .cwd_relative = b.pathJoin(&.{ whisperLazyPath.getPath(b), "include" }),
    });
    exe.addIncludePath(.{
        .cwd_relative = b.pathJoin(&.{ whisperLazyPath.getPath(b), "ggml", "include" }),
    });
    exe.addIncludePath(.{
        .cwd_relative = b.pathJoin(&.{ whisperLazyPath.getPath(b), "src", "include" }),
    });
    exe.addIncludePath(.{
        .cwd_relative = b.pathJoin(&.{ whisperLazyPath.getPath(b), "src" }),
    });
    // Add libsndfile include path (abspath)
    exe.addIncludePath(.{
        .cwd_relative = b.pathJoin(&.{ sndFileLazyPath.getPath(b), "include" }),
    });

    // cmake build --config Debug|Release path
    if (exe.rootModuleTarget().abi == .msvc) {
        exe.addLibraryPath(b.path(b.fmt(".zig-cache/whisper_build/src/{s}", .{switch (optimize) {
            .Debug => "Debug",
            else => "Release",
        }})));
        exe.addLibraryPath(b.path(b.fmt(".zig-cache/whisper_build/ggml/src/{s}", .{switch (optimize) {
            .Debug => "Debug",
            else => "Release",
        }})));
        exe.addLibraryPath(b.path(b.fmt(".zig-cache/libsndfile/{s}", .{switch (optimize) {
            .Debug => "Debug",
            else => "Release",
        }})));
    } else if (exe.rootModuleTarget().isMinGW()) {
        exe.addLibraryPath(b.path(".zig-cache/whisper_build/bin"));
        exe.addLibraryPath(b.path(".zig-cache/whisper_build/ggml/bin"));
        exe.addLibraryPath(b.path(".zig-cache/libsndfile"));
    } else {
        exe.addLibraryPath(b.path(".zig-cache/whisper_build/src"));
        exe.addLibraryPath(b.path(".zig-cache/whisper_build/ggml/src"));
        exe.addLibraryPath(b.path(".zig-cache/libsndfile"));
    }

    if (exe.rootModuleTarget().isDarwin()) {
        exe.linkFramework("Foundation");
        exe.linkFramework("Accelerate");
        exe.linkFramework("Metal");
    }
    exe.step.dependOn(&whisper_build.step);
    exe.step.dependOn(&sndfile_build.step);

    if (exe.rootModuleTarget().os.tag != .windows) {
        exe.linkSystemLibrary("sndfile");
        exe.linkSystemLibrary("whisper");
        exe.linkSystemLibrary("ggml");
    } else {
        exe.linkSystemLibrary2("libsndfile.dll", .{
            .use_pkg_config = .no,
        });
        exe.linkSystemLibrary2("libwhisper.dll", .{
            .use_pkg_config = .no,
        });
        exe.linkSystemLibrary2("libggml.dll", .{
            .use_pkg_config = .no,
        });
    }

    if (exe.rootModuleTarget().abi == .msvc) {
        exe.linkLibC();
        exe.linkSystemLibrary("Advapi32");
    } else {
        exe.defineCMacro("_GNU_SOURCE", null);
        exe.linkLibCpp();
    }
    b.installArtifact(exe);

    const run_cmd = b.addRunArtifact(exe);
    run_cmd.step.dependOn(b.getInstallStep());
    if (b.args) |args| {
        run_cmd.addArgs(args);
    }
    const run_step = b.step("run", "Run the app");
    run_step.dependOn(&run_cmd.step);
}

fn buildWhisper(b: *std.Build, args: struct {
    target: std.Build.ResolvedTarget,
    optimize: std.builtin.OptimizeMode,
    dep_path: std.Build.LazyPath,
}) *std.Build.Step.Run {
    const whisper_path = args.dep_path.getPath(b);
    const whisper_configure = b.addSystemCommand(&.{
        "cmake",
        "-B",
        ".zig-cache/whisper_build",
        "-S",
        whisper_path,
        b.fmt("-DCMAKE_BUILD_TYPE={s}", .{switch (args.optimize) {
            .Debug => "Debug",
            .ReleaseFast => "Release",
            .ReleaseSafe => "RelWithDebInfo",
            .ReleaseSmall => "MinSizeRel",
        }}),
        "-DGGML_OPENMP=OFF",
        "-DWHISPER_BUILD_EXAMPLES=OFF",
        "-DWHISPER_BUILD_TESTS=OFF",
    });
    if (args.target.result.isDarwin())
        whisper_configure.addArgs(&.{
            "-DGGML_METAL_EMBED_LIBRARY=OFF",
            "-DGGML_METAL=ON",
        })
    else
        whisper_configure.addArgs(&.{
            "-DGGML_METAL_EMBED_LIBRARY=OFF",
            "-DGGML_METAL=OFF",
        });

    if (args.target.result.isMinGW()) {
        whisper_configure.addArgs(&.{
            "-G",
            "MinGW Makefiles",
        });
    }
    if (args.target.result.os.tag == .linux or args.target.result.os.tag == .windows)
        whisper_configure.addArgs(&.{
            "-DBUILD_SHARED_LIBS=ON",
        });
    const whisper_build = b.addSystemCommand(&.{
        "cmake",
        "--build",
        ".zig-cache/whisper_build",
    });
    if (args.target.result.abi == .msvc) {
        whisper_build.addArgs(&.{
            "--config",
            b.fmt("{s}", .{switch (args.optimize) {
                .Debug => "Debug",
                else => "Release",
            }}),
        });
    }
    whisper_build.step.dependOn(&whisper_configure.step);
    return whisper_build;
}

fn buildSNDFile(b: *std.Build, args: struct {
    target: std.Build.ResolvedTarget,
    optimize: std.builtin.OptimizeMode,
    dep_path: std.Build.LazyPath,
}) *std.Build.Step.Run {
    const sndfile_path = args.dep_path.getPath(b); // LazyPath to string

    const libsnd_configure = b.addSystemCommand(&.{
        "cmake",
        "-B",
        ".zig-cache/libsndfile",
        "-S",
        sndfile_path,
        b.fmt("-DCMAKE_BUILD_TYPE={s}", .{switch (args.optimize) {
            .Debug => "Debug",
            .ReleaseFast => "Release",
            .ReleaseSafe => "RelWithDebInfo",
            .ReleaseSmall => "MinSizeRel",
        }}),
        "-DBUILD_SHARED_LIBS=OFF",
        "-DENABLE_EXTERNAL_LIBS=OFF",
        "-DENABLE_MPEG=OFF",
    });
    if (args.target.result.isMinGW()) {
        libsnd_configure.addArgs(&.{
            "-G",
            "MinGW Makefiles",
        });
    }
    if (args.target.result.os.tag == .linux or args.target.result.os.tag == .windows)
        libsnd_configure.addArgs(&.{
            "-DBUILD_SHARED_LIBS=ON",
        });
    const libsnd_build = b.addSystemCommand(&.{
        "cmake",
        "--build",
        ".zig-cache/libsndfile",
    });
    if (args.target.result.abi == .msvc) {
        libsnd_build.addArgs(&.{
            "--config",
            b.fmt("{s}", .{switch (args.optimize) {
                .Debug => "Debug",
                else => "Release",
            }}),
        });
    }
    libsnd_build.step.dependOn(&libsnd_configure.step);
    return libsnd_build;
}
