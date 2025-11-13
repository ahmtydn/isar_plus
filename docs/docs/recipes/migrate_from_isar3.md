---
title: Migrate from Isar v3
---

# Migrate from Isar v3 to Isar Plus v4

Upgrading from the legacy `isar` 3.x packages to `isar_plus` (v4) is a **breaking, file-format change**. The v4 core writes different metadata and cannot open a database that was written by v3, so you see errors such as:

```
VersionError: The database version is not compatible with this version of Isar.
```

The fix is to export your existing data with the legacy runtime and import it into a fresh Isar Plus database. The steps below walk you through the process.

## Migration overview

1. Ship (or keep) a build that still depends on `isar:^3.1.0+1` so you can read the legacy files.
2. Add `isar_plus` and `isar_plus_flutter_libs` next to the legacy packages while you migrate.
3. Re-run the code generator so your schemas compile against the v4 APIs.
4. Copy every record from the v3 instance into a brand-new Isar Plus instance.
5. Delete the legacy files and remove the old dependencies once the copy succeeds.

If you do **not** need the old data, you can simply delete the v3 directory and start with a fresh database. The remainder of this guide focuses on preserving existing records.

## Update dependencies side by side

Keep the old runtime until the copy finishes, then add the new one:

```yaml
dependencies:

  isar: ^3.1.0+1
  isar_flutter_libs: ^3.1.0+1
  isar_generator: ^3.1.0+1
  isar_plus: ^1.1.5
  isar_plus_flutter_libs: ^1.1.5

dev_dependencies:
  build_runner: ^2.4.10
```

The two packages expose the same Dart symbols, so always import them with aliases during migration:

```dart
import 'package:isar/isar.dart' as legacy;
import 'package:isar_plus/isar_plus.dart' as plus;
```

## Regenerate your schemas for v4

Isar Plus ships its generator inside the main package. Re-run the builder so it emits the new helpers and adapters:

```bash
dart run build_runner build --delete-conflicting-outputs
```

Pause here and address any compilation errors (for example, nullable `Id?` fields must become non-nullable `int id` or use `Isar.autoIncrement`). The [API Migration Guide](https://github.com/ahmtydn/isar_plus/blob/main/packages/isar_plus/README.md#api-migration-guide) summarizes the key code changes:

- `writeTxn()` -> `writeAsync()` and `writeTxnSync()` -> `write()`
- `txn()` -> `readAsync()` and `txnSync()` -> `read()`
- IDs must be named `id` or annotated with `@id`, and auto-increment now uses `Isar.autoIncrement`
- `@enumerated` became `@enumValue`
- Embedded objects replace most legacy links

## Copy the actual data

Create a one-off migration routine (for example in `main()` before initializing your app, or in a separate `bin/migrate.dart`). The pattern is:

1. Open the legacy store with the v3 runtime.
2. Open a new v4 instance in a different directory or under a different name.
3. Page through each collection, map it to the new schema, and `put` it into the new database.
4. Mark the migration as finished (SharedPreferences, a local file, or a feature flag) so you do not run it twice.

```dart
Future<void> migrateLegacyDb(String directoryPath) async {
  final legacyDb = await legacy.Isar.open(
    [LegacyUserSchema, LegacyTodoSchema],
    directory: directoryPath,
    inspector: false,
    name: 'legacy',
  );

  final plusDb = await plus.Isar.open(
    [UserSchema, TodoSchema],
    directory: directoryPath,
    name: 'app_v4',
    engine: plus.IsarEngine.sqlite, // or IsarEngine.isar for the native core
    inspector: false,
  );

  await _copyUsers(legacyDb, plusDb);
  await _copyTodos(legacyDb, plusDb);

  await legacyDb.close();
  await plusDb.close();
}

Future<void> _copyUsers(legacy.Isar legacyDb, plus.Isar plusDb) async {
  const pageSize = 200;
  final total = await legacyDb.legacyUsers.count();

  for (var offset = 0; offset < total; offset += pageSize) {
    final batch = await legacyDb.legacyUsers.where().offset(offset).limit(pageSize).findAll();
    await plusDb.writeAsync((isar) async {
      await isar.users.putAll(
        batch.map((user) => User(
              id: user.id ?? plus.Isar.autoIncrement,
              email: user.email,
              status: _mapStatus(user.status),
            )),
      );
    });
  }
}
```

> Tip: Keep the mapping methods (`_mapStatus` in the snippet) next to the migration routine so you can handle enum renames, field removals, or any data cleanup in one place.

If you have very large collections, run the loop inside an isolate or background service to avoid blocking the UI. The same pattern works for embedded objects and links—load them with the legacy query API, then persist them with the new schema.

## Make sure it only runs once in production

Shipping both runtimes means every cold start could try to migrate again unless you gate it behind a flag. Persist a migration version so the copy runs only once per installation:

```dart
class MigrationTracker {
  static const key = 'isarPlusMigration';

  static Future<bool> needsMigration() async {
    final prefs = await SharedPreferences.getInstance();
    return !prefs.getBool(key).toString().contains('true');
  }

  static Future<void> markDone() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, true);
  }
}

Future<void> bootstrapIsar(String dir) async {
  if (await MigrationTracker.needsMigration()) {
    await migrateLegacyDb(dir);
    await MigrationTracker.markDone();
  }

  final isar = await plus.Isar.open(
    [UserSchema, TodoSchema],
    directory: dir,
  );

  runApp(MyApp(isar: isar));
}
```

Instead of a boolean you can store a numeric schema version (for example `3` for legacy, `4` for Isar Plus) if you anticipate future migrations. On desktop or server builds you can also write a tiny `.migrated` file next to the database directory instead of using shared preferences.

## Clean up

After every collection finishes copying:

1. Persist a flag (for example `prefs.setBool('migratedToIsarPlus', true)`) so the migration does not run again.
2. Delete the legacy files (either manually or with `plus.Isar.deleteDatabase(name: 'legacy', directory: directoryPath, engine: plus.IsarEngine.isar)`).
3. Remove the `isar` and `isar_flutter_libs` dependencies from `pubspec.yaml`.
4. Rename the new database back to your original name or directory if needed.

Only when you are confident that users no longer open the legacy build should you ship an update that depends solely on `isar_plus`.

## Troubleshooting

- **`VersionError` persists**: Double-check that you deleted the v3 files before opening the v4 instance. Old WAL/LCK files can keep the legacy header around.
- **Duplicate primary keys**: Remember that v4 IDs must be unique, non-null integers. Use `Isar.autoIncrement` or generate your own deterministic keys while copying.
- **Generator fails**: Run `dart pub clean` before `build_runner`, and ensure no `part '...g.dart';` directives are missing.
- **Need to rollback**: Because the migration writes into a separate database, you can safely discard the new files and keep the legacy ones until the copy completes.

Once these steps are in place, users can upgrade directly from an `isar` 3.x build to an `isar_plus` release without data loss.
