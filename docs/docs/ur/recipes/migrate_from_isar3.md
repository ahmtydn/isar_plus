---
title: Isar v3 سے منتقلی
---

# Isar v3 سے Isar Plus v4 تک منتقلی

`isar` 3.x کے پرانے پیکجز کو `isar_plus` (v4) میں اپ گریڈ کرنا **فائل فارمیٹ کی توڑ دینے والی تبدیلی** ہے۔ v4 کا کور مختلف میٹا ڈیٹا لکھتا ہے اور v3 نے جو ڈیٹا بیس بنایا ہو اسے نہیں کھول سکتا، لہٰذا آپ کو اس طرح کی غلطی ملتی ہے:

```
VersionError: The database version is not compatible with this version of Isar.
```

حل یہ ہے کہ پرانے رن ٹائم کے ساتھ موجودہ ڈیٹا ایکسپورٹ کریں اور اسے ایک نئی Isar Plus ڈیٹابیس میں امپورٹ کریں۔ نیچے دیے گئے مراحل اس عمل کی رہنمائی کرتے ہیں۔

## منتقلی کا خلاصہ

1. ایسا بلڈ ریلیز (یا برقرار) رکھیں جو `isar:^3.1.0+1` پر منحصر ہو تاکہ آپ لیگیسی فائلیں پڑھ سکیں۔
2. منتقلی کے دوران `isar_plus` اور `isar_plus_flutter_libs` کو پرانے پیکجز کے ساتھ شامل کریں۔
3. کوڈ جنریٹر دوبارہ چلائیں تاکہ آپ کے اسکیماز v4 API کے مطابق کمپائل ہوں۔
4. v3 انسٹینس کے ہر ریکارڈ کو ایک نئی Isar Plus انسٹینس میں کاپی کریں۔
5. کاپی کامیاب ہوتے ہی لیگیسی فائلیں حذف کریں اور پرانی ڈپنڈنسیز ہٹا دیں۔

اگر آپ کو پرانا ڈیٹا **درکار نہیں** تو صرف v3 ڈائریکٹری حذف کر کے خالی ڈیٹابیس سے آغاز کریں۔ باقی گائیڈ موجودہ ریکارڈ کو محفوظ رکھنے پر مرکوز ہے۔

## ڈپنڈنسیز کو ساتھ ساتھ اپ ڈیٹ کریں

کاپی مکمل ہونے تک پرانا رن ٹائم برقرار رکھیں اور پھر نیا شامل کریں:

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

دونوں پیکجز ایک ہی Dart سمبل ظاہر کرتے ہیں، اس لیے منتقلی کے دوران ہمیشہ انہیں عرفی نام کے ساتھ امپورٹ کریں:

```dart
import 'package:isar/isar.dart' as legacy;
import 'package:isar_plus/isar_plus.dart' as plus;
```

## v4 کے لیے اسکیما دوبارہ بنائیں

Isar Plus اپنا جنریٹر مرکزی پیکج میں ہی فراہم کرتا ہے۔ نئے ہیلپر اور اڈاپٹر جنریٹ کرنے کے لیے بلڈر دوبارہ چلائیں:

```bash
dart run build_runner build --delete-conflicting-outputs
```

یہاں رُک کر کمپائل ایررز حل کریں (مثلاً `Id?` فیلڈ اب `int id` یا `Isar.autoIncrement` استعمال کرے گی)۔ [API مائیگریشن گائیڈ](https://github.com/ahmtydn/isar_plus/blob/main/packages/isar_plus/README.md#api-migration-guide) اہم تبدیلیوں کا خلاصہ پیش کرتی ہے:

- `writeTxn()` -> `writeAsync()` اور `writeTxnSync()` -> `write()`
- `txn()` -> `readAsync()` اور `txnSync()` -> `read()`
- IDs کا نام `id` ہونا چاہیے یا `@id` اینوٹیشن ہونی چاہیے، جبکہ خودکار اضافہ اب `Isar.autoIncrement` کے ذریعے ہوتا ہے
- `@enumerated` اب `@enumValue` کہلاتا ہے
- زیادہ تر پرانے لنکس کی جگہ ایمبیڈڈ آبجیکٹس لیتے ہیں

## اصل ڈیٹا کو کاپی کریں

ایک وقتی مائیگریشن روٹین بنائیں (مثلاً ایپ چلانے سے پہلے `main()` میں یا علیحدہ `bin/migrate.dart` میں)۔ پیٹرن یہ ہے:

1. v3 رن ٹائم سے لیگیسی اسٹور کھولیں۔
2. کسی دوسرے فولڈر یا نام میں نئی v4 انسٹینس کھولیں۔
3. ہر کلیکشن کو صفحہ وار پڑھیں، اسے نئے اسکیما میں میپ کریں اور نئی ڈیٹابیس میں `put` کریں۔
4. SharedPreferences، مقامی فائل یا فیچر فلیگ کے ذریعے اس بات کو محفوظ کریں کہ مائیگریشن مکمل ہو چکی ہے تاکہ یہ دوبارہ نہ چلے۔

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
    engine: plus.IsarEngine.sqlite, // یا مقامی کور کے لیے IsarEngine.isar
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

> مشورہ: `_mapStatus` جیسے میپنگ فنکشنز کو اسی فائل میں رکھیں تاکہ اینم کے نام بدلنے، فیلڈ ہٹانے یا ڈیٹا صاف کرنے کا عمل ایک ہی جگہ رہے۔

اگر کلیکشن بہت بڑی ہو تو لوپ کو کسی isolate یا بیک گراؤنڈ سروس میں چلائیں تاکہ UI بلاک نہ ہو۔ ایمبیڈڈ آبجیکٹس اور لنکس بھی اسی پیٹرن کے ساتھ مائیگریٹ کیے جا سکتے ہیں۔

## یقینی بنائیں کہ پروڈکشن میں صرف ایک بار چلے

جب تک آپ دونوں رن ٹائم ساتھ بھیج رہے ہیں، ہر کولڈ اسٹارٹ دوبارہ مائیگریٹ کرنے کی کوشش کر سکتا ہے۔ کوئی فلیگ یا ورژن ویلیو محفوظ کریں تاکہ ہر انسٹالیشن پر صرف ایک بار کاپی ہو:

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

اگر آئندہ بھی مائیگریشن درکار ہو تو بولین کے بجائے عددی اسکیما ورژن (`3` لیگیسی، `4` Isar Plus) محفوظ کر لیں۔ ڈیسک ٹاپ یا سرور پر ڈیٹابیس فولڈر کے پاس `.migrated` نامی فائل بنانا بھی آسان طریقہ ہے۔

## صفائی کا مرحلہ

تمام کلیکشنز کاپی ہونے کے بعد:

1. `prefs.setBool('migratedToIsarPlus', true)` جیسا فلیگ لکھیں تاکہ روٹین دوبارہ نہ چلے۔
2. لیگیسی فائلیں حذف کریں (دستی طور پر یا `plus.Isar.deleteDatabase(name: 'legacy', directory: directoryPath, engine: plus.IsarEngine.isar)` کے ذریعے).
3. `pubspec.yaml` سے `isar` اور `isar_flutter_libs` ڈپنڈنسیز ہٹا دیں۔
4. ضرورت پڑنے پر نئی ڈیٹابیس کا نام یا ڈائریکٹری اصل نام پر واپس لے آئیں۔

جب یقین ہو جائے کہ صارفین پرانا بلڈ نہیں کھولیں گے تو صرف `isar_plus` پر مبنی ریلیز جاری کریں۔

## مسائل کا ازالہ

- **اب بھی `VersionError` آ رہا ہے**: v4 انسٹینس کھولنے سے پہلے ضرور چیک کریں کہ v3 والی فائلیں حذف ہو چکی ہیں۔ پرانے WAL/LCK ہیڈر برقرار رکھ سکتے ہیں۔
- **پرائمری کی ڈپلیکیشن**: v4 میں ID منفرد اور non-null عددی قدر ہونی چاہیے۔ `Isar.autoIncrement` استعمال کریں یا کاپی کے دوران اپنی کلیدیں بنائیں۔
- **جنریٹر ناکام ہو جاتا ہے**: `dart pub clean` چلائیں، پھر `build_runner` اور یقینی بنائیں کہ کوئی `part '...g.dart';` ڈائریکٹو غائب نہیں ہے۔
- **رول بیک کی ضرورت ہے**: کیونکہ مائیگریشن الگ ڈیٹابیس میں لکھتی ہے، آپ نئی فائلیں حذف کر کے لیگیسی ڈیٹا برقرار رکھ سکتے ہیں۔

ان اقدامات کے بعد صارفین `isar` 3.x سے `isar_plus` ریلیز تک بغیر ڈیٹا کھوئے جا سکتے ہیں۔
