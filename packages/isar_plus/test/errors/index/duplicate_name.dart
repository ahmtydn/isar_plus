// same name

import 'package:isar_plus/isar_plus.dart';

@collection
class Model {
  late int id;

  @Index(name: 'myindex')
  String? prop1;

  @Index(name: 'myindex')
  String? prop2;
}
