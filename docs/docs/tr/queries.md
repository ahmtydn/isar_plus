---
title: Sorgular
---

# Sorgular

Sorgulama, belirli koşulları karşılayan kayıtları bulmanın yoludur, örneğin:

- Tüm yıldızlı kişileri bulma
- Kişilerdeki farklı adları bulma
- Soyadı tanımlanmamış tüm kişileri silme

Sorgular Dart'ta değil veritabanında yürütüldüğü için gerçekten hızlıdırlar. İndeksleri akıllıca kullandığınızda, sorgu performansını daha da artırabilirsiniz. Aşağıda, sorguları nasıl yazacağınızı ve bunları mümkün olduğunca hızlı nasıl yapabileceğinizi öğreneceksiniz.

Kayıtlarınızı filtrelemenin iki farklı yöntemi vardır: Filtreler ve where cümleleri. Önce filtrelerin nasıl çalıştığına bakalım.

## Filtreler

Filtreler kullanımı kolay ve anlaşılırdır. Özelliklerinizin türüne bağlı olarak, çoğu kendini açıklayan adlara sahip farklı filtre işlemleri mevcuttur.

Filtreler, filtrelenen koleksiyondaki her nesne için bir ifadeyi değerlendirerek çalışır. İfade `true` olarak çözülürse, Isar nesneyi sonuçlara dahil eder. Filtreler sonuçların sıralamasını etkilemez.

Aşağıdaki örnekler için aşağıdaki modeli kullanacağız:

```dart
@collection
class Shoe {
  Id? id;

  int? size;

  late String model;

  late bool isUnisex;
}
```

### Sorgu Koşulları

Alan türüne bağlı olarak, farklı koşullar mevcuttur.

| Koşul                    | Açıklama                                                                                                                                        |
| ------------------------ | ----------------------------------------------------------------------------------------------------------------------------------------------- |
| `.equalTo(value)`        | Belirtilen `value` değerine eşit olan değerlerle eşleşir.                                                                                      |
| `.between(lower, upper)` | `lower` ve `upper` arasındaki değerlerle eşleşir.                                                                                              |
| `.greaterThan(bound)`    | `bound` değerinden büyük değerlerle eşleşir.                                                                                                   |
| `.lessThan(bound)`       | `bound` değerinden küçük değerlerle eşleşir. `null` değerler varsayılan olarak dahil edilir çünkü `null` diğer herhangi bir değerden daha küçük kabul edilir. |
| `.isNull()`              | `null` olan değerlerle eşleşir.                                                                                                                |
| `.isNotNull()`           | `null` olmayan değerlerle eşleşir.                                                                                                             |
| `.length()`              | Liste, String ve bağlantı uzunluğu sorguları, bir liste veya bağlantıdaki eleman sayısına göre nesneleri filtreler.                            |

Veritabanının 39, 40, 46 numaralı ve bir de ayarlanmamış (`null`) numaralı dört ayakkabı içerdiğini varsayalım. Sıralama yapmadığınız sürece, değerler id'ye göre sıralanmış olarak döndürülür.

```dart
isar.shoes.filter()
  .sizeLessThan(40)
  .findAll() // -> [39, null]

isar.shoes.filter()
  .sizeLessThan(40, include: true)
  .findAll() // -> [39, null, 40]

isar.shoes.filter()
  .sizeBetween(39, 46, includeLower: false)
  .findAll() // -> [40, 46]
```

### Mantıksal Operatörler

Aşağıdaki mantıksal operatörleri kullanarak yüklemleri birleştirebilirsiniz:

| Operatör   | Açıklama                                                                         |
| ---------- | -------------------------------------------------------------------------------- |
| `.and()`   | Sol ve sağ ifadelerin her ikisi de `true` olarak değerlendirilirse `true` döner. |
| `.or()`    | İfadelerden biri `true` olarak değerlendirilirse `true` döner.                   |
| `.xor()`   | Tam olarak bir ifade `true` olarak değerlendirilirse `true` döner.               |
| `.not()`   | Aşağıdaki ifadenin sonucunu olumsuzlar.                                          |
| `.group()` | Koşulları gruplandırın ve değerlendirme sırasını belirtmeye izin verin.         |

46 numara ayakkabıları bulmak istiyorsanız, aşağıdaki sorguyu kullanabilirsiniz:

```dart
final result = await isar.shoes.filter()
  .sizeEqualTo(46)
  .findAll();
```

Birden fazla koşul kullanmak istiyorsanız, mantıksal **and** `.and()`, mantıksal **or** `.or()` ve mantıksal **xor** `.xor()` kullanarak birden fazla filtreyi birleştirebilirsiniz.

```dart
final result = await isar.shoes.filter()
  .sizeEqualTo(46)
  .and() // İsteğe bağlı. Filtreler örtük olarak mantıksal and ile birleştirilir.
  .isUnisexEqualTo(true)
  .findAll();
```

Bu sorgu şuna eşdeğerdir: `size == 46 && isUnisex == true`.

Mantıksal **or** kullanmak istiyorsanız, filtreleri `.or()` ile sarmalayın:

```dart
final result = await isar.shoes.filter()
  .sizeEqualTo(46)
  .or()
  .isUnisexEqualTo(true)
  .findAll();
```

Bu sorgu şuna eşdeğerdir: `size == 46 || isUnisex == true`.

### String Koşulları

Ayrıca, daha gelişmiş string filtreleme için birkaç ek koşul vardır. Joker karakterler gibi regex ifadeleri harika işe yarar ancak kullanımı zor ve anlaşılması kötü olabilir.

| Koşul            | Açıklama                                                                             |
| ---------------- | ------------------------------------------------------------------------------------ |
| `.startsWith()`  | Belirtilen alt dizeyle başlayan değerleri eşleştirir.                               |
| `.contains()`    | Belirtilen alt dizeyi içeren değerleri eşleştirir.                                  |
| `.endsWith()`    | Belirtilen alt dizeyle biten değerleri eşleştirir.                                  |
| `.matches()`     | Belirtilen joker kalıbıyla eşleşen değerleri bulur. Joker karakterler `*` ve `?`'dır. |

**Büyük/küçük harf duyarlılığı**  
Tüm string işlemleri, büyük/küçük harf duyarlı bir seçeneğe sahiptir. Bu varsayılan olarak etkindir.

```dart
final result = await isar.shoes.filter()
  .modelStartsWith('Nike', caseSensitive: false)
  .findAll();
```

**Joker karakterler**  
Joker karakterler kullanmayı tercih ediyorsanız, `*` karakteri sıfır veya daha fazla karakterle, `?` ise tek bir karakterle eşleşir.

```dart
final result = await isar.shoes.filter()
  .modelMatches('*Nike*')
  .findAll();
```

### Sorgu Değiştiriciler

Bazen belirli bir koşulla nesneleri sıralamanız veya yalnızca bir alt küme döndürmeniz gerekir. Bunun için sorgu değiştiricileri vardır:

| Değiştirici              | Açıklama                                                                                |
| ------------------------ | --------------------------------------------------------------------------------------- |
| `.sortBy(property)`      | Sonuçları artan sırada belirtilen özelliğe göre sıralar.                               |
| `.sortByDesc(property)`  | Sonuçları azalan sırada belirtilen özelliğe göre sıralar.                              |
| `.distinctBy(property)`  | Sonuçlardan belirtilen özellik için yinelenen değerleri kaldırır.                      |
| `.offset(value)`         | İlk `value` kadar sonucu atlar.                                                         |
| `.limit(value)`          | En fazla `value` kadar sonuç döndürür.                                                  |
| `.property()`            | Yalnızca belirli bir özelliği seçin. İsteğe bağlı olarak birden fazla özellik seçebilirsiniz. |

Sonuç listesini yalnızca ilk 10 `Shoe` ile sınırlamak istiyorsak şunu kullanabiliriz:

```dart
final result = await isar.shoes.filter()
  .limit(10)
  .findAll();
```

### Where cümleleri

Where cümleleri çok güçlü bir araçtır ancak biraz daha karmaşıktır. Where cümleleri, bir indeks kullanarak bir filtre oluşturmanın bir yoludur. Veritabanınızın çoğunda yüzlerce veya binlerce kayıt olduğunda, filtreleme çok yavaş olabilir. İndeksleri sorgulamak, bir filtre koşuluna karşılık gelen kayıtları hızlı bir şekilde bulmak için kullanılabilir.

:::tip
Temel kural olarak, where cümleleri ile mümkün olduğunca çok sonucu azaltmaya çalışmalı ve kalan filtreleme için filtreleri kullanmalısınız.
:::

İndeksler kullanmadan yalnızca `.filter()` kullanabilirsiniz ancak where cümleleri bir indeks kullanmanın faydalarından yararlanmanıza olanak tanır.

Birincil indeks, `Id` alanıdır. Her koleksiyon varsayılan olarak bir birincil indekse sahiptir. `where()` indekslenmiş bir özellik belirtmediğinde, birincil indeks kullanılır.

```dart
final result = await isar.shoes.where()
  .findAll();
```

Bunu şu şekilde okuyabiliriz: "Tüm nesneleri ID'ye göre döndür". Varsayılan olarak, nesneler artan sırada döndürülür.

Çoğu zaman manuel olarak bir where cümlesi oluşturmanıza gerek yoktur. Bunun yerine, Isar size QueryBuilder kullanmanıza olanak tanır - indeksler kullanarak where cümleleri oluşturmanın kolay bir yolu.

`.filter()` kullanırken kayıtlar id'ye göre döndürülür. Bunun yerine onları örneğin boyuta göre döndürmek isteyebilirsiniz. Where cümleleriyle bunu yapabilirsiniz:

```dart
final result = await isar.shoes.where()
  .sizeEqualTo(42)
  .findAll();
```

Where cümleleri çok hızlıdır ancak her özellik bir indekse sahip değildir. Size özelliği için nasıl bir indeks oluşturacağınızı öğrenmek için [İndeksler](indexes) bölümünü okuyun.

Ek bir avantaj, sonuçlarınızı sıralamayı alırsınız. Veritabanınızda bir dizi indekslenmiş kayıt varsa, bu büyük bir performans artışı sağlar çünkü veritabanının tüm kayıtları döndürmesi ve ardından bellekte sıralaması gerekmez.

:::warning
Yalnızca where cümlelerini AND ile birleştirebilirsiniz. Başka bir deyişle, tek bir indeksin birden fazla koşulu için where cümleleri alamazsınız.
:::

## Sonuçları İşleme

Bir sorguyu yürüttükten sonra, sonuçları almanın birkaç yöntemi vardır:

| Yöntem              | Açıklama                                                                        |
| ------------------- | ------------------------------------------------------------------------------- |
| `.findFirst()`      | Yalnızca ilk eşleşen nesneyi alın veya eşleşme yoksa `null`.                   |
| `.findAll()`        | Tüm eşleşen nesneleri alın.                                                     |
| `.count()`          | Kaç nesnenin sorguyla eşleştiğini sayın.                                       |
| `.deleteFirst()`    | Veritabanından ilk eşleşen nesneyi silin.                                      |
| `.deleteAll()`      | Veritabanından tüm eşleşen nesneleri silin.                                    |
| `.build()`          | Sorguyu daha sonra yeniden kullanmak üzere derleyin.                           |

### Nesneleri Alma

`.findAll()` kullanarak tüm eşleşen nesneleri alabilirsiniz:

```dart
final shoes = await isar.shoes.filter()
  .sizeEqualTo(42)
  .findAll();
```

Yalnızca ilk nesneyi almak istiyorsanız `.findFirst()` kullanın:

```dart
final shoe = await isar.shoes.filter()
  .sizeEqualTo(42)
  .findFirst();
```

### Nesneleri Silme

Bir sorguyla eşleşen nesneleri silmek istiyorsanız, `.deleteFirst()` veya `.deleteAll()` kullanın:

```dart
final count = await isar.shoes.filter()
  .sizeEqualTo(42)
  .deleteAll();
```

### Özellikleri İzleme

Bir sorguyu izlemek istiyorsanız, `.watch()` kullanın. Bu, sonuçlar her değiştiğinde size bir bildirim gönderir:

```dart
Stream<List<Shoe>> shoes = isar.shoes.where()
  .sizeEqualTo(42)
  .watch(fireImmediately: true);
```

### Sorgu Performansı

Isar hızlıdır. Ancak, sorgu performansını daha da artırabilirsiniz:

1. Where cümleleri ve indeksler kullanın
2. Mümkün olduğunca filtreleri azaltın  
3. Özellik seçicileri ile yalnızca ihtiyacınız olan verileri alın
4. Büyük sorgular için sonuçları sayfalandırın

Çok sayıda nesne döndüren sorgularda dikkatli olun. Bunun yerine sorguyu sınırlamayı düşünün.
