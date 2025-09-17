// ids cannot be indexed

import 'package:isar_plus/isar.dart';

@collection
class Model {
  Id? id;

  @Index(composite: [CompositeIndex('id')])
  String? str;
}
