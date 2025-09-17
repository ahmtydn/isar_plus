// only int and string properties can be used as id

import 'package:isar_plus/isar_plus.dart';

@collection
class Test {
  late TestEnum id;
}

enum TestEnum { a, b, c }
