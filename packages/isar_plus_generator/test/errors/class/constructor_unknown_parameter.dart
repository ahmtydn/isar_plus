// constructor parameter does not match a property

import 'package:isar_plus/isar.dart';

@collection
class Model {
  // ignore: avoid_unused_constructor_parameters - parameter used for testing error handling
  Model(this.prop1, String somethingElse);

  Id? id;

  final String prop1;
}
