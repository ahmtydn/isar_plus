---
title: Bağlantılar
---

# Bağlantılar

Bağlantılar, nesneler arasındaki ilişkileri ifade etmenize olanak tanır, örneğin bir yorumun yazarı (User). Isar bağlantılarıyla `1:1`, `1:n` ve `n:n` ilişkilerini modelleyebilirsiniz. Bağlantıları kullanmak, gömülü nesneleri kullanmaktan daha az ergonomiktir ve mümkün olduğunda gömülü nesneleri kullanmalısınız.

Bağlantıyı ilişkiyi içeren ayrı bir tablo olarak düşünün. SQL ilişkilerine benzer ancak farklı bir özellik setine ve API'ye sahiptir.

## IsarLink

`IsarLink<T>`, ilişkili bir nesne içermeyebilir veya içerebilir ve bir-e-bir ilişkiyi ifade etmek için kullanılabilir. `IsarLink`, bağlı nesneyi tutan `value` adlı tek bir özelliğe sahiptir.

Bağlantılar tembel olduğundan, `IsarLink`'e `value` değerini açıkça yüklemesini veya kaydetmesini söylemeniz gerekir. Bunu `linkProperty.load()` ve `linkProperty.save()` çağrılarını yaparak yapabilirsiniz.

:::tip
Bir bağlantının kaynak ve hedef koleksiyonlarının id özelliği final olmamalıdır.
:::

Web olmayan hedefler için, bağlantılar ilk kez kullandığınızda otomatik olarak yüklenir. Bir koleksiyona bir IsarLink ekleyerek başlayalım:

```dart
@collection
class Teacher {
  Id? id;

  late String subject;
}

@collection
class Student {
  Id? id;

  late String name;

  final teacher = IsarLink<Teacher>();
}
```

Öğretmenler ve öğrenciler arasında bir bağlantı tanımladık. Bu örnekte her öğrencinin tam olarak bir öğretmeni olabilir.

İlk olarak, öğretmeni oluşturuyoruz ve bir öğrenciye atıyoruz. Öğretmeni `.put()` yapmamız ve bağlantıyı manuel olarak kaydetmemiz gerekir.

```dart
final mathTeacher = Teacher()..subject = 'Matematik';

final linda = Student()
  ..name = 'Linda'
  ..teacher.value = mathTeacher;

await isar.writeAsync((isar) async {
  await isar.students.put(linda);
  await linda.teacher.save();
});
```

Şimdi bağlantıyı kullanabiliriz:

```dart
final linda = await isar.students.where()
  .nameEqualTo('Linda')
  .findFirst();

final teacher = linda.teacher.value; // -> Matematik öğretmeni
```

Yüklenen bağlantıları bellekte tutmayı deneyin. Bir bağlantıyı yeniden yüklerseniz, mevcut `value` değerinin üzerine yazılır.

## IsarLinks

Birden çok ilişkili nesneyi içermek mantıklı olduğunda, `IsarLinks<T>` bunu gerçekleştirmenin doğru yoludur.

`IsarLinks<T>` bir `Set<T>` genişletir ve tüm yöntemlere bir Set'in sahip olduğu izin verir.

`IsarLinks`, `IsarLink` ile benzer şekilde çalışır ancak birden fazla nesne tutmanıza olanak tanır. Yukarıdaki örnekten devam ederek, bir öğrencinin birden fazla öğretmene sahip olabilmesini istiyoruz:

```dart
@collection
class Student {
  Id? id;

  late String name;

  final teachers = IsarLinks<Teacher>();
}
```

Bu, öncekiyle aynı şekilde çalışır, tek fark birden fazla öğretmeni tutmamızdır.

```dart
final mathTeacher = Teacher()..subject = 'Matematik';
final englishTeacher = Teacher()..subject = 'İngilizce';

final linda = Student()
  ..name = 'Linda'
  ..teachers.addAll([mathTeacher, englishTeacher]);

await isar.writeAsync((isar) async {
  await isar.students.put(linda);
  await linda.teachers.save();
});
```

## Geri Bağlantılar

Peki ya ters yönde gitmek istersek? İlişki çift yönlü olduğunu söyleyerek "geri bağlantılar" tanımlayabilirsiniz. Geri bağlantılar yalnızca `IsarLinks` için kullanılabilir.

Geri bağlantılar bir ilişkinin karşı tarafını içerir. Her bağlantı için açıkça bir geri bağlantı tanımlayabilirsiniz.

Bir öğretmen için öğrencilere geri bağlantı eklersek aşağıdaki gibi görünür:

```dart
@collection
class Teacher {
  Id? id;

  late String subject;

  @Backlink(to: 'teachers')
  final students = IsarLinks<Student>();
}
```

Geri bağlantıların bir kaynak bağlantıyı işaret etmesi gerekir. Kaynak bağlantı herhangi bir koleksiyonda olabilir.

## İlişkilerin Başlatılması

`IsarLink` ve `IsarLinks` boş başlatıcılarla başlatılmalıdır ve bağlantılar atanmadan önce İsar koleksiyonunu bilmelidir. Yalnızca bir nesneyi bir koleksiyona ekledikten sonra, bir bağlantı kullanılabilir.

:::warning
Bir nesneyi eklemeyi unutursanız ve bağlantıyı kullanmaya çalışırsanız, Isar bir hata fırlatacaktır.
:::

Bağlantıların kullanılabilir hale geldiğini anlamak için:

```dart
final student = Student();

// student.teachers.add(mathTeacher); -> hata: bağlantı henüz başlatılmadı

await isar.writeAsync((isar) async {
  await isar.students.put(student);

  student.teachers.add(mathTeacher); // -> şimdi çalışır
  await student.teachers.save();
});
```
