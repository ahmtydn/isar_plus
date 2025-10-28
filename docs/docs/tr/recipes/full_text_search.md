---
title: Tam Metin Arama
---

# Tam Metin Arama

Tam metin arama, veritabanında metin aramak için güçlü bir yoldur. [İndekslerin](/indexes) nasıl çalıştığını zaten biliyor olmalısınız, ancak temel bilgileri gözden geçirelim.

Bir indeks, arama tablosu gibi çalışır ve sorgu motorunun belirli bir değere sahip kayıtları hızlı bir şekilde bulmasını sağlar. Örneğin, nesnenizde bir `title` alanınız varsa, belirli bir başlığa sahip nesneleri bulmayı daha hızlı hale getirmek için bu alan üzerinde bir indeks oluşturabilirsiniz.

## Tam metin arama neden kullanışlıdır?

Filtreleri kullanarak metni kolayca arayabilirsiniz. Örneğin `.startsWith()`, `.contains()` ve `.matches()` gibi çeşitli string işlemleri vardır. Filtrelerin sorunu, çalışma sürelerinin `O(n)` olmasıdır, burada `n` koleksiyondaki kayıt sayısıdır. `.matches()` gibi string işlemleri özellikle pahalıdır.

:::tip
Tam metin arama filtrelerden çok daha hızlıdır, ancak indekslerin bazı sınırlamaları vardır. Bu tarifde, bu sınırlamaları aşmanın yollarını keşfedeceğiz.
:::

## Temel Örnek

Fikir her zaman aynıdır: Tüm metni indekslemek yerine, metindeki kelimeleri indeksleriz, böylece bunları ayrı ayrı arayabiliriz.

En temel tam metin indeksini oluşturalım:

```dart
class Message {
  Id? id;

  late String content;

  @Index()
  List<String> get contentWords => content.split(' ');
}
```

Artık içeriğinde belirli kelimeler olan mesajları arayabiliriz:

```dart
final posts = await isar.messages
  .where()
  .contentWordsAnyEqualTo('merhaba')
  .findAll();
```

Bu sorgu süper hızlıdır, ancak bazı sorunlar vardır:

1. Yalnızca tam kelimeleri arayabiliriz
2. Noktalama işaretlerini dikkate almıyoruz
3. Diğer boşluk karakterlerini desteklemiyoruz

## Metni Doğru Şekilde Bölme

Önceki örneği geliştirmeye çalışalım. Kelime bölmeyi düzeltmek için karmaşık bir regex geliştirmeyi deneyebiliriz, ancak bu muhtemelen yavaş olacak ve uç durumlar için yanlış olacaktır.

[Unicode Annex #29](https://unicode.org/reports/tr29/), metni neredeyse tüm diller için kelimelere doğru şekilde nasıl böleceğini tanımlar. Oldukça karmaşıktır, ancak neyse ki Isar bizim için ağır işi yapar:

```dart
Isar.splitWords('merhaba dünya'); // -> ['merhaba', 'dünya']

Isar.splitWords('Hızlı ("kahverengi") tilki 32,3 feet atlayamaz, değil mi?');
// -> ['Hızlı', 'kahverengi', 'tilki', '32.3', 'feet', 'atlayamaz', 'değil', 'mi']
```

## Daha Fazla Kontrol İstiyorum

Çok kolay! İndeksimizi önek eşleştirme ve büyük/küçük harf duyarsız eşleştirmeyi destekleyecek şekilde de değiştirebiliriz:

```dart
class Post {
  Id? id;

  late String title;

  @Index(type: IndexType.value, caseSensitive: false)
  List<String> get titleWords => title.split(' ');
}
```

Varsayılan olarak, Isar kelimeleri hızlı ve alan verimli olan hash değerleri olarak saklar. Ancak hash'ler önek eşleştirme için kullanılamaz. `IndexType.value` kullanarak, indeksi kelimeleri doğrudan kullanacak şekilde değiştirebiliriz. Bu bize `.titleWordsAnyStartsWith()` where cümlesini verir:

```dart
final posts = await isar.posts
  .where()
  .titleWordsAnyStartsWith('mer')
  .or()
  .titleWordsAnyStartsWith('hoş')
  .or()
  .titleWordsAnyStartsWith('nasl')
  .findAll();
```

## `.endsWith()` de İhtiyacım Var

Tabii ki! `.endsWith()` eşleştirmesini başarmak için bir hile kullanacağız:

```dart
class Post {
    Id? id;

    late String title;

    @Index(type: IndexType.value, caseSensitive: false)
    List<String> get revTitleWords {
        return Isar.splitWords(title).map(
          (word) => word.split('').reversed.join()).toList()
        );
    }
}
```

Aramak istediğiniz sonu tersine çevirmeyi unutmayın:

```dart
final posts = await isar.posts
  .where()
  .revTitleWordsAnyStartsWith('geldin'.split('').reversed.join())
  .findAll();
```

## Köklendirme Algoritmaları

Ne yazık ki, indeksler `.contains()` eşleştirmesini desteklemez (bu diğer veritabanları için de geçerlidir). Ancak keşfetmeye değer birkaç alternatif vardır. Seçim büyük ölçüde kullanımınıza bağlıdır. Bir örnek, tüm kelime yerine kelime köklerini indekslemektir.

Bir köklendirme algoritması, bir kelimenin varyant formlarının ortak bir forma indirgendiği dilsel normalleştirme sürecidir:

```
bağlantı
bağlantılar
bağlayıcı          --->   bağla
bağlı
bağlanıyor
```

Popüler algoritmalar [Porter köklendirme algoritması](https://tartarus.org/martin/PorterStemmer/) ve [Snowball köklendirme algoritmaları](https://snowballstem.org/algorithms/)'dır.

Ayrıca [lemmatization](https://en.wikipedia.org/wiki/Lemmatisation) gibi daha gelişmiş formlar da vardır.

## Fonetik Algoritmalar

Bir [fonetik algoritma](https://en.wikipedia.org/wiki/Phonetic_algorithm), kelimeleri telaffuzlarına göre indekslemek için bir algoritmadır. Başka bir deyişle, aradığınız kelimelere benzer şekilde seslenen kelimeleri bulmanıza olanak tanır.

:::warning
Çoğu fonetik algoritma yalnızca tek bir dili destekler.
:::

### Soundex

[Soundex](https://en.wikipedia.org/wiki/Soundex), isimleri İngilizce telaffuz edildiği şekilde sesleriyle indekslemek için bir fonetik algoritmadır. Amaç, homofonların aynı temsile kodlanması ve yazımdaki küçük farklılıklara rağmen eşleştirilmeleridir. Basit bir algoritmadır ve birden fazla geliştirilmiş versiyonu vardır.

Bu algoritma kullanılarak, hem `"Robert"` hem de `"Rupert"` `"R163"` dizesini döndürürken `"Rubin"` `"R150"` verir. `"Ashcraft"` ve `"Ashcroft"` her ikisi de `"A261"` verir.

### Double Metaphone

[Double Metaphone](https://en.wikipedia.org/wiki/Metaphone) fonetik kodlama algoritması, bu algoritmanın ikinci nesldir. Orijinal Metaphone algoritmasına göre birkaç temel tasarım iyileştirmesi yapar.

Double Metaphone, Slav, Germen, Kelt, Yunan, Fransız, İtalyan, İspanyol, Çin ve diğer kökenli İngilizcedeki çeşitli düzensizlikleri hesaba katar.
