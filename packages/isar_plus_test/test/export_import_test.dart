@TestOn('vm')
library;

import 'dart:io';

import 'package:isar_plus/isar_plus.dart';
import 'package:isar_plus_test/isar_plus_test.dart';
import 'package:path/path.dart' as path;
import 'package:test/test.dart';

part 'export_import_test.g.dart';

@collection
class User {
  User({required this.id, required this.name, required this.email});

  final int id;
  final String name;
  final String email;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is User &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          name == other.name &&
          email == other.email;
}

void main() {
  group('Database Export/Import', () {
    late Isar isar;
    late List<User> testUsers;

    setUp(() async {
      isar = await openTempIsar([UserSchema], maxSizeMiB: isSQLite ? 0 : 20);

      testUsers = [
        User(id: 1, name: 'Alice', email: 'alice@example.com'),
        User(id: 2, name: 'Bob', email: 'bob@example.com'),
        User(id: 3, name: 'Charlie', email: 'charlie@example.com'),
        User(id: 4, name: 'Diana', email: 'diana@example.com'),
        User(id: 5, name: 'Eve', email: 'eve@example.com'),
      ];

      isar.write((isar) => isar.users.putAll(testUsers));
    });

    isarTest('Export: .copyToFile() should create backup file', () async {
      final backupPath = path.join(isar.directory, 'backup_test.isar');
      final backupFile = File(backupPath);

      if (backupFile.existsSync()) {
        backupFile.deleteSync();
      }

      expect(backupFile.existsSync(), false);

      isar.copyToFile(backupPath);

      expect(backupFile.existsSync(), true);
      expect(backupFile.lengthSync(), greaterThan(0));

      await backupFile.delete();
    });

    isarTest('Export: .copyToFile() should preserve all data', () async {
      final backupName = getRandomName();
      final backupPath = path.join(
        isar.directory,
        isSQLite ? '$backupName.sqlite' : '$backupName.isar',
      );

      isar.copyToFile(backupPath);

      final exportedIsar = await openTempIsar(
        [UserSchema],
        directory: isar.directory,
        name: backupName,
        maxSizeMiB: 20,
      );

      final exportedUsers = exportedIsar.users.where().findAll();
      expect(exportedUsers.length, testUsers.length);

      for (var i = 0; i < testUsers.length; i++) {
        expect(exportedUsers[i], testUsers[i]);
      }

      exportedIsar.close();
    });

    isarTest('Import: Restore database from backup file', () async {
      final backupName = getRandomName();
      final backupPath = path.join(
        isar.directory,
        isSQLite ? '$backupName.sqlite' : '$backupName.isar',
      );

      isar.copyToFile(backupPath);

      isar.write((isar) {
        isar.users.where().deleteAll();
        isar.users.put(User(id: 999, name: 'Test', email: 'test@example.com'));
      });

      expect(isar.users.count(), 1);
      expect(isar.users.get(999)?.name, 'Test');

      final originalName = isar.name;
      final originalDir = isar.directory;
      isar.close();

      final backupFile = File(backupPath);
      final originalPath = path.join(
        originalDir,
        isSQLite ? '$originalName.sqlite' : '$originalName.isar',
      );
      await backupFile.copy(originalPath);

      final restoredIsar = await openTempIsar(
        [UserSchema],
        directory: originalDir,
        name: originalName,
        maxSizeMiB: 20,
      );

      final restoredUsers = restoredIsar.users.where().findAll();
      expect(restoredUsers.length, testUsers.length);

      for (var i = 0; i < testUsers.length; i++) {
        expect(restoredUsers[i], testUsers[i]);
      }

      expect(restoredIsar.users.get(999), null);

      restoredIsar.close();
      await backupFile.delete();
    });

    isarTest(
      'Export: .copyToFile() creates valid backup after fragmentation',
      () async {
        isar.write((isar) {
          final largeUsers = List.generate(
            100,
            (i) => User(
              id: i + 100,
              name: 'User $i' * 100,
              email: 'user$i@example.com' * 100,
            ),
          );
          isar.users.putAll(largeUsers);
        });

        isar.write(
          (isar) => isar.users.where().idBetween(100, 149).deleteAll(),
        );

        final backupName = getRandomName();
        final backupPath = path.join(
          isar.directory,
          isSQLite ? '$backupName.sqlite' : '$backupName.isar',
        );

        isar.copyToFile(backupPath);

        final backupFile = File(backupPath);

        expect(backupFile.existsSync(), true);
        expect(backupFile.lengthSync(), greaterThan(0));

        final backupIsar = await openTempIsar(
          [UserSchema],
          directory: isar.directory,
          name: backupName,
          maxSizeMiB: 20,
        );

        expect(backupIsar.users.count(), 55);

        for (var i = 0; i < testUsers.length; i++) {
          final user = backupIsar.users.get(testUsers[i].id);
          expect(user, isNotNull);
          expect(user, testUsers[i]);
        }

        for (var i = 100; i < 150; i++) {
          expect(backupIsar.users.get(i), null);
        }

        for (var i = 150; i < 200; i++) {
          final user = backupIsar.users.get(i);
          expect(user, isNotNull);
          expect(user!.id, i);
        }

        backupIsar.close();
        await backupFile.delete();
      },
    );

    isarTest('Export/Import: Multiple backup and restore cycles', () async {
      final backup1Name = getRandomName();
      final backup1Path = path.join(
        isar.directory,
        isSQLite ? '$backup1Name.sqlite' : '$backup1Name.isar',
      );

      isar.copyToFile(backup1Path);

      isar.write((isar) {
        isar.users.put(User(id: 10, name: 'Frank', email: 'frank@example.com'));
      });

      final backup2Name = getRandomName();
      final backup2Path = path.join(
        isar.directory,
        isSQLite ? '$backup2Name.sqlite' : '$backup2Name.isar',
      );

      isar.copyToFile(backup2Path);

      final backup1Isar = await openTempIsar(
        [UserSchema],
        directory: isar.directory,
        name: backup1Name,
        maxSizeMiB: 20,
      );
      expect(backup1Isar.users.count(), 5);
      backup1Isar.close();

      final backup2Isar = await openTempIsar(
        [UserSchema],
        directory: isar.directory,
        name: backup2Name,
        maxSizeMiB: 20,
      );
      expect(backup2Isar.users.count(), 6);
      expect(backup2Isar.users.get(10)?.name, 'Frank');
      backup2Isar.close();

      await File(backup1Path).delete();
      await File(backup2Path).delete();
    });

    isarTest('Export: .copyToFile() with empty database', () async {
      final emptyIsar = await openTempIsar([
        UserSchema,
      ], maxSizeMiB: isSQLite ? 0 : 20);

      final backupName = getRandomName();
      final backupPath = path.join(
        emptyIsar.directory,
        isSQLite ? '$backupName.sqlite' : '$backupName.isar',
      );

      emptyIsar.copyToFile(backupPath);

      final backupFile = File(backupPath);
      expect(backupFile.existsSync(), true);
      expect(backupFile.lengthSync(), greaterThan(0));

      final backupIsar = await openTempIsar(
        [UserSchema],
        directory: emptyIsar.directory,
        name: backupName,
        maxSizeMiB: 20,
      );

      expect(backupIsar.users.count(), 0);

      backupIsar.close();
      emptyIsar.close();
      await backupFile.delete();
    });

    isarTest('Export: Consecutive exports should have same size', () async {
      final backup1Name = getRandomName();
      final backup1Path = path.join(
        isar.directory,
        isSQLite ? '$backup1Name.sqlite' : '$backup1Name.isar',
      );

      final backup2Name = getRandomName();
      final backup2Path = path.join(
        isar.directory,
        isSQLite ? '$backup2Name.sqlite' : '$backup2Name.isar',
      );

      isar.copyToFile(backup1Path);
      isar.copyToFile(backup2Path);

      final backup1Size = File(backup1Path).lengthSync();
      final backup2Size = File(backup2Path).lengthSync();

      expect(backup1Size, backup2Size);

      await File(backup1Path).delete();
      await File(backup2Path).delete();
    });
  });
}
