<p align="center">
  <a href="https://github.com/ahmtydn/isar">
    <img src="https://raw.githubusercontent.com/ahmtydn/isar_plus/main/.github/assets/isar.svg?sanitize=true" height="128">
  </a>
  <h1 align="center">Isar Plus Database</h1>
</p>

<p align="center">
  <a href="https://pub.dev/packages/isar_plus"><img src="https://img.shields.io/pub/v/isar_plus?label=pub.dev&labelColor=333940&logo=dart"></a>
  <a href="https://pub.dev/packages/isar_plus/score"><img src="https://img.shields.io/pub/points/isar_plus?label=score&labelColor=333940&logo=dart"></a>
  <a href="https://github.com/ahmtydn/isar_plus"><img src="https://img.shields.io/github/stars/ahmtydn/isar_plus?style=social"></a>
  <a href="https://buymeacoffee.com/ahmtydn">
  <img src="https://img.shields.io/badge/Buy%20Me%20a%20Coffee-ffdd00?style=for-the-badge&logo=buy-me-a-coffee&logoColor=black" alt="Buy Me A Coffee" style="display: block; margin: 0 auto; padding: 0;">
  </a>
</p>

## About Isar Plus

Isar Plus is an enhanced fork of the original [Isar database](https://github.com/isar/isar) created by Simon Choi. This project builds upon the solid foundation of the original Isar, adding new features, improvements, and ongoing maintenance.

### What's Different?

- ✨ **Enhanced Features**: Additional capabilities beyond the original Isar
- 🌐 **Improved Web Support**: Better SQLite/WASM integration for Flutter Web
- 🔧 **Active Maintenance**: Regular updates and bug fixes
- 🌍 **Multilingual Documentation**: Including Turkish language support
- 🚀 **Performance Optimizations**: Continuous improvements to speed and efficiency

### Credits

This project is built upon the original Isar database:
- **Original Author**: Simon Choi
- **Original Repository**: https://github.com/isar/isar
- **License**: Apache License 2.0

Special thanks to all the [original Isar contributors](https://github.com/isar/isar/graphs/contributors) whose work made this project possible.

**Isar Plus Maintainer**: Ahmet Aydın ([@ahmtydn](https://github.com/ahmtydn))

## Features

- 💙 **Made for Flutter**. Easy to use, no config, no boilerplate
- 🚀 **Highly scalable** The sky is the limit (pun intended)
- 🍭 **Feature rich**. Composite & multi-entry indexes, query modifiers, JSON support etc.
- ⏱ **Asynchronous**. Parallel query operations & multi-isolate support by default
- 🦄 **Open source**. Everything is open source and free forever!
- ✨ **Enhanced**. Additional features and improvements over the original Isar
- 🌐 **Persistent web storage**. Automatic OPFS + IndexedDB fallback for Flutter Web.

## Installation

Add the following to your `pubspec.yaml`:

```yaml
dependencies:
  isar_plus: latest
  isar_plus_flutter_libs: latest

dev_dependencies:
  build_runner: any
```

## Flutter Web Persistence

Isar Plus now ships a SQLite/WebAssembly stack backed by [`sqlite-wasm-rs`](https://github.com/ahmtydn/isar_plus/tree/main/packages/sqlite-wasm-rs). Chrome and Edge store your database inside the Origin Private File System (OPFS), while Safari, Firefox, and other browsers fall back to an IndexedDB-backed VFS. The database schema and APIs match the native SQLite engine, so your collections remain portable across platforms.

### Bundle the WASM artifacts

- Every release uploads both `isar.wasm` and the generated `isar.js` glue file.
- For local development run `./tool/prepare_local_dev.sh --targets wasm` (or `./tool/build_wasm.sh`) to regenerate both files in the repository root.
- Copy the pair into your Flutter project's `web/` directory or configure your web server/CDN to serve them side-by-side. The loader expects `isar.js` to live next to `isar.wasm`.

### Initialize Isar on the web

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (kIsWeb) {
    await Isar.initialize();
  }

  final isar = await Isar.open(
    [UserSchema],
    engine: IsarEngine.sqlite,
    directory: 'isar_data',
  );

  runApp(MyApp(isar: isar));
}
```

`directory` becomes a logical folder inside OPFS/IndexedDB (the default value is `isar`). Use `Isar.sqliteInMemory` when you intentionally want a transient database.

## Android 16KB Page Size Support

Starting with Android 15, devices may use 16KB memory page sizes for improved performance. Google Play requires apps targeting Android 15+ to support 16KB page sizes starting November 1st, 2025.

Isar Plus includes full support for 16KB page sizes out of the box. The native libraries are built with the necessary alignment flags to ensure compatibility with these devices.

### Build Requirements

When building from source, ensure you have:

- **Android NDK r27 or higher** (recommended for best 16KB support)
- **Android Gradle Plugin 8.5.1 or higher** (already included)
- **Rust toolchain** with Android targets installed

The build system automatically includes the necessary linker flags (`-Wl,-z,max-page-size=16384`) for all Android architectures.

Join the [Telegram group](https://t.me/isarplus) for discussion and sneak peeks of new versions of the DB.

If you want to say thank you, star us on GitHub and like us on pub.dev 🙌💙

## API Migration Guide

Isar Plus v4 introduces a new transaction API that's more intuitive and consistent. Here's what you need to know:

### Transaction API Changes

| **Isar v3**      | **Isar Plus v4**     | **Description**                          |
|------------------|----------------------|------------------------------------------|
| `writeTxn()`     | `writeAsync()`       | Asynchronous write transaction           |
| `writeTxnSync()` | `write()`            | Synchronous write transaction            |
| `txn()`          | `readAsync()`        | Asynchronous read transaction            |
| `txnSync()`      | `read()`             | Synchronous read transaction             |

### Example: Write Operations

**Old API (v3):**
```dart
await isar.writeTxn(() async {
  await isar.users.put(user);
});
```

**New API (v4):**
```dart
await isar.writeAsync((isar) async {
  await isar.users.put(user);
});
```

### Example: Read Operations

**Old API (v3):**
```dart
final user = await isar.txn(() async {
  return await isar.users.get(1);
});
```

**New API (v4):**
```dart
final user = await isar.readAsync((isar) async {
  return await isar.users.get(1);
});
```

### Example: Synchronous Operations

**Old API (v3):**
```dart
isar.writeTxnSync(() {
  isar.users.putSync(user);
});
```

**New API (v4):**
```dart
isar.write((isar) {
  isar.users.put(user);
});
```

### Other Notable Changes

- **ID Requirements**: IDs must be named `id` or annotated with `@id`
- **Auto-increment IDs**: Use `Isar.autoIncrement` instead of `null` for auto-generated IDs
- **Enums**: Use `@enumValue` annotation instead of `@enumerated`
- **Embedded Objects**: Replace Isar links with embedded objects using `@embedded`
- **Minimum Android SDK**: Now requires Android SDK 23+

For more details, see the [CHANGELOG.md](packages/isar_plus/CHANGELOG.md).

## Quickstart

Holy smokes you're here! Let's get started on using the coolest Flutter database out there...

### 1. Add to pubspec.yaml

```yaml
dependencies:
  isar_plus: latest
  isar_plus_flutter_libs: latest

dev_dependencies:
  build_runner: any
```

### 2. Annotate a Collection

```dart
part 'email.g.dart';

@collection
class Email {
  Email({
    this.id,
    this.title,
    this.recipients,
    this.status = Status.pending,
  });

  final int id;

  @Index(type: IndexType.value)
  final String? title;

  final List<Recipient>? recipients;

  final Status status;
}

@embedded
class Recipient {
  String? name;

  String? address;
}

enum Status {
  draft,
  pending,
  sent,
}
```

### 3. Open a database instance

```dart
final dir = await getApplicationDocumentsDirectory();
final isar = await Isar.open(
  [EmailSchema],
  directory: dir.path,
);
```

### 4. Query the database

```dart
final emails = isar.emails.where()
  .titleContains('awesome', caseSensitive: false)
  .sortByStatusDesc()
  .limit(10)
  .findAll();
```

## Isar Database Inspector

The Isar Inspector allows you to inspect the Isar instances & collections of your app in real-time. You can execute queries, edit properties, switch between instances and sort the data.

<img src="https://raw.githubusercontent.com/ahmtydn/isar_plus/main/.github/assets/inspector.gif">

To launch the inspector, just run your Isar app in debug mode and open the Inspector link in the logs.

## CRUD operations

All basic crud operations are available via the `IsarCollection`.

```dart
final newEmail = Email()..title = 'Amazing new database';

await isar.writeAsync((isar) {
  isar.emails.put(newEmail); // insert & update
});

final existingEmail = isar.emails.get(newEmail.id!); // get

await isar.writeAsync((isar) {
  isar.emails.delete(existingEmail.id!); // delete
});
```

## Database Queries

Isar database has a powerful query language that allows you to make use of your indexes, filter distinct objects, use complex `and()`, `or()` and `.xor()` groups, query links and sort the results.

```dart
final importantEmails = isar.emails
  .where()
  .titleStartsWith('Important') // use index
  .limit(10)
  .findAll()

final specificEmails = isar.emails
  .filter()
  .recipient((q) => q.nameEqualTo('David')) // query embedded objects
  .or()
  .titleMatches('*university*', caseSensitive: false) // title containing 'university' (case insensitive)
  .findAll()
```

## Database Watchers

With Isar database, you can watch collections, objects, or queries. A watcher is notified after a transaction commits successfully and the target changes.
Watchers can be lazy and not reload the data or they can be non-lazy and fetch new results in the background.

```dart
Stream<void> collectionStream = isar.emails.watchLazy();

Stream<List<Post>> queryStream = importantEmails.watch();

queryStream.listen((newResult) {
  // do UI updates
})
```

## Benchmarks

Benchmarks only give a rough idea of the performance of a database but as you can see, Isar NoSQL database is quite fast 😇

| <img src="https://raw.githubusercontent.com/ahmtydn/isar_plus/main/.github/assets/benchmarks/insert.png" width="100%" /> | <img src="https://raw.githubusercontent.com/ahmtydn/isar_plus/main/.github/assets/benchmarks/query.png" width="100%" /> |
| ---------------------------------------------------------------------------------------------------------------- | --------------------------------------------------------------------------------------------------------------- |
| <img src="https://raw.githubusercontent.com/ahmtydn/isar_plus/main/.github/assets/benchmarks/update.png" width="100%" /> | <img src="https://raw.githubusercontent.com/ahmtydn/isar_plus/main/.github/assets/benchmarks/size.png" width="100%" />  |

If you are interested in more benchmarks or want to check how Isar performs on your device you can run the [benchmarks](https://github.com/isar/isar_benchmark) yourself.

## Unit tests

If you want to use Isar database in unit tests or Dart code, call `await Isar.initializeIsarCore(download: true)` before using Isar in your tests.

Isar NoSQL database will automatically download the correct binary for your platform. You can also pass a `libraries` map to adjust the download location for each platform.

Make sure to use `flutter test -j 1` to avoid tests running in parallel. This would break the automatic download.

## Contributors ✨

### Isar Plus Contributors

Thanks to everyone contributing to Isar Plus:

- [Ahmet Aydın](https://github.com/ahmtydn) - Project maintainer and lead developer


<!-- markdownlint-restore -->
<!-- prettier-ignore-end -->

<!-- ALL-CONTRIBUTORS-LIST:END -->

For a complete list of original Isar contributors, please visit the [original repository](https://github.com/isar/isar/graphs/contributors).
