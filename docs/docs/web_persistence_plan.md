# Web Persistence Implementation Plan

## Problem Statement
- The current web platform bindings (`packages/isar_plus/lib/src/web`) load the `isar.wasm` core and use a stubbed SQLite VFS that always returns `SQLITE_IOERR`, so the runtime falls back to in-memory storage with no persistence.
- As a result, collections lose data after a page reload. We need to provide persistent storage for the web build without regressing existing native platforms.

## Research Summary
1. SQLites official WASM documentation describes multiple persistence strategies, including Origin Private File System (OPFS) and keyvalue VFSs, and details the concurrency and header requirements for OPFS.[^1]
2. Chromes OPFS guidance explains how to host SQLite WASM in a Worker, why `SharedArrayBuffer` and COOP/COEP headers are required, and shows typical database lifecycle code using OPFS-backed files.[^2]
3. Community discussions on Isar web support highlight the need for a persistent VFS (IndexedDB emulation or OPFS) to move beyond in-memory mode.[^3]

[^1]: https://sqlite.org/wasm/doc/tip/persistence.md
[^2]: https://developer.chrome.com/blog/sqlite-wasm-in-the-browser-backed-by-the-origin-private-file-system/
[^3]: https://github.com/isar-community/isar-community/issues/37

## Proposed Architecture
- **Primary storage**: Implement an OPFS-backed VFS exposed to the Rust core through imported host functions. Use `FileSystemSyncAccessHandle` for synchronous reads/writes where available, with an async fallback (IndexedDB/kvvfs) for browsers that lack OPFS.
- **Execution context**: Run the WASM core inside a dedicated Worker so OPFS sync APIs and `SharedArrayBuffer` are available.
- **Host bridge**: Provide a minimal JavaScript module (generated into the Dart web bundle) that implements the filesystem primitives needed by SQLite (`open`, `close`, `read`, `write`, `truncate`, `lock`, etc.) and exports them as WASM imports via the instantiation `imports.env.*`.
- **Rust integration**: Replace the stubbed VFS in `packages/isar_core/src/sqlite/wasm.rs` with real implementations that proxy into the JS bridge, manage file descriptors, and translate SQLite flags to OPFS semantics.
- **Path management**: Extend the Dart web platform layer so instance directories resolve to OPFS root directories. Retain `:memory:` as a fallback for explicit memory-only instances.
- **Concurrency**: Serialize access per database by leveraging OPFS sync handles (single writer) and implement retry/backoff aligned with SQLite expectations to avoid spurious lock errors.

## Implementation Steps
1. **Worker bootstrap**
   - Add a dedicated web Worker entrypoint that loads `isar.wasm`, configures the import object (including filesystem functions and SharedArrayBuffer setup), and exposes message handlers for the Dart main isolate.
   - Update `packages/isar_plus/lib/src/web/web.dart` to spawn the Worker, initialize the bindings asynchronously, and forward API calls via `postMessage`.
2. **JS filesystem bridge**
   - Author a small TypeScript/JavaScript module (compiled to JS) that wraps OPFS handles, maintains an in-memory map of open files, and exposes the required `env` imports (e.g., `isar_opfs_open`, `isar_opfs_close`, `isar_opfs_read`, `isar_opfs_write`, `isar_opfs_truncate`, `isar_opfs_sync`, `isar_opfs_delete`, `isar_opfs_access`).
   - Handle browsers without OPFS by detecting capability at startup and falling back to a kvVFS backed by IndexedDB (using the `sqlite3` kvvfs approach) while clearly surfacing reduced durability.
3. **Rust VFS implementation**
   - Replace `wasm_vfs_*` stubs with real implementations that call the JS bridge via `extern "C"` imports and manage a `sqlite3_io_methods` table stored in static memory.
   - Implement per-file state (size, access mode, lock status) and ensure WAL-related calls map to OPFS operations; when WAL is disabled, translate to rollback journal semantics.
   - Integrate error handling so JS exceptions propagate as the appropriate SQLite error codes.
4. **Initialization plumbing**
   - Ensure `sqlite3_os_init` registers the new VFS and that `sqlite3` uses it by default. Provide a runtime flag to opt out (for tests) by setting `SQLITE_MEMORY_DIR`.
   - Update the WASM import object from Dart to pass function pointers (e.g., `shared memory` base address) if required, and expose memory views for the bridge.
5. **Build & packaging**
   - Adjust `tool/build_wasm.sh` to include any additional assets (worker script, bridge module) in the package output.
   - Ship the worker and JS bridge alongside the wasm binary (e.g., under `packages/isar_plus/lib/src/web/runtime/`). Ensure they are bundled via `build_web_compilers` when published.
6. **Testing**
   - Create integration tests under `packages/isar_plus_test/web` that:
     - Write data, reload the database instance, and verify persistence.
     - Exercise concurrent tabs by simulating two workers.
     - Validate fallback mode when OPFS is unavailable (using a mocked `navigator.storage.persisted` response).
   - Add CI instructions for running headless Chrome with the necessary flags to enable COOP/COEP headers and persistent storage.
7. **Documentation**
   - Update repository docs to mention new web requirements (COOP/COEP headers, serving worker scripts, persistence expectations) and provide migration guidance for existing users.

## Risk & Mitigation
- **Browser compatibility**: Safari <17 lacks stable sync access handles. Mitigate with IndexedDB fallback and clear warnings.
- **Serving constraints**: COOP/COEP headers are mandatory for SharedArrayBuffer. Document required server config and update example Flutter web app to set headers via `web/index.html`.
- **Concurrency limits**: OPFS allows only one sync access handle per file. Implement lock retries and consider enabling SQLites `opfs-unlock-asap` mode for query watchers.

## Success Criteria
- Data written in a Flutter web build remains after full page reloads in browsers that support OPFS.
- Automated web tests pass and detect regressions in both persistence-enabled and fallback modes.
- No regressions for existing native platforms (Android/iOS/desktop) or CLI/API behavior.
