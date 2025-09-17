// ids cannot be indexed

import 'package:isar_plus/isar_plus.dart';

@collection
class Model {
  late String id;

  @Index(composite: ['id'])
  int? value;
}
