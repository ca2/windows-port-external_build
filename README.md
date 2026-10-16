# External Build

Standalone CMake projects for building external dependencies independently of
`windows-build-all`. The parent repository can supply settings and connect their
outputs to its application dependencies.

- [FFmpeg external build](ffmpeg/README.md): Windows XP/ReactOS and recent Windows
  profiles, separate Debug/Release presets, installation options, and parent
  dependency integration.
- [OpenSSL external build](openssl/README.md): OpenSSL 3.0 for XP/ReactOS and
  3.5 LTS for recent Windows, MinGW/MSVC, and automatic SDK/runtime staging.
