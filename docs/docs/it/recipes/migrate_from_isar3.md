---
title: Migrare da Isar v3
---

# Da Isar v3 a Isar Plus v4

L'aggiornamento dai pacchetti legacy `isar` 3.x a `isar_plus` (v4) è una **modifica incompatibile del formato dei file**. Il core di v4 scrive metadati diversi e non può aprire un database creato con v3, quindi compaiono errori come:

```
VersionError: The database version is not compatible with this version of Isar.
```

La soluzione è esportare i dati esistenti con il runtime legacy e importarli in un nuovo database Isar Plus. I passaggi seguenti ti guidano lungo il processo.

## Panoramica della migrazione

1. Distribuisci (o mantieni) una build che dipenda ancora da `isar:^3.1.0+1` per poter leggere i file legacy.
2. Aggiungi `isar_plus` e `isar_plus_flutter_libs` accanto ai pacchetti legacy durante la migrazione.
3. Riesegui il generatore di codice affinché gli schemi compilino contro le API v4.
4. Copia ogni record dall'istanza v3 in una nuova istanza Isar Plus.
5. Elimina i file legacy e rimuovi le vecchie dipendenze una volta completata la copia.

Se **non** ti servono i vecchi dati, puoi semplicemente cancellare la cartella v3 e partire da un database vuoto. Il resto della guida si concentra sulla conservazione dei record.

## Aggiorna le dipendenze in parallelo

Mantieni il runtime legacy finché la copia non termina, poi aggiungi quello nuovo:

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

I due pacchetti espongono gli stessi simboli Dart, quindi importali sempre con alias durante la migrazione:

```dart
import 'package:isar/isar.dart' as legacy;
import 'package:isar_plus/isar_plus.dart' as plus;
```

## Rigenera gli schemi per v4

Isar Plus include il proprio generatore all'interno del package principale. Riesegui il builder così da ottenere i nuovi helper e adattatori:

```bash
dart run build_runner build --delete-conflicting-outputs
```

Fermati qui e risolvi gli eventuali errori di compilazione (ad esempio i campi `Id?` devono diventare `int id` oppure usare `Isar.autoIncrement`). La [guida di migrazione delle API](https://github.com/ahmtydn/isar_plus/blob/main/packages/isar_plus/README.md#api-migration-guide) riassume i cambiamenti fondamentali:

- `writeTxn()` -> `writeAsync()` e `writeTxnSync()` -> `write()`
- `txn()` -> `readAsync()` e `txnSync()` -> `read()`
- Gli ID devono chiamarsi `id` o avere `@id`; l'auto-incremento ora usa `Isar.autoIncrement`
- `@enumerated` è diventato `@enumValue`
- Gli oggetti annidati sostituiscono la maggior parte dei vecchi link

## Copiare i dati

Crea una routine di migrazione una tantum (per esempio in `main()` prima di inizializzare l'app o in un `bin/migrate.dart`). Il modello è questo:

1. Apri l'archivio legacy con il runtime v3.
2. Apri una nuova istanza v4 in una cartella diversa o con un nome diverso.
3. Scorri ogni collezione a pagine, adattala al nuovo schema ed esegui `put` nel nuovo database.
4. Segna la migrazione come completata (SharedPreferences, file locale o feature flag) per non eseguirla due volte.

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
    engine: plus.IsarEngine.sqlite, // o IsarEngine.isar per il core nativo
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

> Suggerimento: tieni le funzioni di mapping (come `_mapStatus`) accanto alla routine così puoi gestire rinomini di enum, campi rimossi o pulizia dati in un unico punto.

Se hai collezioni molto grandi, esegui il ciclo in un isolate o servizio in background per non bloccare la UI. Lo stesso schema vale per oggetti incorporati e link: caricali con l'API legacy e salvali con il nuovo schema.

## Fallo girare una sola volta in produzione

Quando distribuisci entrambi i runtime, ogni avvio a freddo potrebbe tentare di migrare di nuovo se non lo limiti con un flag. Conserva una versione di migrazione per eseguire la copia una sola volta per installazione:

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

Al posto di un booleano puoi salvare una versione numerica dello schema (ad esempio `3` per il legacy e `4` per Isar Plus) se prevedi migrazioni future. Su desktop o server puoi anche scrivere un piccolo file `.migrated` accanto alla cartella del database.

## Pulizia finale

Dopo aver copiato tutte le collezioni:

1. Memorizza un flag (per esempio `prefs.setBool('migratedToIsarPlus', true)`) per evitare esecuzioni successive.
2. Elimina i file legacy (manualmente o con `plus.Isar.deleteDatabase(name: 'legacy', directory: directoryPath, engine: plus.IsarEngine.isar)`).
3. Rimuovi `isar` e `isar_flutter_libs` dalla `pubspec.yaml`.
4. Rinomina il nuovo database con il nome/directory originale se necessario.

Pubblica una release che dipende solo da `isar_plus` solo quando sei certo che gli utenti non aprano più la build legacy.

## Risoluzione dei problemi

- **`VersionError` continua ad apparire**: assicurati di eliminare i file v3 prima di aprire l'istanza v4. I vecchi file WAL/LCK possono mantenere l'intestazione legacy.
- **Chiavi primarie duplicate**: in v4 gli ID devono essere interi univoci e non nulli. Usa `Isar.autoIncrement` o genera chiavi personalizzate durante la copia.
- **Il generatore fallisce**: esegui `dart pub clean` prima di `build_runner` e controlla che non manchino direttive `part '...g.dart';`.
- **Serve un rollback**: poiché la migrazione scrive in un database separato, puoi eliminare i nuovi file e conservare quelli legacy finché la copia non riesce.

Seguendo questi passaggi, gli utenti possono passare direttamente da una build `isar` 3.x a una release `isar_plus` senza perdita di dati.
