// wget https://huggingface.co/ggerganov/whisper.cpp/resolve/main/ggml-tiny.bin
// wget https://github.com/thewh1teagle/vibe/raw/refs/heads/main/samples/short.wav
// zig build
// zig-out/bin/whisper.zig

const std = @import("std");

const whisper = @cImport({
    @cInclude("whisper.h");
});
const libsndfile = @cImport({
    @cInclude("sndfile.h");
});

// Disable whisper log
fn whisper_log_callback(level: c_uint, message: [*c]const u8, user_data: ?*anyopaque) callconv(.C) void {
    _ = level;
    _ = message;
    _ = user_data;
}

pub fn main() !void {
    const model_path = "ggml-tiny.bin";
    const wav_path = "short.wav";
    const language = "en";

    // Read wav
    var sfInfo: libsndfile.SF_INFO = undefined;
    const file = libsndfile.sf_open(wav_path, libsndfile.SFM_READ, &sfInfo);
    if (file == null) {
        return error.FileOpenFailed;
    }

    const n_samples: usize = @intCast(sfInfo.frames * sfInfo.channels);
    var samples: []f32 = undefined; // Allocate memory for the samples buffer
    samples = try std.heap.page_allocator.alloc(f32, n_samples);

    // Read the samples into the buffer
    const read_samples = libsndfile.sf_read_float(file, samples.ptr, @intCast(n_samples));
    if (read_samples != n_samples) {
        return error.FileOpenFailed; // Handle read error
    }

    // whisper
    whisper.whisper_log_set(whisper_log_callback, null);

    const cparams: whisper.whisper_context_params = whisper.whisper_context_default_params();

    const ctx = whisper.whisper_init_from_file_with_params(model_path, cparams);
    if (ctx == null) {
        std.debug.print("Failed to create whisper context", .{});
        std.process.exit(1);
    }
    var fparams = whisper.whisper_full_default_params(whisper.WHISPER_SAMPLING_GREEDY);
    fparams.new_segment_callback = null;
    fparams.language = language;
    fparams.print_realtime = false;
    fparams.debug_mode = false;
    fparams.no_timestamps = true;
    fparams.print_special = false;
    fparams.translate = false;
    fparams.single_segment = true;
    fparams.print_progress = false;
    fparams.no_context = true;

    if (whisper.whisper_full(ctx, fparams, samples.ptr, @intCast(n_samples)) != 0) {
        std.debug.print("failed to call whisper_full\n", .{});
    }
    const n_segments: i32 = whisper.whisper_full_n_segments(ctx);

    for (0..@intCast(n_segments)) |i| {
        const text: [*c]const u8 = whisper.whisper_full_get_segment_text(ctx, @intCast(i));
        std.debug.print("Text: {s}\n", .{text});
    }
    whisper.whisper_free(ctx);
}
