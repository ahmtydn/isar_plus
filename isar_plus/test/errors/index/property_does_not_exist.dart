// property does not exist

import 'package:isar_plus/isar_plus.dart';

@collection
class Model {
  late int id;

  @Index(composite: ['myProp'])
  int? value;
}
