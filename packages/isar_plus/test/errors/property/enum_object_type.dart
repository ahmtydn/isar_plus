// unsupported enum property type

import 'package:isar_plus/isar_plus.dart';

@collection
class Model {
  late int id;

  late MyEnum prop;
}

enum MyEnum {
  optionA;

  @enumValue
  final value = EmbeddedModel();
}

@embedded
class EmbeddedModel {}
