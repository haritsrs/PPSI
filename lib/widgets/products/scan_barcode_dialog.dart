import 'package:flutter/material.dart';

/// Dialog widget for barcode scanning feature
class ScanBarcodeDialog extends StatelessWidget {
  const ScanBarcodeDialog({super.key});

  static void show(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const ScanBarcodeDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          Icon(Icons.qr_code_scanner_rounded, color: Colors.purple[600]),
          const SizedBox(width: 8),
          const Text('Scan Barcode'),
        ],
      ),
      content: const Text('Fitur scan barcode akan segera hadir!'),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('OK'),
        ),
      ],
    );
  }
}


