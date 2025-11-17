---
title: Isar v3'ten Geçiş
---

# Isar v3'ten Isar Plus v4'e geçiş

`isar` 3.x paketlerinden `isar_plus` (v4) paketine yükseltmek **dosya formatını kıran** bir değişikliktir. v4 çekirdeği farklı meta veriler yazar ve v3 tarafından oluşturulmuş bir veritabanını açamaz; bu yüzden şu hatayı görürsünüz:

```
VersionError: The database version is not compatible with this version of Isar.
```

Çözüm, verileri eski çalışma zamanı ile dışa aktarıp yeni bir Isar Plus veritabanına içe aktarmaktır. Aşağıdaki adımlar süreci özetler.

## Migrasyon özeti

1. Eski dosyaları okuyabilmek için `isar:^3.1.0+1` kullanan bir sürümü yayında tutun.
2. Migrasyon sırasında `isar_plus` ve `isar_plus_flutter_libs` paketlerini eskilerin yanına ekleyin.
3. Kod üreticisini yeniden çalıştırarak şemalarınızı v4 API'lerine göre derleyin.
4. v3 instanc'ındaki tüm kayıtları yeni bir Isar Plus instanc'ına kopyalayın.
5. Kopya tamamlanınca eski dosyaları silip eski bağımlılıkları kaldırın.

Eski veriye **ihtiyacınız yoksa**, v3 klasörünü silip temiz bir veritabanıyla başlayabilirsiniz. Bu rehber mevcut kayıtları korumaya odaklanır.

## Bağımlılıkları yan yana güncelleyin

Kopyalama bitene kadar eski runtime'ı tutup, ardından yenisini ekleyin:

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

İki paket aynı Dart sembollerini sunduğundan, migrasyon boyunca mutlaka alias kullanarak içe aktarın:

```dart
import 'package:isar/isar.dart' as legacy;
import 'package:isar_plus/isar_plus.dart' as plus;
```

## Şemaları v4 için yeniden üretin

Isar Plus, jeneratörünü ana pakete dahil eder. Yeni yardımcıları ve adapterleri üretmek için builder'ı tekrar çalıştırın:

```bash
dart run build_runner build --delete-conflicting-outputs
```

Burada durup derleme hatalarını giderin (örneğin `Id?` alanları `int id` olmalı veya `Isar.autoIncrement` kullanılmalı). [API Migrasyon Rehberi](https://github.com/ahmtydn/isar_plus/blob/main/packages/isar_plus/README.md#api-migration-guide) kritik değişiklikleri özetler:

- `writeTxn()` -> `writeAsync()`, `writeTxnSync()` -> `write()`
- `txn()` -> `readAsync()`, `txnSync()` -> `read()`
- ID'ler `id` adını taşımalı veya `@id` ile işaretlenmeli; otomatik artış `Isar.autoIncrement` ile yapılır
- `@enumerated` artık `@enumValue`
- Gömülü nesneler çoğu eski bağlantının yerini alır

## Gerçek verileri kopyalayın

Tek seferlik bir migrasyon rutini oluşturun (örneğin uygulama başlamadan `main()` içinde veya ayrı bir `bin/migrate.dart`). Şablon şöyledir:

1. v3 runtime ile legacy mağazayı açın.
2. Farklı bir dizinde veya isimle yeni bir v4 instanc'ı açın.
3. Her koleksiyonu sayfalayarak okuyun, yeni şemaya dönüştürün ve yeni veritabanına `put` edin.
4. Migrasyon tamamlandığında (SharedPreferences, yerel dosya veya feature flag ile) işaretleyin ki ikinci kez çalışmasın.

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
    engine: plus.IsarEngine.sqlite, // yerel çekirdek için IsarEngine.isar
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

> İpucu: `_mapStatus` gibi eşleme fonksiyonlarını migrasyon kodunun yanında tutarak enum yeniden adlandırmaları, alan kaldırmaları veya veri temizliğini tek yerde yönetebilirsiniz.

Çok büyük koleksiyonlarınız varsa döngüyü bir isolate veya arka plan servisinde çalıştırın ki UI kilitlenmesin. Gömülü nesneler ve bağlantılar için de aynı desen geçerlidir: legacy API ile yükleyip yeni şema ile kaydedin.

## Üretimde yalnızca bir kez çalıştığından emin olun

Her iki runtime'ı birlikte dağıttığınızda, her soğuk başlangıç yeniden migrasyon denemesi yapabilir. Kurulum başına yalnızca bir kez çalışması için bir bayrak veya sürüm değeri saklayın:

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

Gelecekte başka migrasyonlar bekliyorsanız bool yerine sayısal bir şema versiyonu (`3` legacy, `4` Isar Plus) saklayabilirsiniz. Masaüstü veya sunucuda veritabanı klasörünün yanına `.migrated` adlı küçük bir dosya bırakmak da işe yarar.

## Temizlik

Tüm koleksiyonları kopyaladıktan sonra:

1. Migrasyonun tekrar çalışmasını önlemek için `prefs.setBool('migratedToIsarPlus', true)` gibi bir bayrak yazın.
2. Eski dosyaları silin (manuel olarak ya da `plus.Isar.deleteDatabase(name: 'legacy', directory: directoryPath, engine: plus.IsarEngine.isar)` çağırarak).
3. `pubspec.yaml` dosyasından `isar` ve `isar_flutter_libs` bağımlılıklarını kaldırın.
4. Gerekirse yeni veritabanını eski isim veya dizine geri taşıyın.

Kullanıcıların legacy sürümü açmadığından emin olduktan sonra yalnızca `isar_plus` içeren bir sürüm yayınlayın.

## Sorun giderme

- **`VersionError` devam ediyor**: v4'ü açmadan önce v3 dosyalarını sildiğinizden emin olun. Eski WAL/LCK dosyaları legacy başlığı tutabilir.
- **Yinelenen birincil anahtarlar**: v4'te ID'ler tekil ve null olmayan tamsayı olmalıdır. `Isar.autoIncrement` kullanın veya kopyalama sırasında kendi anahtarlarınızı üretin.
- **Generator hata veriyor**: `dart pub clean` çalıştırıp `build_runner` komutunu tekrar deneyin; `part '...g.dart';` direktiflerinin eksiksiz olduğuna bakın.
- **Geri almak istiyorsunuz**: Migrasyon ayrı bir veritabanına yazdığı için yeni dosyaları güvenle silip legacy verileri koruyabilirsiniz.

Bu adımlarla kullanıcılar `isar` 3.x sürümünden `isar_plus` sürümüne veri kaybetmeden geçebilir.
