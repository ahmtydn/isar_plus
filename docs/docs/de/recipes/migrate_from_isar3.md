---
title: Migration von Isar v3
---

# Von Isar v3 zu Isar Plus v4 migrieren

Das Upgrade von den Legacy-Paketen `isar` 3.x auf `isar_plus` (v4) ist eine **inkompatible Änderung des Dateiformats**. Der v4-Core schreibt andere Metadaten und kann deshalb keine Datenbanken öffnen, die von v3 erzeugt wurden. Andernfalls siehst du Fehler wie:

```
VersionError: The database version is not compatible with this version of Isar.
```

Die Lösung besteht darin, deine vorhandenen Daten mit der alten Laufzeit zu exportieren und in eine frische Isar-Plus-Datenbank zu importieren. Die folgenden Schritte führen dich durch den Ablauf.

## Überblick über die Migration

1. Veröffentliche (oder behalte) einen Build, der weiterhin von `isar:^3.1.0+1` abhängt, damit du die Legacy-Dateien lesen kannst.
2. Füge `isar_plus` und `isar_plus_flutter_libs` zusätzlich zu den alten Paketen hinzu, solange die Migration läuft.
3. Starte den Codegenerator neu, damit deine Schemas gegen die v4-APIs gebaut werden.
4. Kopiere jeden Datensatz aus der v3-Instanz in eine brandneue Isar-Plus-Instanz.
5. Lösche die Legacy-Dateien und entferne die alten Abhängigkeiten, sobald die Kopie erfolgreich war.

Wenn du die alten Daten **nicht** benötigst, kannst du das v3-Verzeichnis löschen und mit einer leeren Datenbank starten. Der Rest dieser Anleitung konzentriert sich darauf, vorhandene Datensätze zu erhalten.

## Abhängigkeiten parallel aktualisieren

Behalte die alte Laufzeit, bis die Kopie abgeschlossen ist, und füge erst dann die neue hinzu:

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

Die beiden Pakete stellen identische Dart-Symbole bereit. Importiere sie daher während der Migration stets mit Aliasen:

```dart
import 'package:isar/isar.dart' as legacy;
import 'package:isar_plus/isar_plus.dart' as plus;
```

## Schemas für v4 neu generieren

Isar Plus liefert seinen Generator im Hauptpaket. Führe den Builder erneut aus, damit er die neuen Helfer und Adapter generiert:

```bash
dart run build_runner build --delete-conflicting-outputs
```

Halte an dieser Stelle an und behebe Kompilierfehler (zum Beispiel müssen nullable `Id?` Felder zu nicht-nullbaren `int id` werden oder `Isar.autoIncrement` verwenden). Die [API-Migrationsanleitung](https://github.com/ahmtydn/isar_plus/blob/main/packages/isar_plus/README.md#api-migration-guide) fasst die wichtigsten Codeänderungen zusammen:

- `writeTxn()` -> `writeAsync()` und `writeTxnSync()` -> `write()`
- `txn()` -> `readAsync()` und `txnSync()` -> `read()`
- IDs müssen `id` heißen oder mit `@id` annotiert sein, Auto-Increment verwendet jetzt `Isar.autoIncrement`
- `@enumerated` wurde zu `@enumValue`
- Eingebettete Objekte ersetzen die meisten Legacy-Links

## Daten kopieren

Erstelle eine einmalige Migrationsroutine (z. B. in `main()` vor dem App-Start oder in einem separaten `bin/migrate.dart`). Das Muster sieht so aus:

1. Öffne den Legacy-Store mit der v3-Laufzeit.
2. Öffne eine neue v4-Instanz in einem anderen Verzeichnis oder unter einem anderen Namen.
3. Durchlaufe jede Collection seitenweise, überführe sie ins neue Schema und speichere sie in der neuen Datenbank.
4. Markiere die Migration als abgeschlossen (SharedPreferences, Datei oder Feature Flag), damit sie nicht zweimal läuft.

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
    engine: plus.IsarEngine.sqlite, // oder IsarEngine.isar für den nativen Core
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

> Tipp: Platziere Mapping-Hilfen (wie `_mapStatus`) direkt neben der Migration, damit du Enum-Umbenennungen, Feldentfernungen oder Datenbereinigungen zentral erledigen kannst.

Wenn du sehr große Collections hast, führe die Schleife in einem Isolate oder Hintergrunddienst aus, damit die UI nicht blockiert. Das gleiche Muster funktioniert für eingebettete Objekte und Links – lade sie mit der Legacy-API und speichere sie anschließend mit dem neuen Schema.

## Migration nur einmal in Produktion ausführen

Solange beide Laufzeiten ausgeliefert werden, könnte jeder Cold Start erneut versuchen zu migrieren. Sichere den Fortschritt also mit einem Flag, damit die Kopie nur einmal pro Installation läuft:

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

Statt eines Booles kannst du auch eine numerische Schema-Version speichern (z. B. `3` für Legacy und `4` für Isar Plus), falls du zukünftige Migrationen erwartest. Auf Desktop oder Servern kannst du alternativ eine kleine `.migrated`-Datei neben dem Datenbankverzeichnis ablegen.

## Aufräumen

Nachdem alle Collections kopiert wurden:

1. Speichere ein Flag (z. B. `prefs.setBool('migratedToIsarPlus', true)`), damit die Migration nicht erneut läuft.
2. Lösche die Legacy-Dateien (manuell oder per `plus.Isar.deleteDatabase(name: 'legacy', directory: directoryPath, engine: plus.IsarEngine.isar)`).
3. Entferne die Abhängigkeiten `isar` und `isar_flutter_libs` aus der `pubspec.yaml`.
4. Benenne die neue Datenbank bei Bedarf wieder auf den ursprünglichen Namen oder das ursprüngliche Verzeichnis um.

Erst wenn du sicher bist, dass keine Nutzer mehr die Legacy-Version öffnen, solltest du ein Update veröffentlichen, das ausschließlich `isar_plus` verwendet.

## Fehlerbehebung

- **`VersionError` bleibt bestehen**: Stelle sicher, dass du die v3-Dateien gelöscht hast, bevor du die v4-Instanz öffnest. Alte WAL/LCK-Dateien können den Legacy-Header beibehalten.
- **Doppelte Primärschlüssel**: IDs in v4 müssen eindeutige, nicht-nullbare Integer sein. Verwende `Isar.autoIncrement` oder generiere während der Kopie eigene Schlüssel.
- **Generator schlägt fehl**: Führe `dart pub clean` vor `build_runner` aus und prüfe, ob alle `part '...g.dart';` Direktiven vorhanden sind.
- **Rollback nötig**: Da die Migration in eine separate Datenbank schreibt, kannst du die neuen Dateien verwerfen und die Legacy-Version behalten, bis die Kopie sauber durchläuft.

Wenn all diese Schritte erledigt sind, können Nutzer direkt von einem `isar`-3.x-Build auf eine `isar_plus`-Version upgraden, ohne Daten zu verlieren.
