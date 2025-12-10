import 'package:isar_plus/isar_plus.dart';
import 'package:isar_plus_test/isar_plus_test.dart';
import 'package:test/test.dart';

part 'native_error_test.g.dart';

@collection
class SimpleModel {
  SimpleModel(this.id);

  final int id;

  String value = '';

  @override
  bool operator ==(Object other) =>
      other is SimpleModel && id == other.id && value == other.value;

  @override
  int get hashCode => Object.hash(id, value);
}

void main() {
  group('Native Errors', () {
    isarTest('PathError - invalid directory', web: false, () async {
      await prepareTest();
      expect(
        () => Isar.open(
          schemas: [SimpleModelSchema],
          name: 'test_path_error',
          directory: '/nonexistent_root_path/subdir/another',
          inspector: false,
        ),
        throwsA(isA<PathError>()),
      );
    });

    isarTest(
      'DatabaseError - generic database error with message',
      sqlite: false,
      web: false,
      () async {
        await prepareTest();
        expect(
          () => Isar.open(
            schemas: [SimpleModelSchema],
            name: 'test_db_error',
            directory: testTempPath ?? '.',
            maxSizeMiB: -1,
            inspector: false,
          ),
          throwsA(isA<DatabaseError>()),
        );
      },
    );
  });
}
