// double properties cannot be indexed

import 'package:isar_plus/isar_plus.dart';

@collection
class Model {
  late int id;

  @index
  double? val1;

  String? val2;
}
