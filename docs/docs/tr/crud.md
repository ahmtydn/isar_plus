---
title: Oluştur, Oku, Güncelle, Sil
---

# Oluştur, Oku, Güncelle, Sil

Koleksiyonlarınızı tanımladığınızda, bunları nasıl değiştireceğinizi öğrenin!

## Isar'ı Açma

Herhangi bir şey yapmadan önce, bir Isar örneğine ihtiyacımız var. Her örnek, veritabanı dosyasının saklanabileceği yazma izni olan bir dizin gerektirir. Bir dizin belirtmezseniz, Isar mevcut platform için uygun bir varsayılan dizin bulacaktır.

Isar örneğiyle kullanmak istediğiniz tüm şemaları sağlayın. Birden fazla örnek açarsanız, her örneğe yine aynı şemaları sağlamanız gerekir.

```dart
final dir = await getApplicationDocumentsDirectory();
final isar = await Isar.open(
  [RecipeSchema],
  directory: dir.path,
);
```

Varsayılan yapılandırmayı kullanabilir veya aşağıdaki parametrelerden bazılarını sağlayabilirsiniz:

| Yapılandırma    | Açıklama                                                                                                                                                                                                                                                                                     |
| --------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `name`          | Farklı adlarla birden fazla örnek açın. Varsayılan olarak `"default"` kullanılır.                                                                                                                                                                                                           |
| `directory`     | Bu örnek için depolama konumu. Flutter Web'de OPFS/IndexedDB içindeki bir klasöre eşlenir (örneğin `isar_data`). Kasıtlı olarak geçici bir veritabanı istediğinizde `Isar.sqliteInMemory` kullanın.                                                                                        |
| `maxSizeMib`    | MiB cinsinden veritabanı dosyasının maksimum boyutu. Isar, sonsuz bir kaynak olmayan sanal bellek kullanır, bu nedenle buradaki değere dikkat edin. Birden fazla örnek açarsanız, kullanılabilir sanal belleği paylaşırlar, bu nedenle her örneğin daha küçük bir `maxSizeMib` değeri olmalıdır. Varsayılan 2048'dir. |
| `relaxedDurability` | Yazma performansını artırmak için dayanıklılık garantisini gevşetir. Bir sistem çökmesi durumunda (uygulama çökmesi değil), son işlem kaybedilebilir. Bozulma mümkün değildir                                                                                                               |
| `compactOnLaunch`   | Örnek açıldığında veritabanının sıkıştırılması gerekip gerekmediğini kontrol etmek için koşullar.                                                                                                                                                                                           |
| `inspector`     | Hata ayıklama derlemeleri için Inspector'ı etkinleştirir. Profil ve sürüm derlemeleri için bu seçenek yok sayılır.                                                                                                                                                                          |

Bir örnek zaten açıksa, `Isar.open()` çağrısı, belirtilen parametrelere bakılmaksızın mevcut örneği verir. Bu, Isar'ı bir izolasyonda kullanmak için yararlıdır.

:::tip
Tüm platformlarda geçerli bir yol almak için [path_provider](https://pub.dev/packages/path_provider) paketini kullanmayı düşünün.
:::

Veritabanı dosyasının depolama konumu `directory/name.isar`'dır

## Veritabanından Okuma

Isar'da belirli bir türdeki nesneleri bulmak, sorgulamak ve oluşturmak için `IsarCollection` örneklerini kullanın.

Aşağıdaki örnekler için, aşağıdaki gibi tanımlanmış bir `Recipe` koleksiyonumuz olduğunu varsayıyoruz:

```dart
@collection
class Recipe {
  Id? id;

  String? name;

  DateTime? lastCooked;

  bool? isFavorite;
}
```

### Bir Koleksiyon Alma

Tüm koleksiyonlarınız Isar örneğinde yaşar. Tarifler koleksiyonunu şununla alabilirsiniz:

```dart
final recipes = isar.recipes;
```

Bu kolaydı! Koleksiyon erişimcilerini kullanmak istemiyorsanız, `collection()` yöntemini de kullanabilirsiniz:

```dart
final recipes = isar.collection<Recipe>();
```

### Bir Nesne Alma (id'ye göre)

Henüz koleksiyonda verimiz yok ama varmış gibi yapalım ve `123` id'sine sahip hayali bir nesneyi alalım

```dart
final recipe = await isar.recipes.get(123);
```

`get()`, nesneyi veya yoksa `null` döndüren bir `Future` döndürür. Tüm Isar işlemleri varsayılan olarak asenkrondur ve çoğunun senkron bir karşılığı vardır:

```dart
final recipe = isar.recipes.getSync(123);
```

:::warning
UI izolasyonunuzda yöntemlerin asenkron sürümünü varsayılan olarak kullanmalısınız. Isar çok hızlı olduğundan, senkron sürümü kullanmak genellikle kabul edilebilir.
:::

Aynı anda birden fazla nesne almak istiyorsanız, `getAll()` veya `getAllSync()` kullanın:

```dart
final recipes = await isar.recipes.getAll([1, 2]);
```

### Nesneleri Sorgulama

Id'ye göre nesneleri almak yerine, `.where()` ve `.filter()` kullanarak belirli koşulları karşılayan nesnelerin bir listesini de sorgulayabilirsiniz:

```dart
final allRecipes = await isar.recipes.where().findAll();
```

:::warning
Varsayılan olarak Isar, tüm nesnelerinizi bellekte tutmaz. `findAll()` çağırdığınızda, veritabanından nesneleri okur. Nesneleri değiştirirseniz, değişiklikleri veritabanına geri yazmanız gerekir.
:::

## Veritabanına Yazma

Artık veritabanından okumayı öğrendiğinize göre, bazı veriler yazalım! Bir nesne oluşturmak, güncellemek ve silmek için Isar şu yöntemleri sunar: `put()`, `putAll()`, `delete()` ve `deleteAll()`. Tüm yazma işlemleri için `put` ve `delete` varyantları vardır.

```dart
final pancakes = Recipe()
  ..name = 'Pancakes'
  ..lastCooked = DateTime.now()
  ..isFavorite = true;

await isar.writeTxn(() async {
  await isar.recipes.put(pancakes); // id'yi atamak için put kullanın
});
```

:::tip
Bir yazma işleminde, id alanını okuyabilir veya yazabilirsiniz. Yazma işlemi taahhüt edildikten sonra, id ayarlanacak ve okuyabileceğiniz şekilde güncellenecektir.
:::

## Yazma İşlemleri

Veritabanı durumunun güvenliğini sağlamak ve çok sayıda değişikliği birlikte yapmanın performansını en üst düzeye çıkarmak için Isar işlemleri kullanır.

Isar'da iki tür işlem vardır:

### Okuma İşlemleri

Okuma işlemleri isteğe bağlıdır ancak birden fazla okuma işlemini bir araya getirmenize ve işlem sırasında veritabanının tutarlı bir anlık görüntüsünü elde etmenize olanak tanır. Açık okuma işlemleri dahili olarak yönetilir.

:::tip
Asenkron okuma işlemleri, diğer okuma ve yazma işlemleriyle paralel olarak çalışır. Harika performans!
:::

### Yazma İşlemleri

Veritabanının verilerini değiştirmeden önce bir yazma işlemi gerçekleştirmeniz gerekir.

Yazma işlemlerinin içinde, verilere olağan şekilde erişebilirsiniz. İşlem taahhüt edildiğinde, tüm değişiklikler bir kerede diske yazılır. Bir hata meydana gelirse, değişiklikler geri alınır ve veritabanı değişmeden kalır. İşlemler "hepsi veya hiçbiri" garantisi sağlar.

```dart
await isar.writeTxn(() async {
  final recipe = await isar.recipes.get(1);
  recipe.isFavorite = true;
  await isar.recipes.put(recipe); // önceki değerin üzerine yaz
});
```

:::warning
Bir yazma işleminde, nesneleri bellekte tutmalısınız. `get()` çağrısı yaparsanız, nesneleri değiştirmeden önce `writeTxn()` içinde yapmalısınız.
:::

## Nesneleri Ekleme

Bir nesneyi veritabanına eklemek için Isar'ın `put()` yöntemini kullanın. Nesne zaten mevcut değilse (id'ye göre) eklenecektir. Varsa, güncellenecektir.

Id alanı `null` veya `Isar.autoIncrement` ise, Isar otomatik artan bir id kullanacaktır.

```dart
final pancakes = Recipe()
  ..name = 'Pancakes'
  ..lastCooked = DateTime.now()
  ..isFavorite = true;

await isar.writeTxn(() async {
  await isar.recipes.put(pancakes);
});
```

Isar, id'yi otomatik olarak nesneye atar. Aynı anda birkaç nesne eklemek istiyorsanız, `putAll()` kullanın:

```dart
await isar.writeTxn(() async {
  await isar.recipes.putAll([pancakes, pizza]);
});
```

## Nesneleri Güncelleme

Hem oluşturma hem de güncelleme `put()` ile çalışır. Nesneyi id'ye göre bulur, varsa günceller. 

Bir nesneyi güncellemek istiyorsanız, birkaç seçeneğiniz vardır. İlk seçenek, nesneyi almak, değiştirmek ve geri koymaktır:

```dart
await isar.writeTxn(() async {
  final recipe = await isar.recipes.get(1);
  recipe?.isFavorite = true;
  await isar.recipes.put(recipe!);
});
```

Mevcut bir nesneyi güncelleyeceğinizden eminseniz, yeni bir nesne oluşturabilir ve aynı id'yi ayarlayabilirsiniz:

```dart
final recipe = Recipe()
  ..id = 1
  ..isFavorite = true;

await isar.writeTxn(() async {
  await isar.recipes.put(recipe);
});
```

:::warning
Bir nesneyi bu şekilde güncellediğinizde, ayarlamadığınız tüm alanlar üzerine yazılır veya `null` olarak ayarlanır. İkinci örnekte, tüm alanlar `null` (veya varsayılan değerleri) olacaktır, `id` ve `isFavorite` hariç.
:::

## Nesneleri Silme

Bir nesneyi veritabanından kaldırmak ister misiniz? `delete()` kullanın. Aynı anda birden fazla nesneyi silmek istiyorsanız, `deleteAll()` kullanın:

```dart
await isar.writeTxn(() async {
  final success = await isar.recipes.delete(1);
  // success = nesne silindi mi
});
```

Benzer şekilde, id'leri biliyorsanız, birden fazla nesneyi silebilirsiniz:

```dart
await isar.writeTxn(() async {
  final count = await isar.recipes.deleteAll([1, 2, 3]);
  // count = silinen nesnelerin sayısı
});
```

Bir sorgu kullanarak nesneleri silmek istiyorsanız, `deleteFirst()` veya `deleteAll()` kullanın:

```dart
await isar.writeTxn(() async {
  final count = await isar.recipes.filter()
    .isFavoriteEqualTo(false)
    .deleteAll();
  // count = silinen nesnelerin sayısı
});
```
