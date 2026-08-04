import 'dart:async';
import 'dart:ffi';
import 'dart:io';
import 'dart:isolate';

import 'package:ffi/ffi.dart';
import 'package:isar_plus/isar_plus.dart';
import 'package:isar_plus/src/native/bindings.dart';

export 'dart:isolate';

export 'bindings.dart';
export 'ffi.dart';

/// @nodoc
FutureOr<IsarCoreBindings> initializePlatformBindings([String? library]) {
  late IsarCoreBindings bindings;
  try {
    bindings = IsarCoreBindings(_openIsarCore(library));
  } catch (e) {
    throw IsarNotReadyError(
      'Could not initialize IsarCore library for processor architecture '
      '"${Abi.current()}". If you create a Flutter app, make sure to add '
      'isar_plus_flutter_libs to your dependencies. For Dart-only apps or unit '
      'tests, make sure to place the correct Isar binary in the correct '
      'directory.\n$e',
    );
  }

  final coreVersion = bindings.isar_plus_version().cast<Utf8>().toDartString();
  if (coreVersion != Isar.version && coreVersion != 'debug') {
    throw IsarNotReadyError(
      'Incorrect Isar Core version: Required ${Isar.version} found '
      '$coreVersion. Make sure to use the latest '
      'isar_plus_flutter_libs. If you have a Dart only project, make '
      'sure that old Isar Core binaries are deleted.',
    );
  }

  bindings.isar_plus_connect_dart_api(NativeApi.initializeApiDLData);

  return bindings;
}

const _appleFramework = 'IsarPlusCore';

DynamicLibrary _openIsarCore(String? library) {
  if (library != null) {
    return DynamicLibrary.open(library);
  }

  if (!Platform.isIOS && !Platform.isMacOS) {
    return DynamicLibrary.open(Abi.current().localName);
  }

  final attempts = <String>[];
  for (final candidate in _appleLibraryCandidates()) {
    try {
      return DynamicLibrary.open(candidate);
    } on Object catch (e) {
      attempts.add('  $candidate -> $e');
    }
  }
  throw ArgumentError(
    'Could not load $_appleFramework.framework. Make sure '
    'isar_plus_flutter_libs is a dependency of your app so the framework is '
    'embedded. Tried:\n${attempts.join('\n')}',
  );
}

Iterable<String> _appleLibraryCandidates() sync* {
  const bundled = '$_appleFramework.framework/$_appleFramework';
  final executableDir = File(Platform.resolvedExecutable).parent;

  if (Platform.isIOS) {
    // Runner.app/Runner -> Runner.app/Frameworks/IsarPlusCore.framework/...
    yield '${executableDir.path}/Frameworks/$bundled';
  } else {
    // Runner.app/Contents/MacOS/Runner
    //   -> Runner.app/Contents/Frameworks/IsarPlusCore.framework/...
    yield '${executableDir.parent.path}/Frameworks/$bundled';
  }
  yield bundled;

  if (Platform.isMacOS) {
    yield Abi.current().localName;
  }
}

/// @nodoc
const tryInline = pragma('vm:prefer-inline');

extension on Abi {
  String get localName {
    switch (Abi.current()) {
      case Abi.androidArm:
      case Abi.androidArm64:
      case Abi.androidX64:
        return 'libisar_plus.so';
      case Abi.macosArm64:
      case Abi.macosX64:
        return 'libisar_plus.dylib';
      case Abi.linuxX64:
        return 'libisar_plus.so';
      case Abi.windowsArm64:
      case Abi.windowsX64:
        return 'isar_plus.dll';
      case Abi.androidIA32:
        throw IsarNotReadyError(
          'Unsupported processor architecture. X86 Android emulators are not '
          'supported. Please use an x86_64 emulator instead. All physical '
          'Android devices are supported including 32bit ARM.',
        );
      default:
        throw IsarNotReadyError(
          'Unsupported processor architecture "${Abi.current()}". '
          'Please open an issue on GitHub to request it.',
        );
    }
  }
}

/// @nodoc
int platformFastHash(String string) {
  // This is native code, JS rounding is not applicable
  // ignore: avoid_js_rounded_ints
  var hash = 0xcbf29ce484222325;

  var i = 0;
  while (i < string.length) {
    final codeUnit = string.codeUnitAt(i++);
    hash ^= codeUnit >> 8;
    hash *= 0x100000001b3;
    hash ^= codeUnit & 0xFF;
    hash *= 0x100000001b3;
  }

  return hash;
}

/// @nodoc
@tryInline
Future<T> runIsolate<T>(String debugName, FutureOr<T> Function() computation) {
  return Isolate.run(computation, debugName: debugName);
}
