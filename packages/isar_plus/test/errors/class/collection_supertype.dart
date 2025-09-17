// supertype annotated with @collection

import 'package:isar_plus/isar_plus.dart';

@collection
class Supertype {
  late int id;
}

class Subtype implements Supertype {
  @override
  late int id;
}

@collection
class Model implements Subtype {
  @override
  late int id;
}
