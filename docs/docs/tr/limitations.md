---
title: Sınırlamalar
---

# Sınırlamalar

Bildiğiniz gibi, Isar hem VM'de çalışan mobil cihazlar ve masaüstlerinde hem de Web'de çalışır. Her iki platform da çok farklıdır ve farklı sınırlamalara sahiptir.

## VM Sınırlamaları

- Bir string'in yalnızca ilk 1024 baytı önek where-cümlesi için kullanılabilir
- Nesneler yalnızca 16MB boyutunda olabilir

## Web Sınırlamaları

Isar Plus artık WebAssembly'ye derlenmiş SQLite üzerinde çalışır. Chrome ve Edge, verileri Origin Private File System (OPFS) içinde kalıcı hale getirir; Safari, Firefox ve eski Chromium derlemeleri, IndexedDB destekli bir VFS'ye geri döner. OPFS arka ucu yerel SQLite davranışını yansıtırken, geri dönüş hala birkaç tarayıcı tarafından uygulanan kısıtlama taşır:

- Web'de asenkron API'leri kullanın; senkron koleksiyon yardımcıları `UnsupportedError` fırlatır.
- `Isar.splitWords()` ve `.matches()` gibi metin yardımcıları web motoru için uygulanmamış olarak kalır.
- Şema migrasyonları VM'deki kadar sıkı doğrulanmaz, bu nedenle sürümler sırasında kırılma değişikliklerini iki kez kontrol edin.
- IndexedDB geri dönüşü etkin olduğunda, bazı dönüş değerleri (örneğin `delete()` sayıları) yerel SQLite'tan farklı olabilir ve otomatik artış sayaçları `clear()` ile sıfırlanmaz.
