// Single-method abstracts are acceptable for defining contracts
// ignore_for_file: one_member_abstracts

part of 'package:isar_plus/isar_plus.dart';

/// Contract for objects that can be serialized to/from JSON.
///
/// Implementations must provide both instance serialization and static
/// deserialization capabilities. The static factory pattern is preferred
/// over constructors for better error handling and type safety.
///
/// Example implementation:
/// ```dart
/// class User implements DocumentSerializable {
///   const User({required this.id, required this.name});
///
///   final int id;
///   final String name;
///
///   @override
///   Map<String, dynamic> toJson() => {'id': id, 'name': name};
///
///   static User fromJson(Map<String, dynamic> json) {
///     return User(
///       id: json['id'] as int,
///       name: json['name'] as String,
///     );
///   }
/// }
/// ```
abstract interface class DocumentSerializable {
  /// Serializes this object to a JSON-compatible map.
  ///
  /// Should return a map containing only JSON-serializable values
  /// (String, int, double, bool, List, Map, null).
  Map<String, dynamic> toJson();
}

/// Enumeration of database change operations.
///
/// Each value represents a distinct type of modification that can occur
/// to data within a persistent storage system.
enum ChangeType {
  /// A new record was created and added to storage.
  insert('insert'),

  /// An existing record was modified in place.
  update('update'),

  /// A record was permanently removed from storage.
  delete('delete');

  const ChangeType(this.value);

  /// The string representation used in serialization.
  final String value;

  /// Parses a string value to a ChangeType, with error handling.
  static ChangeType fromString(String value) {
    for (final type in ChangeType.values) {
      if (type.value.toLowerCase() == value.toLowerCase()) {
        return type;
      }
    }
    throw ArgumentError.value(
      value,
      'value',
      'Invalid change type. Valid '
          'values: ${ChangeType.values.map((t) => t.value).join(', ')}',
    );
  }

  @override
  String toString() => value;
}

/// Immutable representation of a field-level change.
///
/// Captures the modification of a single field, preserving both the
/// previous state and the new state. Values are kept as dynamic to
/// accommodate the varying data types found in document databases.
///
/// The class implements value equality and provides comprehensive
/// debugging information.
@immutable
class FieldChange<T extends DocumentSerializable> {
  /// Creates a field change record.
  ///
  /// [fieldName] must be non-empty and represent a valid field identifier.
  /// [oldValue] represents the state before modification (null for inserts).
  /// [newValue] represents the state after modification (null for deletes).
  const FieldChange({required this.fieldName, this.oldValue, this.newValue})
    : assert(fieldName != '', 'Field name cannot be empty');

  /// Deserializes a FieldChange from JSON with validation.
  factory FieldChange.fromJson(
    Map<String, dynamic> json, {
    T Function(Map<String, dynamic>)? documentParser,
  }) {
    final fieldName = json['field_name'];
    if (fieldName is! String || fieldName.isEmpty) {
      throw const FormatException('field_name must be a non-empty string');
    }
    var oldValue = json['old_value'];
    var newValue = json['new_value'];
    if (fieldName == 'value') {
      if (oldValue is Map<String, dynamic> && documentParser != null) {
        oldValue = documentParser(oldValue);
      } else if (oldValue is String && documentParser != null) {
        final parsed = jsonDecode(oldValue) as Map<String, dynamic>;
        oldValue = documentParser(parsed);
      }
      if (newValue is Map<String, dynamic> && documentParser != null) {
        newValue = documentParser(newValue);
      } else if (newValue is String && documentParser != null) {
        final parsed = jsonDecode(newValue) as Map<String, dynamic>;
        newValue = documentParser(parsed);
      }
    }

    return FieldChange(
      fieldName: fieldName,
      oldValue: oldValue,
      newValue: newValue,
    );
  }

  /// The identifier of the field that was modified.
  final String fieldName;

  /// The value before the change occurred.
  ///
  /// Will be null for insert operations where no previous value existed.
  final Object? oldValue;

  /// The value after the change was applied.
  ///
  /// Will be null for delete operations where the value no longer exists.
  final Object? newValue;

  /// Determines if this represents a field creation (insert scenario).
  bool get isCreation => oldValue == null && newValue != null;

  /// Determines if this represents a field deletion (delete scenario).
  bool get isDeletion => oldValue != null && newValue == null;

  /// Determines if this represents a field modification (update scenario).
  bool get isModification => oldValue != null && newValue != null;

  /// Determines if the old and new values are effectively the same.
  bool get hasActualChange => !_valuesEqual(oldValue, newValue);

  /// Serializes this field change to JSON.
  Map<String, dynamic> toJson() => {
    'field_name': fieldName,
    'old_value': oldValue,
    'new_value': newValue,
  };

  /// Provides a comprehensive string representation for debugging.
  @override
  String toString() {
    final buffer = StringBuffer('FieldChange(')..write('field: $fieldName');

    if (isCreation) {
      buffer.write(', created: $newValue');
    } else if (isDeletion) {
      buffer.write(', deleted: $oldValue');
    } else {
      buffer.write(', $oldValue → $newValue');
    }

    buffer.write(')');
    return buffer.toString();
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FieldChange &&
          fieldName == other.fieldName &&
          _valuesEqual(oldValue, other.oldValue) &&
          _valuesEqual(newValue, other.newValue);

  @override
  int get hashCode => Object.hash(fieldName, oldValue, newValue);

  /// Compares two values for deep equality, handling collections properly.
  static bool _valuesEqual(Object? a, Object? b) {
    if (identical(a, b)) return true;
    if (a == null || b == null) return a == b;

    // Handle collections that might have same content but different references
    if (a is List && b is List) {
      if (a.length != b.length) return false;
      for (var i = 0; i < a.length; i++) {
        if (!_valuesEqual(a[i], b[i])) return false;
      }
      return true;
    }

    if (a is Map && b is Map) {
      if (a.length != b.length) return false;
      for (final key in a.keys) {
        if (!b.containsKey(key) || !_valuesEqual(a[key], b[key])) {
          return false;
        }
      }
      return true;
    }

    return a == b;
  }
}

/// Comprehensive record of a change event for a specific database entity.
///
/// This immutable class encapsulates all information about a modification
/// to a single object, including metadata, field-level changes, and
/// optionally the complete document state after the change.
///
/// The generic parameter [T] is constrained to types that can be serialized,
/// ensuring type safety for the full document representation.
@immutable
class ChangeDetail<T extends DocumentSerializable> {
  /// Creates a change detail record.
  ///
  /// [collectionName] identifies the data collection (table, index, etc.).
  /// [objectId] is the unique identifier within that collection.
  /// [changeType] specifies the nature of the modification.
  /// [fieldChanges] contains the individual field modifications.
  /// [fullDocument] holds the complete post-change state.
  /// [timestamp] records when the change occurred (defaults to current time).
  const ChangeDetail({
    required this.collectionName,
    required this.objectId,
    required this.changeType,
    required this.fieldChanges,
    required this.fullDocument,
    this.timestamp,
  }) : assert(collectionName != '', 'Collection name cannot be empty');

  /// Deserializes a ChangeDetail from JSON with robust error handling.
  factory ChangeDetail.fromJson(
    Map<String, dynamic> json, {
    T Function(Map<String, dynamic>)? documentParser,
  }) {
    try {
      final collectionName = json['collection_name'];
      if (collectionName is! String || collectionName.isEmpty) {
        throw const FormatException(
          'collection_name must be a non-empty string',
        );
      }

      final objectId = json['object_id'];
      if (objectId is! int) {
        throw const FormatException('object_id must be an integer');
      }

      final changeTypeStr = json['change_type'];
      if (changeTypeStr is! String) {
        throw const FormatException('change_type must be a string');
      }

      final changeType = ChangeType.fromString(changeTypeStr);

      final fieldChangesJson = json['field_changes'] as List<dynamic>? ?? [];
      final fieldChanges = fieldChangesJson
          .cast<Map<String, dynamic>>()
          .map(
            (json) =>
                FieldChange.fromJson(json, documentParser: documentParser),
          )
          .toList(growable: false);

      T fullDocument;
      final fullDocumentJson = json['full_document'];
      if (fullDocumentJson != null && documentParser != null) {
        if (fullDocumentJson is Map<String, dynamic>) {
          fullDocument = documentParser(fullDocumentJson);
        } else if (fullDocumentJson is String) {
          final parsed = jsonDecode(fullDocumentJson) as Map<String, dynamic>;
          fullDocument = documentParser(parsed);
        } else {
          throw const FormatException(
            'full_document must be a Map<String, dynamic> or JSON string',
          );
        }
      } else {
        throw const FormatException(
          'full_document is required and documentParser must be provided',
        );
      }

      DateTime? timestamp;
      final timestampValue = json['timestamp'];
      if (timestampValue is String && timestampValue.isNotEmpty) {
        timestamp = DateTime.tryParse(timestampValue);
      }

      return ChangeDetail<T>(
        collectionName: collectionName,
        objectId: objectId,
        changeType: changeType,
        fieldChanges: fieldChanges,
        fullDocument: fullDocument,
        timestamp: timestamp ?? DateTime.now(),
      );
    } catch (e, stack) {
      throw Exception(
        'Failed to deserialize ChangeDetail<$T> from JSON  '
        ':\nError: $e\nStack: $stack\nJSON: $json',
      );
    }
  }

  /// The name of the collection where this change occurred.
  final String collectionName;

  /// The unique identifier of the changed object within its collection.
  final int objectId;

  /// The type of database operation that was performed.
  final ChangeType changeType;

  /// When this change was recorded.
  final DateTime? timestamp;

  /// The complete document state after the change was applied.
  ///
  /// This contains the full document data and is guaranteed to be present.
  final T fullDocument;

  /// Individual field-level changes within this object.
  ///
  /// This list is immutable and contains detailed before/after information
  /// for each modified field.
  final List<FieldChange> fieldChanges;

  /// Indicates whether this change has any actual field modifications.
  bool get hasFieldChanges => fieldChanges.isNotEmpty;

  /// Returns only the field changes that represent actual value modifications.
  List<FieldChange> get significantChanges =>
      fieldChanges.where((change) => change.hasActualChange).toList();

  /// Gets the field names that were modified in this change.
  Set<String> get modifiedFields =>
      fieldChanges.map((change) => change.fieldName).toSet();

  /// Checks if a specific field was modified in this change.
  bool wasFieldModified(String fieldName) =>
      fieldChanges.any((change) => change.fieldName == fieldName);

  /// Gets the field change for a specific field, if it exists.
  FieldChange? getFieldChange(String fieldName) =>
      fieldChanges.cast<FieldChange?>().firstWhere(
        (change) => change?.fieldName == fieldName,
        orElse: () => null,
      );

  /// Serializes this change detail to JSON.
  Map<String, dynamic> toJson() => {
    'collection_name': collectionName,
    'object_id': objectId,
    'change_type': changeType.value,
    'timestamp': timestamp?.toIso8601String(),
    'full_document': fullDocument.toJson(),
    'field_changes': fieldChanges.map((fc) => fc.toJson()).toList(),
  };

  /// Creates a copy with modified fields.
  ChangeDetail<T> copyWith({
    String? collectionName,
    int? objectId,
    ChangeType? changeType,
    DateTime? timestamp,
    T? fullDocument,
    List<FieldChange>? fieldChanges,
  }) => ChangeDetail<T>(
    collectionName: collectionName ?? this.collectionName,
    objectId: objectId ?? this.objectId,
    changeType: changeType ?? this.changeType,
    timestamp: timestamp ?? this.timestamp,
    fullDocument: fullDocument ?? this.fullDocument,
    fieldChanges: fieldChanges ?? this.fieldChanges,
  );

  /// Provides detailed string representation for debugging and logging.
  @override
  String toString() {
    final buffer = StringBuffer()
      ..write('ChangeDetail<$T>(')
      ..write('collection: $collectionName, ')
      ..write('id: $objectId, ')
      ..write('type: $changeType, ')
      ..write('timestamp: ${timestamp?.toIso8601String()}, ')
      ..write('fieldChanges: ${fieldChanges.length}')
      ..write(')');

    return buffer.toString();
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ChangeDetail<T> &&
          collectionName == other.collectionName &&
          objectId == other.objectId &&
          changeType == other.changeType &&
          timestamp == other.timestamp &&
          fullDocument == other.fullDocument &&
          _listEquals(fieldChanges, other.fieldChanges);

  @override
  int get hashCode => Object.hash(
    collectionName,
    objectId,
    changeType,
    timestamp,
    fullDocument,
    Object.hashAll(fieldChanges),
  );

  /// Efficiently compares two lists for equality.
  static bool _listEquals<E>(List<E> a, List<E> b) {
    if (identical(a, b)) return true;
    if (a.length != b.length) return false;

    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }

    return true;
  }
}
