import 'package:isar_plus/isar.dart';

Future<void> prepareTest() async {
  await Isar.initialize('http://localhost:3000/isar.wasm');
}
