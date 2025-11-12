import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/receipt_service.dart';

class PrintReceiptDialog extends StatefulWidget {
  final String transactionId;
  final Map<String, dynamic> transactionData;

  const PrintReceiptDialog({
    super.key,
    required this.transactionId,
    required this.transactionData,
  });

  @override
  State<PrintReceiptDialog> createState() => _PrintReceiptDialogState();
}

class _PrintReceiptDialogState extends State<PrintReceiptDialog> {
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          Icon(Icons.print_rounded, color: Colors.blue[600]),
          const SizedBox(width: 8),
          const Text('Cetak Struk'),
        ],
      ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Struk akan dicetak menggunakan printer sistem.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue[200]!),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline_rounded, color: Colors.blue[700], size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Pilih printer dari dialog sistem yang muncul. PDF printing bekerja dengan semua jenis printer termasuk thermal printer.',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.blue[900],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
          child: const Text('Batal'),
        ),
        ElevatedButton.icon(
          onPressed: _isLoading ? null : () => _handlePrint(context),
          icon: _isLoading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.print_rounded, size: 18),
          label: const Text('Cetak'),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF6366F1),
            foregroundColor: Colors.white,
          ),
        ),
      ],
    );
  }

  Future<void> _handlePrint(BuildContext context) async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Parse transaction data
      final items = widget.transactionData['items'] as List<dynamic>? ?? [];
      final itemsList = items.map((item) => Map<String, dynamic>.from(item as Map)).toList();
      
      DateTime date;
      try {
        date = DateTime.parse(widget.transactionData['createdAt'] as String);
      } catch (e) {
        date = DateTime.now();
      }

      // PDF Print - Works with any printer
      Navigator.of(context).pop();
      
      final pdf = await ReceiptService.generatePDFReceipt(
        transactionId: widget.transactionId,
        date: date,
        customerName: widget.transactionData['customerName'] as String?,
        items: itemsList,
        subtotal: (widget.transactionData['subtotal'] as num?)?.toDouble() ?? 0.0,
        tax: (widget.transactionData['tax'] as num?)?.toDouble() ?? 0.0,
        total: (widget.transactionData['total'] as num?)?.toDouble() ?? 0.0,
        paymentMethod: widget.transactionData['paymentMethod'] as String? ?? 'Cash',
        cashAmount: (widget.transactionData['cashAmount'] as num?)?.toDouble(),
        change: (widget.transactionData['change'] as num?)?.toDouble(),
      );

      await ReceiptService.printPDFReceipt(pdf);
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Struk berhasil dikirim ke printer'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }
}

