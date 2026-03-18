import 'package:isar_plus/isar_plus.dart';

/// Actions for Isar Connect communication.
enum ConnectAction {
  /// List all instances.
  listInstances('ext.isar.listInstances'),

  /// Get schemas.
  getSchemas('ext.isar.getSchemas'),

  /// Watch an instance.
  watchInstance('ext.isar.watchInstance'),

  /// Execute a query.
  executeQuery('ext.isar.executeQuery'),

  /// Delete a query.
  deleteQuery('ext.isar.deleteQuery'),

  /// Import JSON.
  importJson('ext.isar.importJson'),

  /// Export JSON.
  exportJson('ext.isar.exportJson'),

  /// Edit a property.
  editProperty('ext.isar.editProperty');

  const ConnectAction(this.method);

  /// The method name for the action.
  final String method;
}

/// Events for Isar Connect communication.
enum ConnectEvent {
  /// Instances changed.
  instancesChanged('isar.instancesChanged'),

  /// Query changed.
  queryChanged('isar.queryChanged'),

  /// Collection info changed.
  collectionInfoChanged('isar.collectionInfoChanged');

  const ConnectEvent(this.event);

  /// The event name.
  final String event;
}

/// Payload for connect instance.
class ConnectInstancePayload {
  /// Creates a [ConnectInstancePayload].
  ConnectInstancePayload(this.instance);

  /// Creates a [ConnectInstancePayload] from JSON.
  factory ConnectInstancePayload.fromJson(Map<String, dynamic> json) {
    return ConnectInstancePayload(json['instance'] as String);
  }

  /// The instance name.
  final String instance;

  /// Converts this payload to JSON.
  Map<String, dynamic> toJson() {
    return {'instance': instance};
  }
}

/// Payload for connect instance names.
/// Payload for connect instance names.
class ConnectInstanceNamesPayload {
  /// Creates a [ConnectInstanceNamesPayload].
  ConnectInstanceNamesPayload(this.instances);

  /// Creates a [ConnectInstanceNamesPayload] from JSON.
  factory ConnectInstanceNamesPayload.fromJson(Map<String, dynamic> json) {
    return ConnectInstanceNamesPayload(
      (json['instances'] as List).cast<String>(),
    );
  }

  /// The list of instance names.
  final List<String> instances;

  /// Converts this payload to JSON.
  Map<String, dynamic> toJson() {
    return {'instances': instances};
  }
}

/// Payload for schemas.
class ConnectSchemasPayload {
  /// Creates a [ConnectSchemasPayload].
  ConnectSchemasPayload(this.schemas);

  /// Creates a [ConnectSchemasPayload] from JSON.
  factory ConnectSchemasPayload.fromJson(Map<String, dynamic> json) {
    return ConnectSchemasPayload(
      (json['schemas'] as List)
          .map((e) => IsarSchema.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  /// The list of schemas.
  final List<IsarSchema> schemas;

  /// Converts this payload to JSON.
  Map<String, dynamic> toJson() {
    return {'schemas': schemas.map((e) => e.toJson()).toList()};
  }
}

/// Payload for executing a query.
class ConnectQueryPayload {
  /// Creates a [ConnectQueryPayload].
  ConnectQueryPayload({
    required this.instance,
    required this.collection,
    this.filter,
    this.offset,
    this.limit,
    this.sortProperty,
    this.sortAsc = true,
  });

  /// Creates a [ConnectQueryPayload] from JSON.
  factory ConnectQueryPayload.fromJson(Map<String, dynamic> json) {
    return ConnectQueryPayload(
      instance: json['instance'] as String,
      collection: json['collection'] as String,
      filter: json['filter'] != null
          ? _filterFromJson(json['filter'] as Map<String, dynamic>)
          : null,
      offset: json['offset'] as int?,
      limit: json['limit'] as int?,
      sortProperty: json['sortProperty'] as int?,
      sortAsc: json['sortAsc'] as bool,
    );
  }

  /// The instance name.
  final String instance;

  /// The collection name.
  final String collection;

  /// The filter to apply.
  final Filter? filter;

  /// The offset for pagination.
  final int? offset;

  /// The limit for pagination.
  final int? limit;

  /// The property to sort by.
  final int? sortProperty;

  /// Whether to sort ascending.
  final bool sortAsc;

  /// Converts this payload to JSON.
  Map<String, dynamic> toJson() {
    return {
      'instance': instance,
      'collection': collection,
      if (filter != null) 'filter': _filterToJson(filter!),
      if (offset != null) 'offset': offset,
      if (limit != null) 'limit': limit,
      if (sortProperty != null) 'sortProperty': sortProperty,
      'sortAsc': sortAsc,
    };
  }

  /// Converts a JSON map to a Filter.
  static Filter _filterFromJson(Map<String, dynamic> json) {
    final property = json['property'] as int?;
    final value = json['value'] ?? json['wildcard'];
    switch (json['type']) {
      case 'eq':
        return EqualCondition(property: property!, value: value);
      case 'gt':
        return GreaterCondition(property: property!, value: value);
      case 'gte':
        return GreaterOrEqualCondition(property: property!, value: value);
      case 'lt':
        return LessCondition(property: property!, value: value);
      case 'lte':
        return LessOrEqualCondition(property: property!, value: value);
      case 'between':
        return BetweenCondition(
          property: property!,
          lower: json['lower'],
          upper: json['upper'],
        );
      case 'startsWith':
        return StartsWithCondition(property: property!, value: value as String);
      case 'endsWith':
        return EndsWithCondition(property: property!, value: value as String);
      case 'contains':
        return ContainsCondition(property: property!, value: value as String);
      case 'matches':
        return MatchesCondition(property: property!, wildcard: value as String);
      case 'isNull':
        return IsNullCondition(property: property!);
      case 'and':
        return AndGroup(
          (json['filters'] as List)
              .map((e) => _filterFromJson(e as Map<String, dynamic>))
              .toList(),
        );
      case 'or':
        return OrGroup(
          (json['filters'] as List)
              .map((e) => _filterFromJson(e as Map<String, dynamic>))
              .toList(),
        );
      case 'not':
        return NotGroup(
          _filterFromJson(json['filter'] as Map<String, dynamic>),
        );
      default:
        throw UnimplementedError();
    }
  }

  /// Converts a Filter to a JSON map.
  static Map<String, dynamic> _filterToJson(Filter filter) {
    switch (filter) {
      case EqualCondition(:final property, :final value):
        return {'type': 'eq', 'property': property, 'value': value};
      case GreaterCondition(:final property, :final value):
        return {'type': 'gt', 'property': property, 'value': value};
      case GreaterOrEqualCondition(:final property, :final value):
        return {'type': 'gte', 'property': property, 'value': value};
      case LessCondition(:final property, :final value):
        return {'type': 'lt', 'property': property, 'value': value};
      case LessOrEqualCondition(:final property, :final value):
        return {'type': 'lte', 'property': property, 'value': value};
      case BetweenCondition(:final property, :final lower, :final upper):
        return {
          'type': 'between',
          'property': property,
          'lower': lower,
          'upper': upper,
        };
      case StartsWithCondition(:final property, :final value):
        return {'type': 'startsWith', 'property': property, 'value': value};
      case EndsWithCondition(:final property, :final value):
        return {'type': 'endsWith', 'property': property, 'value': value};
      case ContainsCondition(:final property, :final value):
        return {'type': 'contains', 'property': property, 'value': value};
      case MatchesCondition(:final property, :final wildcard):
        return {'type': 'matches', 'property': property, 'value': wildcard};
      case IsNullCondition(:final property):
        return {'type': 'isNull', 'property': property};
      case AndGroup(:final filters):
        return {'type': 'and', 'filters': filters.map(_filterToJson).toList()};
      case OrGroup(:final filters):
        return {'type': 'or', 'filters': filters.map(_filterToJson).toList()};
      case NotGroup(:final filter):
        return {'type': 'not', 'filter': _filterToJson(filter)};
      case ObjectFilter():
        throw UnimplementedError();
    }
  }

  /// Converts this payload to an Isar query.
  IsarQuery<dynamic> toQuery(Isar isar) {
    final colIndex = isar.schemas.indexWhere((e) => e.name == this.collection);
    final collection = isar.collectionByIndex<dynamic, dynamic>(colIndex);
    return collection.buildQuery(
      filter: filter,
      sortBy: [
        if (sortProperty != null)
          SortProperty(
            property: sortProperty!,
            sort: sortAsc ? Sort.asc : Sort.desc,
          ),
      ],
    );
  }
}

/// Payload for editing a property.
class ConnectEditPayload {
  /// Creates a [ConnectEditPayload].
  ConnectEditPayload({
    required this.instance,
    required this.collection,
    required this.id,
    required this.path,
    required this.value,
  });

  /// Creates a [ConnectEditPayload] from JSON.
  factory ConnectEditPayload.fromJson(Map<String, dynamic> json) {
    return ConnectEditPayload(
      instance: json['instance'] as String,
      collection: json['collection'] as String,
      id: json['id'],
      path: json['path'] as String,
      value: json['value'],
    );
  }

  /// The instance name.
  final String instance;

  /// The collection name.
  final String collection;

  /// The object ID.
  final dynamic id;

  /// The property path.
  final String path;

  /// The new value.
  final dynamic value;

  /// Converts this payload to JSON.
  Map<String, dynamic> toJson() {
    return {
      'instance': instance,
      'collection': collection,
      'id': id,
      'path': path,
      'value': value,
    };
  }
}

/// Payload for collection info.
class ConnectCollectionInfoPayload {
  /// Creates a [ConnectCollectionInfoPayload].
  ConnectCollectionInfoPayload({
    required this.instance,
    required this.collection,
    required this.size,
    required this.count,
  });

  /// Creates a [ConnectCollectionInfoPayload] from JSON.
  factory ConnectCollectionInfoPayload.fromJson(Map<String, dynamic> json) {
    return ConnectCollectionInfoPayload(
      instance: json['instance'] as String,
      collection: json['collection'] as String,
      size: json['size'] as int,
      count: json['count'] as int,
    );
  }

  /// The instance name.
  final String instance;

  /// The collection name.
  final String collection;

  /// The size in bytes.
  final int size;

  /// The number of objects.
  final int count;

  /// Converts this payload to JSON.
  Map<String, dynamic> toJson() {
    return {
      'instance': instance,
      'collection': collection,
      'size': size,
      'count': count,
    };
  }
}

/// Payload for objects.
class ConnectObjectsPayload {
  /// Creates a [ConnectObjectsPayload].
  ConnectObjectsPayload({
    required this.instance,
    required this.collection,
    required this.objects,
    int? count,
  }) : count = count ?? objects.length;

  /// Creates a [ConnectObjectsPayload] from JSON.
  factory ConnectObjectsPayload.fromJson(Map<String, dynamic> json) {
    return ConnectObjectsPayload(
      instance: json['instance'] as String,
      collection: json['collection'] as String,
      objects: (json['objects'] as List).cast<Map<String, dynamic>>(),
      count: json['count'] as int,
    );
  }

  /// The instance name.
  final String instance;

  /// The collection name.
  final String collection;

  /// The list of objects.
  final List<Map<String, dynamic>> objects;

  /// The total count.
  final int count;

  /// Converts this payload to JSON.
  Map<String, dynamic> toJson() {
    return {
      'instance': instance,
      'collection': collection,
      'objects': objects,
      'count': count,
    };
  }
}
