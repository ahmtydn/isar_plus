part of '../isar_plus_generator.dart';

String _generateEnumMaps(ObjectInfo object) {
  final buffer = StringBuffer();
  for (final property in object.properties.where((e) => e.isEnum)) {
    final enumName = property.typeClassName;
    buffer.write('const ${property.enumMapName(object)} = {');
    for (final enumElementName in property.enumMap!.keys) {
      final value = property.enumMap![enumElementName];
      if (value is String) {
        buffer.write("r'$value': $enumName.$enumElementName,");
      } else {
        buffer.write('$value: $enumName.$enumElementName,');
      }
    }
    buffer.write('};');
  }

  return buffer.toString();
}
