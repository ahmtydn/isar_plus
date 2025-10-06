import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:isar_plus_inspector/object/property_builder.dart';

/// A sophisticated JSON value renderer that handles nested structures
/// recursively
class PropertyJsonValue extends StatelessWidget {
  const PropertyJsonValue({
    required this.value,
    this.onUpdate,
    super.key,
    this.depth = 0,
  });

  final dynamic value;
  final void Function(dynamic newValue)? onUpdate;
  final int depth;

  @override
  Widget build(BuildContext context) {
    if (value == null) {
      return _NullJsonValue(onUpdate: onUpdate);
    }

    // Handle different JSON types recursively
    if (value is Map) {
      return _MapJsonValue(
        value: value as Map<String, dynamic>,
        onUpdate: onUpdate,
        depth: depth,
      );
    } else if (value is List) {
      return _ListJsonValue(
        value: value as List<dynamic>,
        onUpdate: onUpdate,
        depth: depth,
      );
    } else if (value is String) {
      return _StringJsonValue(value: value as String, onUpdate: onUpdate);
    } else if (value is num) {
      return _NumJsonValue(value: value as num, onUpdate: onUpdate);
    } else if (value is bool) {
      return _BoolJsonValue(value: value as bool, onUpdate: onUpdate);
    } else {
      // Fallback for any other type - try to display as string
      return _StringJsonValue(value: value.toString(), onUpdate: onUpdate);
    }
  }
}

class _NullJsonValue extends StatelessWidget {
  const _NullJsonValue({this.onUpdate});

  final void Function(dynamic newValue)? onUpdate;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onUpdate == null
          ? null
          : () => _showJsonEditor(context, null, onUpdate!),
      child: Text(
        'null',
        style: GoogleFonts.jetBrainsMono(
          color: Colors.grey,
          fontWeight: FontWeight.bold,
          fontStyle: FontStyle.italic,
        ),
      ),
    );
  }
}

class _StringJsonValue extends StatefulWidget {
  const _StringJsonValue({
    required this.value,
    this.onUpdate,
  });

  final String value;
  final void Function(dynamic newValue)? onUpdate;

  @override
  State<_StringJsonValue> createState() => _StringJsonValueState();
}

class _StringJsonValueState extends State<_StringJsonValue> {
  late final controller = TextEditingController(
    text: widget.value.length > 50
        ? '"${widget.value.substring(0, 47)}..."'
        : '"${widget.value}"',
  );

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onUpdate == null
          ? null
          : () => _showJsonEditor(context, widget.value, widget.onUpdate!),
      child: Tooltip(
        message: widget.value.length > 50 ? widget.value : '',
        child: Text(
          widget.value.length > 50
              ? '"${widget.value.substring(0, 47)}..."'
              : '"${widget.value}"',
          style: GoogleFonts.jetBrainsMono(
            color: Colors.green,
            fontWeight: FontWeight.w500,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }
}

class _NumJsonValue extends StatefulWidget {
  const _NumJsonValue({
    required this.value,
    this.onUpdate,
  });

  final num value;
  final void Function(dynamic newValue)? onUpdate;

  @override
  State<_NumJsonValue> createState() => _NumJsonValueState();
}

class _NumJsonValueState extends State<_NumJsonValue> {
  late final controller = TextEditingController(text: widget.value.toString());

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      enabled: widget.onUpdate != null,
      onSubmitted: (value) {
        final numValue = num.tryParse(value);
        if (numValue != null) {
          widget.onUpdate?.call(numValue);
        }
      },
      decoration: InputDecoration.collapsed(
        hintText: '0',
        hintStyle: GoogleFonts.jetBrainsMono(
          color: Colors.grey,
          fontWeight: FontWeight.bold,
        ),
      ),
      style: GoogleFonts.jetBrainsMono(
        color: Colors.blue,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}

class _BoolJsonValue extends StatelessWidget {
  const _BoolJsonValue({
    required this.value,
    this.onUpdate,
  });

  final bool value;
  final void Function(dynamic newValue)? onUpdate;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: onUpdate == null
          ? null
          : (TapDownDetails details) async {
              final newValue = await showMenu(
                context: context,
                position: RelativeRect.fromLTRB(
                  details.globalPosition.dx,
                  details.globalPosition.dy,
                  100000,
                  0,
                ),
                items: const [
                  PopupMenuItem<bool?>(value: true, child: Text('true')),
                  PopupMenuItem<bool?>(value: false, child: Text('false')),
                  PopupMenuItem<bool?>(value: null, child: Text('null')),
                ],
              );
              onUpdate?.call(newValue);
            },
      child: Text(
        value.toString(),
        style: GoogleFonts.jetBrainsMono(
          color: Colors.orange,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class _MapJsonValue extends StatelessWidget {
  const _MapJsonValue({
    required this.value,
    required this.depth,
    this.onUpdate,
  });

  final Map<String, dynamic> value;
  final void Function(dynamic newValue)? onUpdate;
  final int depth;

  @override
  Widget build(BuildContext context) {
    if (value.isEmpty) {
      return Row(
        children: [
          GestureDetector(
            onTap: onUpdate == null
                ? null
                : () => _showJsonEditor(context, value, onUpdate!),
            child: Text(
              '{}',
              style: GoogleFonts.jetBrainsMono(
                color: Colors.grey,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          if (onUpdate != null) ...[
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.add_circle_outline, size: 16),
              onPressed: () => _showAddMapEntry(context, value, onUpdate!),
              tooltip: 'Add key-value pair',
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ],
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Text(
              '{',
              style: GoogleFonts.jetBrainsMono(
                color: Colors.white70,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '${value.length} ${value.length == 1 ? 'key' : 'keys'}',
              style: GoogleFonts.jetBrainsMono(
                color: Colors.grey,
                fontSize: 12,
              ),
            ),
            const Spacer(),
            if (onUpdate != null) ...[
              IconButton(
                icon: const Icon(Icons.add_circle_outline, size: 16),
                onPressed: () => _showAddMapEntry(context, value, onUpdate!),
                tooltip: 'Add key-value pair',
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
              const SizedBox(width: 4),
              IconButton(
                icon: const Icon(Icons.edit, size: 16),
                onPressed: () => _showJsonEditor(context, value, onUpdate!),
                tooltip: 'Edit JSON',
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ],
        ),
        Padding(
          padding: const EdgeInsets.only(left: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final entry in value.entries)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Row(
                    children: [
                      Expanded(
                        child: PropertyBuilder(
                          property: entry.key,
                          type: _getTypeName(entry.value),
                          value: PropertyJsonValue(
                            value: entry.value,
                            depth: depth + 1,
                            onUpdate: onUpdate == null
                                ? null
                                : (newValue) {
                                    final updatedMap =
                                        Map<String, dynamic>.from(value);
                                    if (newValue == null) {
                                      updatedMap.remove(entry.key);
                                    } else {
                                      updatedMap[entry.key] = newValue;
                                    }
                                    onUpdate?.call(updatedMap);
                                  },
                          ),
                        ),
                      ),
                      if (onUpdate != null)
                        IconButton(
                          icon: const Icon(
                            Icons.delete_outline,
                            size: 14,
                            color: Colors.red,
                          ),
                          onPressed: () {
                            final updatedMap = Map<String, dynamic>.from(value);
                            updatedMap.remove(entry.key);
                            onUpdate?.call(updatedMap);
                          },
                          tooltip: 'Delete key',
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                    ],
                  ),
                ),
            ],
          ),
        ),
        Text(
          '}',
          style: GoogleFonts.jetBrainsMono(
            color: Colors.white70,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ],
    );
  }
}

class _ListJsonValue extends StatelessWidget {
  const _ListJsonValue({
    required this.value,
    required this.depth,
    this.onUpdate,
  });

  final List<dynamic> value;
  final void Function(dynamic newValue)? onUpdate;
  final int depth;

  @override
  Widget build(BuildContext context) {
    if (value.isEmpty) {
      return Row(
        children: [
          GestureDetector(
            onTap: onUpdate == null
                ? null
                : () => _showJsonEditor(context, value, onUpdate!),
            child: Text(
              '[]',
              style: GoogleFonts.jetBrainsMono(
                color: Colors.grey,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          if (onUpdate != null) ...[
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.add_circle_outline, size: 16),
              onPressed: () => _showAddListItem(context, value, onUpdate!),
              tooltip: 'Add item',
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ],
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Text(
              '[',
              style: GoogleFonts.jetBrainsMono(
                color: Colors.white70,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '${value.length} ${value.length == 1 ? 'item' : 'items'}',
              style: GoogleFonts.jetBrainsMono(
                color: Colors.grey,
                fontSize: 12,
              ),
            ),
            const Spacer(),
            if (onUpdate != null) ...[
              IconButton(
                icon: const Icon(Icons.add_circle_outline, size: 16),
                onPressed: () => _showAddListItem(context, value, onUpdate!),
                tooltip: 'Add item',
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
              const SizedBox(width: 4),
              IconButton(
                icon: const Icon(Icons.edit, size: 16),
                onPressed: () => _showJsonEditor(context, value, onUpdate!),
                tooltip: 'Edit JSON',
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ],
        ),
        Padding(
          padding: const EdgeInsets.only(left: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var i = 0; i < value.length; i++)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Row(
                    children: [
                      Expanded(
                        child: PropertyBuilder(
                          property: '[$i]',
                          type: _getTypeName(value[i]),
                          value: PropertyJsonValue(
                            value: value[i],
                            depth: depth + 1,
                            onUpdate: onUpdate == null
                                ? null
                                : (newValue) {
                                    final updatedList =
                                        List<dynamic>.from(value);
                                    if (newValue == null) {
                                      updatedList.removeAt(i);
                                    } else {
                                      updatedList[i] = newValue;
                                    }
                                    onUpdate?.call(updatedList);
                                  },
                          ),
                        ),
                      ),
                      if (onUpdate != null)
                        IconButton(
                          icon: const Icon(
                            Icons.delete_outline,
                            size: 14,
                            color: Colors.red,
                          ),
                          onPressed: () {
                            final updatedList = List<dynamic>.from(value);
                            updatedList.removeAt(i);
                            onUpdate?.call(updatedList);
                          },
                          tooltip: 'Delete item',
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                    ],
                  ),
                ),
            ],
          ),
        ),
        Text(
          ']',
          style: GoogleFonts.jetBrainsMono(
            color: Colors.white70,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ],
    );
  }
}

String _getTypeName(dynamic value) {
  if (value == null) return 'null';
  if (value is String) return 'String';
  if (value is int) return 'int';
  if (value is double) return 'double';
  if (value is num) return 'num';
  if (value is bool) return 'bool';
  if (value is List) return 'List (${value.length})';
  if (value is Map) return 'Map (${value.length})';
  return value.runtimeType.toString();
}

void _showJsonEditor(
  BuildContext context,
  dynamic currentValue,
  void Function(dynamic) onUpdate,
) {
  final controller = TextEditingController(
    text: currentValue == null
        ? ''
        : const JsonEncoder.withIndent('  ').convert(currentValue),
  );

  showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Edit JSON Value'),
      content: SizedBox(
        width: 600,
        height: 400,
        child: TextField(
          controller: controller,
          maxLines: null,
          expands: true,
          decoration: InputDecoration(
            hintText: 'Enter JSON value...',
            border: const OutlineInputBorder(),
            filled: true,
            fillColor: Colors.grey[900],
          ),
          style: GoogleFonts.jetBrainsMono(
            fontSize: 13,
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () {
            try {
              final text = controller.text.trim();
              if (text.isEmpty) {
                onUpdate(null);
              } else {
                final parsed = jsonDecode(text);
                onUpdate(parsed);
              }
              Navigator.of(context).pop();
            } catch (e) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Invalid JSON: $e'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          },
          child: const Text('Save'),
        ),
      ],
    ),
  ).then((_) {
    // Dispose controller after dialog is closed
    controller.dispose();
  });
}

void _showAddListItem(
  BuildContext context,
  List<dynamic> currentList,
  void Function(dynamic) onUpdate,
) {
  final controller = TextEditingController();

  showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Add List Item'),
      content: SizedBox(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Enter JSON value for the new item:'),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              maxLines: 5,
              decoration: InputDecoration(
                hintText: 'e.g., "text", 123, true, {"key": "value"}, []',
                border: const OutlineInputBorder(),
                filled: true,
                fillColor: Colors.grey[900],
              ),
              style: GoogleFonts.jetBrainsMono(fontSize: 13),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () {
            try {
              final text = controller.text.trim();
              if (text.isEmpty) {
                throw const FormatException('Value cannot be empty');
              }
              final parsed = jsonDecode(text);
              final updatedList = List<dynamic>.from(currentList)..add(parsed);
              onUpdate(updatedList);
              Navigator.of(context).pop();
            } catch (e) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Invalid JSON: $e'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          },
          child: const Text('Add'),
        ),
      ],
    ),
  ).then((_) {
    // Dispose controller after dialog is closed
    controller.dispose();
  });
}

void _showAddMapEntry(
  BuildContext context,
  Map<String, dynamic> currentMap,
  void Function(dynamic) onUpdate,
) {
  final keyController = TextEditingController();
  final valueController = TextEditingController();

  showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Add Map Entry'),
      content: SizedBox(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: keyController,
              decoration: InputDecoration(
                labelText: 'Key',
                hintText: 'Enter key name',
                border: const OutlineInputBorder(),
                filled: true,
                fillColor: Colors.grey[900],
              ),
              style: GoogleFonts.jetBrainsMono(fontSize: 13),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: valueController,
              maxLines: 5,
              decoration: InputDecoration(
                labelText: 'Value (JSON)',
                hintText: 'e.g., "text", 123, true, {"key": "value"}, []',
                border: const OutlineInputBorder(),
                filled: true,
                fillColor: Colors.grey[900],
              ),
              style: GoogleFonts.jetBrainsMono(fontSize: 13),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () {
            try {
              final key = keyController.text.trim();
              final valueText = valueController.text.trim();

              if (key.isEmpty) {
                throw const FormatException('Key cannot be empty');
              }
              if (valueText.isEmpty) {
                throw const FormatException('Value cannot be empty');
              }

              final parsedValue = jsonDecode(valueText);
              final updatedMap = Map<String, dynamic>.from(currentMap);
              updatedMap[key] = parsedValue;
              onUpdate(updatedMap);
              Navigator.of(context).pop();
            } catch (e) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Error: $e'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          },
          child: const Text('Add'),
        ),
      ],
    ),
  ).then((_) {
    // Dispose controllers after dialog is closed
    keyController.dispose();
    valueController.dispose();
  });
}
