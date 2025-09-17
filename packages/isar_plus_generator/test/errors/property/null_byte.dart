// bytes must not be nullable

import 'package:isar_plus/isar.dart';

@collection
class Model {
  Id? id;

  late byte? prop;
}
