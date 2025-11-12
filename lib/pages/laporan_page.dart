import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math' as math;
import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:excel/excel.dart' hide Border;
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import '../services/database_service.dart';
import '../widgets/print_receipt_dialog.dart';

class LaporanPage extends StatefulWidget {
  const LaporanPage({super.key});

  @override
  State<LaporanPage> createState() => _LaporanPageState();
}

class _LaporanPageState extends State<LaporanPage> with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  
  String _selectedPeriod = 'Hari';
  String _selectedFilter = 'Semua';
  
  final List<String> _periods = ['Hari', 'Minggu', 'Bulan'];
  final List<String> _filters = ['Semua', 'Hari Ini', 'Minggu Ini', 'Bulan Ini', 'Rentang Tanggal'];
  
  // Date range selection
  DateTime? _startDate;
  DateTime? _endDate;
  bool _useDateRange = false;
  
  final DatabaseService _databaseService = DatabaseService();
  List<Transaction> _transactions = [];
  bool _isLoading = true;
  bool _localeInitialized = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));
    
    _animationController.forward();
    _initializeLocale();
    _loadTransactions();
  }

  Future<void> _initializeLocale() async {
    if (!_localeInitialized) {
      await initializeDateFormatting('id_ID', null);
      setState(() {
        _localeInitialized = true;
      });
    }
  }

  Future<void> _loadTransactions() async {
    setState(() {
      _isLoading = true;
    });

    try {
      _databaseService.getTransactionsStream().listen((transactionsData) {
        if (mounted) {
          setState(() {
            _transactions = transactionsData.map((data) {
              return Transaction.fromFirebase(data);
            }).toList();
            _isLoading = false;
          });
        }
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading transactions: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  List<Transaction> get _filteredTransactions {
    return _transactions.where((transaction) {
      if (_useDateRange && _startDate != null && _endDate != null) {
        final transactionDate = DateTime(
          transaction.date.year,
          transaction.date.month,
          transaction.date.day,
        );
        final start = DateTime(_startDate!.year, _startDate!.month, _startDate!.day);
        final end = DateTime(_endDate!.year, _endDate!.month, _endDate!.day).add(const Duration(days: 1));
        return transactionDate.isAfter(start.subtract(const Duration(days: 1))) &&
               transactionDate.isBefore(end);
      }
      
      switch (_selectedFilter) {
        case 'Hari Ini':
          final today = DateTime.now();
          return transaction.date.year == today.year &&
                 transaction.date.month == today.month &&
                 transaction.date.day == today.day;
        case 'Minggu Ini':
          return transaction.date.isAfter(DateTime.now().subtract(const Duration(days: 7)));
        case 'Bulan Ini':
          final now = DateTime.now();
          return transaction.date.year == now.year &&
                 transaction.date.month == now.month;
        default:
          return true;
      }
    }).toList();
  }

  // Total penghasilan (income) from all transactions for reporting
  double get _totalRevenue {
    return _filteredTransactions.fold(0.0, (sum, transaction) => sum + transaction.total);
  }

  int get _totalTransactions {
    return _filteredTransactions.length;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle.dark,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.analytics_rounded,
                color: Colors.white,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              "Laporan",
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              onPressed: () {
                HapticFeedback.lightImpact();
                _showExportDialog();
              },
              icon: const Icon(Icons.download_rounded, color: Colors.white),
            ),
          ),
        ],
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: _isLoading
              ? const Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF6366F1)),
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                // Period Toggle
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Periode Laporan",
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF1F2937),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: _periods.map((period) {
                          final isSelected = _selectedPeriod == period;
                          return Expanded(
                            child: GestureDetector(
                              onTap: () {
                                setState(() {
                                  _selectedPeriod = period;
                                });
                                HapticFeedback.lightImpact();
                              },
                              child: Container(
                                margin: const EdgeInsets.only(right: 8),
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                decoration: BoxDecoration(
                                  color: isSelected ? const Color(0xFF6366F1) : Colors.grey[100],
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  period,
                                  textAlign: TextAlign.center,
                                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: isSelected ? Colors.white : Colors.grey[600],
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Summary Cards
                Row(
                  children: [
                    Expanded(
                      child: _buildSummaryCard(
                        title: "Total Penghasilan",
                        value: _totalRevenue,
                        icon: Icons.trending_up_rounded,
                        color: const Color(0xFF10B981),
                        isCurrency: true,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildSummaryCard(
                        title: "Total Transaksi",
                        value: _totalTransactions.toDouble(),
                        icon: Icons.receipt_long_rounded,
                        color: const Color(0xFF3B82F6),
                        isCurrency: false,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // Chart Section
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Grafik Penghasilan",
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF1F2937),
                        ),
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        height: 200,
                        child: _buildChart(),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Filter and Transaction List
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "Daftar Transaksi",
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF1F2937),
                            ),
                          ),
                          DropdownButton<String>(
                            value: _selectedFilter,
                            onChanged: (String? newValue) {
                              setState(() {
                                _selectedFilter = newValue!;
                                if (newValue == 'Rentang Tanggal') {
                                  _useDateRange = true;
                                  _showDateRangePicker();
                                } else {
                                  _useDateRange = false;
                                }
                              });
                            },
                            underline: Container(),
                            items: _filters.map<DropdownMenuItem<String>>((String value) {
                              return DropdownMenuItem<String>(
                                value: value,
                                child: Text(
                                  value,
                                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: const Color(0xFF1F2937),
                                  ),
                                ),
                              );
                            }).toList(),
                            icon: const Icon(Icons.filter_list_rounded, color: Color(0xFF6366F1)),
                          ),
                        ],
                      ),
                      // Date range display
                      if (_useDateRange && _startDate != null && _endDate != null) ...[
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFF6366F1).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.calendar_today_rounded, color: Color(0xFF6366F1), size: 20),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  '${DateFormat('dd/MM/yyyy').format(_startDate!)} - ${DateFormat('dd/MM/yyyy').format(_endDate!)}',
                                  style: const TextStyle(
                                    color: Color(0xFF6366F1),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              TextButton(
                                onPressed: _showDateRangePicker,
                                child: const Text('Ubah'),
                              ),
                            ],
                          ),
                        ),
                      ],
                      const SizedBox(height: 16),
                      _filteredTransactions.isEmpty
                          ? Center(
                              child: Padding(
                                padding: const EdgeInsets.all(32.0),
                                child: Column(
                                  children: [
                                    Icon(
                                      Icons.receipt_long_outlined,
                                      size: 64,
                                      color: Colors.grey[400],
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      _transactions.isEmpty
                                          ? "Belum ada transaksi"
                                          : "Tidak ada transaksi yang cocok",
                                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                        color: Colors.grey[600],
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            )
                          : ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: _filteredTransactions.length,
                              itemBuilder: (context, index) {
                                final transaction = _filteredTransactions[index];
                                return TransactionCard(
                                  transaction: transaction,
                                  onTap: () => _showTransactionDetail(transaction),
                                );
                              },
                            ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryCard({
    required String title,
    required double value,
    required IconData icon,
    required Color color,
    required bool isCurrency,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
        border: Border.all(
          color: color.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 24,
                ),
              ),
              Icon(
                Icons.trending_up_rounded,
                color: Colors.green[600],
                size: 20,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            isCurrency 
                ? 'Rp ${value.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')}'
                : value.toStringAsFixed(0),
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: const Color(0xFF1F2937),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChart() {
    final chartData = _calculateChartData(_filteredTransactions);
    
    if (chartData.isEmpty) {
      return Center(
        child: Text(
          'Tidak ada data untuk ditampilkan',
          style: TextStyle(color: Colors.grey[600]),
        ),
      );
    }
    
    final double maxValue = chartData.reduce(math.max);
    
    return CustomPaint(
      size: const Size(double.infinity, 200),
      painter: ChartPainter(chartData, maxValue),
    );
  }

  void _showTransactionDetail(Transaction transaction) async {
    // Get full transaction data for printing
    final fullTransactionData = await _databaseService.transactionsRef
        .child(transaction.id)
        .get()
        .then((snapshot) {
      if (snapshot.exists) {
        return {
          'id': transaction.id,
          ...Map<String, dynamic>.from(snapshot.value as Map),
        };
      }
      return null;
    });

    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => TransactionDetailModal(
        transaction: transaction,
        fullTransactionData: fullTransactionData,
        onPrint: fullTransactionData != null
            ? () {
                Navigator.pop(context);
                showDialog(
                  context: context,
                  builder: (context) => PrintReceiptDialog(
                    transactionId: transaction.id,
                    transactionData: fullTransactionData,
                  ),
                );
              }
            : null,
      ),
    );
  }

  Future<void> _showDateRangePicker() async {
    // Ensure locale is initialized before showing date picker
    if (!_localeInitialized) {
      await _initializeLocale();
    }
    
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: _startDate != null && _endDate != null
          ? DateTimeRange(start: _startDate!, end: _endDate!)
          : null,
      locale: const Locale('id', 'ID'),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF6366F1),
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Color(0xFF1F2937),
            ),
          ),
          child: child!,
        );
      },
    );
    
    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
        _useDateRange = true;
        _selectedFilter = 'Rentang Tanggal';
      });
    }
  }

  void _showExportDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
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
              onPressed: () async {
                Navigator.of(context).pop();
                await _exportToPDF();
              },
              icon: const Icon(Icons.picture_as_pdf_rounded, size: 18),
              label: const Text('PDF'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
            ),
            ElevatedButton.icon(
              onPressed: () async {
                Navigator.of(context).pop();
                await _exportToExcel();
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
      },
    );
  }

  Future<void> _exportToPDF() async {
    try {
      HapticFeedback.mediumImpact();
      
      // Ensure locale is initialized
      if (!_localeInitialized) {
        await _initializeLocale();
      }
      
      // Show loading
      if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
            content: Row(
              children: [
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                ),
                SizedBox(width: 16),
                Text('Membuat PDF...'),
              ],
            ),
            duration: Duration(seconds: 2),
          ),
        );
      }

      final pdf = pw.Document();
      final filtered = _filteredTransactions;
      final dateTimeFormat = DateFormat('dd/MM/yyyy HH:mm', 'id_ID');

      // Calculate chart data
      final chartData = _calculateChartData(filtered);
      
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
                          'Periode: ${_getPeriodText()}',
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
                  _buildSummaryBox('Total Penghasilan', _totalRevenue, true),
                  _buildSummaryBox('Total Transaksi', _totalTransactions.toDouble(), false),
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
                'Daftar Transaksi (${filtered.length})',
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
                  ...filtered.map((transaction) {
                    return pw.TableRow(
                      children: [
                        _buildTableCell(transaction.id.substring(0, 8)),
                        _buildTableCell(dateTimeFormat.format(transaction.date)),
                        _buildTableCell(transaction.customerName),
                        _buildTableCell('${transaction.items}'),
                        _buildTableCell('Rp ${_formatCurrency(transaction.total)}'),
                      ],
                    );
                  }).toList(),
                ],
              ),
            ];
          },
        ),
      );

      // Save PDF - Use platform-agnostic approach
      final pdfBytes = await pdf.save();
      File? file;
      
      try {
        // Try path_provider first
        try {
          final output = await getTemporaryDirectory();
          file = File('${output.path}/laporan_${DateTime.now().millisecondsSinceEpoch}.pdf');
          await file.writeAsBytes(pdfBytes);
        } catch (e) {
          // Fallback: try application documents directory
          try {
            final output = await getApplicationDocumentsDirectory();
            file = File('${output.path}/laporan_${DateTime.now().millisecondsSinceEpoch}.pdf');
            await file.writeAsBytes(pdfBytes);
          } catch (e2) {
            // Last resort: use system temp directory
            try {
              final tempDir = Directory.systemTemp;
              file = File('${tempDir.path}/laporan_${DateTime.now().millisecondsSinceEpoch}.pdf');
              await file.writeAsBytes(pdfBytes);
            } catch (e3) {
              // If all else fails, show error
              if (mounted) {
                await Share.share(
                  'Laporan Transaksi - ${_getPeriodText()}\n\nFile PDF tidak dapat disimpan. Silakan restart aplikasi untuk mengaktifkan plugin path_provider.',
                  subject: 'Laporan Transaksi',
                );
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error: Tidak dapat mengakses direktori file. Error: $e\n\nSilakan restart aplikasi setelah menjalankan "flutter clean && flutter pub get && flutter run"'),
                    backgroundColor: Colors.red,
                    duration: const Duration(seconds: 7),
                  ),
                );
              }
              return;
            }
          }
        }

        // Save to Downloads/Documents and show success
        if (mounted) {
          // Try to save to a more accessible location (Documents folder)
          try {
            final documentsDir = await getApplicationDocumentsDirectory();
            final timestamp = DateTime.now().millisecondsSinceEpoch;
            final fileName = 'Laporan_Transaksi_$timestamp.pdf';
            final downloadsFile = File('${documentsDir.path}/$fileName');
            await downloadsFile.writeAsBytes(pdfBytes);
            
            // Show success dialog with options
            _showDownloadSuccessDialog(
              context: context,
              filePath: downloadsFile.path,
              fileName: fileName,
              fileType: 'PDF',
              onShare: () async {
                Navigator.pop(context);
                try {
                  await Share.shareXFiles(
                    [XFile(downloadsFile.path)],
                    text: 'Laporan Transaksi - ${_getPeriodText()}',
                    subject: 'Laporan Transaksi',
                  );
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Error sharing: $e'),
                        backgroundColor: Colors.orange,
                      ),
                    );
                  }
                }
              },
            );
          } catch (saveError) {
            // If saving to Documents fails, just use the temp file and share
            try {
              await Share.shareXFiles(
                [XFile(file.path)],
                text: 'Laporan Transaksi - ${_getPeriodText()}',
                subject: 'Laporan Transaksi',
              );
              
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('PDF berhasil dibuat di: ${file.path}'),
                    backgroundColor: Colors.green,
                  duration: const Duration(seconds: 3),
                ),
              );
            } catch (shareError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('PDF berhasil dibuat di: ${file.path}\nError sharing: $shareError'),
                  backgroundColor: Colors.orange,
                  duration: const Duration(seconds: 5),
                ),
              );
            }
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error membuat PDF: $e'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 5),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _exportToExcel() async {
    try {
      HapticFeedback.mediumImpact();
      
      // Ensure locale is initialized
      if (!_localeInitialized) {
        await _initializeLocale();
      }
      
      // Show loading
      if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
            content: Row(
              children: [
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                ),
                SizedBox(width: 16),
                Text('Membuat Excel...'),
              ],
            ),
            duration: Duration(seconds: 2),
          ),
        );
      }

      final excel = Excel.createExcel();
      excel.delete('Sheet1');
      final sheet = excel['Laporan Transaksi'];
      
      final filtered = _filteredTransactions;
      final dateTimeFormat = DateFormat('dd/MM/yyyy HH:mm', 'id_ID');

      // Header
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 0)).value = 'Laporan Transaksi';
      sheet.merge(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 0),
                  CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: 0));
      
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 1)).value = 'Periode: ${_getPeriodText()}';
      sheet.merge(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 1),
                  CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: 1));
      
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 2)).value = 'Tanggal Ekspor: ${DateFormat('dd/MM/yyyy HH:mm', 'id_ID').format(DateTime.now())}';
      sheet.merge(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 2),
                  CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: 2));
      
      // Summary
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 4)).value = 'Total Penghasilan:';
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: 4)).value = 'Rp ${_formatCurrency(_totalRevenue)}';
      
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 5)).value = 'Total Transaksi:';
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: 5)).value = _totalTransactions;
      
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
      for (int i = 0; i < filtered.length; i++) {
        final transaction = filtered[i];
        final row = headerRow + 1 + i;
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row)).value = transaction.id;
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: row)).value = dateTimeFormat.format(transaction.date);
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: row)).value = transaction.customerName;
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: row)).value = transaction.items;
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: row)).value = transaction.total;
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 5, rowIndex: row)).value = transaction.paymentMethod;
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 6, rowIndex: row)).value = transaction.status;
      }

      // Save Excel - Use platform-agnostic approach
      final excelBytes = excel.save();
      if (excelBytes == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Error: Tidak dapat membuat file Excel'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }
      
      File? file;
      
      try {
        // Try path_provider first
        try {
          final output = await getTemporaryDirectory();
          file = File('${output.path}/laporan_${DateTime.now().millisecondsSinceEpoch}.xlsx');
          await file.writeAsBytes(excelBytes);
        } catch (e) {
          // Fallback: try application documents directory
          try {
            final output = await getApplicationDocumentsDirectory();
            file = File('${output.path}/laporan_${DateTime.now().millisecondsSinceEpoch}.xlsx');
            await file.writeAsBytes(excelBytes);
          } catch (e2) {
            // Last resort: use system temp directory
            try {
              final tempDir = Directory.systemTemp;
              file = File('${tempDir.path}/laporan_${DateTime.now().millisecondsSinceEpoch}.xlsx');
              await file.writeAsBytes(excelBytes);
            } catch (e3) {
              // If all else fails, show error
              if (mounted) {
                await Share.share(
                  'Laporan Transaksi - ${_getPeriodText()}\n\nFile Excel tidak dapat disimpan. Silakan restart aplikasi untuk mengaktifkan plugin path_provider.',
                  subject: 'Laporan Transaksi',
                );
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error: Tidak dapat mengakses direktori file. Error: $e\n\nSilakan restart aplikasi setelah menjalankan "flutter clean && flutter pub get && flutter run"'),
                    backgroundColor: Colors.red,
                    duration: const Duration(seconds: 7),
                  ),
                );
              }
              return;
            }
          }
        }

        // Save to Downloads/Documents and show success
        if (mounted) {
          // Try to save to a more accessible location (Documents folder)
          try {
            final documentsDir = await getApplicationDocumentsDirectory();
            final timestamp = DateTime.now().millisecondsSinceEpoch;
            final fileName = 'Laporan_Transaksi_$timestamp.xlsx';
            final downloadsFile = File('${documentsDir.path}/$fileName');
            await downloadsFile.writeAsBytes(excelBytes);
            
            // Show success dialog with options
            _showDownloadSuccessDialog(
              context: context,
              filePath: downloadsFile.path,
              fileName: fileName,
              fileType: 'Excel',
              onShare: () async {
                Navigator.pop(context);
                try {
                  await Share.shareXFiles(
                    [XFile(downloadsFile.path)],
                    text: 'Laporan Transaksi - ${_getPeriodText()}',
                    subject: 'Laporan Transaksi',
                  );
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Error sharing: $e'),
                        backgroundColor: Colors.orange,
                      ),
                    );
                  }
                }
              },
            );
          } catch (saveError) {
            // If saving to Documents fails, just use the temp file and share
            try {
              await Share.shareXFiles(
                [XFile(file.path)],
                text: 'Laporan Transaksi - ${_getPeriodText()}',
                subject: 'Laporan Transaksi',
              );
              
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Excel berhasil dibuat di: ${file.path}'),
                  backgroundColor: Colors.green,
                  duration: const Duration(seconds: 3),
                ),
              );
            } catch (shareError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Excel berhasil dibuat di: ${file.path}\nError sharing: $shareError'),
                  backgroundColor: Colors.orange,
                  duration: const Duration(seconds: 5),
                ),
              );
            }
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error membuat Excel: $e'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 5),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  String _getPeriodText() {
    if (_useDateRange && _startDate != null && _endDate != null) {
      return '${DateFormat('dd/MM/yyyy').format(_startDate!)} - ${DateFormat('dd/MM/yyyy').format(_endDate!)}';
    }
    return _selectedFilter;
  }

  List<double> _calculateChartData(List<Transaction> transactions) {
    if (transactions.isEmpty) return [];
    
    final Map<String, double> dailyRevenue = {};
    for (var transaction in transactions) {
      final dateKey = DateFormat('yyyy-MM-dd').format(transaction.date);
      dailyRevenue[dateKey] = (dailyRevenue[dateKey] ?? 0.0) + transaction.total;
    }
    
    final sortedDates = dailyRevenue.keys.toList()..sort();
    return sortedDates.map((date) => dailyRevenue[date]!).toList();
  }

  pw.Widget _buildChartWidget(List<double> data) {
    if (data.isEmpty) {
      return pw.Text('Tidak ada data untuk ditampilkan');
    }
    
    final maxValue = data.reduce(math.max);
    final minValue = data.reduce(math.min);
    final range = maxValue - minValue;
    
    // Build chart as a simple bar chart using containers
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

  pw.Widget _buildSummaryBox(String title, double value, bool isCurrency) {
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
            isCurrency ? 'Rp ${_formatCurrency(value)}' : value.toStringAsFixed(0),
            style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildTableCell(String text, {bool isHeader = false}) {
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

  String _formatCurrency(double value) {
    return value.toStringAsFixed(0).replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]}.',
    );
  }

  void _showDownloadSuccessDialog({
    required BuildContext context,
    required String filePath,
    required String fileName,
    required String fileType,
    required VoidCallback onShare,
  }) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              Icon(Icons.check_circle_rounded, color: Colors.green[600], size: 28),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'File Berhasil Disimpan',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'File $fileType telah disimpan ke:',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: SelectableText(
                  filePath,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontFamily: 'monospace',
                    fontSize: 11,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Anda dapat menemukan file ini di folder Documents aplikasi.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Tutup'),
            ),
            ElevatedButton.icon(
              onPressed: onShare,
              icon: const Icon(Icons.share_rounded, size: 18),
              label: const Text('Bagikan'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6366F1),
                foregroundColor: Colors.white,
              ),
            ),
          ],
        );
      },
    );
  }
}

class ChartPainter extends CustomPainter {
  final List<double> data;
  final double maxValue;

  ChartPainter(this.data, this.maxValue);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    final path = Path();
    final stepX = size.width / (data.length - 1);

    for (int i = 0; i < data.length; i++) {
      final x = i * stepX;
      final y = size.height - (data[i] / maxValue) * size.height;

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    paint.style = PaintingStyle.stroke;
    paint.strokeWidth = 3;
    canvas.drawPath(path, paint);

    // Draw data points
    final pointPaint = Paint()
      ..color = const Color(0xFF6366F1)
      ..style = PaintingStyle.fill;

    for (int i = 0; i < data.length; i++) {
      final x = i * stepX;
      final y = size.height - (data[i] / maxValue) * size.height;
      canvas.drawCircle(Offset(x, y), 4, pointPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}


class TransactionCard extends StatelessWidget {
  final Transaction transaction;
  final VoidCallback onTap;

  const TransactionCard({
    super.key,
    required this.transaction,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.grey.withOpacity(0.1),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: const Color(0xFF6366F1).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.receipt_rounded,
                color: Color(0xFF6366F1),
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    transaction.id,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF1F2937),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${transaction.customerName} • ${transaction.items} item(s)',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatDateTime(transaction.date),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  'Rp ${transaction.total.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')}',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF6366F1),
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    transaction.status,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.green[700],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return '${difference.inDays} hari lalu';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} jam lalu';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} menit lalu';
    } else {
      return 'Baru saja';
    }
  }
}

class TransactionDetailModal extends StatelessWidget {
  final Transaction transaction;
  final Map<String, dynamic>? fullTransactionData;
  final VoidCallback? onPrint;

  const TransactionDetailModal({
    super.key,
    required this.transaction,
    this.fullTransactionData,
    this.onPrint,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.6,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: Column(
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          
          // Header
          Padding(
            padding: const EdgeInsets.all(24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Detail Transaksi",
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF1F2937),
                  ),
                ),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.grey.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.close_rounded,
                      color: Colors.grey,
                      size: 20,
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Transaction Details
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildDetailRow("ID Transaksi", transaction.id),
                  _buildDetailRow("Tanggal", _formatDateTime(transaction.date)),
                  _buildDetailRow("Pelanggan", transaction.customerName),
                  _buildDetailRow("Jumlah Item", "${transaction.items} item"),
                  _buildDetailRow("Metode Pembayaran", transaction.paymentMethod),
                  _buildDetailRow("Status", transaction.status),
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        Text(
                          "Total Transaksi",
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: Colors.white70,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Rp ${transaction.total.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')}',
                          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Print Button
                  if (onPrint != null)
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: onPrint,
                        icon: const Icon(Icons.print_rounded),
                        label: const Text('Cetak Struk'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF6366F1),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Colors.grey,
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              color: Color(0xFF1F2937),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    return "${dateTime.day.toString().padLeft(2, '0')}/${dateTime.month.toString().padLeft(2, '0')}/${dateTime.year} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}";
  }
}

// Data Models
class Transaction {
  final String id;
  final DateTime date;
  final String customerName;
  final int items;
  final double total;
  final String paymentMethod;
  final String status;

  Transaction({
    required this.id,
    required this.date,
    required this.customerName,
    required this.items,
    required this.total,
    required this.paymentMethod,
    required this.status,
  });

  factory Transaction.fromFirebase(Map<String, dynamic> data) {
    // Parse date from ISO string or timestamp
    DateTime date;
    if (data['createdAt'] != null) {
      try {
        date = DateTime.parse(data['createdAt'] as String);
      } catch (e) {
        date = DateTime.now();
      }
    } else {
      date = DateTime.now();
    }

    // Get items count
    final itemsList = data['items'] as List<dynamic>? ?? [];
    final itemsCount = itemsList.length;

    // Get customer name (if available, otherwise use default)
    final customerName = data['customerName'] as String? ?? 'Pelanggan';

    // Get payment method
    final paymentMethod = data['paymentMethod'] as String? ?? 'Cash';

    // Get total
    final total = (data['total'] as num?)?.toDouble() ?? 0.0;

    return Transaction(
      id: data['id'] as String? ?? data['key'] as String? ?? '',
      date: date,
      customerName: customerName,
      items: itemsCount,
      total: total,
      paymentMethod: paymentMethod,
      status: 'Selesai', // Default status
    );
  }
}
