import 'package:isar_plus/isar_plus.dart';
import 'package:test/test.dart';

part 'web_persistence_test.g.dart';

@collection
class PersistenceTestModel {
  int id = 0;
  late String value;
  late int timestamp;
}

void main() {
  group('Web Persistence', () {
    late Isar isar;

    setUp(() async {
      // Initialize Isar for web
      await Isar.initialize();

      // Delete any existing test database
      try {
        Isar.deleteDatabase(
          name: 'persistence_test',
          directory: '/test-databases',
          engine: IsarEngine.sqlite,
        );
      } catch (e) {
        // Ignore if database doesn't exist
      }

      // Open a new database
      isar = await Isar.openAsync(
        name: 'persistence_test',
        directory: '/test-databases',
        schemas: [PersistenceTestModelSchema],
        engine: IsarEngine.sqlite,
      );
    });

    tearDown(() async {
      if (isar.isOpen) {
        isar.close(deleteFromDisk: true);
      }
    });

    test(
      'should persist data across database reopens',
      () async {
        // Write some data
        final testData = PersistenceTestModel()
          ..value = 'test-value-${DateTime.now().millisecondsSinceEpoch}'
          ..timestamp = DateTime.now().millisecondsSinceEpoch;

        await isar.writeAsync((isar) {
          isar.persistenceTestModels.put(testData);
        });

        final writtenId = testData.id;
        expect(writtenId, isNotNull);

        // Close the database
        isar.close();

        // Reopen the database
        isar = await Isar.openAsync(
          name: 'persistence_test',
          directory: '/test-databases',
          schemas: [PersistenceTestModelSchema],
          engine: IsarEngine.sqlite,
        );

        // Read the data back
        final retrieved = await isar.readAsync((isar) {
          return isar.persistenceTestModels.get(writtenId);
        });

        expect(retrieved, isNotNull);
        expect(retrieved!.id, equals(writtenId));
        expect(retrieved.value, equals(testData.value));
        expect(retrieved.timestamp, equals(testData.timestamp));
      },
      skip: true, // Skip by default since it requires OPFS
    );

    test('should handle multiple write operations', () async {
      final models = List.generate(
        10,
        (i) => PersistenceTestModel()
          ..value = 'item-$i'
          ..timestamp = DateTime.now().millisecondsSinceEpoch + i,
      );

      await isar.writeAsync((isar) {
        isar.persistenceTestModels.putAll(models);
      });

      final count = await isar.readAsync((isar) {
        return isar.persistenceTestModels.count();
      });

      expect(count, equals(10));
    });

    test('should support transactions', () async {
      await isar.writeAsync((isar) {
        isar.persistenceTestModels.put(
          PersistenceTestModel()
            ..value = 'transaction-test'
            ..timestamp = DateTime.now().millisecondsSinceEpoch,
        );
      });

      final count = await isar.readAsync((isar) {
        return isar.persistenceTestModels.count();
      });

      expect(count, equals(1));
    });

    test('should support queries', () async {
      // Insert test data
      final models = [
        PersistenceTestModel()
          ..value = 'alpha'
          ..timestamp = 1000,
        PersistenceTestModel()
          ..value = 'beta'
          ..timestamp = 2000,
        PersistenceTestModel()
          ..value = 'gamma'
          ..timestamp = 3000,
      ];

      await isar.writeAsync((isar) {
        isar.persistenceTestModels.putAll(models);
      });

      // Query with filter
      final results = await isar.readAsync((isar) {
        return isar.persistenceTestModels
            .where()
            .timestampGreaterThan(1500)
            .findAll();
      });

      expect(results.length, equals(2));
      expect(results.map((e) => e.value), containsAll(['beta', 'gamma']));
    });

    test('should handle delete operations', () async {
      final model = PersistenceTestModel()
        ..value = 'to-delete'
        ..timestamp = DateTime.now().millisecondsSinceEpoch;

      await isar.writeAsync((isar) {
        isar.persistenceTestModels.put(model);
      });

      final id = model.id;

      await isar.writeAsync((isar) {
        isar.persistenceTestModels.delete(id);
      });

      final retrieved = await isar.readAsync((isar) {
        return isar.persistenceTestModels.get(id);
      });

      expect(retrieved, isNull);
    });

    test('should support clear operation', () async {
      // Add some data
      await isar.writeAsync((isar) {
        isar.persistenceTestModels.putAll([
          PersistenceTestModel()
            ..value = 'item1'
            ..timestamp = 1,
          PersistenceTestModel()
            ..value = 'item2'
            ..timestamp = 2,
        ]);
      });

      // Clear all data
      await isar.writeAsync((isar) {
        isar.persistenceTestModels.clear();
      });

      final count = await isar.readAsync((isar) {
        return isar.persistenceTestModels.count();
      });

      expect(count, equals(0));
    });
  });

  group('Web Persistence - Fallback Mode', () {
    test('should work without OPFS (in-memory)', () async {
      await Isar.initialize();

      // Use in-memory database explicitly
      final isar = await Isar.openAsync(
        name: 'memory_test',
        directory: Isar.sqliteInMemory,
        schemas: [PersistenceTestModelSchema],
        engine: IsarEngine.sqlite,
      );

      try {
        final model = PersistenceTestModel()
          ..value = 'memory-only'
          ..timestamp = DateTime.now().millisecondsSinceEpoch;

        await isar.writeAsync((isar) {
          isar.persistenceTestModels.put(model);
        });

        final retrieved = await isar.readAsync((isar) {
          return isar.persistenceTestModels.get(model.id);
        });

        expect(retrieved, isNotNull);
        expect(retrieved!.value, equals('memory-only'));
      } finally {
        isar.close();
      }
    });
  });
}
