// constructor parameter type does not match property type

import 'package:isar_plus/isar.dart';

@collection
class Model {
  // ignore: avoid_unused_constructor_parameters - parameter used for testing error handling
  Model(int prop1);

  Id? id;

  String prop1 = '5';
}
