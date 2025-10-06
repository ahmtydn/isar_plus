import 'dart:js_interop';
import 'dart:typed_data';

@JS()
extension type JSWindow._(JSObject _) implements JSObject {}

extension JSWIndowX on JSWindow {
  external JSIsar get isar;

  /// ignored to avoid "non-constant identifier names" warning
  // ignore: non_constant_identifier_names
  external JSWasm get WebAssembly;

  external JSObject fetch(String url);
}

@JS()
extension type JSWasm._(JSObject _) implements JSObject {}

extension JSWasmX on JSWasm {
  external JSPromise<JSWasmModule> instantiateStreaming(
    JSObject source,
    JSAny importObject,
  );
}

@JS()
extension type JSWasmModule._(JSObject _) implements JSObject {}

extension JSWasmModuleX on JSWasmModule {
  external JSWasmInstance get instance;
}

@JS()
extension type JSWasmInstance._(JSObject _) implements JSObject {}

extension JSWasmInstanceX on JSWasmInstance {
  external JSIsar get exports;
}

@JS()
extension type JSIsar._(JSObject _) implements JSObject {}

extension JSIsarX on JSIsar {
  external JsMemory get memory;

  Uint8List get u8Heap => memory.buffer.toDart.asUint8List();

  Uint16List get u16Heap => memory.buffer.toDart.asUint16List();

  Uint32List get u32Heap => memory.buffer.toDart.asUint32List();

  external int malloc(int byteCount);

  external void free(int ptrAddress);
}

@JS()
extension type JsMemory._(JSObject _) implements JSObject {}

extension JsMemoryX on JsMemory {
  external JSArrayBuffer get buffer;
}
