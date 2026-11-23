# External Build

Standalone CMake projects for building external dependencies independently of
`windows-build-all`. The parent repository can supply settings and connect their
outputs to its application dependencies.

- [FFmpeg external build](ffmpeg/README.md): Windows XP/ReactOS and recent Windows
  profiles, separate Debug/Release presets, installation options, and parent
  dependency integration.
- [OpenSSL external build](openssl/README.md): OpenSSL 3.0 for XP/ReactOS and
  3.5 LTS for recent Windows, MinGW/MSVC, and automatic SDK/runtime staging.
- [CEF redistributable](cefclient/README.md): deploys the pinned prebuilt SDK,
  runtime resources, headers, and C++ wrapper.

## Shared Windows headers

After installation, the OpenSSL and FFmpeg build targets merge their installed
SDK headers into
`../operating_system/storage-windows/<architecture>/<configuration>/include`
relative to the checkout containing `port/external_build`, including when the
build helper generates its CMake driver elsewhere. For example, x64 Debug builds
share `storage-windows/x64/Debug/include`, with headers under directories such
as `openssl/` and `libavcodec/`.

`build_external` checks and builds both Release and Debug for MSVC x64.
Pass `--preset windows-release` or `--preset windows-debug` to select a single
configuration. Pass a formula name to limit the build to that formula, as in
`build_external openssl`. The XP/ReactOS presets are `xp-release` and
`xp-debug` (MinGW Win32).

Set `EXTERNAL_BUILD_HEADER_STORAGE_ROOT` to an absolute path to override
`storage-windows`. Each formula keeps its own SDK install prefix. New formulas
can register the same post-install step with
`external_build_stage_headers(<build-target> "<sdk-install-directory>")`
from `stage-headers.cmake`.
