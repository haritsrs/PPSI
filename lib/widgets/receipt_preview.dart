import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import 'package:pdf/pdf.dart';
import '../services/receipt_service.dart';

class ReceiptPreview extends StatelessWidget {
  final String transactionId;
  final DateTime date;
  final String? customerName;
  final List<Map<String, dynamic>> items;
  final double subtotal;
  final double tax;
  final double total;
  final String paymentMethod;
  final double? cashAmount;
  final double? change;
  final String? storeName;
  final String? storeAddress;
  final String? storePhone;

  const ReceiptPreview({
    super.key,
    required this.transactionId,
    required this.date,
    this.customerName,
    required this.items,
    required this.subtotal,
    required this.tax,
    required this.total,
    required this.paymentMethod,
    this.cashAmount,
    this.change,
    this.storeName,
    this.storeAddress,
    this.storePhone,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Preview Struk'),
        actions: [
          IconButton(
            icon: const Icon(Icons.print_rounded),
            onPressed: () => _printReceipt(context),
            tooltip: 'Print',
          ),
        ],
      ),
      body: PdfPreview(
        build: (PdfPageFormat format) async {
          final pdf = await ReceiptService.generatePDFReceipt(
            transactionId: transactionId,
            date: date,
            customerName: customerName,
            items: items,
            subtotal: subtotal,
            tax: tax,
            total: total,
            paymentMethod: paymentMethod,
            cashAmount: cashAmount,
            change: change,
            storeName: storeName ?? 'Toko Saya',
            storeAddress: storeAddress,
            storePhone: storePhone,
          );
          return pdf.save();
        },
        allowPrinting: true,
        allowSharing: true,
        canChangeOrientation: false,
        canChangePageFormat: false,
        canDebug: false,
      ),
    );
  }

  Future<void> _printReceipt(BuildContext context) async {
    try {
      final pdf = await ReceiptService.generatePDFReceipt(
        transactionId: transactionId,
        date: date,
        customerName: customerName,
        items: items,
        subtotal: subtotal,
        tax: tax,
        total: total,
        paymentMethod: paymentMethod,
        cashAmount: cashAmount,
        change: change,
        storeName: storeName ?? 'Toko Saya',
        storeAddress: storeAddress,
        storePhone: storePhone,
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
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

