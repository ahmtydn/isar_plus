part of 'package:isar_plus/isar_plus.dart';

/// Use `IsarCollection` instances to find, query, and create new objects of a
/// given type in Isar.
///
/// You can get an instance of `IsarCollection` by calling `isar.get<OBJ>()` or
/// by using the generated `isar.yourCollections` getter.
@pragma('vm:isolate-unsendable')
abstract class IsarCollection<ID, OBJ> {
  /// The corresponding Isar instance.
  Isar get isar;

  /// The schema of this collection.
  IsarSchema get schema;

  /// Fetch the next auto increment id for this collection.
  ///
  /// After an app restart the auto increment counter will be set to the largest
  /// id in the collection. If the collection is empty, the counter will be set
  /// to 1.
  int autoIncrement();

  /// {@template collection_get}
  /// Get a single object by its [id]. Returns `null` if the object does not
  /// exist.
  /// {@endtemplate}
  OBJ? get(ID id) => getAll([id]).firstOrNull;

  /// {@template collection_get_all}
  /// Get a list of objects by their [ids]. Objects in the list are `null`
  /// if they don't exist.
  /// {@endtemplate}
  List<OBJ?> getAll(List<ID> ids);

  /// Insert or update the [object].
  void put(OBJ object) => putAll([object]);

  /// Insert or update a list of [objects].
  void putAll(List<OBJ> objects);

  /// This is a low level method to update objects.
  ///
  /// It is not recommended to use this method directly, instead use the
  /// generated `update()` method.
  @protected
  int updateProperties(List<ID> ids, Map<int, dynamic> changes);

  /// Delete a single object by its [id].
  ///
  /// Returns whether the object has been deleted.
  bool delete(ID id);

  /// Delete a list of objects by their [ids].
  ///
  /// Returns the number of deleted objects.
  int deleteAll(List<ID> ids);

  /// Start building a query using the [QueryBuilder].
  QueryBuilder<OBJ, OBJ, QStart> where();

  /// Returns the total number of objects in this collection.
  ///
  /// This method is extremely fast and independent of the
  /// number of objects in the collection.
  int count();

  /// Calculates the size of the collection in bytes.
  int getSize({bool includeIndexes = false});

  /// Import a list of json objects.
  ///
  /// The json objects must have the same structure as the objects in this
  /// collection. Otherwise an exception will be thrown.
  int importJson(List<Map<String, dynamic>> json) =>
      importJsonString(jsonEncode(json));

  /// Import a list of json objects.
  ///
  /// The json objects must have the same structure as the objects in this
  /// collection. Otherwise an exception will be thrown.
  int importJsonString(String json);

  /// Remove all data in this collection and reset the auto increment value.
  void clear();

  /// Watch the collection for changes.
  ///
  /// If [fireImmediately] is `true`, an event will be fired immediately.
  Stream<void> watchLazy({bool fireImmediately = false});

  /// Watch the object with [id] for changes. If a change occurs, the new object
  /// will be returned in the stream.
  ///
  /// Objects that don't exist (yet) can also be watched. If [fireImmediately]
  /// is `true`, the object will be sent to the consumer immediately.
  Stream<OBJ?> watchObject(ID id, {bool fireImmediately = false});

  /// Watch the object with [id] for changes.
  ///
  /// If [fireImmediately] is `true`, an event will be fired immediately.
  Stream<void> watchObjectLazy(ID id, {bool fireImmediately = false});

  /// Watch the collection for detailed changes with field-level tracking.
  ///
  /// Returns a stream of [ChangeDetail] objects that contain comprehensive
  /// information about each change that occurs in the collection, including:
  /// - The type of change (insert, update, delete)
  /// - Individual field changes with before/after values
  /// - Complete document representation (if T extends DocumentSerializable)
  /// - Object ID and collection name
  ///
  /// **Type Parameter:**
  /// - `T`: The type to parse fullDocument into.
  ///  Must extend [DocumentSerializable]
  ///   to enable automatic JSON parsing,
  /// or use custom parsing with documentParser.
  ///
  /// **Platform Support:**
  /// This method is not supported on web platforms and will throw an
  /// [UnsupportedError] if called on web.
  ///
  /// **Usage Examples:**
  ///
  /// Basic usage without document parsing:
  /// ```dart
  /// collection.watchDetailed<dynamic>().listen((change) {
  ///   print('Change type: ${change.changeType}');
  ///   print('Object ID: ${change.objectId}');
  ///   print('Field changes: ${change.fieldChanges.length}');
  /// });
  /// ```
  ///
  /// With custom document parsing:
  /// ```dart
  /// class User extends DocumentSerializable {
  ///   final String name;
  ///   final int age;
  ///
  ///   User({required this.name, required this.age});
  ///
  ///   factory User.fromJsonString(String json) {
  ///     final map = jsonDecode(json);
  ///     return User(name: map['name'], age: map['age']);
  ///   }
  ///
  ///   @override
  ///   Map<String, dynamic> toJson() => {'name': name, 'age': age};
  /// }
  ///
  /// collection.watchDetailed<User>().listen((change) {
  ///   print('User name: ${change.fullDocument.name}');
  ///   print('User age: ${change.fullDocument.age}');
  /// });
  /// ```
  ///
  /// **Performance Considerations:**
  /// - Detailed watchers have more overhead than regular watchers
  /// - Field-level change tracking requires additional processing
  /// - Consider using [watchLazy] if you only need change notifications
  /// - The stream automatically handles cleanup when canceled
  ///
  /// **Change Types:**
  /// - [ChangeType.insert]: New object was added to the collection
  /// - [ChangeType.update]: Existing object was modified
  /// - [ChangeType.delete]: Object was removed from the collection
  ///
  /// **Thread Safety:**
  /// This method is thread-safe and can be called from any isolate.
  /// The returned stream will emit changes that occur across all isolates.
  ///
  /// @throws UnsupportedError if called on web platforms
  /// @returns A stream of [ChangeDetail] objects representing database changes
  Stream<ChangeDetail<T>> watchDetailed<T extends DocumentSerializable>({
    T Function(Map<String, dynamic> json)? documentParser,
  });

  /// Build a query dynamically for example to build a custom query language.
  ///
  /// It is highly discouraged to use this method. Only in very special cases
  /// should it be used. If you open an issue please always mention that you
  /// used this method.
  ///
  /// The type argument [R] needs to be equal to [OBJ] if no [properties] are
  /// specified. Otherwise it should be the type of the property.
  @experimental
  IsarQuery<R> buildQuery<R>({
    Filter? filter,
    List<SortProperty>? sortBy,
    List<DistinctProperty>? distinctBy,
    List<int>? properties,
  });
}

/// Asychronous extensions for [IsarCollection].
extension CollectionAsync<ID, OBJ> on IsarCollection<ID, OBJ> {
  /// {@macro collection_get}
  Future<OBJ?> getAsync(ID id) {
    return isar.readAsync((isar) => isar.collection<ID, OBJ>().get(id));
  }

  /// {@macro collection_get_all}
  Future<List<OBJ?>> getAllAsync(List<ID> ids) {
    return isar.readAsync((isar) => isar.collection<ID, OBJ>().getAll(ids));
  }
}
