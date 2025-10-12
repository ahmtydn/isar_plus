// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'main.dart';

// **************************************************************************
// _IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, invalid_use_of_protected_member, lines_longer_than_80_chars, constant_identifier_names, avoid_js_rounded_ints, no_leading_underscores_for_local_identifiers, require_trailing_commas, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_in_if_null_operators, library_private_types_in_public_api, prefer_const_constructors
// ignore_for_file: type=lint

extension GetCountCollection on Isar {
  IsarCollection<int, Count> get counts => this.collection();
}

final CountSchema = IsarGeneratedSchema(
  schema: IsarSchema(
    name: 'Count',
    idName: 'id',
    embedded: false,
    properties: [
      IsarPropertySchema(
        name: 'step',
        type: IsarType.long,
      ),
      IsarPropertySchema(
        name: 'metadata',
        type: IsarType.object,
        target: 'StepMetadata',
      ),
    ],
    indexes: [],
  ),
  converter: IsarObjectConverter<int, Count>(
    serialize: serializeCount,
    deserialize: deserializeCount,
    deserializeProperty: deserializeCountProp,
  ),
  getEmbeddedSchemas: () => [StepMetadataSchema],
);

@isarProtected
int serializeCount(IsarWriter writer, Count object) {
  IsarCore.writeLong(writer, 1, object.step);
  {
    final value = object.metadata;
    final objectWriter = IsarCore.beginObject(writer, 2);
    serializeStepMetadata(objectWriter, value);
    IsarCore.endObject(writer, objectWriter);
  }
  return object.id;
}

@isarProtected
Count deserializeCount(IsarReader reader) {
  final int _id;
  _id = IsarCore.readId(reader);
  final int _step;
  _step = IsarCore.readLong(reader, 1);
  final StepMetadata _metadata;
  {
    final objectReader = IsarCore.readObject(reader, 2);
    if (objectReader.isNull) {
      _metadata = StepMetadata(
        recordedAt:
            DateTime.fromMillisecondsSinceEpoch(0, isUtc: true).toLocal(),
      );
    } else {
      final embedded = deserializeStepMetadata(objectReader);
      IsarCore.freeReader(objectReader);
      _metadata = embedded;
    }
  }
  final object = Count(
    _id,
    _step,
    _metadata,
  );
  return object;
}

@isarProtected
dynamic deserializeCountProp(IsarReader reader, int property) {
  switch (property) {
    case 0:
      return IsarCore.readId(reader);
    case 1:
      return IsarCore.readLong(reader, 1);
    case 2:
      {
        final objectReader = IsarCore.readObject(reader, 2);
        if (objectReader.isNull) {
          return StepMetadata(
            recordedAt:
                DateTime.fromMillisecondsSinceEpoch(0, isUtc: true).toLocal(),
          );
        } else {
          final embedded = deserializeStepMetadata(objectReader);
          IsarCore.freeReader(objectReader);
          return embedded;
        }
      }
    default:
      throw ArgumentError('Unknown property: $property');
  }
}

sealed class _CountUpdate {
  bool call({
    required int id,
    int? step,
  });
}

class _CountUpdateImpl implements _CountUpdate {
  const _CountUpdateImpl(this.collection);

  final IsarCollection<int, Count> collection;

  @override
  bool call({
    required int id,
    Object? step = ignore,
  }) {
    return collection.updateProperties([
          id
        ], {
          if (step != ignore) 1: step as int?,
        }) >
        0;
  }
}

sealed class _CountUpdateAll {
  int call({
    required List<int> id,
    int? step,
  });
}

class _CountUpdateAllImpl implements _CountUpdateAll {
  const _CountUpdateAllImpl(this.collection);

  final IsarCollection<int, Count> collection;

  @override
  int call({
    required List<int> id,
    Object? step = ignore,
  }) {
    return collection.updateProperties(id, {
      if (step != ignore) 1: step as int?,
    });
  }
}

extension CountUpdate on IsarCollection<int, Count> {
  _CountUpdate get update => _CountUpdateImpl(this);

  _CountUpdateAll get updateAll => _CountUpdateAllImpl(this);
}

sealed class _CountQueryUpdate {
  int call({
    int? step,
  });
}

class _CountQueryUpdateImpl implements _CountQueryUpdate {
  const _CountQueryUpdateImpl(this.query, {this.limit});

  final IsarQuery<Count> query;
  final int? limit;

  @override
  int call({
    Object? step = ignore,
  }) {
    return query.updateProperties(limit: limit, {
      if (step != ignore) 1: step as int?,
    });
  }
}

extension CountQueryUpdate on IsarQuery<Count> {
  _CountQueryUpdate get updateFirst => _CountQueryUpdateImpl(this, limit: 1);

  _CountQueryUpdate get updateAll => _CountQueryUpdateImpl(this);
}

class _CountQueryBuilderUpdateImpl implements _CountQueryUpdate {
  const _CountQueryBuilderUpdateImpl(this.query, {this.limit});

  final QueryBuilder<Count, Count, QOperations> query;
  final int? limit;

  @override
  int call({
    Object? step = ignore,
  }) {
    final q = query.build();
    try {
      return q.updateProperties(limit: limit, {
        if (step != ignore) 1: step as int?,
      });
    } finally {
      q.close();
    }
  }
}

extension CountQueryBuilderUpdate on QueryBuilder<Count, Count, QOperations> {
  _CountQueryUpdate get updateFirst =>
      _CountQueryBuilderUpdateImpl(this, limit: 1);

  _CountQueryUpdate get updateAll => _CountQueryBuilderUpdateImpl(this);
}

extension CountQueryFilter on QueryBuilder<Count, Count, QFilterCondition> {
  QueryBuilder<Count, Count, QAfterFilterCondition> idEqualTo(
    int value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        EqualCondition(
          property: 0,
          value: value,
        ),
      );
    });
  }

  QueryBuilder<Count, Count, QAfterFilterCondition> idGreaterThan(
    int value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        GreaterCondition(
          property: 0,
          value: value,
        ),
      );
    });
  }

  QueryBuilder<Count, Count, QAfterFilterCondition> idGreaterThanOrEqualTo(
    int value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        GreaterOrEqualCondition(
          property: 0,
          value: value,
        ),
      );
    });
  }

  QueryBuilder<Count, Count, QAfterFilterCondition> idLessThan(
    int value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        LessCondition(
          property: 0,
          value: value,
        ),
      );
    });
  }

  QueryBuilder<Count, Count, QAfterFilterCondition> idLessThanOrEqualTo(
    int value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        LessOrEqualCondition(
          property: 0,
          value: value,
        ),
      );
    });
  }

  QueryBuilder<Count, Count, QAfterFilterCondition> idBetween(
    int lower,
    int upper,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        BetweenCondition(
          property: 0,
          lower: lower,
          upper: upper,
        ),
      );
    });
  }

  QueryBuilder<Count, Count, QAfterFilterCondition> stepEqualTo(
    int value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        EqualCondition(
          property: 1,
          value: value,
        ),
      );
    });
  }

  QueryBuilder<Count, Count, QAfterFilterCondition> stepGreaterThan(
    int value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        GreaterCondition(
          property: 1,
          value: value,
        ),
      );
    });
  }

  QueryBuilder<Count, Count, QAfterFilterCondition> stepGreaterThanOrEqualTo(
    int value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        GreaterOrEqualCondition(
          property: 1,
          value: value,
        ),
      );
    });
  }

  QueryBuilder<Count, Count, QAfterFilterCondition> stepLessThan(
    int value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        LessCondition(
          property: 1,
          value: value,
        ),
      );
    });
  }

  QueryBuilder<Count, Count, QAfterFilterCondition> stepLessThanOrEqualTo(
    int value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        LessOrEqualCondition(
          property: 1,
          value: value,
        ),
      );
    });
  }

  QueryBuilder<Count, Count, QAfterFilterCondition> stepBetween(
    int lower,
    int upper,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        BetweenCondition(
          property: 1,
          lower: lower,
          upper: upper,
        ),
      );
    });
  }
}

extension CountQueryObject on QueryBuilder<Count, Count, QFilterCondition> {
  QueryBuilder<Count, Count, QAfterFilterCondition> metadata(
      FilterQuery<StepMetadata> q) {
    return QueryBuilder.apply(this, (query) {
      return query.object(q, 2);
    });
  }
}

extension CountQuerySortBy on QueryBuilder<Count, Count, QSortBy> {
  QueryBuilder<Count, Count, QAfterSortBy> sortById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(0);
    });
  }

  QueryBuilder<Count, Count, QAfterSortBy> sortByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(0, sort: Sort.desc);
    });
  }

  QueryBuilder<Count, Count, QAfterSortBy> sortByStep() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(1);
    });
  }

  QueryBuilder<Count, Count, QAfterSortBy> sortByStepDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(1, sort: Sort.desc);
    });
  }
}

extension CountQuerySortThenBy on QueryBuilder<Count, Count, QSortThenBy> {
  QueryBuilder<Count, Count, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(0);
    });
  }

  QueryBuilder<Count, Count, QAfterSortBy> thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(0, sort: Sort.desc);
    });
  }

  QueryBuilder<Count, Count, QAfterSortBy> thenByStep() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(1);
    });
  }

  QueryBuilder<Count, Count, QAfterSortBy> thenByStepDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(1, sort: Sort.desc);
    });
  }
}

extension CountQueryWhereDistinct on QueryBuilder<Count, Count, QDistinct> {
  QueryBuilder<Count, Count, QAfterDistinct> distinctByStep() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(1);
    });
  }
}

extension CountQueryProperty1 on QueryBuilder<Count, Count, QProperty> {
  QueryBuilder<Count, int, QAfterProperty> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(0);
    });
  }

  QueryBuilder<Count, int, QAfterProperty> stepProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(1);
    });
  }

  QueryBuilder<Count, StepMetadata, QAfterProperty> metadataProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(2);
    });
  }
}

extension CountQueryProperty2<R> on QueryBuilder<Count, R, QAfterProperty> {
  QueryBuilder<Count, (R, int), QAfterProperty> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(0);
    });
  }

  QueryBuilder<Count, (R, int), QAfterProperty> stepProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(1);
    });
  }

  QueryBuilder<Count, (R, StepMetadata), QAfterProperty> metadataProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(2);
    });
  }
}

extension CountQueryProperty3<R1, R2>
    on QueryBuilder<Count, (R1, R2), QAfterProperty> {
  QueryBuilder<Count, (R1, R2, int), QOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(0);
    });
  }

  QueryBuilder<Count, (R1, R2, int), QOperations> stepProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(1);
    });
  }

  QueryBuilder<Count, (R1, R2, StepMetadata), QOperations> metadataProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(2);
    });
  }
}

// **************************************************************************
// _IsarEmbeddedGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, invalid_use_of_protected_member, lines_longer_than_80_chars, constant_identifier_names, avoid_js_rounded_ints, no_leading_underscores_for_local_identifiers, require_trailing_commas, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_in_if_null_operators, library_private_types_in_public_api, prefer_const_constructors
// ignore_for_file: type=lint

final StepMetadataSchema = IsarGeneratedSchema(
  schema: IsarSchema(
    name: 'StepMetadata',
    embedded: true,
    properties: [
      IsarPropertySchema(
        name: 'recordedAt',
        type: IsarType.dateTime,
      ),
      IsarPropertySchema(
        name: 'note',
        type: IsarType.string,
      ),
    ],
    indexes: [],
  ),
  converter: IsarObjectConverter<void, StepMetadata>(
    serialize: serializeStepMetadata,
    deserialize: deserializeStepMetadata,
  ),
);

@isarProtected
int serializeStepMetadata(IsarWriter writer, StepMetadata object) {
  IsarCore.writeLong(
      writer, 1, object.recordedAt.toUtc().microsecondsSinceEpoch);
  IsarCore.writeString(writer, 2, object.note);
  return 0;
}

@isarProtected
StepMetadata deserializeStepMetadata(IsarReader reader) {
  final DateTime _recordedAt;
  {
    final value = IsarCore.readLong(reader, 1);
    if (value == -9223372036854775808) {
      _recordedAt =
          DateTime.fromMillisecondsSinceEpoch(0, isUtc: true).toLocal();
    } else {
      _recordedAt =
          DateTime.fromMicrosecondsSinceEpoch(value, isUtc: true).toLocal();
    }
  }
  final String _note;
  _note = IsarCore.readString(reader, 2) ?? '';
  final object = StepMetadata(
    recordedAt: _recordedAt,
    note: _note,
  );
  return object;
}

extension StepMetadataQueryFilter
    on QueryBuilder<StepMetadata, StepMetadata, QFilterCondition> {
  QueryBuilder<StepMetadata, StepMetadata, QAfterFilterCondition>
      recordedAtEqualTo(
    DateTime value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        EqualCondition(
          property: 1,
          value: value,
        ),
      );
    });
  }

  QueryBuilder<StepMetadata, StepMetadata, QAfterFilterCondition>
      recordedAtGreaterThan(
    DateTime value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        GreaterCondition(
          property: 1,
          value: value,
        ),
      );
    });
  }

  QueryBuilder<StepMetadata, StepMetadata, QAfterFilterCondition>
      recordedAtGreaterThanOrEqualTo(
    DateTime value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        GreaterOrEqualCondition(
          property: 1,
          value: value,
        ),
      );
    });
  }

  QueryBuilder<StepMetadata, StepMetadata, QAfterFilterCondition>
      recordedAtLessThan(
    DateTime value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        LessCondition(
          property: 1,
          value: value,
        ),
      );
    });
  }

  QueryBuilder<StepMetadata, StepMetadata, QAfterFilterCondition>
      recordedAtLessThanOrEqualTo(
    DateTime value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        LessOrEqualCondition(
          property: 1,
          value: value,
        ),
      );
    });
  }

  QueryBuilder<StepMetadata, StepMetadata, QAfterFilterCondition>
      recordedAtBetween(
    DateTime lower,
    DateTime upper,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        BetweenCondition(
          property: 1,
          lower: lower,
          upper: upper,
        ),
      );
    });
  }

  QueryBuilder<StepMetadata, StepMetadata, QAfterFilterCondition> noteEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        EqualCondition(
          property: 2,
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<StepMetadata, StepMetadata, QAfterFilterCondition>
      noteGreaterThan(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        GreaterCondition(
          property: 2,
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<StepMetadata, StepMetadata, QAfterFilterCondition>
      noteGreaterThanOrEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        GreaterOrEqualCondition(
          property: 2,
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<StepMetadata, StepMetadata, QAfterFilterCondition> noteLessThan(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        LessCondition(
          property: 2,
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<StepMetadata, StepMetadata, QAfterFilterCondition>
      noteLessThanOrEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        LessOrEqualCondition(
          property: 2,
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<StepMetadata, StepMetadata, QAfterFilterCondition> noteBetween(
    String lower,
    String upper, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        BetweenCondition(
          property: 2,
          lower: lower,
          upper: upper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<StepMetadata, StepMetadata, QAfterFilterCondition>
      noteStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        StartsWithCondition(
          property: 2,
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<StepMetadata, StepMetadata, QAfterFilterCondition> noteEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        EndsWithCondition(
          property: 2,
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<StepMetadata, StepMetadata, QAfterFilterCondition> noteContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        ContainsCondition(
          property: 2,
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<StepMetadata, StepMetadata, QAfterFilterCondition> noteMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        MatchesCondition(
          property: 2,
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<StepMetadata, StepMetadata, QAfterFilterCondition>
      noteIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const EqualCondition(
          property: 2,
          value: '',
        ),
      );
    });
  }

  QueryBuilder<StepMetadata, StepMetadata, QAfterFilterCondition>
      noteIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const GreaterCondition(
          property: 2,
          value: '',
        ),
      );
    });
  }
}

extension StepMetadataQueryObject
    on QueryBuilder<StepMetadata, StepMetadata, QFilterCondition> {}
