const std = @import("std");

const whisper = @cImport({
    @cInclude("whisper.h");
});

const libsndfile = @cImport({
    @cInclude("sndfile.h");
});

pub fn main() !void {
    const model_path = "ggml-tiny.bin";
    const wav_path = "short.wav";
    // const language = "en";

    // Read wav
    var sfInfo: libsndfile.SF_INFO = undefined;
    const file = libsndfile.sf_open(wav_path, libsndfile.SFM_READ, &sfInfo);
    if (file == null) {
        return error.FileOpenFailed;
    }

    const cparams: whisper.whisper_context_params = whisper.whisper_context_default_params();

    const ctx = whisper.whisper_init_from_file_with_params(model_path, cparams);
    if (ctx == null) {
        return error.FielOpenFailed;
    }
    whisper.whisper_free(ctx);

    std.debug.print("cparams: {}\n", .{cparams.use_gpu});
}
