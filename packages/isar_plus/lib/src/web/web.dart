import 'dart:async';
import 'dart:js_interop';

import 'package:isar_plus/isar_plus.dart';
import 'package:isar_plus/src/web/interop.dart';
import 'package:web/web.dart' as web;

export 'bindings.dart';
export 'ffi.dart';
export 'interop.dart';

@JS('wasm_bindgen')
external JSPromise? _wasmBindgenInit([JSAny? pathOrModule]);

@JS('window.wasm_bindgen')
external JSAny? get _windowWasmBindgen;

bool _scriptLoaded = false;

/// Initializes the Isar WebAssembly bindings.
FutureOr<IsarCoreBindings> initializePlatformBindings([String? library]) async {
  final url =
      library ?? 'https://unpkg.com/isar_plus@${Isar.version}/isar.wasm';

  // Ensure the wasm-bindgen JavaScript glue code is loaded
  if (!_scriptLoaded) {
    // Check if wasm_bindgen is already available
    final wasmBindgenExists = _windowWasmBindgen;
    if (wasmBindgenExists == null ||
        wasmBindgenExists.isUndefined ||
        wasmBindgenExists.isNull) {
      // Not loaded yet, load it dynamically
      await _loadWasmBindgenScript(url);
    }
    _scriptLoaded = true;
  }

  // Call the wasm_bindgen init function directly
  final result = await _wasmBindgenInit(url.toJS)!.toDart;

  // The result should have the memory and exports we need
  return result! as JSIsar;
}

/// Loads the wasm-bindgen JavaScript glue code
Future<void> _loadWasmBindgenScript(String wasmUrl) async {
  final completer = Completer<void>();

  // Derive the JS file URL from the WASM URL
  final jsUrl = wasmUrl.replaceAll('.wasm', '.js');

  // Create and inject the script tag
  final script = web.document.createElement('script') as web.HTMLScriptElement;
  script.src = jsUrl;
  script.type = 'text/javascript';

  script.onload =
      (web.Event event) {
        // Schedule async work without making the callback async
        _verifyWasmBindgenLoaded(jsUrl, completer);
      }.toJS;

  script.onerror =
      (web.Event event) {
        completer.completeError(
          Exception(
            'Failed to load isar.js from $jsUrl. '
            'Make sure both isar.wasm and isar.js are '
            'available at the same location. '
            'For local usage, copy both files to your web/ directory.',
          ),
        );
      }.toJS;

  web.document.head!.appendChild(script);

  await completer.future;
}

/// Verifies that wasm_bindgen is loaded and available
Future<void> _verifyWasmBindgenLoaded(
  String jsUrl,
  Completer<void> completer,
) async {
  // Wait a bit for the script to execute and set the global variable
  await Future<void>.delayed(const Duration(milliseconds: 50));

  // Verify wasm_bindgen is now available
  var attempts = 0;
  while (attempts < 10) {
    final wasmBindgenExists = _windowWasmBindgen;
    if (wasmBindgenExists != null &&
        !wasmBindgenExists.isUndefined &&
        !wasmBindgenExists.isNull) {
      completer.complete();
      return;
    }
    await Future<void>.delayed(const Duration(milliseconds: 50));
    attempts++;
  }

  completer.completeError(
    Exception(
      'wasm_bindgen not available after loading $jsUrl. '
      'This usually means isar.js failed to execute properly. '
      'Check the browser console for more details.',
    ),
  );
}

typedef IsarCoreBindings = JSIsar;

const tryInline = pragma('dart2js:tryInline');

class ReceivePort extends Stream<dynamic> {
  final sendPort = SendPort();

  @override
  StreamSubscription<void> listen(
    void Function(dynamic event)? onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) {
    throw UnimplementedError();
  }

  void close() {
    throw UnimplementedError();
  }
}

class SendPort {
  int get nativePort => 0;

  void send(dynamic message) {
    throw UnimplementedError();
  }
}

int platformFastHash(String str) {
  var i = 0;
  var t0 = 0;
  var v0 = 0x2325;
  var t1 = 0;
  var v1 = 0x8422;
  var t2 = 0;
  var v2 = 0x9ce4;
  var t3 = 0;
  var v3 = 0xcbf2;

  while (i < str.length) {
    v0 ^= str.codeUnitAt(i++);
    t0 = v0 * 435;
    t1 = v1 * 435;
    t2 = v2 * 435;
    t3 = v3 * 435;
    t2 += v0 << 8;
    t3 += v1 << 8;
    t1 += t0 >>> 16;
    v0 = t0 & 65535;
    t2 += t1 >>> 16;
    v1 = t1 & 65535;
    v3 = (t3 + (t2 >>> 16)) & 65535;
    v2 = t2 & 65535;
  }

  return (v3 & 15) * 281474976710656 +
      v2 * 4294967296 +
      v1 * 65536 +
      (v0 ^ (v3 >> 4));
}

@tryInline
Future<T> runIsolate<T>(
  String debugName,
  FutureOr<T> Function() computation,
) async {
  return computation();
}
