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

Build in Windows (msys2 clang64)

```console
# Enable developer mode for symlinks
# Win + R -> ms-settings:developers -> enable developer mode

# Install dependencies
C:\msys64\msys2_shell.cmd -here -no-start -defterm -mingw64
alias cmake=/mingw64/bin/cmake
pacman -S --needed $MINGW_PACKAGE_PREFIX-{cmake,ninja,toolchain}

# Build
git clone https://github.com/thewh1teagle/whisper.zig --recursive
cd whisper.zig
rm -rf .zig-cache zig-out
"C:\bin\zig\zig.exe" build

# Run
cd zig-out/bin
wget -nc https://github.com/thewh1teagle/vibe/raw/refs/heads/main/samples/short.wav
wget -nc https://huggingface.co/ggerganov/whisper.cpp/resolve/main/ggml-tiny.bin
./whisper.zig.exe
```

Clean

```console
rm -rf lib/whisper.cpp/build lib/libsndfile.cpp/build .zig-cache zig-out
```
