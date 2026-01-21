import 'package:flutter/material.dart';

class ExportDialog extends StatelessWidget {
  final VoidCallback onExportPDF;
  final VoidCallback onExportExcel;

  const ExportDialog({
    super.key,
    required this.onExportPDF,
    required this.onExportExcel,
  });

  static void show(
    BuildContext context, {
    required VoidCallback onExportPDF,
    required VoidCallback onExportExcel,
  }) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return ExportDialog(
          onExportPDF: onExportPDF,
          onExportExcel: onExportExcel,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          Icon(Icons.download_rounded, color: Colors.blue[600]),
          const SizedBox(width: 8),
          const Text('Ekspor Laporan'),
        ],
      ),
      content: const Text('Pilih format ekspor yang diinginkan:'),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Batal'),
        ),
        ElevatedButton.icon(
          onPressed: () {
            Navigator.of(context).pop();
            onExportPDF();
          },
          icon: const Icon(Icons.picture_as_pdf_rounded, size: 18),
          label: const Text('PDF'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
          ),
        ),
        ElevatedButton.icon(
          onPressed: () {
            Navigator.of(context).pop();
            onExportExcel();
          },
          icon: const Icon(Icons.table_chart_rounded, size: 18),
          label: const Text('Excel'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
            foregroundColor: Colors.white,
          ),
        ),
      ],
    );
  }
}


