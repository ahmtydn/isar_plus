part of '../isar_plus_generator.dart';

String _generateQueryObjects(ObjectInfo oi) {
  final buffer = StringBuffer(
    'extension ${oi.dartName}QueryObject on QueryBuilder<${oi.dartName}, '
    '${oi.dartName}, QFilterCondition> {',
  );
  for (final property in oi.properties) {
    if (property.type != IsarType.object) {
      continue;
    }
    final name = property.dartName.decapitalize();
    buffer.write('''
      QueryBuilder<${oi.dartName}, ${oi.dartName}, QAfterFilterCondition> $name(FilterQuery<${property.typeClassName}> q) {
        return QueryBuilder.apply(this, (query) {
          return query.object(q, ${property.index});
        });
      }''');
  }

  return '''
    $buffer
  }''';
}
