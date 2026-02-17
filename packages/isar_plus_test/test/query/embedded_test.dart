import 'package:isar_plus/isar_plus.dart';
import 'package:isar_plus_test/isar_plus_test.dart';
import 'package:test/test.dart';

part 'embedded_test.g.dart';

@collection
class Model {
  Model(this.id, this.embedded, this.nested, this.nestedList);

  final int id;

  final EModel embedded;

  final NModel? nested;

  final List<NModel>? nestedList;

  @override
  bool operator ==(Object other) =>
      other is Model &&
      other.id == id &&
      other.embedded == embedded &&
      other.nested == nested &&
      listEquals(other.nestedList, nestedList);

  @override
  int get hashCode =>
      Object.hash(id, embedded, nested, Object.hashAll(nestedList ?? []));

  @override
  String toString() {
    return 'Model(id: $id, embedded: $embedded, nested: $nested, '
        'nestedList: $nestedList)';
  }
}

@embedded
class EModel {
  EModel([this.value = '']);

  final String value;

  @override
  bool operator ==(Object other) => other is EModel && other.value == value;

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() => 'EModel($value)';
}

@embedded
class NModel {
  NModel([this.embedded, this.nested, this.nestedList]);

  final EModel? embedded;

  final NModel? nested;

  final List<NModel>? nestedList;

  @override
  bool operator ==(Object other) =>
      other is NModel &&
      other.embedded == embedded &&
      other.nested == nested &&
      listEquals(other.nestedList, nestedList);

  @override
  int get hashCode =>
      Object.hash(embedded, nested, Object.hashAll(nestedList ?? []));

  @override
  String toString() =>
      'NModel(embedded: $embedded, nested: $nested, nestedList: $nestedList)';
}

void main() {
  group('Embedded Query', () {
    late Isar isar;

    late Model m1;
    late Model m2;
    late Model m3;
    late Model m4;

    setUp(() async {
      isar = await openTempIsar([ModelSchema]);

      m1 = Model(1, EModel('a'), null, null);
      m2 = Model(2, EModel('b'), NModel(EModel('c')), []);
      m3 = Model(3, EModel('c'), NModel(EModel('d'), NModel(EModel('e'))), [
        NModel(EModel('f')),
      ]);
      m4 = Model(4, EModel('d'), null, [
        NModel(EModel('g')),
        NModel(EModel('h'), NModel(EModel('i'))),
      ]);

      isar.write((isar) {
        isar.models.putAll([m1, m2, m3, m4]);
      });
    });

    isarTest('Filter by embedded value', () {
      expect(
        isar.models.where().embedded((q) => q.valueEqualTo('a')).findAll(),
        [m1],
      );
      expect(
        isar.models.where().embedded((q) => q.valueEqualTo('c')).findAll(),
        [m3],
      );
      expect(
        isar.models.where().embedded((q) => q.valueEqualTo('z')).findAll(),
        isEmpty,
      );
    });

    isarTest('Filter by nested embedded value', () {
      expect(
        isar.models
            .where()
            .nested((q) => q.embedded((q) => q.valueEqualTo('c')))
            .findAll(),
        [m2],
      );
      expect(
        isar.models
            .where()
            .nested((q) => q.embedded((q) => q.valueEqualTo('d')))
            .findAll(),
        [m3],
      );
    });

    isarTest('Filter by nested properties (isNull)', () {
      expect(isar.models.where().nestedIsNull().findAll(), [m1, m4]);
      expect(isar.models.where().nestedIsNotNull().findAll(), [m2, m3]);
    });
  });
}
