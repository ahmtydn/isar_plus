// only classes

import 'package:isar_plus/isar_plus.dart';

// Test case: collection annotation should only be used on classes, not enums
// ignore: invalid_annotation_target
@collection
enum Test { a, b, c }
