import 'package:isar_plus/isar.dart';

void main(List<String> args) {
  if (Isar.version != args[0]) {
    throw StateError(
      'Invalid Isar version for release: ${Isar.version} != ${args[0]}',
    );
  }
}
