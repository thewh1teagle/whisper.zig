# Building

### Prerequisites

[Zig](https://ziglang.org/download/) | [Cmake](https://cmake.org/download/) | [Clang](https://releases.llvm.org/download.html)

### Build (macOS / Linux)

```console
git clone https://github.com/thewh1teagle/whisper.zig
cd whisper.zig
zig build
./zig-out/bin/whisper.zig
```

### Build in Windows (MSYS2 Clang64)

1. Install [MSYS2](https://www.msys2.org/)
2. Enable developer mode for symlink support (Win + R -> ms-settings:developers -> Enable developer mode)
3. Install packages

```console
C:\msys64\msys2_shell.cmd -here -no-start -defterm -clang64
pacman -S --needed $MINGW_PACKAGE_PREFIX-{cmake,ninja,toolchain}
alias cmake=/clang64/bin/cmake
```
4. Build in MSYS2 Clang64

```console
git clone https://github.com/thewh1teagle/whisper.zig
cd whisper.zig
"C:\bin\zig\zig.exe" build
```

### Build with Vulkan

1. Install [VulkanSDK](https://www.lunarg.com/vulkan-sdk/)
2. Set `VULKAN_SDK` env var
3. Build

```console
git clone https://github.com/thewh1teagle/whisper.zig
cd whisper.zig
"C:\bin\zig\zig.exe" build -Dvulkan=true
```

### Run
cd zig-out/bin
wget -nc https://github.com/thewh1teagle/vibe/raw/refs/heads/main/samples/short.wav
wget -nc https://huggingface.co/ggerganov/whisper.cpp/resolve/main/ggml-tiny.bin
./whisper.zig
```

### Clean

```console
rm -rf .zig-cache zig-out
```
