import 'dart:js_interop';
import 'dart:typed_data';

/// JavaScript interop type representing the browser's window object.
@JS()
extension type JSWindow._(JSObject _) implements JSObject {}

/// Extension providing access to window properties needed for Isar web.
extension JSWIndowX on JSWindow {
  /// Gets the Isar instance from the window object.
  external JSIsar get isar;

  /// Gets the WebAssembly API from the window object.
  ///
  /// ignored to avoid "non-constant identifier names" warning
  // ignore: non_constant_identifier_names
  external JSWasm get WebAssembly;

  /// Fetches a resource from the network.
  external JSObject fetch(String url);
}

/// JavaScript interop type representing the WebAssembly API.
@JS()
extension type JSWasm._(JSObject _) implements JSObject {}

/// Extension providing WebAssembly compilation and instantiation methods.
extension JSWasmX on JSWasm {
  /// Compiles and instantiates a WebAssembly module from a streaming source.
  external JSPromise<JSWasmModule> instantiateStreaming(
    JSObject source,
    JSAny importObject,
  );
}

/// JavaScript interop type representing a compiled WebAssembly module.
@JS()
extension type JSWasmModule._(JSObject _) implements JSObject {}

/// Extension providing access to the WebAssembly module instance.
extension JSWasmModuleX on JSWasmModule {
  /// Gets the instantiated WebAssembly instance.
  external JSWasmInstance get instance;
}

/// JavaScript interop type representing an instantiated WebAssembly instance.
@JS()
extension type JSWasmInstance._(JSObject _) implements JSObject {}

/// Extension providing access to exported WebAssembly functions and memory.
extension JSWasmInstanceX on JSWasmInstance {
  /// Gets the exported Isar functions from the WebAssembly instance.
  external JSIsar get exports;
}

/// JavaScript interop type representing the Isar WebAssembly API.
@JS()
extension type JSIsar._(JSObject _) implements JSObject {}

/// Extension providing access to Isar's memory management and heap views.
extension JSIsarX on JSIsar {
  /// Gets the WebAssembly linear memory object.
  external JsMemory get memory;

  /// Gets a Uint8List view of the WebAssembly heap.
  Uint8List get u8Heap => memory.buffer.toDart.asUint8List();

  /// Gets a Uint16List view of the WebAssembly heap.
  Uint16List get u16Heap => memory.buffer.toDart.asUint16List();

  /// Gets a Uint32List view of the WebAssembly heap.
  Uint32List get u32Heap => memory.buffer.toDart.asUint32List();

  /// Allocates memory in the WebAssembly heap.
  ///
  /// Returns a pointer to the allocated memory block.
  external int malloc(int byteCount);

  /// Frees previously allocated memory in the WebAssembly heap.
  external void free(int ptrAddress);
}

/// JavaScript interop type representing WebAssembly linear memory.
@JS()
extension type JsMemory._(JSObject _) implements JSObject {}

/// Extension providing access to the underlying memory buffer.
extension JsMemoryX on JsMemory {
  /// Gets the ArrayBuffer backing the WebAssembly memory.
  external JSArrayBuffer get buffer;
}
