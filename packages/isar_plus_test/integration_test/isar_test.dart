// ignore_for_file: avoid_print

import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:isar_plus_test/isar_plus_test.dart';

import 'all_tests.dart' as tests;

void main() async {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  final completer = Completer<void>();

  group('Integration test', () {
    tearDownAll(() {
      print('Isar test done');
      completer.complete();
    });

    tests.main();
  });

  testWidgets('Isar', (t) async {
    await completer.future;
    expect(testCount > 0, true);
    expect(testErrors, isEmpty);
  }, timeout: Timeout.none);
}
