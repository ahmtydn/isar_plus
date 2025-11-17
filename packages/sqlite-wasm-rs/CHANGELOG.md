# `sqlite-wasm-rs` Change Log
--------------------------------------------------------------------------------

## Unreleased

### Added

* Added `sqlite3_os_end` C interface.
  [#117](https://github.com/Spxg/sqlite-wasm-rs/pull/117)

### Changed

* Allow the OPFS SyncAccessHandle VFS to initialize when running inside a
  window context (e.g., Flutter/Dart web), falling back to IndexedDB only when
  `navigator.storage` is unavailable. This enables Isar Plus web builds to use
  OPFS storage without moving the entire runtime into a dedicated worker.

--------------------------------------------------------------------------------

## [0.4.5](https://github.com/Spxg/sqlite-wasm-rs/compare/0.4.4...0.4.5)

### Changed

* Moved VFS documentation to source files.
  [#112](https://github.com/Spxg/sqlite-wasm-rs/pull/112)

* Removed unnecessary `thread_local` used.
  [#113](https://github.com/Spxg/sqlite-wasm-rs/pull/113)
