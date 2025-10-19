import 'dart:async';
import 'dart:js_interop';

import 'package:isar_plus/isar_plus.dart';
import 'package:isar_plus/src/web/interop.dart';
import 'package:web/web.dart';

export 'bindings.dart';
export 'ffi.dart';
export 'interop.dart';

Worker? _worker;
JSIsar? _wasmBindings;
bool _opfsAvailable = false;
final _initCompleter = Completer<void>();

/// Initializes the Isar WebAssembly bindings.
///
/// On web, this spawns a dedicated worker for WASM execution to enable
/// OPFS persistence. Falls back to in-memory mode if OPFS is unavailable.
FutureOr<IsarCoreBindings> initializePlatformBindings([String? library]) async {
  // Return cached bindings if already initialized
  if (_wasmBindings != null) {
    return _wasmBindings!;
  }

  // Detect if we're in a worker context or main thread
  final isWorkerContext = _isWorkerContext();

  if (isWorkerContext) {
    // We're already in a worker - load WASM directly with OPFS support
    return await _initializeInWorker(library);
  } else {
    // We're on the main thread - spawn a worker for OPFS support
    return await _initializeWithWorker(library);
  }
}

/// Check if we're running in a Worker context
bool _isWorkerContext() {
  // For now, always assume we're on the main thread
  // Worker detection in Dart web is complex and not critical for MVP
  return false;
}

/// Initialize WASM in a worker context (direct loading with OPFS)
Future<JSIsar> _initializeInWorker([String? library]) async {
  final url =
      library ?? 'https://unpkg.com/isar_plus@${Isar.version}/isar.wasm';

  // This path is used for fallback when worker initialization fails
  // or when called from the main thread directly (without worker).
  // The Rust VFS will use OPFS if available, otherwise fall back to in-memory.
  final w = window as JSWindow;
  final object = {'env': <String, String>{}}.jsify();
  if (object == null) {
    throw Exception('Failed to create import object for WebAssembly.');
  }
  final promise = w.WebAssembly.instantiateStreaming(w.fetch(url), object);
  final wasm = await promise.toDart;
  _wasmBindings = wasm.instance.exports;
  return _wasmBindings!;
}

/// Initialize WASM with a dedicated worker for OPFS support
Future<JSIsar> _initializeWithWorker([String? library]) async {
  if (_worker != null && _wasmBindings != null) {
    return _wasmBindings!;
  }

  final url =
      library ?? 'https://unpkg.com/isar_plus@${Isar.version}/isar.wasm';

  try {
    // Create a new worker
    // Note: The worker script path is relative to the application root
    _worker = Worker('packages/isar_plus/src/web/isar_worker.js'.toJS);

    // Set up message handler
    final messageCompleter = Completer<void>();
    _worker!.onmessage =
        (MessageEvent event) {
          final data = event.data;
          if (data == null) return;

          _handleWorkerMessage(data, messageCompleter);
        }.toJS;

    _worker!.onerror =
        (Event event) {
          if (!messageCompleter.isCompleted) {
            messageCompleter.completeError(
              Exception('Worker error: ${event.type}'),
            );
          }
        }.toJS;

    // Wait for worker to be ready
    await messageCompleter.future;

    // Initialize WASM in the worker
    _worker!.postMessage(
      {
        'type': 'initialize',
        'data': {'wasmUrl': url},
      }.jsify(),
    );

    // Wait for initialization to complete
    await _initCompleter.future;

    // For now, also load WASM on the main thread for bindings access
    // In the future, we'll proxy calls through the worker
    final w = window as JSWindow;
    final object = {'env': <String, String>{}}.jsify();
    if (object == null) {
      throw Exception('Failed to create import object for WebAssembly.');
    }
    final promise = w.WebAssembly.instantiateStreaming(w.fetch(url), object);
    final wasm = await promise.toDart;
    _wasmBindings = wasm.instance.exports;

    if (!_opfsAvailable) {
      throw Exception(
        'Warning: OPFS not available. Database will run in memory-only mode. '
        'Data will be lost when the page is reloaded. '
        'To enable persistence, serve your app with COOP/COEP headers and use a '
        'browser that supports OPFS (Chrome 102+, Edge 102+, '
        'Firefox 111+, Safari 16.4+).',
      );
    }

    return _wasmBindings!;
  } on Exception catch (_) {
    return _initializeInWorker(library);
  }
}

/// Handle messages from the worker
void _handleWorkerMessage(JSAny data, Completer<void>? readyCompleter) {
  try {
    final map = (data as JSObject).dartify()! as Map<String, dynamic>;
    final type = map['type'] as String;

    switch (type) {
      case 'ready':
        if (readyCompleter != null && !readyCompleter.isCompleted) {
          readyCompleter.complete();
        }

      case 'initialized':
        _opfsAvailable = map['opfsAvailable'] as bool? ?? false;
        if (!_initCompleter.isCompleted) {
          _initCompleter.complete();
        }

      case 'error':
        final message = map['message'] as String;
        if (!_initCompleter.isCompleted) {
          _initCompleter.completeError(Exception(message));
        }

      case 'result':
        // Handle function call results from worker
        // Note: Current architecture doesn't proxy individual function
        // calls through worker.
        // The worker only handles initialization and OPFS operations
        // are called directly
        // from Rust VFS via JavaScript imports. This case is
        // reserved for future
        // enhancements if we implement full call proxying.
        break;

      case 'pong':
        // Worker is alive
        break;

      default:
    }
  } on Exception catch (_) {}
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
