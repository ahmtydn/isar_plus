// only classes

import 'package:isar_plus/isar_plus.dart';

// Test case: collection annotation should only be used on classes, not mixins
// ignore: invalid_annotation_target
@collection
mixin Test {}
