// ignore_for_file: invalid_annotation_target

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:isar_plus/isar_plus.dart';
import 'package:isar_plus_test/isar_plus_test.dart';
import 'package:test/test.dart';

part 'freezed_test.freezed.dart';
part 'freezed_test.g.dart';

@freezed
@collection
abstract class Person with _$Person {
  const factory Person({
    @id required int isarId,
    required String firstName,
    required String lastName,
    required int age,
  }) = _Person;
}

void main() {
  group('Freezed', () {
    late Isar isar;

    setUp(() async {
      isar = await openTempIsar([PersonSchema]);
    });

    isarTest('get put', () {
      const person = Person(
        isarId: 1,
        firstName: 'Max',
        lastName: 'Mustermann',
        age: 42,
      );

      isar.write((isar) {
        isar.persons.put(person);
      });

      expect(isar.persons.get(1), person);
    });
  });
}
