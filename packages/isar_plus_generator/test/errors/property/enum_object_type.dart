// unsupported enum property type

import 'package:isar_plus/isar.dart';

@collection
class Model {
  Id? id;

  @Enumerated(EnumType.value, 'value')
  late MyEnum prop;
}

enum MyEnum {
  optionA;

  final value = EmbeddedModel();
}

@embedded
class EmbeddedModel {}
