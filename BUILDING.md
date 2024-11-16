# Building

### Prerequisites

[Zig](https://ziglang.org/download/) | [Cmake](https://cmake.org/download/) | [Clang](https://releases.llvm.org/download.html)

Build

```console
git clone https://github.com/thewh1teagle/whisper.zig --recursive
cd whisper.zig
zig build
./zig-out/bin/whisper.zig
```

Clean

```console
rm -rf lib/whisper.cpp/build lib/libsndfile.cpp/build .zig-cache zig-out
```
