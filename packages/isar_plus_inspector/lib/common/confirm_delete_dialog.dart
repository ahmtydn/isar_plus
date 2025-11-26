import 'package:flutter/material.dart';

/// Shows a confirmation dialog before deleting an item
Future<bool?> showConfirmDeleteDialog(BuildContext context, String message) {
  return showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Row(
        children: [
          Icon(
            Icons.warning_amber_rounded,
            color: Colors.orange[700],
            size: 24,
          ),
          const SizedBox(width: 8),
          const Text('Confirm Delete'),
        ],
      ),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        ElevatedButton.icon(
          onPressed: () => Navigator.of(context).pop(true),
          icon: const Icon(Icons.delete_outline, size: 18),
          label: const Text('Delete'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red[700],
            foregroundColor: Colors.white,
          ),
        ),
      ],
    ),
  );
}
