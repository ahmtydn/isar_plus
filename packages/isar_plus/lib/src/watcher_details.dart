part of isar_plus;

/// Represents the type of change that occurred in a database operation.
///
/// This enum is used to categorize different types of database changes
/// for change tracking and auditing purposes.
enum ChangeType {
  /// A new record was inserted into the database
  insert,

  /// An existing record was modified
  update,

  /// A record was removed from the database
  delete,
}

/// Represents a field change with before and after values.
///
/// This class captures the details of a single field modification,
/// storing both the old value (before change) and new value (after change).
///
/// Example:
/// ```dart
/// final change = FieldChange(
///   fieldName: 'name',
///   oldValue: 'John',
///   newValue: 'Jane',
/// );
/// ```
class FieldChange {
  /// Creates a new [FieldChange] instance.
  ///
  /// [fieldName] is required and represents the name of the changed field.
  /// [oldValue] is the previous value of the field (null for inserts).
  /// [newValue] is the current value of the field (null for deletes).
  FieldChange({required this.fieldName, this.oldValue, this.newValue});

  /// Creates a [FieldChange] instance from a JSON map.
  ///
  /// Expected JSON format:
  /// ```json
  /// {
  ///   "field_name": "fieldName",
  ///   "old_value": "previousValue",
  ///   "new_value": "currentValue"
  /// }
  /// ```
  ///
  /// Throws [TypeError] if the JSON structure is invalid.
  factory FieldChange.fromJson(Map<String, dynamic> json) {
    return FieldChange(
      fieldName: json['field_name'] as String,
      oldValue: json['old_value'] as String?,
      newValue: json['new_value'] as String?,
    );
  }

  /// The name of the field that was changed.
  final String fieldName;

  /// The previous value of the field before the change.
  ///
  /// This will be null for insert operations since there was no previous value.
  final String? oldValue;

  /// The new value of the field after the change.
  ///
  /// This will be null for delete operations since the field no longer exists.
  final String? newValue;

  /// Converts this [FieldChange] instance to a JSON map.
  ///
  /// Returns a map suitable for JSON serialization with keys:
  /// - `field_name`: The field name
  /// - `old_value`: The previous value (may be null)
  /// - `new_value`: The current value (may be null)
  Map<String, dynamic> toJson() {
    return {
      'field_name': fieldName,
      'old_value': oldValue,
      'new_value': newValue,
    };
  }

  /// Returns a string representation of this field change.
  ///
  /// Format: `FieldChange(field: fieldName, old: oldValue, new: newValue)`
  @override
  String toString() {
    return 'FieldChange(field: $fieldName, old: $oldValue, new: $newValue)';
  }
}

/// Detailed change information for a single database object.
///
/// This class contains comprehensive information about a change that occurred
/// to a specific object in the database, including what changed and how.
///
/// Example usage:
/// ```dart
/// final changeDetail = ChangeDetail(
///   collectionName: 'users',
///   objectId: 123,
///   changeType: ChangeType.update,
///   fieldChanges: [
///     FieldChange(fieldName: 'email', oldValue: 'old@test.com', newValue: 'new@test.com')
///   ],
/// );
/// ```
class ChangeDetail {
  /// Creates a new [ChangeDetail] instance.
  ///
  /// [collectionName] is the name of the collection/table where the change occurred.
  /// [objectId] is the unique identifier of the changed object.
  /// [changeType] specifies what type of change occurred (insert, update, delete).
  /// [fullDocument] is an optional complete representation of the object after change.
  /// [fieldChanges] is a list of individual field changes within the object.
  ChangeDetail({
    required this.collectionName,
    required this.objectId,
    required this.changeType,
    this.fullDocument,
    required this.fieldChanges,
  });

  /// Creates a [ChangeDetail] instance from a JSON map.
  ///
  /// Expected JSON format:
  /// ```json
  /// {
  ///   "collection_name": "tableName",
  ///   "object_id": 123,
  ///   "change_type": "update",
  ///   "full_document": "optional_document_json",
  ///   "field_changes": [...]
  /// }
  /// ```
  ///
  /// If the change_type is invalid, defaults to [ChangeType.update].
  /// If field_changes is missing, defaults to an empty list.
  ///
  /// Throws [TypeError] if required fields are missing or have wrong types.
  factory ChangeDetail.fromJson(Map<String, dynamic> json) {
    final changeTypeStr = json['change_type'] as String;
    final changeType = ChangeType.values.firstWhere(
      (e) => e.name == changeTypeStr,
      orElse: () => ChangeType.update,
    );

    final fieldChangesJson = json['field_changes'] as List<dynamic>? ?? [];
    final fieldChanges =
        fieldChangesJson
            .map((json) => FieldChange.fromJson(json as Map<String, dynamic>))
            .toList();

    return ChangeDetail(
      collectionName: json['collection_name'] as String,
      objectId: json['object_id'] as int,
      changeType: changeType,
      fullDocument: json['full_document'] as String?,
      fieldChanges: fieldChanges,
    );
  }

  /// The name of the collection or table where the change occurred.
  final String collectionName;

  /// The unique identifier of the object that was changed.
  final int objectId;

  /// The type of change that occurred (insert, update, or delete).
  final ChangeType changeType;

  /// Optional complete document representation after the change.
  ///
  /// This might contain a JSON string or other serialized representation
  /// of the entire object after the change was applied.
  final String? fullDocument;

  /// List of individual field changes within this object.
  ///
  /// Each [FieldChange] represents a modification to a specific field,
  /// showing the before and after values.
  final List<FieldChange> fieldChanges;

  /// Converts this [ChangeDetail] instance to a JSON map.
  ///
  /// Returns a map suitable for JSON serialization containing all
  /// the change information including nested field changes.
  Map<String, dynamic> toJson() {
    return {
      'collection_name': collectionName,
      'object_id': objectId,
      'change_type': changeType.name,
      'full_document': fullDocument,
      'field_changes': fieldChanges.map((fc) => fc.toJson()).toList(),
    };
  }

  /// Returns a string representation of this change detail.
  ///
  /// Format: `ChangeDetail(collection: name, id: objectId,
  /// type: changeType, changes: count)`
  ///
  /// The changes count shows how many individual field changes are included.
  @override
  String toString() {
    return 'ChangeDetail(collection: $collectionName, id: $objectId, '
        'type: $changeType, changes: ${fieldChanges.length})';
  }
}
