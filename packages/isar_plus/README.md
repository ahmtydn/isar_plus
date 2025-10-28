<p align="center">
  <a href="https://github.com/ahmtydn/isar">
    <img src="https://raw.githubusercontent.com/ahmtydn/isar_plus/main/.github/assets/isar.svg?sanitize=true" height="128">
  </a>
  <h1 align="center">Isar Plus Database</h1>
</p>

<!-- Version 1.0.3 - Test release for PR-based release notes -->

<p align="center">
  <a href="https://pub.dev/packages/isar_plus">
    <img src="https://img.shields.io/pub/v/isar_plus?label=pub.dev&labelColor=333940&logo=dart">
  </a>
  <a href="https://github.com/ahmtydn/isar_plus/actions/workflows/test.yaml">
    <img src="https://img.shields.io/github/actions/workflow/status/ahmtydn/isar_plus/test.yaml?branch=isar4&label=tests&labelColor=333940&logo=github">
  </a>
  <a href="https://github.com/ahmtydn/isar_plus">
    <img src="https://img.shields.io/github/stars/ahmtydn/isar_plus?style=social">
  </a>
</p>

> #### Isar Plus [ee-zahr plus]:
>
> Enhanced version of the Isar database with additional features and improvements.

⚠️ ISAR PLUS V4 IS NOT READY FOR PRODUCTION USE ⚠️  
If you want to use Isar Plus in production, please use the stable Isar version 3.

## About Isar Plus

Isar Plus is an enhanced fork of the original Isar database, providing additional features and improvements while maintaining full compatibility with the original API.

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

Big thanks go to these wonderful people:

<!-- ALL-CONTRIBUTORS-LIST:START - Do not remove or modify this section -->
<!-- prettier-ignore-start -->
<!-- markdownlint-disable -->
<table>
  <tbody>
    <tr>
      <td align="center" valign="top" width="14.28%"><a href="https://github.com/AlexisL61"><img src="https://avatars.githubusercontent.com/u/30233189?v=4" width="100px;" alt=""/><br /><sub><b>Alexis</b></sub></a></td>
      <td align="center" valign="top" width="14.28%"><a href="https://github.com/buraktabn"><img src="https://avatars.githubusercontent.com/u/49204989?v=4" width="100px;" alt=""/><br /><sub><b>Burak</b></sub></a></td>
      <td align="center" valign="top" width="14.28%"><a href="https://github.com/CarloDotLog"><img src="https://avatars.githubusercontent.com/u/13763473?v=4" width="100px;" alt=""/><br /><sub><b>Carlo Loguercio</b></sub></a></td>
      <td align="center" valign="top" width="14.28%"><a href="https://github.com/Frostedfox"><img src="https://avatars.githubusercontent.com/u/84601232?v=4" width="100px;" alt=""/><br /><sub><b>Frostedfox</b></sub></a></td>
      <td align="center" valign="top" width="14.28%"><a href="https://github.com/hafeezrana"><img src="https://avatars.githubusercontent.com/u/87476445?v=4" width="100px;" alt=""/><br /><sub><b>Hafeez Rana</b></sub></a></td>
      <td align="center" valign="top" width="14.28%"><a href="https://github.com/h1376h"><img src="https://avatars.githubusercontent.com/u/3498335?v=4" width="100px;" alt=""/><br /><sub><b>Hamed H.</b></sub></a></td>
      <td align="center" valign="top" width="14.28%"><a href="https://github.com/Jtplouffe"><img src="https://avatars.githubusercontent.com/u/32107801?v=4" width="100px;" alt=""/><br /><sub><b>JT</b></sub></a></td>
    </tr>
    <tr>
      <td align="center" valign="top" width="14.28%"><a href="https://github.com/ritksm"><img src="https://avatars.githubusercontent.com/u/111809?v=4" width="100px;" alt=""/><br /><sub><b>Jack Rivers</b></sub></a></td>
      <td align="center" valign="top" width="14.28%"><a href="https://github.com/nohli"><img src="https://avatars.githubusercontent.com/u/43643339?v=4" width="100px;" alt=""/><br /><sub><b>Joachim Nohl</b></sub></a></td>
      <td align="center" valign="top" width="14.28%"><a href="https://github.com/vothvovo"><img src="https://avatars.githubusercontent.com/u/20894472?v=4" width="100px;" alt=""/><br /><sub><b>Johnson</b></sub></a></td>
      <td align="center" valign="top" width="14.28%"><a href="https://github.com/VoidxHoshi"><img src="https://avatars.githubusercontent.com/u/55886143?v=4" width="100px;" alt=""/><br /><sub><b>LaLucid</b></sub></a></td>
      <td align="center" valign="top" width="14.28%"><a href="https://github.com/letyletylety"><img src="https://avatars.githubusercontent.com/u/16468579?v=4" width="100px;" alt=""/><br /><sub><b>Lety</b></sub></a></td>
      <td align="center" valign="top" width="14.28%"><a href="https://github.com/lodisy"><img src="https://avatars.githubusercontent.com/u/8101584?v=4" width="100px;" alt=""/><br /><sub><b>Michael</b></sub></a></td>
      <td align="center" valign="top" width="14.28%"><a href="https://github.com/Moseco"><img src="https://avatars.githubusercontent.com/u/10720298?v=4" width="100px;" alt=""/><br /><sub><b>Moseco</b></sub></a></td>
    </tr>
    <tr>
      <td align="center" valign="top" width="14.28%"><a href="https://github.com/inkomomutane"><img src="https://avatars.githubusercontent.com/u/57417802?v=4" width="100px;" alt=""/><br /><sub><b>Nelson  Mutane</b></sub></a></td>
      <td align="center" valign="top" width="14.28%"><a href="https://github.com/oscarpalomar"><img src="https://avatars.githubusercontent.com/u/13899772?v=4" width="100px;" alt=""/><br /><sub><b>Oscar Palomar</b></sub></a></td>
      <td align="center" valign="top" width="14.28%"><a href="https://github.com/Viper-Bit"><img src="https://avatars.githubusercontent.com/u/24822764?v=4" width="100px;" alt=""/><br /><sub><b>Peyman</b></sub></a></td>
      <td align="center" valign="top" width="14.28%"><a href="https://github.com/leisim"><img src="https://avatars.githubusercontent.com/u/13610195?v=4" width="100px;" alt=""/><br /><sub><b>Simon Choi</b></sub></a></td>
      <td align="center" valign="top" width="14.28%"><a href="https://github.com/ika020202"><img src="https://avatars.githubusercontent.com/u/42883378?v=4" width="100px;" alt=""/><br /><sub><b>Ura</b></sub></a></td>
      <td align="center" valign="top" width="14.28%"><a href="https://github.com/blendthink"><img src="https://avatars.githubusercontent.com/u/32213113?v=4" width="100px;" alt=""/><br /><sub><b>blendthink</b></sub></a></td>
      <td align="center" valign="top" width="14.28%"><a href="https://github.com/mnkeis"><img src="https://avatars.githubusercontent.com/u/41247357?v=4" width="100px;" alt=""/><br /><sub><b>mnkeis</b></sub></a></td>
    </tr>
    <tr>
      <td align="center" valign="top" width="14.28%"><a href="https://github.com/nobkd"><img src="https://avatars.githubusercontent.com/u/44443899?v=4" width="100px;" alt=""/><br /><sub><b>nobkd</b></sub></a></td>
    </tr>
  </tbody>
</table>

<!-- markdownlint-restore -->
<!-- prettier-ignore-end -->

<!-- ALL-CONTRIBUTORS-LIST:END -->
