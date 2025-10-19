# Isar Plus Web Persistence with OPFS

This document explains how Isar Plus implements persistent storage for web applications using the Origin-Private File System (OPFS) API.

## Overview

Isar Plus now supports persistent storage on the web platform using OPFS, which allows databases to survive page reloads. When OPFS is not available, the database falls back to in-memory mode.

## Requirements

### Browser Support

OPFS persistence requires a modern browser:

- **Chrome/Edge**: Version 102 or higher
- **Firefox**: Version 111 or higher  
- **Safari**: Version 16.4 or higher

### Server Configuration

**Critical**: Your web server must emit the following HTTP headers for OPFS to work:

```
Cross-Origin-Embedder-Policy: require-corp
Cross-Origin-Opener-Policy: same-origin
```

These headers enable `SharedArrayBuffer`, which is required for OPFS synchronous access handles.

#### Apache Configuration

Add to your `.htaccess` or Apache configuration:

```apache
<IfModule mod_headers.c>
  Header always set Cross-Origin-Embedder-Policy "require-corp"
  Header always set Cross-Origin-Opener-Policy "same-origin"
</IfModule>
```

#### Nginx Configuration

Add to your server block:

```nginx
add_header Cross-Origin-Embedder-Policy "require-corp" always;
add_header Cross-Origin-Opener-Policy "same-origin" always;
```

#### Flutter Web (Development)

For local development with Flutter, you'll need to configure the development server. Create a `web/index.html` with proper meta tags (handled by flutter_web_plugins automatically when properly configured).

For production builds, ensure your hosting provider supports custom headers:

- **Firebase Hosting**: Add to `firebase.json`:
  ```json
  {
    "hosting": {
      "headers": [
        {
          "source": "**",
          "headers": [
            {
              "key": "Cross-Origin-Embedder-Policy",
              "value": "require-corp"
            },
            {
              "key": "Cross-Origin-Opener-Policy",
              "value": "same-origin"
            }
          ]
        }
      ]
    }
  }
  ```

- **Netlify**: Create `_headers` file in your web directory:
  ```
  /*
    Cross-Origin-Embedder-Policy: require-corp
    Cross-Origin-Opener-Policy: same-origin
  ```

- **Vercel**: Add to `vercel.json`:
  ```json
  {
    "headers": [
      {
        "source": "/(.*)",
        "headers": [
          {
            "key": "Cross-Origin-Embedder-Policy",
            "value": "require-corp"
          },
          {
            "key": "Cross-Origin-Opener-Policy",
            "value": "same-origin"
          }
        ]
      }
    ]
  }
  ```

## Usage

### Initialization

Always call `Isar.initialize()` before opening databases on web:

```dart
import 'package:isar_plus/isar_plus.dart';

Future<void> main() async {
  // Required for web platform
  await Isar.initialize();
  
  // Open database - will persist if OPFS is available
  final isar = await Isar.openAsync(
    schemas: [UserSchema],
    directory: '/databases',  // OPFS virtual path
  );
  
  // Use the database normally
  await isar.writeAsync((isar) {
    isar.users.put(User()..name = 'John');
  });
}
```

### Checking OPFS Availability

Isar will automatically detect OPFS availability and fall back to in-memory mode if unavailable. A warning will be printed to the console if persistence is not available.

### Database Paths

On web, database paths are virtual paths within OPFS:

```dart
// Good: Uses OPFS virtual path
final isar = await Isar.openAsync(
  schemas: [UserSchema],
  directory: '/my-app/databases',
);

// Also valid: Relative paths work
final isar = await Isar.openAsync(
  schemas: [UserSchema],
  directory: 'databases',
);

// In-memory only (even if OPFS available)
final isar = await Isar.openAsync(
  schemas: [UserSchema],
  directory: Isar.sqliteInMemory,
);
```

## Limitations

### Concurrency

OPFS sync access handles provide exclusive file access. This means:

- Only one tab/window can have a database open at a time
- Opening the same database in multiple tabs will cause lock errors
- Consider using Web Locks API for coordination if you need multi-tab access

### Storage Quotas

OPFS storage is subject to browser quotas:

- Typical limit: 10-20% of available disk space per origin
- Minimum guaranteed: Usually 1GB+
- Use `navigator.storage.estimate()` to check available space

### Incognito/Private Mode

OPFS may be disabled or have reduced capacity in private browsing modes. Your app should handle cases where persistence is unavailable.

### Performance

- First database open may be slower (OPFS initialization)
- Subsequent operations have near-native performance
- OPFS is faster than IndexedDB for database operations

## Troubleshooting

### "OPFS not available" Warning

**Cause**: Missing COOP/COEP headers or unsupported browser.

**Solution**:
1. Verify headers are being sent (check Network tab in DevTools)
2. Test in a supported browser version
3. Ensure you're not in incognito/private mode

### "Worker error" Messages

**Cause**: Worker script not found or CORS issues.

**Solution**:
1. Ensure `isar_worker.js` and `opfs_bridge.js` are in the correct location
2. Check browser console for detailed error messages
3. Verify your build includes the worker files

### Database Lock Errors

**Cause**: Same database opened in multiple tabs.

**Solution**:
- Close other tabs with the same database
- Implement tab coordination using Web Locks API
- Use different database names for different app instances

### Data Loss After Reload

**Cause**: OPFS not initialized or headers missing.

**Solution**:
1. Verify COOP/COEP headers are present
2. Check browser console for OPFS warnings
3. Test `await navigator.storage.persisted()` returns `true`


## Architecture Details

The implementation consists of:

1. **JavaScript Bridge** (`opfs_bridge.js`): Wraps OPFS APIs and exposes file operations
2. **Web Worker** (`isar_worker.js`): Runs WASM in a worker context for OPFS access
3. **Rust VFS** (`wasm.rs`): SQLite VFS implementation that calls the JS bridge
4. **Dart Integration** (`web.dart`): Spawns worker and manages initialization

This architecture ensures:
- Synchronous file access for SQLite (required for performance)
- Isolation from main thread (required for OPFS sync handles)
- Graceful fallback when OPFS is unavailable

## Migration from Previous Versions

If you were using Isar Plus web before OPFS support:

1. Your existing in-memory databases will be empty after upgrading
2. Call `Isar.initialize()` before opening databases
3. Set proper COOP/COEP headers on your server
4. Data will persist after the upgrade

No code changes are required beyond adding `Isar.initialize()`.

## Future Improvements

Planned enhancements:

- IndexedDB fallback for browsers without OPFS
- Multi-tab coordination helpers
- Storage quota monitoring APIs
- Improved error messages and diagnostics

## References

- [OPFS Specification](https://fs.spec.whatwg.org/)
- [SQLite WASM OPFS Documentation](https://sqlite.org/wasm/doc/trunk/persistence.md)
- [Chrome OPFS Guide](https://developer.chrome.com/blog/sqlite-wasm-in-the-browser-backed-by-the-origin-private-file-system/)
- [MDN Web Locks API](https://developer.mozilla.org/en-US/docs/Web/API/Web_Locks_API)
