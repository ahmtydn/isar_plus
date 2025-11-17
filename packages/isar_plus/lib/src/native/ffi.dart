import 'dart:typed_data';

import 'package:ffi/ffi.dart' as ffi;
import 'package:isar_plus/src/native/native.dart';

export 'dart:ffi';

export 'package:ffi/ffi.dart';

/// @nodoc
@tryInline
Pointer<T> ptrFromAddress<T extends NativeType>(int addr) =>
    Pointer.fromAddress(addr);

/// @nodoc
extension PointerPointerX<T extends NativeType> on Pointer<Pointer<T>> {
  /// @nodoc
  @tryInline
  Pointer<T> get ptrValue => value;

  /// @nodoc
  @tryInline
  set ptrValue(Pointer<T> ptr) => value = ptr;

  /// @nodoc
  @tryInline
  void setPtrAt(int index, Pointer<T> ptr) {
    this[index] = ptr;
  }
}

/// @nodoc
extension PointerBoolX on Pointer<Bool> {
  /// @nodoc
  @tryInline
  bool get boolValue => value;
}

/// @nodoc
extension PointerU8X on Pointer<Uint8> {
  /// @nodoc
  @tryInline
  Uint8List asU8List(int length) => asTypedList(length);
}

/// @nodoc
extension PointerUint16X on Pointer<Uint16> {
  /// @nodoc
  @tryInline
  Uint16List asU16List(int length) => asTypedList(length);
}

/// @nodoc
extension PointerUint32X on Pointer<Uint32> {
  /// @nodoc
  @tryInline
  int get u32Value => value;
}

/// @nodoc
const Allocator malloc = ffi.malloc;

/// @nodoc
final void Function(Pointer<NativeType> pointer) free = ffi.malloc.free;
