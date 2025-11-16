import 'dart:async';
import 'dart:io';
import 'dart:math' as math;

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:excel/excel.dart' hide Border;
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import '../services/database_service.dart';
import '../widgets/print_receipt_dialog.dart';
import '../utils/error_helper.dart';
import '../utils/security_utils.dart';
import '../widgets/loading_skeletons.dart';
import '../widgets/responsive_page.dart';

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
  String _searchQuery = '';
  String _selectedPaymentMethod = 'Semua';
  
  final List<String> _periods = ['Hari', 'Minggu', 'Bulan'];
  final List<String> _filters = ['Semua', 'Hari Ini', 'Minggu Ini', 'Bulan Ini', 'Rentang Tanggal'];
  final List<String> _paymentMethods = ['Semua', 'Cash', 'QRIS', 'VirtualAccount'];
  
  // Date range selection
  DateTime? _startDate;
  DateTime? _endDate;
  bool _useDateRange = false;
  
  final DatabaseService _databaseService = DatabaseService();
  final TextEditingController _searchController = TextEditingController();
  List<Transaction> _transactions = [];
  bool _isLoading = true;
  bool _localeInitialized = false;
  bool _isRetrying = false;
  bool _hasLoadedOnce = false;
  bool _isRefreshing = false;
  String? _errorMessage;
  bool _isOffline = false;
  Completer<void>? _refreshCompleter;

  bool get _showInitialLoader => _isLoading && !_hasLoadedOnce;
  bool get _showFullErrorState => _errorMessage != null && !_hasLoadedOnce;
  bool get _showInlineErrorBanner => _errorMessage != null && _hasLoadedOnce;

  final Connectivity _connectivity = Connectivity();
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  StreamSubscription<List<Map<String, dynamic>>>? _transactionsSubscription;

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
    _initializeConnectivity();
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

  Future<void> _initializeConnectivity() async {
    try {
      final results = await _connectivity.checkConnectivity();
      _handleConnectivityChange(results, emitSetState: false);
    } catch (_) {
      // Ignore connectivity check errors
    }

    _connectivitySubscription = _connectivity.onConnectivityChanged.listen(_handleConnectivityChange);
  }

  void _handleConnectivityChange(
    List<ConnectivityResult> results, {
    bool emitSetState = true,
  }) {
    final isOffline = results.isEmpty || results.every((result) => result == ConnectivityResult.none);
    if (!mounted) return;

    if (emitSetState) {
      setState(() {
        _isOffline = isOffline;
      });
    } else {
      _isOffline = isOffline;
    }

    if (!isOffline && _errorMessage != null && !_isRetrying) {
      _retryLoadTransactions();
    }
  }

  Future<void> _retryLoadTransactions() async {
    if (_isRetrying) return;
    if (!mounted) return;

    setState(() {
      _isRetrying = true;
      _errorMessage = null;
    });

    await _loadTransactions();
  }

  Future<void> _refreshTransactions() {
    _loadTransactions(isRefresh: true);
    return _refreshCompleter?.future ?? Future.value();
  }

  Future<void> _loadTransactions({bool isRefresh = false}) async {
    _transactionsSubscription?.cancel();

    if (!mounted) return;

    if (isRefresh) {
      if (_refreshCompleter != null && !_refreshCompleter!.isCompleted) {
        _refreshCompleter!.complete();
      }
      _refreshCompleter = Completer<void>();
    }

    setState(() {
      if (isRefresh) {
        _isRefreshing = true;
      } else {
        if (!_hasLoadedOnce) {
          _isLoading = true;
        }
        _isRetrying = _hasLoadedOnce;
      }
      _errorMessage = null;
    });

    _transactionsSubscription = _databaseService.getTransactionsStream().listen(
      (transactionsData) {
        if (!mounted) return;
        setState(() {
          _transactions = transactionsData.map(Transaction.fromFirebase).toList();
          _isLoading = false;
          _isRetrying = false;
          _isRefreshing = false;
          _errorMessage = null;
          _hasLoadedOnce = true;
        });
        _refreshCompleter?.complete();
        _refreshCompleter = null;
      },
      onError: (error) {
        final message = getFriendlyErrorMessage(
          error,
          fallbackMessage: 'Gagal memuat data transaksi.',
        );
        if (!mounted) return;
        setState(() {
          if (!isRefresh) {
            _isLoading = false;
            _isRetrying = false;
          }
          _isRefreshing = false;
          _errorMessage = message;
        });
        _refreshCompleter?.complete();
        _refreshCompleter = null;
      },
    );
  }

  @override
  void dispose() {
    _transactionsSubscription?.cancel();
    _connectivitySubscription?.cancel();
    _animationController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  List<Transaction> get _filteredTransactions {
    return _transactions.where((transaction) {
      // Date filter
      bool matchesDate = true;
      if (_useDateRange && _startDate != null && _endDate != null) {
        final transactionDate = DateTime(
          transaction.date.year,
          transaction.date.month,
          transaction.date.day,
        );
        final start = DateTime(_startDate!.year, _startDate!.month, _startDate!.day);
        final end = DateTime(_endDate!.year, _endDate!.month, _endDate!.day).add(const Duration(days: 1));
        matchesDate = transactionDate.isAfter(start.subtract(const Duration(days: 1))) &&
               transactionDate.isBefore(end);
      } else {
        switch (_selectedFilter) {
          case 'Hari Ini':
            final today = DateTime.now();
            matchesDate = transaction.date.year == today.year &&
                   transaction.date.month == today.month &&
                   transaction.date.day == today.day;
            break;
          case 'Minggu Ini':
            matchesDate = transaction.date.isAfter(DateTime.now().subtract(const Duration(days: 7)));
            break;
          case 'Bulan Ini':
            final now = DateTime.now();
            matchesDate = transaction.date.year == now.year &&
                   transaction.date.month == now.month;
            break;
          default:
            matchesDate = true;
        }
      }
      
      if (!matchesDate) return false;
      
      // Payment method filter
      if (_selectedPaymentMethod != 'Semua' && transaction.paymentMethod != _selectedPaymentMethod) {
        return false;
      }
      
      // Search filter
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        final matchesId = transaction.id.toLowerCase().contains(query);
        final matchesCustomer = transaction.customerName.toLowerCase().contains(query);
        final matchesTotal = transaction.total.toString().contains(query);
        final matchesPayment = transaction.paymentMethod.toLowerCase().contains(query);
        
        if (!matchesId && !matchesCustomer && !matchesTotal && !matchesPayment) {
          return false;
        }
      }
      
      return true;
    }).toList();
  }

  // Total penghasilan (income) from all transactions for reporting
  double get _totalRevenue {
    return _filteredTransactions.fold(0.0, (sum, transaction) => sum + transaction.total);
  }

  int get _totalTransactions {
    return _filteredTransactions.length;
  }

  Widget _buildStatusBanner({
    required MaterialColor color,
    required IconData icon,
    required String message,
    Widget? trailing,
  }) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(icon, color: color),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: color.shade700,
                    fontWeight: FontWeight.w500,
                  ),
            ),
          ),
          if (trailing != null) trailing,
        ],
      ),
    );
  }

  Widget _buildTransactionDismissBackground({
    required Color color,
    required IconData icon,
    required Alignment alignment,
    required String label,
  }) {
    return Container(
      alignment: alignment,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      key: const ValueKey('reports-error'),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              size: 64,
              color: Color(0xFFDC2626),
            ),
            const SizedBox(height: 16),
            Text(
              'Tidak dapat memuat data transaksi',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF1F2937),
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            if (_errorMessage != null)
              Text(
                _errorMessage!,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey[600],
                    ),
                textAlign: TextAlign.center,
              ),
            if (_isOffline) ...[
              const SizedBox(height: 8),
              Text(
                'Periksa koneksi internet Anda sebelum mencoba lagi.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey[500],
                    ),
                textAlign: TextAlign.center,
              ),
            ],
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _isRetrying ? null : _retryLoadTransactions,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6366F1),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              icon: _isRetrying
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Icon(Icons.refresh_rounded),
              label: Text(
                _isRetrying ? 'Mencoba lagi...' : 'Coba Lagi',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle.light.copyWith(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
          statusBarBrightness: Brightness.dark,
        ),
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
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
        child: ResponsivePage(
          child: _showInitialLoader
              ? const SingleChildScrollView(
                  key: ValueKey('reports-loader'),
                  physics: AlwaysScrollableScrollPhysics(),
                  child: ReportListSkeleton(),
                )
              : _showFullErrorState
                  ? _buildErrorState()
                  : _buildContent(),
        ),
          ),
        ),
      ),
    );
  }

  Widget _buildContent() {
    return RefreshIndicator(
      onRefresh: _refreshTransactions,
      color: const Color(0xFF6366F1),
      displacement: 48,
      child: SingleChildScrollView(
        key: const ValueKey('reports-content'),
        physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
      // padding is handled by ResponsivePage
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_isOffline)
            _buildStatusBanner(
              color: Colors.orange,
              icon: Icons.wifi_off_rounded,
              message: 'Anda sedang offline. Data dapat tidak terbaru.',
              trailing: TextButton(
                onPressed: _isRetrying ? null : _retryLoadTransactions,
                child: Text(
                  'Segarkan',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: Colors.orange[700],
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ),
            ),
            if (_showInlineErrorBanner)
            _buildStatusBanner(
              color: Colors.red,
              icon: Icons.error_outline_rounded,
              message: _errorMessage ?? 'Terjadi kesalahan.',
              trailing: TextButton(
                onPressed: _isRetrying ? null : _retryLoadTransactions,
                child: Text(
                  'Coba Lagi',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: Colors.red[600],
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ),
            ),
            if (_isRetrying && _hasLoadedOnce)
            _buildStatusBanner(
              color: Colors.blue,
              icon: Icons.sync_rounded,
              message: 'Menyegarkan data transaksi...',
              trailing: const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF2563EB)),
                ),
              ),
            ),
            if (_isRefreshing && !_showInitialLoader)
              const Padding(
                padding: EdgeInsets.only(bottom: 12),
                child: LinearProgressIndicator(
                  minHeight: 3,
                  color: Color(0xFF6366F1),
                  backgroundColor: Color(0xFFE2E8F0),
                ),
              ),
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
                      const SizedBox(height: 16),
                      // Search Bar
                      TextField(
                        controller: _searchController,
                        onChanged: (value) {
                          setState(() {
                            _searchQuery = value;
                          });
                        },
                        decoration: InputDecoration(
                          hintText: 'Cari transaksi (ID, pelanggan, total, metode pembayaran)...',
                          prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF6366F1)),
                          suffixIcon: _searchQuery.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear_rounded),
                                  onPressed: () {
                                    setState(() {
                                      _searchQuery = '';
                                      _searchController.clear();
                                    });
                                  },
                                )
                              : null,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey.withOpacity(0.3)),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Color(0xFF6366F1), width: 2),
                          ),
                          filled: true,
                          fillColor: const Color(0xFFF8FAFC),
                        ),
                      ),
                      const SizedBox(height: 12),
                      // Payment Method Filter
                      Row(
                        children: [
                          const Icon(Icons.payment_rounded, size: 20, color: Color(0xFF6366F1)),
                          const SizedBox(width: 8),
                          Text(
                            'Metode Pembayaran:',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: DropdownButton<String>(
                              value: _selectedPaymentMethod,
                              isExpanded: true,
                              onChanged: (String? newValue) {
                                setState(() {
                                  _selectedPaymentMethod = newValue!;
                                });
                              },
                              underline: Container(),
                              items: _paymentMethods.map<DropdownMenuItem<String>>((String value) {
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
                            ),
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
                                return TweenAnimationBuilder<double>(
                                  duration: Duration(milliseconds: 220 + (index * 12)),
                                  curve: Curves.easeOutCubic,
                                  tween: Tween<double>(begin: 0, end: 1),
                                  builder: (context, value, child) {
                                    return Opacity(
                                      opacity: value,
                                      child: Transform.translate(
                                        offset: Offset(0, (1 - value) * 16),
                                        child: child,
                                      ),
                                    );
                                  },
                                  child: Dismissible(
                                    key: ValueKey('transaction-${transaction.id}'),
                                    background: _buildTransactionDismissBackground(
                                      color: Colors.indigo.shade100,
                                      icon: Icons.visibility_rounded,
                                      alignment: Alignment.centerLeft,
                                      label: 'Detail',
                                    ),
                                    secondaryBackground: _buildTransactionDismissBackground(
                                      color: Colors.green.shade100,
                                      icon: Icons.print_rounded,
                                      alignment: Alignment.centerRight,
                                      label: 'Cetak',
                                    ),
                                    confirmDismiss: (direction) async {
                                      if (direction == DismissDirection.startToEnd) {
                                        _showTransactionDetail(transaction);
                                      } else {
                                        await _quickPrint(transaction);
                                      }
                                      return false;
                                    },
                                    child: TransactionCard(
                                      transaction: transaction,
                                      onTap: () => _showTransactionDetail(transaction),
                                    ),
                                  ),
                                );
                              },
                            ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          ],
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
    try {
      final fullTransactionData = await _databaseService.getTransaction(transaction.id);

      if (!mounted) return;

      showModalBottomSheet(
        context: context,
        backgroundColor: Colors.transparent,
        isScrollControlled: true,
        builder: (context) => TransactionDetailModal(
          transaction: transaction,
          fullTransactionData: fullTransactionData,
          databaseService: _databaseService,
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
          onCancelled: () {
            _loadTransactions();
          },
        ),
      );
    } catch (error) {
      if (!mounted) return;
      final message = getFriendlyErrorMessage(
        error,
        fallbackMessage: 'Gagal memuat detail transaksi.',
      );
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _quickPrint(Transaction transaction) async {
    try {
      final fullTransactionData = await _databaseService.getTransaction(transaction.id);
      if (!mounted) return;

      if (fullTransactionData == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Detail transaksi tidak ditemukan.'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      showDialog(
        context: context,
        builder: (context) => PrintReceiptDialog(
          transactionId: transaction.id,
          transactionData: fullTransactionData,
        ),
      );
    } catch (error) {
      if (!mounted) return;
      final message = getFriendlyErrorMessage(
        error,
        fallbackMessage: 'Gagal menyiapkan struk.',
      );
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
        ),
      );
    }
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
      } catch (error) {
        if (!mounted) return;
        final message = getFriendlyErrorMessage(
          error,
          fallbackMessage: 'Gagal membuat file PDF.',
        );
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } catch (error) {
      if (!mounted) return;
      final message = getFriendlyErrorMessage(
        error,
        fallbackMessage: 'Gagal membuat laporan PDF.',
      );
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
        ),
      );
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
      } catch (error) {
        if (!mounted) return;
        final message = getFriendlyErrorMessage(
          error,
          fallbackMessage: 'Gagal membuat file Excel.',
        );
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } catch (error) {
      if (!mounted) return;
      final message = getFriendlyErrorMessage(
        error,
        fallbackMessage: 'Gagal membuat laporan Excel.',
      );
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
        ),
      );
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

class TransactionDetailModal extends StatefulWidget {
  final Transaction transaction;
  final Map<String, dynamic>? fullTransactionData;
  final VoidCallback? onPrint;
  final DatabaseService databaseService;
  final VoidCallback? onCancelled;

  const TransactionDetailModal({
    super.key,
    required this.transaction,
    this.fullTransactionData,
    this.onPrint,
    required this.databaseService,
    this.onCancelled,
  });

  @override
  State<TransactionDetailModal> createState() => _TransactionDetailModalState();
}

class _TransactionDetailModalState extends State<TransactionDetailModal> {
  bool _isLoading = false;
  String _currentStatus = '';

  @override
  void initState() {
    super.initState();
    _currentStatus = widget.transaction.status;
  }

  Future<void> _cancelTransaction() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.warning_rounded, color: Colors.orange),
            SizedBox(width: 8),
            Text('Batalkan Transaksi'),
          ],
        ),
        content: const Text('Apakah Anda yakin ingin membatalkan transaksi ini? Stok produk akan dikembalikan.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Ya, Batalkan'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() {
      _isLoading = true;
    });

    try {
      await widget.databaseService.cancelTransaction(widget.transaction.id);
      if (mounted) {
        setState(() {
          _currentStatus = 'Dibatalkan';
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Transaksi berhasil dibatalkan'),
            backgroundColor: Colors.green,
          ),
        );
        widget.onCancelled?.call();
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final canCancel = _currentStatus != 'Dibatalkan' && _currentStatus != 'Dikembalikan';
    
    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
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
                  _buildDetailRow("ID Transaksi", widget.transaction.id),
                  _buildDetailRow("Tanggal", _formatDateTime(widget.transaction.date)),
                  _buildDetailRow("Pelanggan", widget.transaction.customerName),
                  _buildDetailRow("Jumlah Item", "${widget.transaction.items} item"),
                  _buildDetailRow("Metode Pembayaran", widget.transaction.paymentMethod),
                  _buildDetailRow("Status", _currentStatus),
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
                          'Rp ${widget.transaction.total.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')}',
                          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Action Buttons
                  Row(
                    children: [
                      if (widget.onPrint != null)
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: widget.onPrint,
                            icon: const Icon(Icons.print_rounded),
                            label: const Text('Cetak'),
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
                      if (canCancel && widget.onPrint != null) const SizedBox(width: 12),
                      if (canCancel)
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _isLoading ? null : _cancelTransaction,
                            icon: _isLoading
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                    ),
                                  )
                                : const Icon(Icons.cancel_rounded),
                            label: const Text('Batalkan'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
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
    final encryptionHelper = EncryptionHelper();
    String customerName = 'Pelanggan';
    if (data['customerName'] is String) {
      final rawName = data['customerName'] as String;
      if (data['customerNameEncrypted'] == true) {
        customerName = encryptionHelper.decryptIfPossible(rawName) ?? 'Pelanggan';
      } else {
        customerName = SecurityUtils.sanitizeInput(rawName);
      }
    }

    // Get payment method
    final paymentMethod = SecurityUtils.sanitizeInput(data['paymentMethod'] as String? ?? 'Cash');

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
