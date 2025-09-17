// objects may not be indexed

import 'package:isar_plus/isar.dart';

@collection
class Model {
  Id? id;

  @Index()
  EmbeddedModel? obj;
}

@embedded
class EmbeddedModel {}
