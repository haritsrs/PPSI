import 'dart:async';
import 'package:printing/printing.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'receipt_builder.dart';

class ReceiptService {
  // Flag statis untuk melacak inisialisasi lokal
  static bool _localeInitialized = false;
  static Completer<void>? _localeInitCompleter;

  /// Ensure locale data is initialized (only once, thread-safe)
  static Future<void> _ensureLocaleInitialized() async {
    // Jika sudah diinisialisasi, kembali segera
    if (_localeInitialized) {
      return;
    }

    // Jika inisialisasi sedang berlangsung, tunggu
    if (_localeInitCompleter != null && !_localeInitCompleter!.isCompleted) {
      try {
        await _localeInitCompleter!.future;
        return;
      } catch (e) {
        // Jika inisialisasi sebelumnya gagal, atur ulang dan coba lagi
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
    final dateFormat = DateFormat('dd MMM yyyy HH:mm:ss', 'id_ID');
    
    // Classic compact 80mm thermal layout for 58/80mm printers
    const double headerFontSize = 12;
    const double normalFontSize = 8.5;
    const double smallFontSize = 7.5;
    const double totalFontSize = 10.5;
    const double lineHeight = 1.05;
    const double spacing = 2;
    const double sectionSpacing = 3;
    
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat(80 * PdfPageFormat.mm, double.infinity,
            marginAll: 2 * PdfPageFormat.mm),
        build: (pw.Context context) {
          final headerStyle = pw.TextStyle(
            fontSize: headerFontSize,
            fontWeight: pw.FontWeight.bold,
            height: lineHeight,
          );
          final normalStyle = pw.TextStyle(fontSize: normalFontSize, height: lineHeight);
          final smallStyle = pw.TextStyle(fontSize: smallFontSize, height: lineHeight);
          final totalStyle = pw.TextStyle(
            fontSize: totalFontSize,
            fontWeight: pw.FontWeight.bold,
            height: lineHeight,
          );

          pw.Widget separator() => pw.Text(
                '------------------------------------------',
                style: smallStyle,
                textAlign: pw.TextAlign.center,
              );

          String truncateLeft(String text, int maxLen) {
            if (text.length <= maxLen) return text;
            if (maxLen <= 3) return text.substring(0, maxLen);
            return '${text.substring(0, maxLen - 3)}...';
          }

          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.stretch,
            children: [
              // Header (centered store name, tightly stacked address + phone)
              pw.Text(
                storeName ?? 'Toko Saya',
                style: headerStyle,
                textAlign: pw.TextAlign.center,
              ),
              if (storeAddress != null && storeAddress.trim().isNotEmpty)
                pw.Text(
                  storeAddress.trim(),
                  style: smallStyle,
                  textAlign: pw.TextAlign.center,
                ),
              if (storePhone != null && storePhone.trim().isNotEmpty)
                pw.Text(
                  storePhone.trim(),
                  style: smallStyle,
                  textAlign: pw.TextAlign.center,
                ),
              pw.Text(
                dateFormat.format(date),
                style: smallStyle,
                textAlign: pw.TextAlign.center,
              ),

              pw.SizedBox(height: spacing),
              separator(),
              pw.SizedBox(height: spacing),

              // Transaction meta
              pw.Text('Nomor Nota: $transactionId', style: normalStyle),
              pw.Text('Tanggal: ${dateFormat.format(date)}', style: normalStyle),

              pw.SizedBox(height: spacing),
              separator(),
              pw.SizedBox(height: spacing),

              // Items with two-line pattern
              ...items.map((item) {
                final name = (item['productName'] as String?) ??
                    (item['name'] as String?) ??
                    'Item';
                final quantity = (item['quantity'] as num?)?.toInt() ?? 0;
                final price = (item['price'] as num?)?.toDouble() ?? 0.0;
                final itemTotal = quantity * price;

                final qtyLine = '${quantity} x ${_formatMoney(price)}';
                final rightText = _formatMoney(itemTotal);
                final maxLeft = ((32 - rightText.length - 1).clamp(8, 32)).toInt();
                final truncatedName = truncateLeft(name.trim(), maxLeft + 6);

                return pw.Padding(
                  padding: const pw.EdgeInsets.only(bottom: 2),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(truncatedName, style: normalStyle),
                      pw.Row(
                        children: [
                          pw.Expanded(
                            child: pw.Text(
                              qtyLine,
                              style: normalStyle,
                              maxLines: 1,
                              overflow: pw.TextOverflow.clip,
                            ),
                          ),
                          pw.Text(rightText, style: normalStyle),
                        ],
                      ),
                    ],
                  ),
                );
              }),

              pw.SizedBox(height: spacing),
              separator(),
              pw.SizedBox(height: spacing),

              _buildReceiptRow('Total', total, totalStyle, isTight: true),
              _buildReceiptRow('Bayar ${_formatPaymentMethod(paymentMethod)}', cashAmount ?? total, normalStyle, isTight: true),
              _buildReceiptRow('Kembali', change ?? 0, normalStyle, isTight: true),

              pw.SizedBox(height: sectionSpacing),
              pw.Text('Terima kasih atas kunjungan Anda', style: totalStyle, textAlign: pw.TextAlign.center),
            ],
          );
        },
      ),
    );
    
    return pdf;
  }

  static pw.Widget _buildReceiptRow(
    String label,
    double value,
    pw.TextStyle style, {
    bool isTight = false,
  }) {
    return pw.Padding(
      padding: pw.EdgeInsets.only(bottom: isTight ? 0 : 1),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            '$label :',
            style: style,
          ),
          pw.Text(
            _formatMoney(value),
            style: style,
          ),
        ],
      ),
    );
  }


  static String _formatMoney(double value) {
    return value
        .toStringAsFixed(0)
        .replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.');
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
      date: date,
    );

    // Transaction info
    await builder.addTransactionInfo(
      transactionId: transactionId,
      date: date,
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

  // Cetak ke printer termal menggunakan PrinterService
  // Metode ini harus dipanggil dengan instance PrinterService
  // Contoh: await printerService.printBytes(bytes);
  // PrinterService menangani koneksi USB dan Bluetooth
}


