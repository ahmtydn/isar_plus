// composite indexes cannot have more than 3 properties

import 'package:isar_plus/isar_plus.dart';

@collection
class Model {
  late int id;

  @Index(composite: ['int2', 'int3', 'int4'], hash: false)
  int? int1;

  int? int2;

  int? int3;

  int? int4;
}
