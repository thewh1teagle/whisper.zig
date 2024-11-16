const std = @import("std");

const whisper = @cImport({
    @cInclude("whisper.h");
});

pub fn main() !void {
    const cparams: whisper.whisper_context_params = whisper.whisper_context_default_params();
    std.debug.print("cparams: {}\n", .{cparams.use_gpu});
}
