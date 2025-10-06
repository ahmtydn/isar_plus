// constructor parameter type does not match property type

import 'package:isar_plus/isar_plus.dart';

@collection
class Model {
  Model(int prop1);

  late int id;

  String prop1 = '5';
}
