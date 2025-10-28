part of 'package:isar_plus/isar_plus.dart';

/// @nodoc
abstract final class IsarCore {
  /// Whether the code is running on the web platform.
  static const bool kIsWeb = bool.fromEnvironment('dart.library.js_util');

  static var _initialized = false;
  static String? _library;
  static var _webPersistenceReady = false;
  static Future<void>? _webPersistencePending;

  /// The Isar core bindings.
  static late final IsarCoreBindings b;

  /// Pointer to a pointer for native operations.
  static Pointer<Pointer<NativeType>> ptrPtr = malloc<Pointer<NativeType>>();

  /// Pointer to a uint32 for count operations.
  static Pointer<Uint32> countPtr = malloc<Uint32>();

  /// Pointer to a bool for boolean operations.
  static Pointer<Bool> boolPtr = malloc<Bool>();

  /// Pointer to a pointer to uint8 for string operations.
  static final Pointer<Pointer<Uint8>> stringPtrPtr =
      ptrPtr.cast<Pointer<Uint8>>();

  /// Gets the string pointer value.
  static Pointer<Uint8> get stringPtr => stringPtrPtr.ptrValue;

  /// Pointer to a pointer to CIsarReader for reader operations.
  static final Pointer<Pointer<CIsarReader>> readerPtrPtr =
      ptrPtr.cast<Pointer<CIsarReader>>();

  /// Gets the reader pointer value.
  static Pointer<CIsarReader> get readerPtr => readerPtrPtr.ptrValue;

  static Pointer<Uint16> _nativeStringPtr = nullptr;
  static int _nativeStringPtrLength = 0;

  static FutureOr<void> _initialize({String? library, bool explicit = false}) {
    if (_initialized) {
      return null;
    }

    if (kIsWeb && !explicit) {
      throw IsarNotReadyError(
        'On web you have to call Isar.initialize() '
        'manually before using Isar.',
      );
    }

    final result = initializePlatformBindings(library);
    return Future.value(result).then((bindings) async {
      b = bindings;
      _library = library;
      if (kIsWeb) {
        await _ensureWebPersistence();
      }
      _initialized = true;
    });
  }

  static void _free() {
    free(ptrPtr);
    free(countPtr);
    free(boolPtr);
    if (!_nativeStringPtr.isNull) {
      free(_nativeStringPtr);
    }
  }

  static Pointer<CString> _toNativeString(String str) {
    if (_nativeStringPtrLength < str.length) {
      if (_nativeStringPtr != nullptr) {
        free(_nativeStringPtr);
      }
      _nativeStringPtr = malloc<Uint16>(str.length);
      _nativeStringPtrLength = str.length;
    }

    final list = _nativeStringPtr.asU16List(str.length);
    for (var i = 0; i < str.length; i++) {
      list[i] = str.codeUnitAt(i);
    }

    return b.isar_string(_nativeStringPtr, str.length);
  }

  @tryInline
  /// Reads an ID value from the reader.
  static int readId(Pointer<CIsarReader> reader) {
    return b.isar_read_id(reader);
  }

  @tryInline
  /// Reads a null check from the reader at the given index.
  static bool readNull(Pointer<CIsarReader> reader, int index) {
    return b.isar_read_null(reader, index) != 0;
  }

  @tryInline
  /// Reads a boolean value from the reader at the given index.
  static bool readBool(Pointer<CIsarReader> reader, int index) {
    return b.isar_read_bool(reader, index) != 0;
  }

  @tryInline
  /// Reads a byte value from the reader at the given index.
  static int readByte(Pointer<CIsarReader> reader, int index) {
    return b.isar_read_byte(reader, index);
  }

  @tryInline
  /// Reads an integer value from the reader at the given index.
  static int readInt(Pointer<CIsarReader> reader, int index) {
    return b.isar_read_int(reader, index);
  }

  @tryInline
  /// Reads a float value from the reader at the given index.
  static double readFloat(Pointer<CIsarReader> reader, int index) {
    return b.isar_read_float(reader, index);
  }

  @tryInline
  /// Reads a long value from the reader at the given index.
  static int readLong(Pointer<CIsarReader> reader, int index) {
    return b.isar_read_long(reader, index);
  }

  @tryInline
  /// Reads a double value from the reader at the given index.
  static double readDouble(Pointer<CIsarReader> reader, int index) {
    return b.isar_read_double(reader, index);
  }

  @tryInline
  /// Reads a string value from the reader at the given index.
  static String? readString(Pointer<CIsarReader> reader, int index) {
    final length = b.isar_read_string(reader, index, stringPtrPtr, boolPtr);
    if (stringPtr.isNull) {
      return null;
    } else {
      final bytes = stringPtr.asU8List(length);
      if (boolPtr.boolValue) {
        return String.fromCharCodes(bytes);
      } else {
        return utf8.decode(bytes);
      }
    }
  }

  @tryInline
  /// Reads an object from the reader at the given index.
  static Pointer<CIsarReader> readObject(
    Pointer<CIsarReader> reader,
    int index,
  ) {
    return b.isar_read_object(reader, index);
  }

  @tryInline
  /// Reads a list from the reader at the given index.
  static int readList(
    Pointer<CIsarReader> reader,
    int index,
    Pointer<Pointer<CIsarReader>> listReader,
  ) {
    return b.isar_read_list(reader, index, listReader);
  }

  @tryInline
  /// Frees the reader.
  static void freeReader(Pointer<CIsarReader> reader) {
    b.isar_read_free(reader);
  }

  @tryInline
  /// Writes a null value to the writer at the given index.
  static void writeNull(Pointer<CIsarWriter> writer, int index) {
    b.isar_write_null(writer, index);
  }

  @tryInline
  /// Writes a boolean value to the writer at the given index.
  static void writeBool(
    Pointer<CIsarWriter> writer,
    int index, {
    required bool value,
  }) {
    b.isar_write_bool(writer, index, value);
  }

  @tryInline
  /// Writes a byte value to the writer at the given index.
  static void writeByte(Pointer<CIsarWriter> writer, int index, int value) {
    b.isar_write_byte(writer, index, value);
  }

  @tryInline
  /// Writes an integer value to the writer at the given index.
  static void writeInt(Pointer<CIsarWriter> writer, int index, int value) {
    b.isar_write_int(writer, index, value);
  }

  @tryInline
  /// Writes a float value to the writer at the given index.
  static void writeFloat(Pointer<CIsarWriter> writer, int index, double value) {
    b.isar_write_float(writer, index, value);
  }

  @tryInline
  /// Writes a long value to the writer at the given index.
  static void writeLong(Pointer<CIsarWriter> writer, int index, int value) {
    b.isar_write_long(writer, index, value);
  }

  @tryInline
  /// Writes a double value to the writer at the given index.
  static void writeDouble(
    Pointer<CIsarWriter> writer,
    int index,
    double value,
  ) {
    b.isar_write_double(writer, index, value);
  }

  @tryInline
  /// Writes a string value to the writer at the given index.
  static void writeString(
    Pointer<CIsarWriter> writer,
    int index,
    String value,
  ) {
    final valuePtr = _toNativeString(value);
    b.isar_write_string(writer, index, valuePtr);
  }

  @tryInline
  /// Begins writing an object to the writer at the given index.
  static Pointer<CIsarWriter> beginObject(
    Pointer<CIsarWriter> writer,
    int index,
  ) {
    return b.isar_write_object(writer, index);
  }

  @tryInline
  /// Ends writing an object to the writer.
  static void endObject(
    Pointer<CIsarWriter> writer,
    Pointer<CIsarWriter> objectWriter,
  ) {
    b.isar_write_object_end(writer, objectWriter);
  }

  static Future<void> _ensureWebPersistence() async {
    if (!kIsWeb || _webPersistenceReady) {
      return;
    }

    if (_webPersistencePending != null) {
      await _webPersistencePending;
      return;
    }

    final future = _initializeWebPersistence();
    _webPersistencePending = future;
    try {
      await future;
    } finally {
      _webPersistencePending = null;
    }
  }

  static Future<void> _initializeWebPersistence() async {
    final directoryPtr = _toNativeString('isar');
    final handle = b.isar_web_persistence_start(directoryPtr);
    const pollInterval = Duration(milliseconds: 15);

    while (true) {
      final status = b.isar_web_persistence_poll(handle);
      if (status == 0) {
        await Future<void>.delayed(pollInterval);
        continue;
      }

      if (status == 1) {
        _webPersistenceReady = true;
        return;
      }

      final error =
          _currentErrorMessage() ??
          'Failed to initialize Isar web persistence backend.';
      throw DatabaseError(error);
    }
  }

  static String? _currentErrorMessage() {
    final length = b.isar_get_error(stringPtrPtr);
    final ptr = stringPtr;
    if (length == 0 || ptr.isNull) {
      return null;
    }
    return utf8.decode(ptr.asU8List(length));
  }

  @tryInline
  /// Begins writing a list to the writer at the given index.
  static Pointer<CIsarWriter> beginList(
    Pointer<CIsarWriter> writer,
    int index,
    int length,
  ) {
    return b.isar_write_list(writer, index, length);
  }

  @tryInline
  /// Ends writing a list to the writer.
  static void endList(
    Pointer<CIsarWriter> writer,
    Pointer<CIsarWriter> listWriter,
  ) {
    b.isar_write_list_end(writer, listWriter);
  }
}

/// @nodoc
extension PointerX on Pointer<void> {
  @tryInline
  /// Returns true if the pointer is null.
  bool get isNull => address == 0;
}
