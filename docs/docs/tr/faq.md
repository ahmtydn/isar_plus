---
title: Sık Sorulan Sorular
---

# Sık Sorulan Sorular

Isar ve Flutter veritabanları hakkında sıkça sorulan soruların rastgele bir koleksiyonu.

### Neden bir veritabanına ihtiyacım var?

> Verilerimi bir arka uç veritabanında saklıyorum, neden Isar'a ihtiyacım var?

Bugün bile, metrodaysanız veya uçaktaysanız veya Wi-Fi'si olmayan ve çok kötü bir cep telefonu sinyali olan büyükannenizi ziyaret ediyorsanız veri bağlantınız olmayabilir. Kötü bağlantının uygulamanızı felce uğratmasına izin vermemelisiniz!

### Isar'a karşı Hive

Cevap kolay: Isar [Hive'ın yerine geçmek için başlatıldı](https://github.com/hivedb/hive/issues/246) ve şimdi Hive yerine her zaman Isar'ı kullanmanızı tavsiye ettiğim bir durumda.

### Where cümleleri?!

> Neden **_BEN_** hangi indeksi kullanacağımı seçmek zorundayım?

Birden fazla neden vardır. Birçok veritabanı, belirli bir sorgu için en iyi indeksi seçmek için sezgisel yöntemler kullanır. Veritabanının ek kullanım verilerini toplaması gerekir (-> ek yük) ve yine de yanlış indeksi seçebilir. Ayrıca sorgu oluşturmayı daha yavaş hale getirir.

Verilerinizi siz geliştiriciden daha iyi kimse bilmez. Bu nedenle, optimal indeksi seçebilir ve örneğin sorgulama veya sıralama için bir indeks kullanıp kullanmayacağınıza karar verebilirsiniz.

### İndeksleri / where cümlelerini kullanmak zorunda mıyım?

Hayır! Yalnızca filtrelere güvenirseniz, Isar büyük olasılıkla yeterince hızlıdır.

### Isar yeterince hızlı mı?

Isar, mobil için en hızlı veritabanları arasındadır, bu nedenle çoğu kullanım durumu için yeterince hızlı olmalıdır. Performans sorunlarıyla karşılaşırsanız, muhtemelen yanlış bir şey yapıyorsunuzdur.

### Isar uygulamama boyutunu artırıyor mu?

Biraz, evet. Isar, yerel uygulamanızın indirme boyutunu yaklaşık 1 - 1,5 MB artıracaktır. Flutter Web paketi ayrıca `isar.wasm` (yaklaşık 1 MB optimize edilmiş) ve hafif `isar.js` yükleyicisine (~50 KB) ihtiyaç duyar, bu nedenle her iki dosyayı da uygulama kabuğunuzun yanında barındırdığınızdan emin olun.

### Dokümanlar yanlış / bir yazım hatası var.

Vay hayır, üzgünüm. Lütfen [bir sorun açın](https://github.com/ahmtydn/isar_plus/issues/new/choose) veya daha da iyisi, bunu düzeltmek için bir PR açın 💪.
