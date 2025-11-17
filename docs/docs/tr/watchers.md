---
title: İzleyiciler
---

# İzleyiciler

Isar, veritabanındaki değişikliklere abone olmanıza olanak tanır. Belirli bir nesnedeki, tüm bir koleksiyondaki veya bir sorgudaki değişiklikleri "izleyebilirsiniz".

İzleyiciler, veritabanındaki değişikliklere verimli bir şekilde tepki vermenizi sağlar. Örneğin, bir kişi eklendiğinde kullanıcı arayüzünüzü yeniden oluşturabilir, bir belge güncellendiğinde bir ağ isteği gönderebilirsiniz, vb.

Bir izleyici, bir işlem başarıyla taahhüt edildikten ve hedef gerçekten değiştikten sonra bildirilir.

## Nesneleri İzleme

Belirli bir nesnenin oluşturulması, güncellenmesi veya silinmesi durumunda bildirilmek istiyorsanız, bir nesneyi izlemelisiniz:

```dart
Stream<User> userChanged = isar.users.watchObject(5);
userChanged.listen((newUser) {
  print('Kullanıcı değişti: ${newUser?.name}');
});

final user = User(id: 5)..name = 'David';
await isar.users.put(user);
// yazdırır: Kullanıcı değişti: David

final user2 = User(id: 5)..name = 'Mark';
await isar.users.put(user);
// yazdırır: Kullanıcı değişti: Mark

await isar.users.delete(5);
// yazdırır: Kullanıcı değişti: null
```

Yukarıdaki örnekte görebileceğiniz gibi, nesnenin henüz var olması gerekmez. İzleyici, oluşturulduğunda bildirilecektir.

Ek bir `fireImmediately` parametresi vardır. `true` olarak ayarlarsanız, Isar hemen nesnenin mevcut değerini akışa ekleyecektir.

### Tembel İzleme

Belki de yeni değeri almanız gerekmez ancak yalnızca değişiklik hakkında bilgilendirilmek istersiniz. Bu, Isar'ın nesneyi almasını sağlar:

```dart
Stream<void> userChanged = isar.users.watchObjectLazy(5);
userChanged.listen(() {
  print('Kullanıcı 5 değişti');
});

final user = User(id: 5)..name = 'David';
await isar.users.put(user);
// yazdırır: Kullanıcı 5 değişti
```

## Koleksiyonları İzleme

Tüm bir koleksiyondaki değişiklikleri izlemek istiyorsanız, bir koleksiyonu izleyebilirsiniz:

```dart
Stream<void> usersChanged = isar.users.watchLazy();
usersChanged.listen(() {
  print('Kullanıcılar değişti');
});

final user = User()..name = 'David';
await isar.users.put(user);
// yazdırır: Kullanıcılar değişti
```

## Sorguları İzleme

Tüm bir sorgunun sonuçlarını bile izlemek mümkündür. Isar, ilk sonuçları yeniden hesaplamadan sonuçların değişip değişmediğini bilmek için elinden geleni yapar. İzlenen sorgular için `fireImmediately` parametresini kullanmanız önerilir.

```dart
Query<User> usersWithA = isar.users.filter()
  .nameStartsWith('A')
  .build();

Stream<List<User>> queryChanged = usersWithA.watch(fireImmediately: true);
queryChanged.listen((users) {
  print('A ile başlayan kullanıcılar: ${users.length}');
});
// yazdırır: A ile başlayan kullanıcılar: 0

final user = User()..name = 'Albert';
await isar.users.put(user);
// yazdırır: A ile başlayan kullanıcılar: 1
```

:::warning
Sorguların izlenmesi yalnızca where cümleleri ve filtreleri içeren sorgular için mümkündür. Sıralama, farklı, offset, limit gibi değiştirilen sorgular için izleme kullanılırsa, izleyici her değişiklikte tetiklenir.
:::

Koleksiyon izleyicileri gibi, sorgu izleyicilerinin de tembel bir versiyonu vardır:

```dart
Stream<void> queryChanged = usersWithA.watchLazy();
queryChanged.listen(() {
  print('A ile başlayan kullanıcıların sayısı değişti');
});
```
