# OpenSSL external build

Standalone, checksum-pinned CMake/ExternalProject builds for Windows. Build on a
recent Windows host; copy the resulting XP binaries to XP/ReactOS for testing.
No installed compiler, Perl, or MSYS2 is needed on the target system.

| Profile | Version | Compiler | Runtime |
| --- | --- | --- | --- |
| `__REACTOS__=ON` | 3.0.22 | 32-bit MinGW/MSVCRT | XP / ReactOS compatibility |
| `__REACTOS__=OFF` | 3.5.8 LTS | MSVC or 32/64-bit MinGW | Recent Windows |

OpenSSL dropped XP/Server 2003 support starting with 3.1. The 3.0 series reached
the end of public support on September 7, 2026; its last public archive is used
here for compatibility, not as a claim of current upstream security support.
Recent Windows uses 3.5 LTS rather than the older compatibility series.

Sources: [XP support decision](https://github.com/openssl/general-policies/issues/22),
[release strategy](https://openssl-library.org/policies/general/release-strategy/),
[3.0 archives](https://openssl-library.org/source/old/3.0/),
[3.5 archives](https://openssl-library.org/source/old/3.5/),
and the downloaded source's `NOTES-WINDOWS.md` and `INSTALL.md`.

## Prerequisites

- CMake 3.24 or newer, Ninja, and a Windows C compiler.
- MinGW: MSYS2 Bash, `/usr/bin/perl`, and `/usr/bin/make`. In MSYS2 install
  `perl` and `make` if needed (`pacman -S --needed perl make`). The selected
  CMake compiler is used; MSYS2's own GCC is not substituted. XP additionally
  requires an XP-compatible 32-bit **MSVCRT** toolchain, e.g. this workspace's
  `C:/mingw32/bin/gcc.exe`; UCRT and 64-bit XP profiles are rejected.
- MSVC: run CMake from the appropriate x86/x64 Visual Studio developer prompt
  with native Windows Perl (e.g. Strawberry Perl) and NMake available.
  The wrapper uses embedded `/Z7` compiler debug information to avoid compiler
  PDB failures during dependency scans; linker PDB files are retained.
- Assembly is disabled by default to avoid an extra assembler prerequisite.
  Set `OPENSSL_ASM=ON` for upstream assembly optimizations; MSVC then needs NASM.

Use separate build and install directories for every compiler, architecture,
XP/recent-Windows profile, and Debug/Release configuration. Installed files with
the same names must not be shared between these builds.

## In windows-build-all / CLion

The outer `operating_system/operating_system-windows/tools/openssl/windows-build-all.cmake` connects this project to ca2's
`libcrypto` and `libssl` targets. There is no dependency on a manually installed
OpenSSL SDK. Reload CMake after updating the files.

For the reported Release-MinGW XP profile, from the workspace root:

```powershell
cmake -S . -B cmake-build-release-mingw-windows_xp
cmake --build cmake-build-release-mingw-windows_xp --target openssl_xp_build -j 14
cmake --build cmake-build-release-mingw-windows_xp --target release_all -j 14
```

Building a consumer such as `apex` or `release_all` also builds OpenSSL when
needed. The explicit OpenSSL target is useful for diagnosing downloads/builds.
`OPENSSL_JOBS` controls GNU make parallelism inside OpenSSL, independently of
Ninja's `-j` option. NMake is serial.

The XP SDK defaults to `${PORT_STORAGE_ROOT}/${CMAKE_BUILD_TYPE}/binary`:

```text
binary/include/openssl/...
binary/lib/libcrypto.dll.a
binary/lib/libssl.dll.a
binary/bin/libcrypto-3.dll
binary/bin/libssl-3.dll
binary/bin/openssl.exe
binary/lib/ossl-modules/...
binary/lib/engines-3/...
```

The outer project stages the runtime DLLs beside the applications, and stages
stripped copies into the existing XP deployment directory. Provider modules
are staged into `ossl-modules`. The default provider is built into libcrypto;
applications explicitly loading optional providers should set `OPENSSL_MODULES`
to the deployed `ossl-modules` directory. Optional engines remain in the SDK;
applications using those must deploy them and set `OPENSSL_ENGINES` as needed.
The SDK also contains upstream configuration files under `ssl`.

Overrides such as `OPENSSL_VERSION`, `OPENSSL_INSTALL_DIR`, `OPENSSL_JOBS`, and
`OPENSSL_ASM` can be supplied in the CLion profile's CMake options. Changing
release outside the pinned versions requires `OPENSSL_SHA256`.

## Standalone XP build

From this `openssl` directory:

```powershell
cmake --preset xp-release
cmake --build --preset xp-release
```

Use `xp-debug` for Debug. If Ninja is not on PATH, pass
`-DCMAKE_MAKE_PROGRAM=<absolute-path-to-ninja.exe>` when configuring.
The default SDK is `build/<preset>/install`. The wrapper adds `__REACTOS__`,
`_WIN32_WINNT=0x0501`, and `WINVER=0x0501` only to the XP build. Upstream 3.0
then uses CryptoAPI entropy and critical sections, retaining threading and
error handling without patches to OpenSSL sources.

## Standalone recent Windows build

MSVC, in an x64 Visual Studio developer prompt:

```powershell
cmake --preset windows-release -DCMAKE_C_COMPILER=cl.exe
cmake --build --preset windows-release
```

Or MinGW, selecting the compiler explicitly:

```powershell
cmake --preset windows-release -DCMAKE_C_COMPILER=C:/mingw64/bin/gcc.exe
cmake --build --preset windows-release
```

Use an x86 developer prompt/compiler and a separate build directory for 32-bit.
For MSVC the import libraries are `lib/libcrypto.lib` and `lib/libssl.lib`.
64-bit DLLs have upstream's `-x64` suffix. The targets `OpenSSL::Crypto` and
`OpenSSL::SSL` are available in addition to ca2's `libcrypto`/`libssl` names.

## Downloads, tests, and troubleshooting

- `OPENSSL_URL`: optional local tarball or alternate URL; SHA256 verification
  is retained. Default URLs are the upstream GitHub release assets.
- `OPENSSL_SOURCE_DIR`: optional existing **unmodified** source tree. Its
  `VERSION.dat` must match `OPENSSL_VERSION`. Builds are out of tree.
- `OPENSSL_EXTRA_CONFIGURE_ARGS`: extra Configure arguments, as a CMake list.
  Do not override `shared`, `--prefix`, `--libdir`, or the target architecture.
- `OPENSSL_RUN_TESTS=ON`: builds and runs the upstream suite before installing.
- `OPENSSL_VERIFY=ON` (default): runs version, random-generator, TLS cipher, and
  SHA256 known-answer smoke tests on the **build host**, saving results in
  `build-verification.txt`. Disable this for a host that cannot execute the target.

XP installations also save import reports and reject selected known post-XP
APIs, UCRT/API-set DLLs, BCrypt, and MSYS/Cygwin runtime imports. This is an
additional check, not an exhaustive XP API database. It does not prove target
runtime compatibility. Run the installed CLI and the existing import audit
inside XP/ReactOS before relying on a new toolchain/release.

ExternalProject logs are in
`build/<preset>/openssl-<version>-<profile>-<pointer-bytes>-<configuration>/src/openssl_build-stamp/`.
The parent build uses `port/external-openssl` instead of `build/<preset>`.
An incremental build reuses the downloaded archive and completed build steps;
changed wrapper settings invalidate the configure/build/install steps.
