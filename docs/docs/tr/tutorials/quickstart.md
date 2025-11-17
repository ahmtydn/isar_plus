---
title: Hızlı Başlangıç
---

# Hızlı Başlangıç

Vay canına, buradasınız! Hadi en havalı Flutter veritabanını kullanmaya başlayalım...

Bu hızlı başlangıçta az konuşup çok kod yazacağız.

## 1. Bağımlılıkları Ekleyin

Eğlence başlamadan önce, `pubspec.yaml` dosyasına birkaç paket eklememiz gerekiyor. Ağır işleri pub'ın yapmasına izin verebiliriz.

```bash
flutter pub add isar isar_plus_flutter_libs
flutter pub add -d isar_generator build_runner
```

## 2. Sınıfları İşaretleyin

Koleksiyon sınıflarınızı `@collection` ile işaretleyin ve bir `Id` alanı seçin.

```dart
part 'user.g.dart';

@collection
class User {
  Id id = Isar.autoIncrement; // otomatik artış için id = null de kullanabilirsiniz

  String? name;

  int? age;
}
```

Id'ler, bir koleksiyondaki nesneleri benzersiz şekilde tanımlar ve daha sonra tekrar bulmanıza olanak tanır.

## 3. Kod Üreticiyi Çalıştırın

`build_runner`'ı başlatmak için aşağıdaki komutu çalıştırın:

```
dart run build_runner build
```

Flutter kullanıyorsanız, aşağıdakini kullanın:

```
flutter pub run build_runner build
```

## 4. Isar Örneğini Açın

Yeni bir Isar örneği açın ve tüm koleksiyon şemalarınızı iletin. İsteğe bağlı olarak bir örnek adı ve dizin belirtebilirsiniz.

```dart
final dir = await getApplicationDocumentsDirectory();
final isar = await Isar.open(
  [UserSchema],
  directory: dir.path,
);
```

:::tip Flutter web
- Uygulamanızın `web/` dizinine `isar.wasm` ve `isar.js` ekleyin. Bunları en son sürümden indirebilir veya `./tool/prepare_local_dev.sh --targets wasm` ile yeniden oluşturabilirsiniz.
- Wasm çalışma zamanı ve kalıcılık arka ucunun hazır olması için ilk örneğinizi açmadan önce `await Isar.initialize();` çağrısını yapın.
- SQLite motorunu kalıcı bir klasör adıyla kullanın, örneğin:

  ```dart
  final isar = await Isar.open(
    [UserSchema],
    engine: IsarEngine.sqlite,
    directory: 'isar_data',
  );
  ```
:::

## 5. Yazma ve Okuma

Örneğiniz açıldığında, koleksiyonları kullanmaya başlayabilirsiniz.

Tüm temel CRUD işlemleri `IsarCollection` aracılığıyla kullanılabilir.

```dart
final newUser = User()..name = 'Jane Doe'..age = 36;

await isar.writeAsync((isar) async {
  await isar.users.put(newUser); // ekleme ve güncelleme
});

final existingUser = await isar.users.get(newUser.id); // alma

await isar.writeAsync((isar) async {
  await isar.users.delete(existingUser.id!); // silme
});
```

## Diğer Kaynaklar

Görsel bir öğrenci misiniz? Isar'a başlamak için bu videoları izleyin:
<div class="video-block">
  <iframe max-width=100% height=auto src="https://www.youtube.com/embed/CwC9-a9hJv4" title="Isar Database" frameborder="0" allow="accelerometer; clipboard-write; encrypted-media; gyroscope; picture-in-picture" allowfullscreen></iframe>
</div>
<br>
<div class="video-block">
  <iframe max-width=100% height=auto src="https://www.youtube.com/embed/videoseries?list=PLKKf8l1ne4_hMBtRykh9GCC4MMyteUTyf" title="Isar Database" frameborder="0" allow="accelerometer; clipboard-write; encrypted-media; gyroscope; picture-in-picture" allowfullscreen></iframe>
</div>
<br>
<div class="video-block">
  <iframe max-width=100% height=auto src="https://www.youtube.com/embed/pdKb8HLCXOA " title="Isar Database" frameborder="0" allow="accelerometer; clipboard-write; encrypted-media; gyroscope; picture-in-picture" allowfullscreen></iframe>
</div>
