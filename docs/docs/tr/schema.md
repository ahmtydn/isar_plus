---
title: Şema
---

# Şema

Uygulamanızın verilerini saklamak için Isar kullandığınızda, koleksiyonlarla çalışırsınız. Bir koleksiyon, ilişkili Isar veritabanındaki bir veritabanı tablosu gibidir ve yalnızca tek bir Dart nesne türü içerebilir. Her koleksiyon nesnesi, ilgili koleksiyondaki bir veri satırını temsil eder.

Bir koleksiyon tanımına "şema" denir. Isar Generator sizin için ağır işi yapacak ve koleksiyonu kullanmak için ihtiyacınız olan kodun çoğunu oluşturacaktır.

## Bir Koleksiyonun Anatomisi

Her Isar koleksiyonunu `@collection` veya `@Collection()` ile bir sınıfı işaretleyerek tanımlarsınız. Bir Isar koleksiyonu, birincil anahtarı içeren bir sütun dahil olmak üzere veritabanındaki ilgili tablodaki her sütun için alanlar içerir.

Aşağıdaki kod, ID, ad ve soyadı için sütunlarla bir `User` tablosu tanımlayan basit bir koleksiyon örneğidir:

```dart
@collection
class User {
  Id? id;

  String? firstName;

  String? lastName;
}
```

:::tip
Bir alanı kalıcı hale getirmek için Isar'ın ona erişimi olmalıdır. Bir alana Isar'ın erişimini, onu genel yaparak veya getter ve setter yöntemleri sağlayarak sağlayabilirsiniz.
:::

Koleksiyonu özelleştirmek için birkaç isteğe bağlı parametre vardır:

| Yapılandırma | Açıklama                                                                                                      |
| ------------ | ------------------------------------------------------------------------------------------------------------- |
| `inheritance` | Üst sınıfların ve mixin'lerin alanlarının Isar'da saklanıp saklanmayacağını kontrol eder. Varsayılan olarak etkindir. |
| `accessor`    | Varsayılan koleksiyon erişimcisini yeniden adlandırmanıza olanak tanır (örneğin `Contact` koleksiyonu için `isar.contacts`). |
| `ignore`      | Belirli özellikleri yok saymanıza olanak tanır. Bunlar üst sınıflar için de geçerlidir.                      |

### Isar Id

Her koleksiyon sınıfı, bir nesneyi benzersiz şekilde tanımlayan `Id` türünde bir id özelliği tanımlamalıdır. `Id`, Isar Generator'ın id özelliğini tanımasını sağlayan `int` için sadece bir takma addır.

Isar, id alanlarını otomatik olarak indeksler, bu da nesneleri id'lerine göre verimli bir şekilde almanıza ve değiştirmenize olanak tanır.

Id'leri kendiniz ayarlayabilir veya Isar'dan otomatik artan bir id atamasını isteyebilirsiniz. `id` alanı `null` ve `final` değilse, Isar otomatik artan bir id atayacaktır. Null olmayan bir otomatik artan id istiyorsanız, `null` yerine `Isar.autoIncrement` kullanabilirsiniz.

:::tip
Bir nesne silindiğinde otomatik artan id'ler yeniden kullanılmaz. Otomatik artan id'leri sıfırlamanın tek yolu veritabanını temizlemektir.
:::

### Koleksiyonları ve Alanları Yeniden Adlandırma

Varsayılan olarak, Isar koleksiyon adı olarak sınıf adını kullanır. Benzer şekilde, Isar veritabanındaki sütun adları olarak alan adlarını kullanır. Bir koleksiyonun veya alanın farklı bir adı olmasını istiyorsanız, `@Name` açıklamasını ekleyin. Aşağıdaki örnek, koleksiyon ve alanlar için özel adları gösterir:

```dart
@collection
@Name("User")
class MyUserClass1 {

  @Name("id")
  Id myObjectId;

  @Name("firstName")
  String theFirstName;

  @Name("lastName")
  String familyNameOrWhatever;
}
```

Özellikle veritabanında zaten saklanan Dart alanlarını veya sınıflarını yeniden adlandırmak istiyorsanız, `@Name` açıklamasını kullanmayı düşünmelisiniz. Aksi takdirde, veritabanı alanı veya koleksiyonu silip yeniden oluşturacaktır.

### Alanları Yok Sayma

Isar, bir koleksiyon sınıfının tüm genel alanlarını kalıcı hale getirir. Bir özelliği veya getter'ı `@ignore` ile işaretleyerek, aşağıdaki kod parçacığında gösterildiği gibi onu kalıcılıktan hariç tutabilirsiniz:

```dart
@collection
class User {
  Id? id;

  String? firstName;

  String? lastName;

  @ignore
  String? password;
}
```

Bir koleksiyonun üst koleksiyondan alanları miras aldığı durumlarda, genellikle `@Collection` açıklamasının `ignore` özelliğini kullanmak daha kolaydır:

```dart
@collection
class User {
  Image? profilePicture;
}

@Collection(ignore: {'profilePicture'})
class Member extends User {
  Id? id;

  String? firstName;

  String? lastName;
}
```

Bir koleksiyon, Isar tarafından desteklenmeyen bir türde bir alan içeriyorsa, alanı yok saymanız gerekir.

:::warning
Isar nesnelerinde kalıcı olmayan bilgileri saklamanın iyi bir uygulama olmadığını unutmayın.
:::

## Desteklenen Türler

Isar aşağıdaki veri türlerini destekler:

- `bool`
- `byte`
- `short`
- `int`
- `float`
- `double`
- `DateTime`
- `String`
- `List<bool>`
- `List<byte>`
- `List<short>`
- `List<int>`
- `List<float>`
- `List<double>`
- `List<DateTime>`
- `List<String>`

Ek olarak, gömülü nesneler ve enum'lar desteklenir. Bunları aşağıda ele alacağız.

## byte, short, float

Birçok kullanım durumu için, 64 bitlik bir tamsayı veya double'ın tam aralığına ihtiyacınız yoktur. Isar, daha küçük sayıları saklarken alan ve bellek tasarrufu yapmanıza olanak tanıyan ek türleri destekler.

| Tür        | Bayt Cinsinden Boyut | Aralık                                                  |
| ---------- | -------------------- | ------------------------------------------------------- |
| **byte**   | 1                    | 0 ile 255                                               |
| **short**  | 4                    | -2,147,483,647 ile 2,147,483,647                        |
| **int**    | 8                    | -9,223,372,036,854,775,807 ile 9,223,372,036,854,775,807 |
| **float**  | 4                    | -3.4e38 ile 3.4e38                                      |
| **double** | 8                    | -1.7e308 ile 1.7e308                                    |

Ek sayı türleri, yerel Dart türleri için sadece takma adlardır, bu nedenle örneğin `short` kullanmak, `int` kullanmakla aynı şekilde çalışır.

İşte yukarıdaki türlerin tümünü içeren örnek bir koleksiyon:

```dart
@collection
class TestCollection {
  Id? id;

  late byte byteValue;

  short? shortValue;

  int? intValue;

  float? floatValue;

  double? doubleValue;
}
```

Tüm sayı türleri listelerde de kullanılabilir. Baytları saklamak için `List<byte>` kullanmalısınız.

## Null Olabilen Türler

Isar'da null olabilirliğin nasıl çalıştığını anlamak önemlidir: Sayı türlerinin özel bir `null` temsili **YOKTUR**. Bunun yerine, belirli bir değer kullanılır:

| Tür        | VM            |
| ---------- | ------------- |
| **short**  | `-2147483648` |
| **int**    |  `int.MIN`    |
| **float**  | `double.NaN`  |
| **double** |  `double.NaN` |

`bool`, `String` ve `List` ayrı bir `null` temsiline sahiptir.

Bu davranış, performans iyileştirmelerini mümkün kılar ve alanlarınızın null olabilirliğini, geçiş veya `null` değerlerini işlemek için özel kod gerektirmeden özgürce değiştirmenize olanak tanır.

:::warning
`byte` türü null değerleri desteklemez.
:::

## DateTime

Isar, tarihlerinizin saat dilimi bilgilerini saklamaz. Bunun yerine, `DateTime`'ları saklamadan önce UTC'ye dönüştürür. Isar, tüm tarihleri yerel saatte döndürür.

`DateTime`'lar mikrosaniye hassasiyetiyle saklanır. Tarayıcılarda, JavaScript sınırlamaları nedeniyle yalnızca milisaniye hassasiyeti desteklenir.

## Enum

Isar, enum'ları diğer Isar türleri gibi saklamanıza ve kullanmanıza olanak tanır. Ancak, Isar'ın enum'u diskte nasıl temsil etmesi gerektiğini seçmeniz gerekir. Isar dört farklı stratejiyi destekler:

| EnumType    | Açıklama                                                                                         |
| ----------- | ------------------------------------------------------------------------------------------------ |
| `ordinal`   | Enum'un indeksi `byte` olarak saklanır. Bu çok verimlidir ancak null olabilen enum'lara izin vermez |
| `ordinal32` | Enum'un indeksi `short` (4 baytlık tamsayı) olarak saklanır.                                    |
| `name`      | Enum adı `String` olarak saklanır.                                                              |
| `value`     | Enum değerini almak için özel bir özellik kullanılır.                                           |

:::warning
`ordinal` ve `ordinal32`, enum değerlerinin sırasına bağlıdır. Sırayı değiştirirseniz, mevcut veritabanları yanlış değerler döndürecektir.
:::

Her strateji için bir örneğe bakalım.

```dart
@collection
class EnumCollection {
  Id? id;

  @enumerated // EnumType.ordinal ile aynı
  late TestEnum byteIndex; // null olamaz

  @Enumerated(EnumType.ordinal)
  late TestEnum byteIndex2; // null olamaz

  @Enumerated(EnumType.ordinal32)
  TestEnum? shortIndex;

  @Enumerated(EnumType.name)
  TestEnum? name;

  @Enumerated(EnumType.value, 'myValue')
  TestEnum? myValue;
}

enum TestEnum {
  first(10),
  second(100),
  third(1000);

  const TestEnum(this.myValue);

  final short myValue;
}
```

Tabii ki, Enum'lar listelerde de kullanılabilir.

## Gömülü Nesneler

Koleksiyon modelinizde iç içe nesnelere sahip olmak genellikle yararlıdır. Nesneleri ne kadar derine iç içe koyabileceğinizin bir sınırı yoktur. Ancak, derin iç içe bir nesneyi güncellemenin, tüm nesne ağacını veritabanına yazmayı gerektireceğini unutmayın.

```dart
@collection
class Email {
  Id? id;

  String? title;

  Recepient? recipient;
}

@embedded
class Recepient {
  String? name;

  String? address;
}
```

Gömülü nesneler null olabilir ve diğer nesneleri genişletebilir. Tek gereklilik, `@embedded` ile işaretlenmeleri ve gerekli parametreler olmadan bir varsayılan yapıcıya sahip olmalarıdır.
