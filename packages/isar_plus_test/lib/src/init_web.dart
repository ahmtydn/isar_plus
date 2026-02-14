import 'package:isar_plus/isar_plus.dart';
import 'package:isar_plus_test/src/common.dart';

var _setUp = false;
Future<void> prepareTest({bool cleanup = true}) async {
  if (!_setUp) {
    await Isar.initialize('http://localhost:3000/isar.wasm');
    testTempPath = '/isar_test';
    _setUp = true;
  }
}
