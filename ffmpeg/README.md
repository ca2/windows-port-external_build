# Standalone FFmpeg build for Windows

This directory is a standalone CMake project. It does not require the ca2 parent
project or its deployment scripts. [`port.cmake`](port.cmake) connects the
formula to the parent build and handles application runtime staging.

## Prerequisites

- CMake 3.24 or newer and Ninja.
- MSYS2 bash, GNU make and standard Unix utilities, normally under
  `C:/msys64/usr/bin`. Override `FFMPEG_BASH` if installed elsewhere.
- A MinGW-w64 C compiler and matching binutils, or an MSVC developer prompt.
- NASM on PATH or alongside the MinGW compiler for optimized x86 assembly.
  Alternatively use `-DFFMPEG_EXTRA_CONFIGURE_ARGS=--disable-x86asm`.

## Windows XP / ReactOS, 32-bit MinGW

Run from this directory:

```powershell
cmake -S . -B build-xp -G Ninja -DCMAKE_C_COMPILER=C:/mingw32/bin/gcc.exe -D__REACTOS__=ON
cmake --build build-xp --target ffmpeg_build
```

The default is FFmpeg **6.1.6**, the current maintenance release in the 6.1 series.
Use `-DFFMPEG_VERSION=6.1.2` to request 6.1.2 instead; checksums for 6.1.2, 6.1.4
and 6.1.6 are included. The XP profile explicitly requires 32-bit MinGW and uses
`__REACTOS__`; selecting MinGW alone does not select XP.

Use an XP-compatible **MSVCRT** toolchain and matching winpthread runtime.
The wrapper targets NT 5.1, uses pthreads instead of Vista synchronization APIs,
disables BCrypt, and supplies strict UTF-16 conversion compatible with XP.
It patches a generated copy of configure, leaving downloaded sources unchanged.
Flags alone cannot make an incompatible compiler runtime support XP: validate
the resulting DLLs and compiler runtimes in the actual guest before shipping.

## Recent Windows

```powershell
cmake -S . -B build-windows -G Ninja -DCMAKE_C_COMPILER=C:/path/to/mingw64/bin/gcc.exe
cmake --build build-windows --target ffmpeg_build
```

The default is FFmpeg **9.0.2**. MSVC is also supported by the wrapper: run from a
Visual Studio developer prompt and replace the compiler option with
`-DCMAKE_C_COMPILER=cl`. Keep the developer environment available during builds.
MSVC uses FFmpeg's native linker adapter and installs generated PDB files beside the DLLs.

Release defaults are pinned for reproducibility, based on the
[official FFmpeg releases](https://ffmpeg.org/download.html), checked 2026-10-16.
They do not silently update during a build. Use separate build directories for
different compilers, architectures, or XP/recent Windows profiles.

## Debug and Release

Four presets keep configuration outputs separate:

```powershell
cmake --preset xp-debug
cmake --build --preset xp-debug
cmake --preset xp-release
cmake --build --preset xp-release
```

Use `windows-debug` and `windows-release` for recent Windows. The XP presets
select `C:/mingw32/bin/gcc.exe`; override that cache variable for a different
XP-compatible toolchain. For recent MinGW, supply your compiler when configuring,
for example `cmake --preset windows-debug -DCMAKE_C_COMPILER=C:/mingw64/bin/gcc.exe`.
For MSVC, use a Visual Studio developer prompt.

Each preset installs under `build/<preset>/install` in this directory. Debug and
Release DLLs retain upstream filenames, so deploy one configuration at a time.
Debug enables GCC level-3 symbols (MSVC uses CodeView/PDB), disables stripping and optimization, and disables
inline assembly so that compiler-generated code remains debuggable. External
NASM assembly is still enabled. Release uses optimized binaries without FFmpeg debug symbols.
`RelWithDebInfo` preserves symbols with optimization, and `MinSizeRel` requests
small optimized binaries; select these with `-DCMAKE_BUILD_TYPE=...` in a separate
build directory. An unspecified build type defaults to Release. Use a
single-configuration generator such as Ninja; Visual Studio and Ninja Multi-Config
generators are not supported by this wrapper.

## Integration with windows-build-all

The parent repository configures this project through [`port.cmake`](port.cmake)
when `INCLUDE_AUDIO` is enabled. That adapter defines the parent-build defaults.
The standalone CMake project does not depend on that integration.

The parent sets overridable `FFMPEG_*` cache variables before adding this project:
FFmpeg 6.1.6 for `__REACTOS__`, otherwise 9.0.2; configuration-specific installation
paths; library-only builds; networking disabled; and optional extra configure
arguments. Compiler, architecture and `CMAKE_BUILD_TYPE` follow the parent build.
CLion CMake profile options or `cmake -D...` can override the cache settings.
`CA2_FFMPEG_SOURCE_DIRECTORY` selects the wrapper project, while
`FFMPEG_SOURCE_DIR` selects pristine upstream FFmpeg sources.

The parent connects the five imported library targets and runtime staging targets
to its application dependencies and `port_all`. The ca2 audio resampler uses
`swr_alloc_set_opts2` with explicit `AVChannelLayout` values for FFmpeg 6.1 and
recent releases, with a legacy setup retained for older headers. This shared API
path works with both XP/ReactOS and recent Windows without newer Windows API imports.

Normal Debug executables and DLLs keep their symbols in the usual output directory
inside `CMAKE_BINARY_DIR`. For 32-bit MinGW builds with `__REACTOS__` enabled,
the deployment helper additionally creates stripped copies in
`../_stripped_output`, relative to the parent source root. Override that destination
with `CA2_REACTOS_DEPLOY_DIRECTORY`. These copies reduce PE image size and pressure
on the guest's 32-bit address space; they do not replace the original Debug files
or change the normal output directory. Recent Windows builds do not enable this
helper automatically.

Validation on the Windows host covered full XP-profile Debug/Release library
builds, reduced recent-Windows MinGW Debug/Release builds, a reduced 64-bit MSVC
Debug build with installed PDBs, DLL loading and stereo resampling smoke checks,
and compilation of the ca2 resampler against both SDK versions. Actual XP guest
runtime compatibility and a complete recent-Windows application build remain
unverified.

## Outputs and options

The default SDK is installed under `<build>/install`:

- `bin`: avutil, swresample, avcodec, avformat and swscale DLLs, plus matching
  available MinGW compiler runtime DLLs.
- `include`: public FFmpeg headers.
- `lib`: MinGW import libraries and pkg-config metadata. MSVC import libraries
  are installed beside the DLLs in `bin`, following upstream FFmpeg behavior.

Default builds enable upstream's built-in codecs, formats and protocols, with
networking disabled. External library autodetection is disabled to keep builds
independent of unrelated host packages. CLI programs, avfilter and avdevice are
disabled by default. No external codecs or their source trees are downloaded.

| CMake setting | Purpose |
| --- | --- |
| `FFMPEG_INSTALL_DIR` | Override the SDK installation directory |
| `FFMPEG_VERSION` | Select a pinned 6.1.x or 9.0.x release; XP accepts 6.1.x |
| `FFMPEG_SHA256` | Required checksum for an unlisted archive release |
| `FFMPEG_URL` | Override archive URL, or use a local archive file |
| `FFMPEG_SOURCE_DIR` | Use existing pristine sources matching `FFMPEG_VERSION` |
| `FFMPEG_JOBS` | GNU make parallelism; defaults to available processors |
| `FFMPEG_BUILD_PROGRAMS=ON` | Also build ffmpeg/ffprobe, avfilter and avdevice |
| `FFMPEG_NETWORK=ON` | Enable upstream network protocols |
| `FFMPEG_EXTRA_CONFIGURE_ARGS` | Additional configure arguments, separated by semicolons |

For example, a reduced codec set can be requested with
`'-DFFMPEG_EXTRA_CONFIGURE_ARGS=--disable-everything;--enable-decoder=mp3'`.
Additional arguments come last. Do not disable the five exported libraries,
change shared-library naming, or override the XP compatibility flags: imported
CMake targets and the compatibility profile rely on those settings.

Use `add_subdirectory()` to consume the project from another CMake build. It
exports `FFmpeg::avutil`, `FFmpeg::swresample`, `FFmpeg::avcodec`,
`FFmpeg::avformat`, and `FFmpeg::swscale` imported shared targets, with build
ordering, include directories, and library dependencies already attached.
`FFMPEG_BUILD_PROGRAMS=ON` also exports avfilter and avdevice targets.

ExternalProject logs are under
`<build>/ffmpeg-<version>-<profile>-<configuration>/src/ffmpeg_build-stamp/`.
Configure probe details are in the sibling `build/ffbuild/config.log`.
