import 'package:isar_plus/isar_plus.dart';
import 'package:isar_plus_test/isar_plus_test.dart';
import 'package:test/test.dart';

part 'enum_test.g.dart';

enum IndexEnum { option1, option2, option3 }

enum ByteEnum {
  option1(1),
  option2(2),
  option3(3);

  const ByteEnum(this.value);

  @enumValue
  final byte value;
}

enum ByteEnum2 {
  option1(2),
  option2(4),
  option3(6),
  option4(8);

  const ByteEnum2(this.value);

  @enumValue
  final byte value;
}

enum ShortEnum {
  option1(5),
  option2(6),
  option3(77);

  const ShortEnum(this.value);

  @enumValue
  final short value;
}

enum IntEnum {
  option1(-1),
  option2(0),
  option3(1);

  const IntEnum(this.value);

  @enumValue
  final int value;
}

enum StringEnum {
  option1('a'),
  option2('b'),
  option3('c');

  const StringEnum(this.value);

  @enumValue
  final String value;
}

@collection
class EnumModel {
  EnumModel(
    this.id,
    this.ordinalEnum,
    this.byteEnum,
    this.shortEnum,
    this.intEnum,
    this.stringEnum,
  );

  final int id;

  final IndexEnum ordinalEnum;

  final ByteEnum byteEnum;

  final ShortEnum shortEnum;

  final IntEnum intEnum;

  final StringEnum stringEnum;

  @override
  // ignore: hash_and_equals
  bool operator ==(Object other) =>
      other is EnumModel &&
      other.id == id &&
      other.ordinalEnum == ordinalEnum &&
      other.byteEnum == byteEnum &&
      other.shortEnum == shortEnum &&
      other.intEnum == intEnum &&
      other.stringEnum == stringEnum;
}

@collection
@Name('EnumModel')
class EnumModelV2 {
  EnumModelV2(
    this.id,
    this.ordinalEnum,
    this.byteEnum,
    this.shortEnum,
    this.intEnum,
    this.stringEnum,
  );

  final int id;

  final IndexEnum ordinalEnum;

  final ByteEnum2 byteEnum;

  final ShortEnum shortEnum;

  final IntEnum intEnum;

  final StringEnum stringEnum;

  @override
  // ignore: hash_and_equals
  bool operator ==(Object other) =>
      other is EnumModelV2 &&
      other.id == id &&
      other.ordinalEnum == ordinalEnum &&
      other.byteEnum == byteEnum &&
      other.shortEnum == shortEnum &&
      other.intEnum == intEnum &&
      other.stringEnum == stringEnum;
}

void main() {
  group('Enum', () {
    late Isar isar;

    setUp(() async {
      isar = await openTempIsar([EnumModelSchema]);
    });

    isarTest('Verify property types', () {
      final schema = isar.enumModels.schema;
      final properties = schema.properties;

      // ordinalEnum → byte (index-based)
      final ordinalProp = properties.firstWhere(
        (p) => p.name == 'ordinalEnum',
      );
      expect(ordinalProp.type, IsarType.byte);
      expect(ordinalProp.enumMap, {'option1': 0, 'option2': 1, 'option3': 2});

      // byteEnum → byte (custom value)
      final byteProp = properties.firstWhere((p) => p.name == 'byteEnum');
      expect(byteProp.type, IsarType.byte);
      expect(byteProp.enumMap, {'option1': 1, 'option2': 2, 'option3': 3});

      // shortEnum → int (short)
      final shortProp = properties.firstWhere((p) => p.name == 'shortEnum');
      expect(shortProp.type, IsarType.int);
      expect(shortProp.enumMap, {'option1': 5, 'option2': 6, 'option3': 77});

      // intEnum → long
      final intProp = properties.firstWhere((p) => p.name == 'intEnum');
      expect(intProp.type, IsarType.long);
      expect(intProp.enumMap, {'option1': -1, 'option2': 0, 'option3': 1});

      // stringEnum → string
      final stringProp = properties.firstWhere((p) => p.name == 'stringEnum');
      expect(stringProp.type, IsarType.string);
      expect(stringProp.enumMap, {
        'option1': 'a',
        'option2': 'b',
        'option3': 'c',
      });
    });

    isarTest('.get() / .put()', () {
      final obj1 = EnumModel(
        1,
        IndexEnum.option1,
        ByteEnum.option1,
        ShortEnum.option1,
        IntEnum.option1,
        StringEnum.option1,
      );
      final obj2 = EnumModel(
        2,
        IndexEnum.option2,
        ByteEnum.option2,
        ShortEnum.option2,
        IntEnum.option2,
        StringEnum.option2,
      );
      final obj3 = EnumModel(
        3,
        IndexEnum.option3,
        ByteEnum.option3,
        ShortEnum.option3,
        IntEnum.option3,
        StringEnum.option3,
      );

      // Initially empty
      expect(isar.enumModels.get(1), null);
      expect(isar.enumModels.get(2), null);

      // Put and verify round-trip
      isar.write((isar) {
        isar.enumModels.put(obj1);
        expect(isar.enumModels.get(1), obj1);
        expect(isar.enumModels.get(2), null);

        isar.enumModels.put(obj2);
        expect(isar.enumModels.get(1), obj1);
        expect(isar.enumModels.get(2), obj2);
      });

      // Verify persistence after transaction
      expect(isar.enumModels.get(1), obj1);
      expect(isar.enumModels.get(2), obj2);

      // PutAll and verify
      isar.write((isar) {
        isar.enumModels.putAll([obj1, obj2, obj3]);
      });
      expect(isar.enumModels.getAll([1, 2, 3]), [obj1, obj2, obj3]);

      // Verify individual enum property values
      final retrieved = isar.enumModels.get(1)!;
      expect(retrieved.ordinalEnum, IndexEnum.option1);
      expect(retrieved.byteEnum, ByteEnum.option1);
      expect(retrieved.shortEnum, ShortEnum.option1);
      expect(retrieved.intEnum, IntEnum.option1);
      expect(retrieved.stringEnum, StringEnum.option1);

      final retrieved3 = isar.enumModels.get(3)!;
      expect(retrieved3.ordinalEnum, IndexEnum.option3);
      expect(retrieved3.byteEnum, ByteEnum.option3);
      expect(retrieved3.shortEnum, ShortEnum.option3);
      expect(retrieved3.intEnum, IntEnum.option3);
      expect(retrieved3.stringEnum, StringEnum.option3);

      // Update with different enum values
      final updated = EnumModel(
        1,
        IndexEnum.option3,
        ByteEnum.option3,
        ShortEnum.option3,
        IntEnum.option3,
        StringEnum.option3,
      );
      isar.write((isar) {
        isar.enumModels.put(updated);
      });
      expect(isar.enumModels.get(1), updated);
    });

    isarTest('.exportJson()', () {
      final obj = EnumModel(
        1,
        IndexEnum.option2,
        ByteEnum.option2,
        ShortEnum.option2,
        IntEnum.option2,
        StringEnum.option2,
      );

      isar.write((isar) {
        isar.enumModels.put(obj);
      });

      final exported = isar.enumModels.where().exportJson();
      expect(exported.length, 1);

      final json = exported.first;
      expect(json['id'], 1);
      // ordinalEnum stored as index
      expect(json['ordinalEnum'], IndexEnum.option2.index); // 1
      // byteEnum stored as custom value
      expect(json['byteEnum'], ByteEnum.option2.value); // 2
      // shortEnum stored as custom value
      expect(json['shortEnum'], ShortEnum.option2.value); // 6
      // intEnum stored as custom value
      expect(json['intEnum'], IntEnum.option2.value); // 0
      // stringEnum stored as custom value
      expect(json['stringEnum'], StringEnum.option2.value); // 'b'
    });

    isarTest('.importJson()', () {
      isar.write((isar) {
        isar.enumModels.importJson([
          {
            'id': 1,
            'ordinalEnum': 2, // IndexEnum.option3
            'byteEnum': 3, // ByteEnum.option3
            'shortEnum': 77, // ShortEnum.option3
            'intEnum': -1, // IntEnum.option1
            'stringEnum': 'c', // StringEnum.option3
          },
        ]);
      });

      final result = isar.enumModels.get(1)!;
      expect(result.ordinalEnum, IndexEnum.option3);
      expect(result.byteEnum, ByteEnum.option3);
      expect(result.shortEnum, ShortEnum.option3);
      expect(result.intEnum, IntEnum.option1);
      expect(result.stringEnum, StringEnum.option3);
    });

    isarTest('Added value', web: false, () async {
      // Write data with ByteEnum (3 values: 1, 2, 3)
      final isar1 = await openTempIsar([EnumModelSchema]);
      final isarName = isar1.name;

      isar1.write((isar) {
        isar.enumModels.putAll([
          EnumModel(
            1,
            IndexEnum.option1,
            ByteEnum.option1,
            ShortEnum.option1,
            IntEnum.option1,
            StringEnum.option1,
          ),
          EnumModel(
            2,
            IndexEnum.option2,
            ByteEnum.option2,
            ShortEnum.option2,
            IntEnum.option2,
            StringEnum.option2,
          ),
        ]);
      });
      expect(isar1.close(), true);

      // Reopen with ByteEnum2 (4 values: 2, 4, 6, 8) via EnumModelV2
      final isar2 = await openTempIsar([EnumModelV2Schema], name: isarName);

      // Existing data should still be readable
      final results = isar2.enumModelV2s.where().findAll();
      expect(results.length, 2);

      // Write data with the new enum value (option4)
      isar2.write((isar) {
        isar.enumModelV2s.put(
          EnumModelV2(
            3,
            IndexEnum.option3,
            ByteEnum2.option4,
            ShortEnum.option3,
            IntEnum.option3,
            StringEnum.option3,
          ),
        );
      });
      expect(isar2.enumModelV2s.count(), 3);
      expect(isar2.enumModelV2s.get(3)!.byteEnum, ByteEnum2.option4);
    });

    isarTest('Removed value', web: false, () async {
      // Write data with ByteEnum2 (4 values including option4 = 8)
      final isar1 = await openTempIsar([EnumModelV2Schema]);
      final isarName = isar1.name;

      isar1.write((isar) {
        isar.enumModelV2s.putAll([
          EnumModelV2(
            1,
            IndexEnum.option1,
            ByteEnum2.option1,
            ShortEnum.option1,
            IntEnum.option1,
            StringEnum.option1,
          ),
          EnumModelV2(
            2,
            IndexEnum.option2,
            ByteEnum2.option4, // value = 8, not in ByteEnum
            ShortEnum.option2,
            IntEnum.option2,
            StringEnum.option2,
          ),
        ]);
      });
      expect(isar1.close(), true);

      // Reopen with ByteEnum (3 values: 1, 2, 3) — value 8 is unknown
      final isar2 = await openTempIsar([EnumModelSchema], name: isarName);

      final results = isar2.enumModels.where().findAll();
      expect(results.length, 2);

      // Known value should round-trip correctly
      // ByteEnum2.option1 value = 2 → ByteEnum.option2 (value = 2)
      expect(results[0].byteEnum, ByteEnum.option2);

      // Unknown value (8) should fall back to first enum value
      expect(results[1].byteEnum, ByteEnum.option1);
    });
  });
}
