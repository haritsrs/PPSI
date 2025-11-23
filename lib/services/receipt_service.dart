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
    
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat(80 * PdfPageFormat.mm, double.infinity,
            marginAll: 4 * PdfPageFormat.mm),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            children: [
              // Store Header
              if (storeName != null) ...[
                pw.Text(
                  storeName,
                  style: pw.TextStyle(
                    fontSize: 18,
                    fontWeight: pw.FontWeight.bold,
                  ),
                  textAlign: pw.TextAlign.center,
                ),
                pw.SizedBox(height: 4),
              ],
              if (storeAddress != null) ...[
                pw.Text(
                  storeAddress,
                  style: const pw.TextStyle(fontSize: 10),
                  textAlign: pw.TextAlign.center,
                ),
                pw.SizedBox(height: 2),
              ],
              if (storePhone != null) ...[
                pw.Text(
                  storePhone,
                  style: const pw.TextStyle(fontSize: 10),
                  textAlign: pw.TextAlign.center,
                ),
                pw.SizedBox(height: 8),
              ],
              if (storeName == null && storeAddress == null && storePhone == null)
                pw.Text(
                  'Toko Saya',
                  style: pw.TextStyle(
                    fontSize: 18,
                    fontWeight: pw.FontWeight.bold,
                  ),
                  textAlign: pw.TextAlign.center,
                ),
              
              pw.Divider(),
              pw.SizedBox(height: 4),
              
              // Transaction Info
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('ID: $transactionId', style: const pw.TextStyle(fontSize: 9)),
                  pw.Text(dateFormat.format(date), style: const pw.TextStyle(fontSize: 9)),
                ],
              ),
              
              if (customerName != null && customerName.isNotEmpty) ...[
                pw.SizedBox(height: 4),
                pw.Text('Pelanggan: $customerName', style: const pw.TextStyle(fontSize: 9)),
              ],
              
              pw.SizedBox(height: 8),
              pw.Divider(),
              pw.SizedBox(height: 4),
              
              // Items
              ...items.map((item) {
                // Support both 'name' and 'productName' fields for backward compatibility
                final name = (item['productName'] as String?) ?? 
                             (item['name'] as String?) ?? 
                             'Item';
                final quantity = (item['quantity'] as num?)?.toInt() ?? 0;
                final price = (item['price'] as num?)?.toDouble() ?? 0.0;
                final itemTotal = quantity * price;
                
                return pw.Padding(
                  padding: const pw.EdgeInsets.only(bottom: 6),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Expanded(
                            child: pw.Text(
                              name,
                              style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
                            ),
                          ),
                          pw.Text(
                            _formatCurrency(itemTotal),
                            style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
                          ),
                        ],
                      ),
                      pw.SizedBox(height: 2),
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Text(
                            '$quantity x ${_formatCurrency(price)}',
                            style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              }).toList(),
              
              pw.SizedBox(height: 8),
              pw.Divider(),
              pw.SizedBox(height: 4),
              
              // Totals
              _buildTotalRow('Subtotal', subtotal),
              // Tax (only show if > 0)
              if (tax > 0) _buildTotalRow('Pajak', tax),
              pw.SizedBox(height: 4),
              pw.Divider(thickness: 2),
              pw.SizedBox(height: 4),
              _buildTotalRow('TOTAL', total, isBold: true, isLarge: true),
              
              pw.SizedBox(height: 8),
              pw.Divider(),
              pw.SizedBox(height: 4),
              
              // Payment Info
              pw.Text(
                'Pembayaran: ${_formatPaymentMethod(paymentMethod)}',
                style: const pw.TextStyle(fontSize: 10),
              ),
              if (cashAmount != null) ...[
                pw.SizedBox(height: 2),
                pw.Text(
                  'Tunai: ${_formatCurrency(cashAmount)}',
                  style: const pw.TextStyle(fontSize: 10),
                ),
              ],
              if (change != null && change > 0) ...[
                pw.SizedBox(height: 2),
                pw.Text(
                  'Kembalian: ${_formatCurrency(change)}',
                  style: const pw.TextStyle(fontSize: 10),
                ),
              ],
              
              pw.SizedBox(height: 16),
              pw.Text(
                'Terima Kasih',
                style: pw.TextStyle(
                  fontSize: 12,
                  fontWeight: pw.FontWeight.bold,
                ),
                textAlign: pw.TextAlign.center,
              ),
              pw.SizedBox(height: 4),
              pw.Text(
                'Selamat Berbelanja Kembali',
                style: const pw.TextStyle(fontSize: 10),
                textAlign: pw.TextAlign.center,
              ),
              pw.SizedBox(height: 8),
            ],
          );
        },
      ),
    );
    
    return pdf;
  }

  static pw.Widget _buildTotalRow(String label, double value, {bool isBold = false, bool isLarge = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 4),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            label,
            style: pw.TextStyle(
              fontSize: isLarge ? 12 : 10,
              fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
            ),
          ),
          pw.Text(
            _formatCurrency(value),
            style: pw.TextStyle(
              fontSize: isLarge ? 12 : 10,
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

