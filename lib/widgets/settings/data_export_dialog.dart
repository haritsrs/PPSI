import 'dart:io';
import 'package:flutter/material.dart';
import '../../services/data_export_service.dart';
import '../../utils/error_helper.dart';
import '../../utils/snackbar_helper.dart';

class DataExportDialog extends StatefulWidget {
  const DataExportDialog({super.key});

  static void show(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const DataExportDialog(),
    );
  }

  @override
  State<DataExportDialog> createState() => _DataExportDialogState();
}

class _DataExportDialogState extends State<DataExportDialog> {
  final DataExportService _exportService = DataExportService();
  bool _isExporting = false;
  String? _errorMessage;

  Future<void> _exportData() async {
    setState(() {
      _isExporting = true;
      _errorMessage = null;
    });

    try {
      final file = await _exportService.exportAllUserData();
      if (file != null && mounted) {
        await _exportService.shareExportedData(file);
        if (mounted) {
          Navigator.of(context).pop();
          SnackbarHelper.showSuccess(
            context,
            'Data berhasil diekspor dan dibagikan!',
          );
        }
      }
    } catch (e) {
      setState(() {
        _errorMessage = getFriendlyErrorMessage(e);
      });
    } finally {
      if (mounted) {
        setState(() {
          _isExporting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Ekspor Data Saya'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Anda akan menerima file JSON yang berisi semua data Anda, termasuk:',
          ),
          const SizedBox(height: 12),
          const Padding(
            padding: EdgeInsets.only(left: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('• Produk'),
                Text('• Transaksi'),
                Text('• Pelanggan'),
                Text('• Pengaturan'),
                Text('• Notifikasi'),
                Text('• Log Audit'),
              ],
            ),
          ),
          if (_errorMessage != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: Text(
                _errorMessage!,
                style: TextStyle(color: Colors.red.shade700),
              ),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: _isExporting ? null : () => Navigator.of(context).pop(),
          child: const Text('Batal'),
        ),
        ElevatedButton(
          onPressed: _isExporting ? null : _exportData,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF6366F1),
            foregroundColor: Colors.white,
          ),
          child: _isExporting
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Ekspor'),
        ),
      ],
    );
  }
}


