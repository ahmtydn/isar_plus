// embedded object properties cannot be indexed

import 'package:isar_plus/isar_plus.dart';

@collection
class Model {
  late int id;

  @Index()
  EmbeddedModel? obj;
}

@embedded
class EmbeddedModel {}
