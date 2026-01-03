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
    bool compactMode = false,
  }) async {
    // Ensure locale is initialized before using DateFormat
    await _ensureLocaleInitialized();
    
    final pdf = pw.Document();
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm', 'id_ID');
    
    // Compact mode uses smaller spacing and font sizes
    final double headerFontSize = compactMode ? 14 : 18;
    final double normalFontSize = compactMode ? 8 : 10;
    final double smallFontSize = compactMode ? 7 : 9;
    final double itemFontSize = compactMode ? 8 : 10;
    final double totalFontSize = compactMode ? 10 : 12;
    final double spacing = compactMode ? 2 : 4;
    final double sectionSpacing = compactMode ? 4 : 8;
    
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat(80 * PdfPageFormat.mm, double.infinity,
            marginAll: compactMode ? 2 * PdfPageFormat.mm : 4 * PdfPageFormat.mm),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            children: [
              // Store Header
              if (storeName != null) ...[
                pw.Text(
                  storeName,
                  style: pw.TextStyle(
                    fontSize: headerFontSize,
                    fontWeight: pw.FontWeight.bold,
                  ),
                  textAlign: pw.TextAlign.center,
                ),
                pw.SizedBox(height: spacing),
              ],
              if (storeAddress != null && !compactMode) ...[
                pw.Text(
                  storeAddress,
                  style: pw.TextStyle(fontSize: normalFontSize),
                  textAlign: pw.TextAlign.center,
                ),
                pw.SizedBox(height: spacing / 2),
              ],
              if (storePhone != null && !compactMode) ...[
                pw.Text(
                  storePhone,
                  style: pw.TextStyle(fontSize: normalFontSize),
                  textAlign: pw.TextAlign.center,
                ),
                pw.SizedBox(height: sectionSpacing),
              ],
              if (storeName == null && storeAddress == null && storePhone == null)
                pw.Text(
                  'Toko Saya',
                  style: pw.TextStyle(
                    fontSize: headerFontSize,
                    fontWeight: pw.FontWeight.bold,
                  ),
                  textAlign: pw.TextAlign.center,
                ),
              
              pw.Divider(),
              pw.SizedBox(height: spacing),
              
              // Transaction Info
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('ID: $transactionId', style: pw.TextStyle(fontSize: smallFontSize)),
                  pw.Text(dateFormat.format(date), style: pw.TextStyle(fontSize: smallFontSize)),
                ],
              ),
              
              if (customerName != null && customerName.isNotEmpty && !compactMode) ...[
                pw.SizedBox(height: spacing),
                pw.Text('Pelanggan: $customerName', style: pw.TextStyle(fontSize: smallFontSize)),
              ],
              
              pw.SizedBox(height: sectionSpacing),
              pw.Divider(),
              pw.SizedBox(height: spacing),
              
              // Items - compact mode shows simplified format
              ...items.map((item) {
                // Support both 'name' and 'productName' fields for backward compatibility
                final name = (item['productName'] as String?) ?? 
                             (item['name'] as String?) ?? 
                             'Item';
                final quantity = (item['quantity'] as num?)?.toInt() ?? 0;
                final price = (item['price'] as num?)?.toDouble() ?? 0.0;
                final itemTotal = quantity * price;
                
                if (compactMode) {
                  // Single line format for compact mode
                  return pw.Padding(
                    padding: pw.EdgeInsets.only(bottom: spacing / 2),
                    child: pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Expanded(
                          child: pw.Text(
                            '$name x$quantity',
                            style: pw.TextStyle(fontSize: itemFontSize),
                          ),
                        ),
                        pw.Text(
                          _formatCurrency(itemTotal),
                          style: pw.TextStyle(fontSize: itemFontSize),
                        ),
                      ],
                    ),
                  );
                }
                
                return pw.Padding(
                  padding: pw.EdgeInsets.only(bottom: spacing + 2),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Expanded(
                            child: pw.Text(
                              name,
                              style: pw.TextStyle(fontSize: itemFontSize, fontWeight: pw.FontWeight.bold),
                            ),
                          ),
                          pw.Text(
                            _formatCurrency(itemTotal),
                            style: pw.TextStyle(fontSize: itemFontSize, fontWeight: pw.FontWeight.bold),
                          ),
                        ],
                      ),
                      pw.SizedBox(height: spacing / 2),
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Text(
                            '$quantity x ${_formatCurrency(price)}',
                            style: pw.TextStyle(fontSize: smallFontSize, color: PdfColors.grey700),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              }).toList(),
              
              pw.SizedBox(height: sectionSpacing),
              pw.Divider(),
              pw.SizedBox(height: spacing),
              
              // Totals
              _buildTotalRowCompact('Subtotal', subtotal, normalFontSize, spacing),
              // Tax (only show if > 0)
              if (tax > 0) _buildTotalRowCompact('Pajak', tax, normalFontSize, spacing),
              pw.SizedBox(height: spacing),
              pw.Divider(thickness: 2),
              pw.SizedBox(height: spacing),
              _buildTotalRowCompact('TOTAL', total, totalFontSize, spacing, isBold: true),
              
              pw.SizedBox(height: sectionSpacing),
              pw.Divider(),
              pw.SizedBox(height: spacing),
              
              // Payment Info
              pw.Text(
                'Pembayaran: ${_formatPaymentMethod(paymentMethod)}',
                style: pw.TextStyle(fontSize: normalFontSize),
              ),
              if (cashAmount != null && !compactMode) ...[
                pw.SizedBox(height: spacing / 2),
                pw.Text(
                  'Tunai: ${_formatCurrency(cashAmount)}',
                  style: pw.TextStyle(fontSize: normalFontSize),
                ),
              ],
              if (change != null && change > 0) ...[
                pw.SizedBox(height: spacing / 2),
                pw.Text(
                  'Kembalian: ${_formatCurrency(change)}',
                  style: pw.TextStyle(fontSize: normalFontSize),
                ),
              ],
              
              pw.SizedBox(height: compactMode ? sectionSpacing : 16),
              if (!compactMode) ...[
                pw.Text(
                  'Terima Kasih',
                  style: pw.TextStyle(
                    fontSize: 12,
                    fontWeight: pw.FontWeight.bold,
                  ),
                  textAlign: pw.TextAlign.center,
                ),
                pw.SizedBox(height: spacing),
                pw.Text(
                  'Selamat Berbelanja Kembali',
                  style: pw.TextStyle(fontSize: normalFontSize),
                  textAlign: pw.TextAlign.center,
                ),
                pw.SizedBox(height: sectionSpacing),
              ] else ...[
                pw.Text(
                  'Terima Kasih',
                  style: pw.TextStyle(fontSize: normalFontSize, fontWeight: pw.FontWeight.bold),
                  textAlign: pw.TextAlign.center,
                ),
                pw.SizedBox(height: spacing),
              ],
            ],
          );
        },
      ),
    );
    
    return pdf;
  }

  static pw.Widget _buildTotalRowCompact(String label, double value, double fontSize, double spacing, {bool isBold = false}) {
    return pw.Padding(
      padding: pw.EdgeInsets.only(bottom: spacing),
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

