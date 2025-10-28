---
title: String ID'ler
---

# String ID'ler

Bu, aldığım en sık isteklerden biridir, bu yüzden işte String id'leri kullanma hakkında bir eğitim.

Isar, yerel olarak String id'leri desteklemez ve bunun iyi bir nedeni vardır: tamsayı id'ler çok daha verimli ve hızlıdır. Özellikle bağlantılar için, bir String id'nin ek yükü çok önemlidir.

Bazen UUID'ler veya diğer tamsayı olmayan id'leri kullanan harici verileri saklamanız gerektiğini anlıyorum. String id'yi nesnenizde bir özellik olarak saklamanızı ve Id olarak kullanılabilecek 64 bitlik bir int oluşturmak için hızlı bir hash uygulaması kullanmanızı öneririm.

```dart
@collection
class User {
  String? id;

  Id get isarId => fastHash(id!);

  String? name;

  int? age;
}
```

Bu yaklaşımla, her iki dünyanın da en iyisini elde edersiniz: Bağlantılar için verimli tamsayı id'ler ve String id'leri kullanma yeteneği.

## Hızlı Hash Fonksiyonu

İdeal olarak, hash fonksiyonunuz yüksek kalitede olmalıdır (çakışma istemezsiniz) ve hızlı olmalıdır. Aşağıdaki uygulamayı kullanmanızı öneririm:

```dart
/// Dart String'leri için optimize edilmiş FNV-1a 64bit hash algoritması
int fastHash(String string) {
  var hash = 0xcbf29ce484222325;

  var i = 0;
  while (i < string.length) {
    final codeUnit = string.codeUnitAt(i++);
    hash ^= codeUnit >> 8;
    hash *= 0x100000001b3;
    hash ^= codeUnit & 0xFF;
    hash *= 0x100000001b3;
  }

  return hash;
}
```

Farklı bir hash fonksiyonu seçerseniz, 64 bitlik bir int döndürdüğünden emin olun ve kriptografik hash fonksiyonları kullanmaktan kaçının çünkü bunlar çok daha yavaştır.

:::warning
`string.hashCode` kullanmaktan kaçının çünkü farklı platformlar ve Dart sürümleri arasında kararlı olması garanti edilmez.
:::
