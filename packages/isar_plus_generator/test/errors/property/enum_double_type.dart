// unsupported enum property type

import 'package:isar_plus/isar.dart';

@collection
class Model {
  Id? id;

  @Enumerated(EnumType.value, 'value')
  late MyEnum field;
}

enum MyEnum {
  optionA;

  final double value = 5.5;
}
