import 'dart:async';
import 'package:printing/printing.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'receipt_builder.dart';

class ReceiptService {
  // Static flag to track locale initialization
  static bool _localeInitialized = false;
  static Completer<void>? _localeInitCompleter;

  /// Ensure locale data is initialized (only once, thread-safe)
  static Future<void> _ensureLocaleInitialized() async {
    // If already initialized, return immediately
    if (_localeInitialized) {
      return;
    }

    // If initialization is in progress, wait for it
    if (_localeInitCompleter != null && !_localeInitCompleter!.isCompleted) {
      try {
        await _localeInitCompleter!.future;
        return;
      } catch (e) {
        // If previous initialization failed, reset and try again
        _localeInitCompleter = null;
        _localeInitialized = false;
      }
    }

    // Start new initialization
    _localeInitCompleter = Completer<void>();
    try {
      await initializeDateFormatting('id_ID', null);
      _localeInitialized = true;
      _localeInitCompleter!.complete();
    } catch (e) {
      _localeInitCompleter!.completeError(e);
      // Don't mark as initialized if it failed - allow retry
      _localeInitCompleter = null;
      rethrow;
    }
  }

  // Generate PDF receipt for preview and printing
  // Always uses minimal format: store name, date, items, subtotal, tax (if enabled), total, payment
  static Future<pw.Document> generatePDFReceipt({
    required String transactionId,
    required DateTime date,
    required String? customerName,
    required List<Map<String, dynamic>> items,
    required double subtotal,
    required double tax,
    required double total,
    required String paymentMethod,
    double? cashAmount,
    double? change,
    String? storeName,
    String? storeAddress,
    String? storePhone,
  }) async {
    // Ensure locale is initialized before using DateFormat
    await _ensureLocaleInitialized();
    
    final pdf = pw.Document();
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm', 'id_ID');
    
    // Fixed minimal font sizes
    const double headerFontSize = 14;
    const double normalFontSize = 9;
    const double smallFontSize = 8;
    const double totalFontSize = 10;
    const double spacing = 3;
    const double sectionSpacing = 6;
    
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat(80 * PdfPageFormat.mm, double.infinity,
            marginAll: 3 * PdfPageFormat.mm),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            children: [
              // Store Header
              pw.Text(
                storeName ?? 'Toko Saya',
                style: pw.TextStyle(
                  fontSize: headerFontSize,
                  fontWeight: pw.FontWeight.bold,
                ),
                textAlign: pw.TextAlign.center,
              ),
              pw.SizedBox(height: spacing),
              
              // Date/Time
              pw.Text(
                dateFormat.format(date),
                style: pw.TextStyle(fontSize: smallFontSize),
                textAlign: pw.TextAlign.center,
              ),
              
              pw.SizedBox(height: sectionSpacing),
              pw.Divider(),
              pw.SizedBox(height: spacing),
              
              // Items - single line format: name x qty = total
              ...items.map((item) {
                final name = (item['productName'] as String?) ?? 
                             (item['name'] as String?) ?? 
                             'Item';
                final quantity = (item['quantity'] as num?)?.toInt() ?? 0;
                final price = (item['price'] as num?)?.toDouble() ?? 0.0;
                final itemTotal = quantity * price;
                
                return pw.Padding(
                  padding: const pw.EdgeInsets.only(bottom: 2),
                  child: pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Expanded(
                        child: pw.Text(
                          '$name x$quantity',
                          style: pw.TextStyle(fontSize: normalFontSize),
                        ),
                      ),
                      pw.Text(
                        _formatCurrency(itemTotal),
                        style: pw.TextStyle(fontSize: normalFontSize),
                      ),
                    ],
                  ),
                );
              }),
              
              pw.SizedBox(height: sectionSpacing),
              pw.Divider(),
              pw.SizedBox(height: spacing),
              
              // Subtotal
              _buildReceiptRow('Subtotal', subtotal, normalFontSize),
              // Tax (only show if > 0)
              if (tax > 0) _buildReceiptRow('Pajak', tax, normalFontSize),
              pw.SizedBox(height: spacing),
              pw.Divider(thickness: 1.5),
              pw.SizedBox(height: spacing),
              // Total
              _buildReceiptRow('TOTAL', total, totalFontSize, isBold: true),
              
              pw.SizedBox(height: sectionSpacing),
              pw.Divider(),
              pw.SizedBox(height: spacing),
              
              // Payment method
              pw.Text(
                'Pembayaran: ${_formatPaymentMethod(paymentMethod)}',
                style: pw.TextStyle(fontSize: normalFontSize),
              ),
              
              // Change (if applicable)
              if (change != null && change > 0) ...[
                pw.SizedBox(height: 2),
                pw.Text(
                  'Kembalian: ${_formatCurrency(change)}',
                  style: pw.TextStyle(fontSize: normalFontSize),
                ),
              ],
              
              pw.SizedBox(height: sectionSpacing),
              pw.Text(
                'Terima Kasih',
                style: pw.TextStyle(fontSize: normalFontSize, fontWeight: pw.FontWeight.bold),
                textAlign: pw.TextAlign.center,
              ),
              pw.SizedBox(height: spacing),
            ],
          );
        },
      ),
    );
    
    return pdf;
  }

  static pw.Widget _buildReceiptRow(String label, double value, double fontSize, {bool isBold = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 2),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            label,
            style: pw.TextStyle(
              fontSize: fontSize,
              fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
            ),
          ),
          pw.Text(
            _formatCurrency(value),
            style: pw.TextStyle(
              fontSize: fontSize,
              fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }


  static String _formatCurrency(double value) {
    return 'Rp ${value.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')}';
  }

  static String _formatPaymentMethod(String method) {
    switch (method.toLowerCase()) {
      case 'cash':
        return 'Tunai';
      case 'card':
        return 'Kartu';
      case 'qris':
        return 'QRIS';
      default:
        return method;
    }
  }

  // Generate ESC/POS receipt for thermal printers
  static Future<List<int>> generateESCPOSReceipt({
    required String transactionId,
    required DateTime date,
    required String? customerName,
    required List<Map<String, dynamic>> items,
    required double subtotal,
    required double tax,
    required double total,
    required String paymentMethod,
    double? cashAmount,
    double? change,
    String? storeName,
    String? storeAddress,
    String? storePhone,
    String? qrCodeData,
    double discount = 0.0,
  }) async {
    final builder = ReceiptBuilder();

    // Header
    builder.addHeader(
      storeName: storeName ?? 'Toko Saya',
      address: storeAddress,
      phone: storePhone,
    );

    // Transaction info
    await builder.addTransactionInfo(
      transactionId: transactionId,
      date: date,
      customerName: customerName,
    );

    // Items
    builder.addItems(items);

    // Totals
    builder.addTotals(
      subtotal: subtotal,
      tax: tax,
      total: total,
      discount: discount,
    );

    // Payment info
    builder.addPaymentInfo(
      paymentMethod: paymentMethod,
      cashAmount: cashAmount,
      change: change,
    );

    // QR code (if provided)
    if (qrCodeData != null && qrCodeData.isNotEmpty) {
      builder.addQRCode(qrCodeData, label: 'ID Transaksi');
    }

    // Footer
    builder.addFooter();

    return builder.build();
  }

  // Print PDF receipt (for preview and general printing)
  static Future<void> printPDFReceipt(pw.Document pdf) async {
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
    );
  }

  // Print to thermal printer using PrinterService
  // This method should be called with an instance of PrinterService
  // Example: await printerService.printBytes(bytes);
  // The PrinterService handles both USB and Bluetooth connections
}

