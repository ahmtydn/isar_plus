---
title: Limitations
---

# Limitations

As you know, Isar works on mobile devices and desktops running on the VM as well as Web. Both platforms are very different and have different limitations.

## VM Limitations

- Only the first 1024 bytes of a string can be used for a prefix where-clause
- Objects can only be 16MB in size

## Web Limitations

Isar Plus on the web now runs on SQLite compiled to WebAssembly. Chrome and Edge persist data inside the Origin Private File System (OPFS); Safari, Firefox, and older Chromium builds fall back to an IndexedDB-backed VFS. The OPFS backend mirrors native SQLite behaviour, while the fallback still carries a few browser-imposed constraints:

- Use the asynchronous APIs on the web; synchronous collection helpers throw `UnsupportedError`.
- Text helpers such as `Isar.splitWords()` and `.matches()` remain unimplemented for the web engine.
- Schema migrations are not validated as strictly as on the VM, so double-check breaking changes during releases.
- When the IndexedDB fallback is active, some return values (for example `delete()` counts) may differ from native SQLite and auto-increment counters are not reset by `clear()`.
