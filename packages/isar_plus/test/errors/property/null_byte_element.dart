// bytes must not be nullable

import 'package:isar_plus/isar_plus.dart';

@collection
class Model {
  late int id;

  late List<byte?> prop;
}
