---
title: Çoklu İzolasyon Kullanımı
---

# Çoklu İzolasyon Kullanımı

Thread'ler yerine, tüm Dart kodu izolasyonların içinde çalışır. Her izolasyonun kendi bellek yığını vardır ve bir izolasyondaki durumun hiçbiri başka bir izolasyondan erişilebilir değildir.

Isar, aynı anda birden fazla izolasyondan erişilebilir ve izleyiciler bile izolasyonlar arasında çalışır. Bu tarifte, Isar'ı çoklu izolasyon ortamında nasıl kullanacağımıza bakacağız.

## Çoklu İzolasyonları Ne Zaman Kullanmalı

Isar işlemleri, aynı izolasyonda çalışsalar bile paralel olarak yürütülür. Bazı durumlarda, Isar'a birden fazla izolasyondan erişmek yine de faydalıdır.

Bunun nedeni, Isar'ın verileri Dart nesnelerine kodlama ve çözme için oldukça fazla zaman harcamasıdır. Bunu JSON kodlama ve çözme olarak düşünebilirsiniz (sadece daha verimli). Bu işlemler, verilere erişilen izolasyon içinde çalışır ve doğal olarak izolasyondaki diğer kodları engeller. Başka bir deyişle: Isar, işin bir kısmını Dart izolasyonunuzda gerçekleştirir.

Bir seferde sadece birkaç yüz nesne okumanız veya yazmanız gerekiyorsa, bunu UI izolasyonunda yapmak sorun değildir. Ancak büyük işlemler için veya UI thread'i zaten meşgulse, ayrı bir izolasyon kullanmayı düşünmelisiniz.

## Örnek

Yapmamız gereken ilk şey, yeni izolasyonda Isar'ı açmaktır. Isar örneği ana izolasyonda zaten açık olduğundan, `Isar.open()` aynı örneği döndürür.

:::warning
Ana izolasyondaki ile aynı şemaları sağladığınızdan emin olun. Aksi takdirde, bir hata alırsınız.
:::

`compute()`, Flutter'da yeni bir izolasyon başlatır ve verilen fonksiyonu içinde çalıştırır.

```dart
void main() {
  // UI izolasyonunda Isar'ı açın
  final dir = await getApplicationDocumentsDirectory();
  
  final isar = await Isar.open(
    [MessageSchema],
    directory: dir.path,
    name: 'myInstance',
  );

  // veritabanındaki değişiklikleri dinleyin
  isar.messages.watchLazy(() {
    print('Vay be mesajlar değişti!');
  });

  // yeni bir izolasyon başlatın ve 10000 mesaj oluşturun
  compute(createDummyMessages, 10000).then(() {
    print('izolasyon bitti');
  });

  // bir süre sonra:
  // > Vay be mesajlar değişti!
  // > izolasyon bitti
}

// yeni izolasyonda çalıştırılacak fonksiyon
Future createDummyMessages(int count) async {
  // örnek zaten açık olduğu için burada yola ihtiyacımız yok
  final dir = await getApplicationDocumentsDirectory();
  
  final isar = await Isar.open(
    [PostSchema],
    directory: dir.path,
    name: 'myInstance',
  );

  final messages = List.generate(count, (i) => Message()..content = 'Mesaj $i');
  // izolasyonlarda senkron işlemler kullanıyoruz
  isar.write((isar) {
    isar.messages.putAll(messages);
  });
}
```

Yukarıdaki örnekte dikkat edilmesi gereken birkaç ilginç şey vardır:

- `isar.messages.watchLazy()`, UI izolasyonunda çağrılır ve başka bir izolasyondan gelen değişikliklerden haberdar edilir.
- Örnekler isme göre referans alınır. Varsayılan ad `default`'tur, ancak bu örnekte bunu `myInstance` olarak ayarladık.
- Mesajları oluşturmak için senkron bir işlem kullandık. Yeni izolasyonumuzu engellemek sorun değildir ve senkron işlemler biraz daha hızlıdır.
