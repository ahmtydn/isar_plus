// same name

import 'package:isar_plus/isar.dart';

@collection
class Model {
  Id? id;

  String? prop1;

  @Name('prop1')
  String? prop2;
}
