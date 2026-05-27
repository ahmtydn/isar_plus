import 'dart:ffi';
import 'dart:io';
import 'package:ffi/ffi.dart';
import 'package:flutter_test/flutter_test.dart';

typedef _IsarGetErrorNative = Pointer<Utf8> Function(Uint32);
typedef _IsarGetError = Pointer<Utf8> Function(int);

void runDarwinTest() {
  if (Platform.isIOS || Platform.isMacOS) {
    testWidgets('DynamicLibrary.process() can call isar_get_error on Darwin', (
      tester,
    ) async {
      expect(() {
        final lib = DynamicLibrary.process();
        final isarGetError = lib
            .lookupFunction<_IsarGetErrorNative, _IsarGetError>(
              'isar_get_error',
            );
        isarGetError(0);
      }, returnsNormally);
    });
  }
}
