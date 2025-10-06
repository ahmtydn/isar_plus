import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:isar_plus/isar_plus.dart';
import 'package:isar_plus_inspector/object/property_json_value.dart';

class PropertyValue extends StatelessWidget {
  const PropertyValue(
    this.value, {
    required this.enumMap,
    required this.type,
    super.key,
    this.onUpdate,
  });

  final dynamic value;
  final IsarType type;
  final Map<String, dynamic>? enumMap;
  final void Function(dynamic newValue)? onUpdate;

  @override
  Widget build(BuildContext context) {
    if (enumMap != null) {
      return _EnumValue(
        value: value,
        isByte: type == IsarType.byte || type == IsarType.byteList,
        enumMap: enumMap!,
        onUpdate: onUpdate,
      );
    }

    // Handle JSON type with recursive rendering
    if (type == IsarType.json) {
      return PropertyJsonValue(
        value: value,
        onUpdate: onUpdate,
      );
    }

    if (type.isBool) {
      return _BoolValue(value: value as bool?, onUpdate: onUpdate);
    } else if (type.isNum) {
      return _NumValue(value: value as num?, onUpdate: onUpdate);
    } else if (type.isDate) {
      return _DateValue(value: value as int?, onUpdate: onUpdate);
    } else if (type.isString) {
      return _StringValue(value: value as String?, onUpdate: onUpdate);
    } else {
      return const NullValue();
    }
  }
}

class NullValue extends StatelessWidget {
  const NullValue({super.key});

  @override
  Widget build(BuildContext context) {
    return Text(
      'null',
      style: GoogleFonts.jetBrainsMono(
        color: Colors.grey,
        fontWeight: FontWeight.bold,
      ),
    );
  }
}

class _EnumValue extends StatelessWidget {
  const _EnumValue({
    required this.value,
    required this.isByte,
    required this.enumMap,
    this.onUpdate,
  });

  final dynamic value;
  final bool isByte;
  final Map<String, dynamic> enumMap;
  final void Function(dynamic newValue)? onUpdate;

  @override
  Widget build(BuildContext context) {
    final enumName = enumMap.entries.firstWhere(
      (e) => e.value == value,
      orElse: () {
        if (isByte) {
          return enumMap.entries.first;
        } else {
          return const MapEntry('null', null);
        }
      },
    ).key;
    return GestureDetector(
      onTapDown: onUpdate == null
          ? null
          : (TapDownDetails details) async {
              final nullValue = Object();
              final newValue = await showMenu(
                context: context,
                position: RelativeRect.fromLTRB(
                  details.globalPosition.dx,
                  details.globalPosition.dy,
                  100000,
                  0,
                ),
                items: [
                  if (!isByte)
                    PopupMenuItem(
                      value: nullValue,
                      child: const Text('null'),
                    ),
                  for (final enumName in enumMap.keys)
                    PopupMenuItem(
                      value: enumMap[enumName],
                      child: Text(enumName),
                    ),
                ],
              );

              if (newValue != null) {
                onUpdate
                    ?.call(!identical(newValue, nullValue) ? newValue : null);
              }
            },
      child: Text(
        enumName,
        style: GoogleFonts.jetBrainsMono(
          color: enumName != 'null' ? Colors.yellow : Colors.grey,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class _BoolValue extends StatelessWidget {
  const _BoolValue({
    required this.value,
    this.onUpdate,
  });

  final bool? value;
  final void Function(dynamic newValue)? onUpdate;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: onUpdate == null
          ? null
          : (TapDownDetails details) async {
              const nullValue = Object();
              final newValue = await showMenu(
                context: context,
                position: RelativeRect.fromLTRB(
                  details.globalPosition.dx,
                  details.globalPosition.dy,
                  100000,
                  0,
                ),
                items: const [
                  PopupMenuItem(
                    value: nullValue,
                    child: Text('null'),
                  ),
                  PopupMenuItem(
                    value: true,
                    child: Text('true'),
                  ),
                  PopupMenuItem(
                    value: false,
                    child: Text('false'),
                  ),
                ],
              );
              if (newValue != null) {
                onUpdate
                    ?.call(!identical(newValue, nullValue) ? newValue : null);
              }
            },
      child: Text(
        '$value',
        style: GoogleFonts.jetBrainsMono(
          color: value != null ? Colors.orange : Colors.grey,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class _NumValue extends StatefulWidget {
  const _NumValue({
    required this.value,
    this.onUpdate,
  });

  final num? value;
  final void Function(dynamic newValue)? onUpdate;

  @override
  State<_NumValue> createState() => _NumValueState();
}

class _NumValueState extends State<_NumValue> {
  late final controller = TextEditingController(
    text: widget.value?.toString() ?? '',
  );

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      enabled: widget.onUpdate != null,
      onSubmitted: (value) {
        final numValue = num.tryParse(value);
        widget.onUpdate?.call(numValue);
      },
      decoration: InputDecoration.collapsed(
        hintText: 'null',
        hintStyle: GoogleFonts.jetBrainsMono(
          color: Colors.grey,
          fontWeight: FontWeight.bold,
          fontSize: 14,
        ),
      ),
      style: GoogleFonts.jetBrainsMono(
        color: Colors.blue,
        fontWeight: FontWeight.bold,
        fontSize: 14,
      ),
    );
  }
}

class _DateValue extends StatelessWidget {
  const _DateValue({
    required this.value,
    this.onUpdate,
  });

  final int? value;
  final void Function(dynamic newValue)? onUpdate;

  @override
  Widget build(BuildContext context) {
    final date =
        value != null ? DateTime.fromMicrosecondsSinceEpoch(value!) : null;

    return GestureDetector(
      onTap: onUpdate == null
          ? null
          : () async {
              final newDate = await showDatePicker(
                context: context,
                initialDate: date ?? DateTime.now(),
                firstDate: DateTime(1970),
                lastDate: DateTime(2050),
              );
              if (newDate != null) {
                onUpdate?.call(newDate.microsecondsSinceEpoch);
              }
            },
      child: value == null
          ? Text(
              'null',
              style: GoogleFonts.jetBrainsMono(
                color: Colors.grey,
                fontWeight: FontWeight.bold,
              ),
            )
          : Row(
              children: [
                Text(
                  value.toString(),
                  style: GoogleFonts.jetBrainsMono(
                    color: Colors.blue,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '(${_formatDateTime(date!)})',
                    style: GoogleFonts.jetBrainsMono(
                      color: Colors.grey[500],
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
    );
  }

  String _formatDateTime(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    // If it's today, show time
    if (diff.inDays == 0) {
      return 'Today ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    }

    // If it's yesterday
    if (diff.inDays == 1) {
      return 'Yesterday ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    }

    // If it's within a week
    if (diff.inDays < 7 && diff.inDays > 0) {
      return '${diff.inDays} days ago';
    }

    // Otherwise show full date
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}

class _StringValue extends StatefulWidget {
  const _StringValue({
    required this.value,
    this.onUpdate,
  });

  final String? value;
  final void Function(dynamic newValue)? onUpdate;

  @override
  State<_StringValue> createState() => _StringValueState();
}

class _StringValueState extends State<_StringValue> {
  late final controller = TextEditingController(
    text: widget.value != null
        ? '"${widget.value.toString().replaceAll('\n', '⤵')}"'
        : '',
  );

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      enabled: widget.onUpdate != null,
      onSubmitted: (value) {
        if (value.isEmpty) {
          widget.onUpdate?.call(null);
        } else {
          if (value.startsWith('"')) {
            value = value.substring(1);
          }
          if (value.endsWith('"')) {
            value = value.substring(0, value.length - 1);
          }
          widget.onUpdate?.call(value.replaceAll('⤵', '\n'));
        }
      },
      decoration: InputDecoration.collapsed(
        hintText: 'null',
        hintStyle: GoogleFonts.jetBrainsMono(
          color: Colors.grey,
          fontWeight: FontWeight.bold,
          fontSize: 14,
        ),
      ),
      style: GoogleFonts.jetBrainsMono(
        color: Colors.green,
        fontWeight: FontWeight.bold,
        fontSize: 14,
      ),
    );
  }
}
