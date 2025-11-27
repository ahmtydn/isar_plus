@TestOn('vm')
library;

import 'dart:io';

import 'package:isar_plus/isar_plus.dart';
import 'package:isar_plus_test/isar_plus_test.dart';
import 'package:path/path.dart' as path;
import 'package:test/test.dart';

part 'delete_database_test.g.dart';

@collection
class Model {
  Model(this.id);

  final int id;
}

void main() {
  group('Delete database', () {
    isarTest('should delete the database file', () async {
      final isar = await openTempIsar([ModelSchema]);
      final name = isar.name;
      final directory = isar.directory;

      final dbFile = File(
        path.join(
          directory,
          isSQLite ? '$name.sqlite' : '$name.isar',
        ),
      );
      final lockFile = File(path.join(directory, '$name.lock'));

      expect(dbFile.existsSync(), true);
      expect(isar.close(), true);
      Isar.deleteDatabase(
        name: name,
        directory: directory,
        engine: isSQLite ? IsarEngine.sqlite : IsarEngine.isar,
      );

      expect(dbFile.existsSync(), false);
      expect(lockFile.existsSync(), false);
    });

    isarTest('should throw if database is open', () async {
      final isar = await openTempIsar([ModelSchema]);
      final name = isar.name;
      final directory = isar.directory;
      try {
         Isar.deleteDatabase(
          name: name,
          directory: directory,
          engine: isSQLite ? IsarEngine.sqlite : IsarEngine.isar,
        );
      } catch (e) {
        expect(e, isA<IsarError>());
        await isar.close();
        return;
      }
      await isar.close();
    });
  });
}
