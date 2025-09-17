// same name

import 'package:isar_plus/isar.dart';

@collection
class Model {
  Id? id;

  @Index(name: 'myindex')
  String? prop1;

  @Index(name: 'myindex')
  String? prop2;
}
