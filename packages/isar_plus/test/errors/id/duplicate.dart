// two or more properties are annotated with @id

import 'package:isar_plus/isar_plus.dart';

@collection
class Test {
  @id
  late int id1;

  @id
  late int id2;
}
