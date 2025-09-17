// null values are not supported

import 'package:isar_plus/isar.dart';

@collection
class Model {
  Id? id;

  @Enumerated(EnumType.value, 'value')
  late MyEnum prop;
}

enum MyEnum {
  optionA;

  final String? value = null;
}
