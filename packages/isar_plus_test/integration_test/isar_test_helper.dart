import 'dart:ffi';
import 'dart:io';
import 'package:ffi/ffi.dart';
import 'package:flutter_test/flutter_test.dart';

/// Verifies that Isar Core's FFI symbols are reachable on Apple platforms.
///
/// Core ships as the dynamic `IsarPlusCore.framework`. A dynamic framework
/// keeps its exported symbols in every build configuration, whereas the
/// previous static library placed them in the host executable, where Xcode's
/// `strip` pass during `xcodebuild archive` removed the names — so lookups
/// only failed in TestFlight and App Store builds.
void runDarwinTest() {
  if (!Platform.isIOS && !Platform.isMacOS) {
    return;
  }

  testWidgets('IsarPlusCore.framework exports are resolvable', (tester) async {
    const bundled = 'IsarPlusCore.framework/IsarPlusCore';
    final executableDir = File(Platform.resolvedExecutable).parent;
    final candidates = [
      if (Platform.isIOS)
        '${executableDir.path}/Frameworks/$bundled'
      else
        '${executableDir.parent.path}/Frameworks/$bundled',
      bundled,
    ];

    DynamicLibrary? lib;
    final attempts = <String>[];
    for (final candidate in candidates) {
      try {
        lib = DynamicLibrary.open(candidate);
        break;
      } on Object catch (e) {
        attempts.add('$candidate -> $e');
      }
    }
    expect(lib, isNotNull, reason: 'Could not load Core: $attempts');

    final version = lib!
        .lookupFunction<Pointer<Utf8> Function(), Pointer<Utf8> Function()>(
          'isar_plus_version',
        );
    expect(version().toDartString(), isNotEmpty);
  });
}
