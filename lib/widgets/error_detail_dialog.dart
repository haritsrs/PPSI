import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../utils/snackbar_helper.dart';

/// Dialog for displaying detailed error messages with copy capability
class ErrorDetailDialog extends StatelessWidget {
  final String title;
  final String message;
  final String? details;
  final String? stackTrace;

  const ErrorDetailDialog({
    super.key,
    required this.title,
    required this.message,
    this.details,
    this.stackTrace,
  });

  static void show(
    BuildContext context, {
    required String title,
    required String message,
    String? details,
    String? stackTrace,
  }) {
    showDialog(
      context: context,
      builder: (context) => ErrorDetailDialog(
        title: title,
        message: message,
        details: details,
        stackTrace: stackTrace,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final fullErrorText = [
      'Error: $message',
      if (details != null && details!.isNotEmpty) '\nDetail: $details',
      if (stackTrace != null && stackTrace!.isNotEmpty) '\n\nStack Trace:\n$stackTrace',
    ].join();

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          const Icon(Icons.error_outline, color: Colors.red, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Main message
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red[200]!),
              ),
              child: SelectableText(
                message,
                style: const TextStyle(fontSize: 14),
              ),
            ),

            // Details section
            if (details != null && details!.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Text(
                'Detail Teknis:',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: SelectableText(
                  details!,
                  style: const TextStyle(fontSize: 12, fontFamily: 'monospace'),
                ),
              ),
            ],

            // Stack trace section (expandable)
            if (stackTrace != null && stackTrace!.isNotEmpty) ...[
              const SizedBox(height: 16),
              ExpansionTile(
                title: const Text(
                  'Stack Trace (untuk developer)',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                ),
                initiallyExpanded: false,
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: SelectableText(
                      stackTrace!,
                      style: const TextStyle(fontSize: 11, fontFamily: 'monospace'),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton.icon(
          onPressed: () {
            Clipboard.setData(ClipboardData(text: fullErrorText));
            Navigator.pop(context);
            SnackbarHelper.showSuccess(context, 'Error disalin ke clipboard');
          },
          icon: const Icon(Icons.copy_rounded),
          label: const Text('Salin Error'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF6366F1),
            foregroundColor: Colors.white,
          ),
          child: const Text('Tutup'),
        ),
      ],
    );
  }
}

