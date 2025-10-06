import 'package:isar_plus/isar_plus.dart';

Future<void> prepareTest() async {
  await Isar.initialize('http://localhost:3000/isar.wasm');
}
