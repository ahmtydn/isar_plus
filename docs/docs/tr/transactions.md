---
title: İşlemler
---

# İşlemler

Isar'da, işlemler birden fazla veritabanı işlemini tek bir çalışma biriminde birleştirir. Isar ile çoğu etkileşim örtük olarak işlemleri kullanır. Isar'daki okuma ve yazma erişimi [ACID](http://en.wikipedia.org/wiki/ACID) uyumludur. Bir hata oluşursa işlemler otomatik olarak geri alınır.

## Açık İşlemler

Açık bir işlemde, veritabanının tutarlı bir anlık görüntüsünü alırsınız. İşlemlerin süresini en aza indirmeye çalışın. Bir işlemde ağ çağrıları veya diğer uzun süreli işlemleri yapmak yasaktır.

İşlemlerin (özellikle yazma işlemleri) bir maliyeti vardır ve her zaman ardışık işlemleri tek bir işlemde gruplamaya çalışmalısınız.

İşlemler senkron veya asenkron olabilir. Senkron işlemlerde, yalnızca senkron işlemleri kullanabilirsiniz. Asenkron işlemlerde, yalnızca asenkron işlemleri kullanabilirsiniz.

|              | Okuma          | Okuma ve Yazma |
| ------------ | -------------- | -------------- |
| Senkron      | `.read()`      | `.write()`     |
| Asenkron     | `.readAsync()` | `.writeAsync()`|

### Okuma İşlemleri

Açık okuma işlemleri isteğe bağlıdır, ancak atomik okumalar yapmanıza ve işlem içinde veritabanının tutarlı bir durumuna güvenmenize olanak tanır. Dahili olarak Isar, tüm okuma işlemleri için her zaman örtük okuma işlemlerini kullanır.

:::tip
Asenkron okuma işlemleri, diğer okuma ve yazma işlemleriyle paralel olarak çalışır. Oldukça havalı, değil mi?
:::

### Yazma İşlemleri

Okuma işlemlerinin aksine, Isar'daki yazma işlemleri açık bir işleme sarılmalıdır.

Bir yazma işlemi başarıyla tamamlandığında, otomatik olarak taahhüt edilir ve tüm değişiklikler diske yazılır. Bir hata oluşursa, işlem iptal edilir ve tüm değişiklikler geri alınır. İşlemler "ya hep ya hiç"tir: bir işlem içindeki tüm yazmalar başarılı olur veya veri tutarlılığını garanti etmek için hiçbiri etki etmez.

:::warning
Bir veritabanı işlemi başarısız olduğunda, işlem iptal edilir ve artık kullanılmamalıdır. Hatayı Dart'ta yakalasanız bile.
:::

```dart
@collection
class Contact {
  Id? id;

  String? name;
}

// İYİ
await isar.writeAsync((isar) async {
  for (var contact in getContacts()) {
    await isar.contacts.put(contact);
  }
});

// KÖTÜ - işlemleri iç içe yerleştirmeyin
await isar.writeAsync((isar) async {
  for (var contact in getContacts()) {
    await isar.writeAsync((isar) async {
      await isar.contacts.put(contact);
    });
  }
});
```

Bir işlem sırasında yaptığınız değişiklikler aynı işlemde görünür. İşlemler yalıtılmıştır, bu nedenle başka bir işlem, orijinal işlem taahhüt edilene kadar değişiklikleri görmez.
