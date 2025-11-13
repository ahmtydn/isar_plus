---
title: Migrer depuis Isar v3
---

# Migrer d'Isar v3 vers Isar Plus v4

La mise à jour des paquets hérités `isar` 3.x vers `isar_plus` (v4) est un **changement incompatible du format de fichier**. Le cœur v4 écrit des métadonnées différentes et ne peut pas ouvrir une base créée avec v3 ; vous verrez donc des erreurs comme :

```
VersionError: The database version is not compatible with this version of Isar.
```

La solution est d'exporter vos données avec l'ancien runtime puis de les importer dans une nouvelle base Isar Plus. Les étapes ci-dessous détaillent la procédure.

## Vue d'ensemble de la migration

1. Publiez (ou conservez) une build qui dépend encore de `isar:^3.1.0+1` afin de lire les fichiers hérités.
2. Ajoutez `isar_plus` et `isar_plus_flutter_libs` à côté des anciens paquets pendant la migration.
3. Relancez le générateur de code pour compiler vos schémas contre les API v4.
4. Copiez chaque enregistrement de l'instance v3 vers une nouvelle instance Isar Plus.
5. Supprimez les fichiers hérités et retirez les vieilles dépendances une fois la copie terminée.

Si vous **n'avez pas** besoin des anciennes données, supprimez simplement le répertoire v3 et démarrez avec une base vide. Le reste de ce guide se concentre sur la conservation des enregistrements existants.

## Mettre à jour les dépendances en parallèle

Gardez l'ancien runtime jusqu'à la fin de la copie, puis ajoutez le nouveau :

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

Les deux paquets exposent les mêmes symboles Dart, importez-les donc toujours avec des alias pendant la migration :

```dart
import 'package:isar/isar.dart' as legacy;
import 'package:isar_plus/isar_plus.dart' as plus;
```

## Régénérer vos schémas pour v4

Isar Plus embarque son générateur dans le paquet principal. Relancez le builder pour produire les nouveaux helpers et adaptateurs :

```bash
dart run build_runner build --delete-conflicting-outputs
```

Faites une pause ici et corrigez toute erreur de compilation (par exemple, les champs `Id?` doivent devenir des `int id` ou utiliser `Isar.autoIncrement`). Le [guide de migration d'API](https://github.com/ahmtydn/isar_plus/blob/main/packages/isar_plus/README.md#api-migration-guide) récapitule les changements majeurs :

- `writeTxn()` -> `writeAsync()` et `writeTxnSync()` -> `write()`
- `txn()` -> `readAsync()` et `txnSync()` -> `read()`
- Les ID doivent s'appeler `id` ou être annotés avec `@id`; l'auto-incrément passe par `Isar.autoIncrement`
- `@enumerated` devient `@enumValue`
- Les objets embarqués remplacent la plupart des anciens liens

## Copier les données

Créez une routine de migration ponctuelle (par exemple dans `main()` avant l'initialisation de l'app ou dans un `bin/migrate.dart`). Le schéma général est le suivant :

1. Ouvrir le magasin hérité avec le runtime v3.
2. Ouvrir une nouvelle instance v4 dans un autre dossier ou sous un autre nom.
3. Parcourir chaque collection par pages, la mapper vers le nouveau schéma et faire `put` dans la nouvelle base.
4. Marquer la migration comme terminée (SharedPreferences, fichier local ou feature flag) pour éviter une deuxième exécution.

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
    engine: plus.IsarEngine.sqlite, // ou IsarEngine.isar pour le core natif
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

> Astuce : Gardez les fonctions de mapping (comme `_mapStatus`) à côté de la routine afin de gérer renommages d'enums, suppressions de champs ou nettoyage de données au même endroit.

Si vous avez des collections très volumineuses, exécutez la boucle dans un isolate ou un service en arrière-plan pour ne pas bloquer l'UI. Le même schéma s'applique aux objets embarqués et aux liens : chargez-les avec l'API héritée puis persistez-les via le nouveau schéma.

## S'assurer qu'elle ne s'exécute qu'une fois en production

Tant que vous livrez les deux runtimes, chaque démarrage à froid risque de relancer la migration, sauf si vous la protégez par un indicateur. Persistez une version de migration pour que la copie ne s'exécute qu'une fois par installation :

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

Plutôt qu'un booléen, vous pouvez stocker une version numérique du schéma (par exemple `3` pour l'ancien et `4` pour Isar Plus) si vous anticipez d'autres migrations. Sur desktop ou serveur, un simple fichier `.migrated` placé à côté du dossier de base fonctionne aussi.

## Nettoyage

Après avoir copié toutes les collections :

1. Persistez un indicateur (par exemple `prefs.setBool('migratedToIsarPlus', true)`) pour empêcher une nouvelle exécution.
2. Supprimez les fichiers hérités (manuellement ou via `plus.Isar.deleteDatabase(name: 'legacy', directory: directoryPath, engine: plus.IsarEngine.isar)`).
3. Retirez `isar` et `isar_flutter_libs` de `pubspec.yaml`.
4. Renommez la nouvelle base vers le nom ou dossier d'origine si nécessaire.

N'expédiez une version dépendant uniquement de `isar_plus` que lorsque vous êtes sûr que les utilisateurs n'ouvriront plus la build héritée.

## Dépannage

- **`VersionError` persiste** : vérifiez que vous avez supprimé les fichiers v3 avant d'ouvrir l'instance v4. D'anciens fichiers WAL/LCK peuvent conserver l'en-tête hérité.
- **Doublons de clés primaires** : en v4 les ID doivent être des entiers uniques et non nuls. Utilisez `Isar.autoIncrement` ou générez vos propres clés lors de la copie.
- **Le générateur échoue** : exécutez `dart pub clean` avant `build_runner` et assurez-vous que toutes les directives `part '...g.dart';` sont présentes.
- **Besoin de revenir en arrière** : comme la migration écrit dans une base distincte, vous pouvez jeter les nouveaux fichiers et conserver ceux de v3 tant que la copie n'est pas validée.

Une fois ces étapes en place, vos utilisateurs peuvent passer directement d'une build `isar` 3.x à une version `isar_plus` sans perte de données.
