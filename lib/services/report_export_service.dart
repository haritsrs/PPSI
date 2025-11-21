import 'dart:io';
import 'dart:math' as math;
import 'package:excel/excel.dart' hide Border;
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';
import '../models/transaction_model.dart';
import '../utils/home_utils.dart';

class ReportExportService {
  static Future<File?> _saveFile({
    required List<int> bytes,
    required String fileName,
    required String extension,
  }) async {
    try {
      final documentsDir = await getApplicationDocumentsDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fullFileName = '${fileName}_$timestamp.$extension';
      final file = File('${documentsDir.path}/$fullFileName');
      await file.writeAsBytes(bytes);
      return file;
    } catch (e) {
      // Fallback to temp directory
      try {
        final tempDir = Directory.systemTemp;
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        final fullFileName = '${fileName}_$timestamp.$extension';
        final file = File('${tempDir.path}/$fullFileName');
        await file.writeAsBytes(bytes);
        return file;
      } catch (e2) {
        return null;
      }
    }
  }

  static Future<File?> exportToPDF({
    required List<Transaction> transactions,
    required String periodText,
    required double totalRevenue,
    required int totalTransactions,
  }) async {
    final pdf = pw.Document();
    final dateTimeFormat = DateFormat('dd/MM/yyyy HH:mm', 'id_ID');
    final chartData = _calculateChartData(transactions);

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (pw.Context context) {
          return [
            // Header
            pw.Header(
              level: 0,
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'Laporan Transaksi',
                        style: pw.TextStyle(
                          fontSize: 24,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.blueGrey900,
                        ),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        'Periode: $periodText',
                        style: pw.TextStyle(fontSize: 12, color: PdfColors.grey700),
                      ),
                    ],
                  ),
                  pw.Text(
                    DateFormat('dd MMMM yyyy', 'id_ID').format(DateTime.now()),
                    style: pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
                  ),
                ],
              ),
            ),
            
            pw.SizedBox(height: 20),
            
            // Summary Cards
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                _buildSummaryBox('Total Penghasilan', totalRevenue, true),
                _buildSummaryBox('Total Transaksi', totalTransactions.toDouble(), false),
              ],
            ),
            
            pw.SizedBox(height: 30),
            
            // Chart Section
            pw.Text(
              'Grafik Penghasilan',
              style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 10),
            _buildChartWidget(chartData),
            
            pw.SizedBox(height: 30),
            
            // Transaction List
            pw.Text(
              'Daftar Transaksi (${transactions.length})',
              style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 10),
            
            // Table Header
            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.grey300),
              children: [
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: PdfColors.grey200),
                  children: [
                    _buildTableCell('ID', isHeader: true),
                    _buildTableCell('Tanggal', isHeader: true),
                    _buildTableCell('Pelanggan', isHeader: true),
                    _buildTableCell('Item', isHeader: true),
                    _buildTableCell('Total', isHeader: true),
                  ],
                ),
                ...transactions.map((transaction) {
                  return pw.TableRow(
                    children: [
                      _buildTableCell(transaction.id.substring(0, math.min(8, transaction.id.length))),
                      _buildTableCell(dateTimeFormat.format(transaction.date)),
                      _buildTableCell(transaction.customerName),
                      _buildTableCell('${transaction.items}'),
                      _buildTableCell('Rp ${formatCurrency(transaction.total)}'),
                    ],
                  );
                }).toList(),
              ],
            ),
          ];
        },
      ),
    );

    final pdfBytes = await pdf.save();
    return await _saveFile(
      bytes: pdfBytes,
      fileName: 'Laporan_Transaksi',
      extension: 'pdf',
    );
  }

  static Future<File?> exportToExcel({
    required List<Transaction> transactions,
    required String periodText,
    required double totalRevenue,
    required int totalTransactions,
  }) async {
    final excel = Excel.createExcel();
    excel.delete('Sheet1');
    final sheet = excel['Laporan Transaksi'];
    
    final dateTimeFormat = DateFormat('dd/MM/yyyy HH:mm', 'id_ID');

    // Header
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 0)).value = 'Laporan Transaksi';
    sheet.merge(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 0),
                CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: 0));
    
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 1)).value = 'Periode: $periodText';
    sheet.merge(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 1),
                CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: 1));
    
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 2)).value = 'Tanggal Ekspor: ${DateFormat('dd/MM/yyyy HH:mm', 'id_ID').format(DateTime.now())}';
    sheet.merge(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 2),
                CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: 2));
    
    // Summary
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 4)).value = 'Total Penghasilan:';
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: 4)).value = 'Rp ${formatCurrency(totalRevenue)}';
    
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 5)).value = 'Total Transaksi:';
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: 5)).value = totalTransactions;
    
    // Table Header
    final headerRow = 7;
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: headerRow)).value = 'ID Transaksi';
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: headerRow)).value = 'Tanggal';
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: headerRow)).value = 'Pelanggan';
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: headerRow)).value = 'Item';
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: headerRow)).value = 'Total';
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 5, rowIndex: headerRow)).value = 'Metode Pembayaran';
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 6, rowIndex: headerRow)).value = 'Status';

    // Data rows
    for (int i = 0; i < transactions.length; i++) {
      final transaction = transactions[i];
      final row = headerRow + 1 + i;
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row)).value = transaction.id;
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: row)).value = dateTimeFormat.format(transaction.date);
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: row)).value = transaction.customerName;
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: row)).value = transaction.items;
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: row)).value = transaction.total;
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 5, rowIndex: row)).value = transaction.paymentMethod;
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 6, rowIndex: row)).value = transaction.status;
    }

    final excelBytes = excel.save();
    if (excelBytes == null) {
      return null;
    }
    
    return await _saveFile(
      bytes: excelBytes,
      fileName: 'Laporan_Transaksi',
      extension: 'xlsx',
    );
  }

  static Future<void> shareFile(File file, String periodText) async {
    await Share.shareXFiles(
      [XFile(file.path)],
      text: 'Laporan Transaksi - $periodText',
      subject: 'Laporan Transaksi',
    );
  }

  static List<double> _calculateChartData(List<Transaction> transactions) {
    if (transactions.isEmpty) return [];
    
    final Map<String, double> dailyRevenue = {};
    for (var transaction in transactions) {
      final dateKey = DateFormat('yyyy-MM-dd').format(transaction.date);
      dailyRevenue[dateKey] = (dailyRevenue[dateKey] ?? 0.0) + transaction.total;
    }
    
    final sortedDates = dailyRevenue.keys.toList()..sort();
    return sortedDates.map((date) => dailyRevenue[date]!).toList();
  }

  static pw.Widget _buildChartWidget(List<double> data) {
    if (data.isEmpty) {
      return pw.Text('Tidak ada data untuk ditampilkan');
    }
    
    final maxValue = data.reduce(math.max);
    final minValue = data.reduce(math.min);
    final range = maxValue - minValue;
    
    return pw.Container(
      height: 150,
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceEvenly,
        crossAxisAlignment: pw.CrossAxisAlignment.end,
        children: data.map((value) {
          final height = range > 0 ? ((value - minValue) / range) * 150 : 50.0;
          return pw.Container(
            width: 20,
            height: height,
            decoration: pw.BoxDecoration(
              color: PdfColors.blue700,
              borderRadius: const pw.BorderRadius.vertical(top: pw.Radius.circular(2)),
            ),
          );
        }).toList(),
      ),
    );
  }

  static pw.Widget _buildSummaryBox(String title, double value, bool isCurrency) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            title,
            style: pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            isCurrency ? 'Rp ${formatCurrency(value)}' : formatCurrency(value),
            style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildTableCell(String text, {bool isHeader = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(6),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: isHeader ? 10 : 9,
          fontWeight: isHeader ? pw.FontWeight.bold : pw.FontWeight.normal,
        ),
      ),
    );
  }
}

