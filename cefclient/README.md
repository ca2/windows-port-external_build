# Windows CEF redistributable

`build_external cefclient` installs the pinned CEF 109.1.13 SDK for x64
Release and Debug. Pass `--preset windows-release` or
`--preset windows-debug` to select one. CEF and Chromium come from the
official prebuilt SDK. The build compiles the C++ wrapper against that SDK.

The installer verifies the published archive checksum, reuses the sibling
`operating_system/external_build/cef` cache, and stages files in
`../operating_system/storage-windows/<architecture>/<configuration>`.

- `binary/` contains the DLLs, snapshots, resource packs, locale files, and license.
- `library/` contains `libcef.lib` and `libcef_dll_wrapper.lib`.
- `include/` contains the SDK headers. Add the configuration directory to
  the include search path for CEF's `include/cef_*.h` spelling.

The standalone `cefclient_build` CMake target supports MSVC x64 and ARM64.
Configure using a single-configuration generator with `CMAKE_BUILD_TYPE`
set to `Debug` or `Release`. Override `CEF_SDK_ROOT` to use a matching
extracted SDK, `CEF_CACHE_ROOT` for the download and wrapper cache,
`CEF_STORAGE_ROOT` for deployment, or `CEF_PLATFORM_TOOLSET` for the
wrapper compiler toolset. XP/ReactOS presets skip CEF.

The Windows cefclient project calls the same [installer](setup.ps1) and stages
CEF runtime assets beside the application before linking.
