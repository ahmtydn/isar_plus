// names must not be blank or start with "_"

import 'package:isar_plus/isar_plus.dart';

@collection
class Model {
  late int id;

  @Index(name: '_index')
  String? str;
}
