# External library formulas

- Place each formula in a directory named for the upstream project, such as
  `openssl/` or `ffmpeg/`. Use lowercase, version-free project and component
  names. Keep the names stable across upstream releases and build profiles.
- Give each formula a standalone `CMakeLists.txt` and a stable
  `<formula>_build` target. Expose each supported component as an imported
  CMake target. Set its `IMPORTED_IMPLIB` and `IMPORTED_LOCATION` for the
  selected profile so consumers can resolve filenames from the target.
- In a consuming project's `_port.txt`, list one `formula:component` per
  directly linked external library. For example, use `openssl:crypto` for
  `libcrypto.lib` and `ffmpeg:avcodec` for `avcodec.lib`. Put transitive
  dependencies in the formula's CMake target relationships.
- Keep upstream version pins and checksums in the formula. Keep MSVC import
  library basenames stable across versions where upstream supports it.
  Preserve the upstream runtime DLL filename when it is embedded in the
  import library or contains an ABI version or architecture suffix.
- The consuming build stages external binaries and import libraries in
  `storage-windows/<architecture>/<configuration>/binary` and
  `storage-windows/<architecture>/<configuration>/library` respectively.
  Use the selected compiler, architecture, and configuration for the
  formula. Keep the ReactOS/XP path behind `__REACTOS__`.

## Source and Debug layout

- Resolve the external build root as `../operating_system/external_build`
  from the consuming repository root. Repositories with the same parent
  share the sources, builds, and symbols in that parent's directory. Keep
  the formulas under `port/external_build/<formula>`.
  - `~/code/main` uses `~/code/operating_system/external_build`.
  - `~/code/integration/console_build_tools` uses
    `~/code/integration/operating_system/external_build`.
- Use `<external-build-root>/<formula>` for the verified upstream source
  tree and `<external-build-root>/.downloads/<formula>` for downloaded archives.
  Verify the formula's pinned checksum before extracting. Reuse matching
  sources. Keep a different version in a separate source directory and
  preserve source trees used by existing PDBs.
- Put generated files under
  `<external-build-root>/.build/<formula>/<toolchain>/<architecture>/<configuration>`.
  Set the formula's source override to the permanent source directory, such
  as `OPENSSL_SOURCE_DIR` or `FFMPEG_SOURCE_DIR`, before configuring.
- For MSVC Debug builds, compile with source-level debug information, retain the
  linker PDB for each runtime DLL, and stage the matching PDB beside that DLL.
  Build from the permanent source path so the debugger can open the source
  files referenced by the PDB. Verify the PDB matches the DLL and a recorded
  source path resolves on disk before publishing Debug artifacts.
