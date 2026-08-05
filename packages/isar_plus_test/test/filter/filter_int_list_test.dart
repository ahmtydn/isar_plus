import 'package:isar_plus/isar_plus.dart';
import 'package:isar_plus_test/isar_plus_test.dart';
import 'package:test/test.dart';

part 'filter_int_list_test.g.dart';

@collection
class IntModel {
  IntModel(this.id, this.list);

  final int id;

  final List<short>? list;

  @override
  // ignore: hash_and_equals
  bool operator ==(Object other) {
    return other is IntModel && other.id == id && listEquals(list, other.list);
  }
}

void main() {
  group('Int list filter', () {
    late Isar isar;
    late IsarCollection<int, IntModel> col;

    late IntModel objEmpty;
    late IntModel obj1;
    late IntModel obj2;
    late IntModel obj3;
    late IntModel obj4;
    late IntModel objNull;

    setUp(() async {
      isar = await openTempIsar([IntModelSchema]);
      col = isar.intModels;

      objEmpty = IntModel(0, []);
      obj1 = IntModel(1, [123]);
      obj2 = IntModel(2, [0, 255]);
      obj3 = IntModel(3, [1, 123, 3]);
      obj4 = IntModel(4, [0, 255]);
      objNull = IntModel(5, null);

      isar.write((isar) {
        col.putAll([objEmpty, obj1, obj2, obj3, obj4, objNull]);
      });
    });

    isarTest('.elementEqualTo()', () {
      expect(col.where().listElementEqualTo(0).findAll(), [obj2, obj4]);
      expect(col.where().listElementEqualTo(1).findAll(), [obj3]);
      expect(col.where().listElementEqualTo(55).findAll(), isEmpty);
    });

    isarTest('.elementGreaterThan()', () {
      expect(col.where().listElementGreaterThan(123).findAll(), [obj2, obj4]);
      expect(col.where().listElementGreaterThan(255).findAll(), isEmpty);
    });

    isarTest('.elementGreaterThanOrEqualTo()', () {
      expect(col.where().listElementGreaterThanOrEqualTo(123).findAll(), [
        obj1,
        obj2,
        obj3,
        obj4,
      ]);
    });

    isarTest('.elementLessThan()', () {
      expect(col.where().listElementLessThan(123).findAll(), [
        obj2,
        obj3,
        obj4,
      ]);
      expect(col.where().listElementLessThan(0).findAll(), isEmpty);
    });

    isarTest('.elementLessThanOrEqualTo()', () {
      expect(col.where().listElementLessThanOrEqualTo(123).findAll(), [
        obj1,
        obj2,
        obj3,
        obj4,
      ]);
    });

    isarTest('.elementBetween()', () {
      expect(col.where().listElementBetween(123, 255).findAll(), [
        obj1,
        obj2,
        obj3,
        obj4,
      ]);
      expect(col.where().listElementBetween(50, 100).findAll(), isEmpty);
    });

    isarTest('.isNull()', () {
      expect(col.where().listIsNull().findAll(), [objNull]);
    });
  });
}
