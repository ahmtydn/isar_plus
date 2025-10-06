// constructor parameter does not match a property

import 'package:isar_plus/isar_plus.dart';

@collection
class Model {
  // Test case: testing constructor parameter that doesn't match any property
  // ignore: avoid_unused_constructor_parameters
  Model(this.prop1, String somethingElse);

  late int id;

  final String prop1;
}
