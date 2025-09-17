// json properties cannot be indexed

import 'package:isar_plus/isar_plus.dart';

@collection
class Model {
  late int id;

  @index
  dynamic val1;

  String? val2;
}
