// same name

import 'package:isar_plus/isar_plus.dart';

@collection
class Model {
  late int id;

  String? prop1;

  @Name('prop1')
  String? prop2;
}
