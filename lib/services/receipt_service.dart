import 'package:printing/printing.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:intl/intl.dart';

class ReceiptService {
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
                final name = item['name'] as String? ?? 'Item';
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
              _buildTotalRow('Pajak', tax),
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
  // Note: Thermal printer support requires esc_pos_printer package
  // which conflicts with pdf/printing packages. This will be implemented
  // with a compatible alternative package in the future.
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
  }) async {
    // TODO: Implement with compatible thermal printer package
    throw UnimplementedError(
      'Thermal printer support is not yet available due to package conflicts. '
      'Please use PDF printing mode for now. Thermal printer support will be added in a future update.',
    );
  }

  // Print PDF receipt (for preview and general printing)
  static Future<void> printPDFReceipt(pw.Document pdf) async {
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
    );
  }

  // Print to thermal printer via network
  // Note: This requires a compatible thermal printer package
  static Future<void> printToThermalPrinter({
    required String printerIP,
    required int port,
    required List<int> bytes,
  }) async {
    throw UnimplementedError(
      'Thermal printer support is not yet available. '
      'Please use PDF printing mode which works with any printer.',
    );
  }

  // Print to thermal printer via Bluetooth (Android/iOS)
  static Future<void> printToBluetoothPrinter({
    required String printerAddress,
    required List<int> bytes,
  }) async {
    throw UnimplementedError(
      'Bluetooth thermal printer support is not yet available. '
      'Please use PDF printing mode which works with any printer.',
    );
  }
}

