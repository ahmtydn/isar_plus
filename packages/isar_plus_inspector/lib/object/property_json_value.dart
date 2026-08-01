import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:isar_plus_inspector/common/confirm_delete_dialog.dart';

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
  const _StringJsonValue({required this.value, this.onUpdate});

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
  const _NumJsonValue({required this.value, this.onUpdate});

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

  bool _isTimestamp(num value) {
    // Check if the number looks like a timestamp (milliseconds or microseconds)
    if (value is! int) return false;

    // Timestamps are typically between 2000-01-01 and 2100-01-01
    // Milliseconds: 946684800000 to 4102444800000
    // Microseconds: 946684800000000 to 4102444800000000
    return (value >= 946684800000 && value <= 4102444800000) || // milliseconds
        (value >= 946684800000000 && value <= 4102444800000000); // microseconds
  }

  String _formatTimestamp(num value) {
    try {
      DateTime date;
      if (value >= 946684800000000) {
        // Microseconds
        date = DateTime.fromMicrosecondsSinceEpoch(value.toInt());
      } else {
        // Milliseconds
        date = DateTime.fromMillisecondsSinceEpoch(value.toInt());
      }

      return date.toString();
    } on Exception {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isTimestamp = _isTimestamp(widget.value);

    if (!isTimestamp) {
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

    return Stack(
      children: [
        TextField(
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
        ),
        Positioned(
          top: 4,
          bottom: 4,
          left: controller.text.length * 10 + 10,
          child: Text(
            _formatTimestamp(widget.value),
            style: GoogleFonts.jetBrainsMono(
              color: Colors.grey.withValues(alpha: 0.5),
              fontSize: 11,
              fontStyle: FontStyle.italic,
            ),
          ),
        ),
      ],
    );
  }
}

class _BoolJsonValue extends StatelessWidget {
  const _BoolJsonValue({required this.value, this.onUpdate});

  final bool value;
  final void Function(dynamic newValue)? onUpdate;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: onUpdate == null
          ? null
          : (details) async {
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
                  PopupMenuItem<bool?>(child: Text('null')),
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

class _MapJsonValue extends StatefulWidget {
  const _MapJsonValue({
    required this.value,
    required this.depth,
    this.onUpdate,
  });

  final Map<String, dynamic> value;
  final void Function(dynamic newValue)? onUpdate;
  final int depth;

  @override
  State<_MapJsonValue> createState() => _MapJsonValueState();
}

class _MapJsonValueState extends State<_MapJsonValue> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (widget.value.isEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest.withValues(
            alpha: 0.3,
          ),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '{ }',
              style: GoogleFonts.jetBrainsMono(
                color: Colors.grey[500],
                fontWeight: FontWeight.w500,
                fontSize: 13,
              ),
            ),
            if (widget.onUpdate != null) ...[
              const SizedBox(width: 8),
              InkWell(
                onTap: () =>
                    _showAddMapEntry(context, widget.value, widget.onUpdate!),
                child: Icon(
                  Icons.add_circle_outline,
                  size: 16,
                  color: Colors.blue[300],
                ),
              ),
            ],
          ],
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        border: Border(
          left: BorderSide(
            color: theme.colorScheme.outline.withValues(alpha: 0.3),
            width: 2,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: () => setState(() => _isExpanded = !_isExpanded),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
              child: Row(
                children: [
                  Icon(
                    _isExpanded
                        ? Icons.keyboard_arrow_down
                        : Icons.keyboard_arrow_right,
                    size: 18,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(width: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.purple.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(3),
                    ),
                    child: Text(
                      'Object',
                      style: GoogleFonts.jetBrainsMono(
                        color: Colors.purple[300],
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${widget.value.length} '
                    '${widget.value.length == 1 ? 'property' : 'properties'}',
                    style: GoogleFonts.jetBrainsMono(
                      color: Colors.grey[500],
                      fontSize: 11,
                    ),
                  ),
                  const Spacer(),
                  if (widget.onUpdate != null) ...[
                    InkWell(
                      onTap: () => _showAddMapEntry(
                        context,
                        widget.value,
                        widget.onUpdate!,
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(4),
                        child: Icon(
                          Icons.add_circle_outline,
                          size: 14,
                          color: Colors.blue[300],
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    InkWell(
                      onTap: () => _showJsonEditor(
                        context,
                        widget.value,
                        widget.onUpdate!,
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(4),
                        child: Icon(
                          Icons.edit_outlined,
                          size: 14,
                          color: Colors.amber[300],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          if (_isExpanded)
            Padding(
              padding: const EdgeInsets.only(left: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (final entry in widget.value.entries)
                    _buildMapEntry(context, entry),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMapEntry(BuildContext context, MapEntry<String, dynamic> entry) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${entry.key}: ',
                  style: GoogleFonts.jetBrainsMono(
                    color: Colors.lightBlue[200],
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
                Expanded(
                  child: PropertyJsonValue(
                    value: entry.value,
                    depth: widget.depth + 1,
                    onUpdate: widget.onUpdate == null
                        ? null
                        : (newValue) {
                            final updatedMap = Map<String, dynamic>.from(
                              widget.value,
                            );
                            if (newValue == null) {
                              updatedMap.remove(entry.key);
                            } else {
                              updatedMap[entry.key] = newValue;
                            }
                            widget.onUpdate?.call(updatedMap);
                          },
                  ),
                ),
              ],
            ),
          ),
          if (widget.onUpdate != null)
            InkWell(
              onTap: () => _confirmDelete(
                context,
                'Delete property "${entry.key}"?',
                () {
                  final updatedMap = Map<String, dynamic>.from(widget.value);
                  updatedMap.remove(entry.key);
                  widget.onUpdate?.call(updatedMap);
                },
              ),
              child: Padding(
                padding: const EdgeInsets.all(4),
                child: Icon(Icons.close, size: 14, color: Colors.red[300]),
              ),
            ),
        ],
      ),
    );
  }
}

class _ListJsonValue extends StatefulWidget {
  const _ListJsonValue({
    required this.value,
    required this.depth,
    this.onUpdate,
  });

  final List<dynamic> value;
  final void Function(dynamic newValue)? onUpdate;
  final int depth;

  @override
  State<_ListJsonValue> createState() => _ListJsonValueState();
}

class _ListJsonValueState extends State<_ListJsonValue> {
  bool _isExpanded = true;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (widget.value.isEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest.withValues(
            alpha: 0.3,
          ),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '[ ]',
              style: GoogleFonts.jetBrainsMono(
                color: Colors.grey[500],
                fontWeight: FontWeight.w500,
                fontSize: 13,
              ),
            ),
            if (widget.onUpdate != null) ...[
              const SizedBox(width: 8),
              InkWell(
                onTap: () =>
                    _showAddListItem(context, widget.value, widget.onUpdate!),
                child: Icon(
                  Icons.add_circle_outline,
                  size: 16,
                  color: Colors.blue[300],
                ),
              ),
            ],
          ],
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        border: Border(
          left: BorderSide(
            color: theme.colorScheme.outline.withValues(alpha: 0.3),
            width: 2,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: () => setState(() => _isExpanded = !_isExpanded),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
              child: Row(
                children: [
                  Icon(
                    _isExpanded
                        ? Icons.keyboard_arrow_down
                        : Icons.keyboard_arrow_right,
                    size: 18,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(width: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.orange.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(3),
                    ),
                    child: Text(
                      'Array',
                      style: GoogleFonts.jetBrainsMono(
                        color: Colors.orange[300],
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${widget.value.length} '
                    '${widget.value.length == 1 ? 'item' : 'items'}',
                    style: GoogleFonts.jetBrainsMono(
                      color: Colors.grey[500],
                      fontSize: 11,
                    ),
                  ),
                  const Spacer(),
                  if (widget.onUpdate != null) ...[
                    InkWell(
                      onTap: () => _showAddListItem(
                        context,
                        widget.value,
                        widget.onUpdate!,
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(4),
                        child: Icon(
                          Icons.add_circle_outline,
                          size: 14,
                          color: Colors.blue[300],
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    InkWell(
                      onTap: () => _showJsonEditor(
                        context,
                        widget.value,
                        widget.onUpdate!,
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(4),
                        child: Icon(
                          Icons.edit_outlined,
                          size: 14,
                          color: Colors.amber[300],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          if (_isExpanded)
            Padding(
              padding: const EdgeInsets.only(left: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (var i = 0; i < widget.value.length; i++)
                    _buildListItem(context, i),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildListItem(BuildContext context, int index) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
            margin: const EdgeInsets.only(top: 2),
            decoration: BoxDecoration(
              color: Colors.grey[700],
              borderRadius: BorderRadius.circular(2),
            ),
            child: Text(
              '$index',
              style: GoogleFonts.jetBrainsMono(
                color: Colors.grey[300],
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: PropertyJsonValue(
              value: widget.value[index],
              depth: widget.depth + 1,
              onUpdate: widget.onUpdate == null
                  ? null
                  : (newValue) {
                      final updatedList = List<dynamic>.from(widget.value);
                      if (newValue == null) {
                        updatedList.removeAt(index);
                      } else {
                        updatedList[index] = newValue;
                      }
                      widget.onUpdate?.call(updatedList);
                    },
            ),
          ),
          if (widget.onUpdate != null)
            InkWell(
              onTap: () =>
                  _confirmDelete(context, 'Delete item at index $index?', () {
                    final updatedList = List<dynamic>.from(widget.value);
                    updatedList.removeAt(index);
                    widget.onUpdate?.call(updatedList);
                  }),
              child: Padding(
                padding: const EdgeInsets.all(4),
                child: Icon(Icons.close, size: 14, color: Colors.red[300]),
              ),
            ),
        ],
      ),
    );
  }
}

void _showJsonEditor(
  BuildContext context,
  dynamic currentValue,
  void Function(dynamic) onUpdate,
) {
  final theme = Theme.of(context);
  final isDark = theme.brightness == Brightness.dark;

  final controller = TextEditingController(
    text: currentValue == null
        ? ''
        : const JsonEncoder.withIndent('  ').convert(currentValue),
  );

  unawaited(
    showDialog<void>(
      context: context,
      builder: (context) => Theme(
        data: theme.copyWith(
          dialogTheme: DialogThemeData(
            backgroundColor: isDark ? Colors.grey[900] : Colors.white,
          ),
        ),
        child: AlertDialog(
          title: Row(
            children: [
              Icon(Icons.code, color: theme.colorScheme.primary, size: 20),
              const SizedBox(width: 8),
              const Text('Edit JSON Value'),
            ],
          ),
          content: SizedBox(
            width: 700,
            height: 500,
            child: Container(
              decoration: BoxDecoration(
                color: isDark ? Colors.grey[850] : Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isDark ? Colors.grey[700]! : Colors.grey[300]!,
                ),
              ),
              child: TextField(
                controller: controller,
                maxLines: null,
                expands: true,
                decoration: InputDecoration(
                  hintText: '{\n  "key": "value"\n}',
                  hintStyle: GoogleFonts.jetBrainsMono(
                    color: isDark ? Colors.grey[600] : Colors.grey[400],
                    fontSize: 13,
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.all(16),
                ),
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 13,
                  color: isDark ? Colors.green[300] : Colors.green[800],
                  height: 1.5,
                ),
              ),
            ),
          ),
          actions: [
            TextButton.icon(
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.close, size: 18),
              label: const Text('Cancel'),
            ),
            ElevatedButton.icon(
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
                } on Exception catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Row(
                        children: [
                          const Icon(Icons.error_outline, color: Colors.white),
                          const SizedBox(width: 8),
                          Expanded(child: Text('Invalid JSON: $e')),
                        ],
                      ),
                      backgroundColor: Colors.red[700],
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              },
              icon: const Icon(Icons.save, size: 18),
              label: const Text('Save'),
            ),
          ],
        ),
      ),
    ).then((_) {
      controller.dispose();
    }),
  );
}

Future<void> _confirmDelete(
  BuildContext context,
  String message,
  VoidCallback onConfirm,
) async {
  final confirmed = await showConfirmDeleteDialog(context, message);
  if (confirmed ?? false) {
    onConfirm();
  }
}

void _showAddListItem(
  BuildContext context,
  List<dynamic> currentList,
  void Function(dynamic) onUpdate,
) {
  final theme = Theme.of(context);
  final isDark = theme.brightness == Brightness.dark;
  final controller = TextEditingController();

  unawaited(
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.add_circle_outline, color: theme.colorScheme.primary),
            const SizedBox(width: 8),
            const Text('Add Array Item'),
          ],
        ),
        content: SizedBox(
          width: 450,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Enter a JSON value:',
                style: TextStyle(
                  color: isDark ? Colors.grey[400] : Colors.grey[700],
                ),
              ),
              const SizedBox(height: 16),
              Container(
                decoration: BoxDecoration(
                  color: isDark ? Colors.grey[850] : Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isDark ? Colors.grey[700]! : Colors.grey[300]!,
                  ),
                ),
                child: TextField(
                  controller: controller,
                  maxLines: 5,
                  autofocus: true,
                  decoration: InputDecoration(
                    hintText: '"text" or 123 or true or {"key": "value"}',
                    hintStyle: GoogleFonts.jetBrainsMono(
                      color: isDark ? Colors.grey[600] : Colors.grey[400],
                      fontSize: 12,
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.all(12),
                  ),
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 13,
                    color: isDark ? Colors.green[300] : Colors.green[800],
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton.icon(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.close, size: 18),
            label: const Text('Cancel'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              try {
                final text = controller.text.trim();
                if (text.isEmpty) {
                  throw const FormatException('Value cannot be empty');
                }
                final parsed = jsonDecode(text);
                final updatedList = List<dynamic>.from(currentList)
                  ..add(parsed);
                onUpdate(updatedList);
                Navigator.of(context).pop();
              } on Exception catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Row(
                      children: [
                        const Icon(Icons.error_outline, color: Colors.white),
                        const SizedBox(width: 8),
                        Expanded(child: Text('Invalid JSON: $e')),
                      ],
                    ),
                    backgroundColor: Colors.red[700],
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Add'),
          ),
        ],
      ),
    ).then((_) {
      // Dispose controller after dialog is closed
      controller.dispose();
    }),
  );
}

void _showAddMapEntry(
  BuildContext context,
  Map<String, dynamic> currentMap,
  void Function(dynamic) onUpdate,
) {
  final theme = Theme.of(context);
  final isDark = theme.brightness == Brightness.dark;
  final keyController = TextEditingController();
  final valueController = TextEditingController();

  unawaited(
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.add_circle_outline, color: theme.colorScheme.primary),
            const SizedBox(width: 8),
            const Text('Add Property'),
          ],
        ),
        content: SizedBox(
          width: 500,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                decoration: BoxDecoration(
                  color: isDark ? Colors.grey[850] : Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isDark ? Colors.grey[700]! : Colors.grey[300]!,
                  ),
                ),
                child: TextField(
                  controller: keyController,
                  autofocus: true,
                  decoration: InputDecoration(
                    labelText: 'Property Name',
                    hintText: 'e.g., userName, age, isActive',
                    hintStyle: GoogleFonts.jetBrainsMono(
                      color: isDark ? Colors.grey[600] : Colors.grey[400],
                      fontSize: 12,
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.all(12),
                  ),
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 13,
                    color: isDark ? Colors.lightBlue[300] : Colors.blue[700],
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Container(
                decoration: BoxDecoration(
                  color: isDark ? Colors.grey[850] : Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isDark ? Colors.grey[700]! : Colors.grey[300]!,
                  ),
                ),
                child: TextField(
                  controller: valueController,
                  maxLines: 5,
                  decoration: InputDecoration(
                    labelText: 'Value (JSON)',
                    hintText: '"text" or 123 or true or {"key": "value"}',
                    hintStyle: GoogleFonts.jetBrainsMono(
                      color: isDark ? Colors.grey[600] : Colors.grey[400],
                      fontSize: 12,
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.all(12),
                  ),
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 13,
                    color: isDark ? Colors.green[300] : Colors.green[800],
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton.icon(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.close, size: 18),
            label: const Text('Cancel'),
          ),
          ElevatedButton.icon(
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
              } on Exception catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Row(
                      children: [
                        const Icon(Icons.error_outline, color: Colors.white),
                        const SizedBox(width: 8),
                        Expanded(child: Text('Invalid JSON: $e')),
                      ],
                    ),
                    backgroundColor: Colors.red[700],
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                );
              }
            },
            icon: const Icon(Icons.check, size: 18),
            label: const Text('Add'),
          ),
        ],
      ),
    ).then((_) {
      // Dispose controllers after dialog is closed
      keyController.dispose();
      valueController.dispose();
    }),
  );
}
