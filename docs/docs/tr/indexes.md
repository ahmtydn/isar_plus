---
title: İndeksler
---

# İndeksler

İndeksler, Isar'ın en güçlü özelliğidir. Birçok gömülü veritabanı "normal" indeksler sunar (eğer varsa), ancak Isar ayrıca bileşik ve çoklu girişli indekslere de sahiptir. İndekslerin nasıl çalıştığını anlamak, sorgu performansını optimize etmek için esastır. Isar, hangi indeksi kullanmak istediğinizi ve onu nasıl kullanmak istediğinizi seçmenize olanak tanır. İndekslerin ne olduğuna dair hızlı bir girişle başlayacağız.

## İndeksler Nedir?

Bir koleksiyon indekslenmediğinde, satırların sırası muhtemelen sorgu tarafından herhangi bir şekilde optimize edilmiş olarak ayırt edilemez ve bu nedenle sorgunuz nesneleri doğrusal olarak araması gerekir. Başka bir deyişle, sorgu koşulları karşılayan nesneleri bulmak için her nesneyi araması gerekir. Tahmin edebileceğiniz gibi, bu biraz zaman alabilir. Her tek nesneye bakmak çok verimli değildir.

Örneğin, bu `Product` koleksiyonu tamamen sırasızdır.

```dart
@collection
class Product {
  Id? id;

  late String name;

  late int price;
}
```

**Veri:**

| id  | name      | price |
| --- | --------- | ----- |
| 1   | Kitap     | 15    |
| 2   | Masa      | 55    |
| 3   | Sandalye  | 25    |
| 4   | Kalem     | 3     |
| 5   | Ampul     | 12    |
| 6   | Halı      | 60    |
| 7   | Yastık    | 30    |
| 8   | Bilgisayar| 650   |
| 9   | Sabun     | 2     |

€30'dan fazla maliyeti olan tüm ürünleri bulmaya çalışan bir sorgu, dokuz satırın tamamını araması gerekir. Dokuz satır için bu bir sorun değil, ancak 100 bin satır için bir sorun olabilir.

```dart
final expensiveProducts = await isar.products.filter()
  .priceGreaterThan(30)
  .findAll();
```

Bu sorgunun performansını artırmak için `price` özelliğini indeksleriz. Bir indeks, sıralanmış bir arama tablosu gibidir:

```dart
@collection
class Product {
  Id? id;

  late String name;

  @Index()
  late int price;
}
```

**İndekslenmiş veri:**

| price                | id       |
| -------------------- | -------- |
| 2                    | 9        |
| 3                    | 4        |
| 12                   | 5        |
| 15                   | 1        |
| 25                   | 3        |
| 30                   | 7        |
| 55                   | 2        |
| 60                   | 6        |
| 650                  | 8        |

Şimdi sorgu çok daha hızlı çalışabilir. Yürütücü doğrudan indeksin son satırlarına atlayabilir ve ilgili nesneleri id'lerine göre bulabilir.

### İndeksleri Sıralama İçin Kullanma

İndekslerin bir başka harika özelliği de, süper hızlı sıralama sunmalarıdır. Sıralanmış sorgular pahalıdır, özellikle çok sayıda nesne üzerinde sıralama yapmak istiyorsanız. Önceki örnekte yer alan `price` indeksini yeniden kullanırsanız, ücretsiz sıralama elde edersiniz:

```dart
final sortedProducts = await isar.products.where()
  .anyPrice()
  .findAll();
```

### Bileşik İndeksler

Bileşik indeks, birden fazla özelliğin değerine dayanan bir indekstir. Isar, herhangi bir bileşik indeksin herhangi bir önekini kullanmanıza izin verir.

```dart
@collection
class Person {
  Id? id;

  late String firstName;

  late String lastName;

  @Index(composite: [CompositeIndex('lastName')])
  late int age;
}
```

Bu indeks, yaş ve soyad özelliklerini içerir. Aşağıdaki sorgular indeksi kullanabilir:

```dart
// yaş indeksi kullanılır
final people = await isar.persons.where()
  .ageEqualTo(25)
  .findAll();

// yaş ve soyadı indeksi kullanılır
final people = await isar.persons.where()
  .ageEqualTo(25)
  .lastNameStartsWith('M')
  .findAll();
```

Aşağıdaki sorgu indeksi KULLANAMAZ:

```dart
// sadece soyadı indeksi kullanılamaz
final people = await isar.persons.where()
  .lastNameStartsWith('M')
  .findAll();
```

Bir bileşik indeks birden fazla özellik içeriyorsa, indeksin boyutu artar. Yalnızca sorgu performansını gerçekten artıracak bileşik indeksler oluşturmayı deneyin.

### Çoklu Girişli İndeksler

Listeleri indekslemek istiyorsanız, çoklu girişli indeksler kullanabilirsiniz. Bu, listenin her öğesinin indeksleneceği anlamına gelir.

```dart
@collection
class Product {
  Id? id;

  late String name;

  @Index()
  List<String>? tags;
}
```

Listeler yalnızca String türündeki değerleri içermelidir. Çoklu girişli indeksler, bir listenin belirli bir öğeyi içerip içermediğini kontrol etmek için kullanışlıdır:

```dart
final products = await isar.products.where()
  .tagsElementEqualTo('electronic')
  .findAll();
```

### Benzersiz İndeksler

Benzersiz bir indeks, indekslenen özelliğin yinelenen değerlere sahip olmamasını sağlar. Bir benzersiz indeks tek veya bileşik olabilir. Benzersiz bir indeks bir `null` değerine sahipse, yalnızca bir nesne `null` değerine sahip olabilir.

```dart
@collection
class User {
  Id? id;

  @Index(unique: true)
  late String username;

  late int age;
}
```

Mevcut bir indeks değerini eklemek veya güncellemek için herhangi bir girişim bir hatayla sonuçlanır:

```dart
final user1 = User()
  ..id = 1
  ..username = 'user1'
  ..age = 25;

await isar.users.put(user1); // -> ok

final user2 = User()
  ..id = 2
  ..username = 'user1'
  ..age = 30;

// kullanıcı adı zaten mevcut olduğu için hatayla sonuçlanır
await isar.users.put(user2);
```

### Büyük/Küçük Harf Duyarlı Olmayan İndeksler

Tüm indeksler ve where cümleleri varsayılan olarak büyük/küçük harf duyarlıdır. Büyük/küçük harf duyarlı olmayan bir indeks oluşturmak istiyorsanız, `caseSensitive` seçeneğini kullanabilirsiniz:

```dart
@collection
class Person {
  Id? id;

  @Index(caseSensitive: false)
  late String name;

  late int age;
}
```

## İndeks Türleri

İndeksler için farklı türler vardır. Çoğu zaman `IndexType.value` kullanmak isteyeceksiniz, ancak hash indeksleri daha verimlidir.

### Değer İndeksleri

Değer indeksleri, sayılar, String'ler, DateTime ve boolean gibi değerler için olan varsayılan türdür. Dizinli değerleri sıralamak ve karşılaştırmak için kullanılır.

### Hash İndeksleri

String ve listeler hash indekleri kullanabilir. Hash indeksleri, değer indekslerinden çok daha verimlidir ancak eşitlik kontrollerini desteklemez. Hash indeksleri önek aramaları veya sıralama için kullanılamaz.

```dart
@collection
class Person {
  Id? id;

  @Index(type: IndexType.hash)
  late String name;

  late int age;
}
```

### Büyük/Küçük Harf Duyarlı Olmayan Hash İndeksleri

Hash indekslerinin büyük/küçük harf duyarlı olmayan bir versiyonu da vardır:

```dart
@collection
class Person {
  Id? id;

  @Index(type: IndexType.hashElements, caseSensitive: false)
  List<String>? tags;
}
```
