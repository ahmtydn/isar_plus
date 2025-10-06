import 'package:flutter/material.dart';
import 'package:isar_plus/isar_plus.dart';
import 'package:isar_plus_inspector/object/property_builder.dart';
import 'package:isar_plus_inspector/object/property_json_value.dart';
import 'package:isar_plus_inspector/object/property_value.dart';
import 'package:isar_plus_inspector/util.dart';

class PropertyView extends StatelessWidget {
  const PropertyView({
    required this.property,
    required this.value,
    required this.isId,
    required this.isIndexed,
    required this.onUpdate,
    super.key,
  });

  final IsarPropertySchema property;
  final dynamic value;
  final bool isId;
  final bool isIndexed;
  final void Function(dynamic value) onUpdate;

  @override
  Widget build(BuildContext context) {
    final value = this.value;

    // Get length information for display
    final valueLength = _getValueLengthString(value);

    return PropertyBuilder(
      property: property.name,
      bold: isId,
      underline: isIndexed,
      type: '${property.type.typeName} $valueLength',
      value: value is List
          ? null
          : property.type.isList
              ? const NullValue()
              : PropertyValue(
                  value,
                  type: property.type,
                  enumMap: property.enumMap,
                  onUpdate: isId ? null : onUpdate,
                ),
      children: [
        if (value is List)
          for (var i = 0; i < value.length; i++) _buildListItem(i, value[i]),
      ],
    );
  }

  String _getValueLengthString(dynamic value) {
    if (value == null) return '';
    if (value is String) return '(${value.length})';
    if (value is List) return '(${value.length})';
    if (value is Map) return '(${value.length} keys)';
    return '';
  }

  Widget _buildListItem(int index, dynamic item) {
    // For JSON type lists, render each item with full JSON support
    if (property.type == IsarType.json) {
      return PropertyBuilder(
        property: '[$index]',
        type: _getItemTypeName(item),
        value: PropertyJsonValue(
          value: item,
          onUpdate: (newValue) {
            // Update the specific list item
            final list = (value as List).toList();
            if (newValue == null) {
              list.removeAt(index);
            } else {
              list[index] = newValue;
            }
            onUpdate(list);
          },
        ),
      );
    }

    // For regular typed lists, use the standard PropertyValue
    return PropertyBuilder(
      property: '[$index]',
      type: property.type.typeName,
      value: PropertyValue(
        item,
        type: property.type,
        enumMap: property.enumMap,
        onUpdate: (newValue) {
          // Update the specific list item
          final list = (value as List).toList();
          if (newValue == null) {
            list.removeAt(index);
          } else {
            list[index] = newValue;
          }
          onUpdate(list);
        },
      ),
    );
  }

  String _getItemTypeName(dynamic item) {
    if (item == null) return 'null';
    if (item is String) return 'String';
    if (item is int) return 'int';
    if (item is double) return 'double';
    if (item is bool) return 'bool';
    if (item is List) return 'List (${item.length})';
    if (item is Map) return 'Map (${item.length})';
    return item.runtimeType.toString();
  }
}
