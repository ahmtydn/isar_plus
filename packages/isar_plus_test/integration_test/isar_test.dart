import 'dart:async';
import 'dart:ffi';
import 'dart:io';

import 'package:ffi/ffi.dart';
import 'package:flutter/foundation.dart' hide kIsWeb;
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:isar_plus_test/isar_plus_test.dart';

import 'all_tests.dart' as tests;

typedef _IsarGetErrorNative = Pointer<Utf8> Function(Uint32);
typedef _IsarGetError = Pointer<Utf8> Function(int);

void main() async {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  if (kIsWeb ||
      defaultTargetPlatform == TargetPlatform.iOS ||
      defaultTargetPlatform == TargetPlatform.android) {
    isarTestRunner =
        (
          String description,
          dynamic Function() body, {
          String? testOn,
          Timeout? timeout,
          dynamic skip,
          dynamic tags,
          Map<String, dynamic>? onPlatform,
          int? retry,
        }) {
          testWidgets(
            description,
            (tester) async {
              await body();
            },
            timeout: timeout,
            skip: skip,
            tags: tags,
          );
        };
  }

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
  if (Platform.isIOS || Platform.isMacOS) {
    testWidgets(
      'DynamicLibrary.process() can call isar_get_error on Darwin',
      (tester) async {
        expect(
          () {
            final lib = DynamicLibrary.process();
            final isarGetError = lib
                .lookupFunction<_IsarGetErrorNative, _IsarGetError>(
                  'isar_get_error',
                );
            isarGetError(0);
          },
          returnsNormally,
        );
      },
    );
  }
}
