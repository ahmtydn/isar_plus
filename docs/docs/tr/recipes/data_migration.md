---
title: Veri Geçişi
---

# Veri Geçişi

Koleksiyonlar, alanlar veya indeksler ekler veya kaldırırsanız, Isar veritabanı şemalarınızı otomatik olarak geçirir. Bazen verilerinizi de geçirmek isteyebilirsiniz. Isar, yerleşik bir çözüm sunmaz çünkü bu keyfi geçiş kısıtlamaları getirir. İhtiyaçlarınıza uygun geçiş mantığını uygulamak kolaydır.

Bu örnekte, tüm veritabanı için tek bir sürüm kullanmak istiyoruz. Mevcut sürümü saklamak için paylaşılan tercihleri kullanıyoruz ve bunu geçiş yapmak istediğimiz sürümle karşılaştırıyoruz. Sürümler eşleşmiyorsa, verileri geçiriyoruz ve sürümü güncelliyoruz.

:::tip
Her koleksiyona kendi sürümünü de verebilir ve onları ayrı ayrı geçirebilirsiniz.
:::

Bir doğum günü alanı olan bir kullanıcı koleksiyonumuz olduğunu hayal edin. Uygulamamızın 2. sürümünde, kullanıcıları yaşa göre sorgulamak için ek bir doğum yılı alanına ihtiyacımız var.

Sürüm 1:
```dart
@collection
class User {
  Id? id;

  late String name;

  late DateTime birthday;
}
```

Sürüm 2:
```dart
@collection
class User {
  Id? id;

  late String name;

  late DateTime birthday;

  short get birthYear => birthday.year;
}
```

Sorun, mevcut kullanıcı modellerinin boş bir `birthYear` alanına sahip olacağıdır çünkü sürüm 1'de mevcut değildi. `birthYear` alanını ayarlamak için verileri geçirmemiz gerekiyor.

```dart
import 'package:isar_plus/isar_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  final dir = await getApplicationDocumentsDirectory();
  
  final isar = await Isar.open(
    [UserSchema],
    directory: dir.path,
  );

  await performMigrationIfNeeded(isar);

  runApp(MyApp(isar: isar));
}

Future<void> performMigrationIfNeeded(Isar isar) async {
  final prefs = await SharedPreferences.getInstance();
  final currentVersion = prefs.getInt('version') ?? 2;
  switch(currentVersion) {
    case 1:
      await migrateV1ToV2(isar);
      break;
    case 2:
      // Sürüm ayarlanmamışsa (yeni kurulum) veya zaten 2 ise, geçiş yapmamız gerekmez
      return;
    default:
      throw Exception('Bilinmeyen sürüm: $currentVersion');
  }

  // Sürümü güncelle
  await prefs.setInt('version', 2);
}

Future<void> migrateV1ToV2(Isar isar) async {
  final userCount = await isar.users.count();

  // Tüm kullanıcıları aynı anda belleğe yüklemekten kaçınmak için kullanıcıları sayfalara ayırıyoruz
  for (var i = 0; i < userCount; i += 50) {
    final users = await isar.users.where().offset(i).limit(50).findAll();
    await isar.writeAsync((isar) async {
      // birthYear getter'ı kullanıldığı için hiçbir şeyi güncellememiz gerekmez
      await isar.users.putAll(users);
    });
  }
}
```

:::warning
Çok fazla veriyi geçirmeniz gerekiyorsa, UI thread'inde yük oluşturmayı önlemek için bir arka plan izolasyonu kullanmayı düşünün.
:::
