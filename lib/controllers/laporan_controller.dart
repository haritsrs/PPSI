import 'dart:async';
import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import '../models/transaction_model.dart';
import '../services/database_service.dart';
import '../services/report_export_service.dart';
import '../utils/error_helper.dart';
import '../widgets/transaction_detail_modal.dart';
import '../widgets/print_receipt_dialog.dart';
import '../widgets/download_success_dialog.dart';

class LaporanController extends ChangeNotifier {
  final DatabaseService _databaseService = DatabaseService();
  final Connectivity _connectivity = Connectivity();

  // State
  List<Transaction> _transactions = [];
  bool _isLoading = true;
  bool _isRetrying = false;
  bool _hasLoadedOnce = false;
  bool _isRefreshing = false;
  String? _errorMessage;
  bool _isOffline = false;

  // Filters
  String _selectedFilter = 'Semua';
  String _searchQuery = '';
  String _selectedPaymentMethod = 'Semua';
  DateTime? _startDate;
  DateTime? _endDate;
  bool _useDateRange = false;
  
  // Filter options
  final List<String> _periods = ['Hari', 'Minggu', 'Bulan'];
  final List<String> _filters = ['Semua', 'Hari Ini', 'Minggu Ini', 'Bulan Ini', 'Rentang Tanggal'];
  final List<String> _paymentMethods = ['Semua', 'Cash', 'QRIS', 'VirtualAccount'];
  String _selectedPeriod = 'Hari';

  // Subscriptions
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  StreamSubscription<List<Map<String, dynamic>>>? _transactionsSubscription;

  // Getters
  List<Transaction> get transactions => _transactions;
  bool get isLoading => _isLoading;
  bool get isRetrying => _isRetrying;
  bool get hasLoadedOnce => _hasLoadedOnce;
  bool get isRefreshing => _isRefreshing;
  String? get errorMessage => _errorMessage;
  bool get isOffline => _isOffline;
  String get selectedFilter => _selectedFilter;
  String get searchQuery => _searchQuery;
  String get selectedPaymentMethod => _selectedPaymentMethod;
  DateTime? get startDate => _startDate;
  DateTime? get endDate => _endDate;
  bool get useDateRange => _useDateRange;
  List<String> get periods => _periods;
  List<String> get filters => _filters;
  List<String> get paymentMethods => _paymentMethods;
  String get selectedPeriod => _selectedPeriod;

  bool get showInitialLoader => _isLoading && !_hasLoadedOnce;
  bool get showFullErrorState => _errorMessage != null && !_hasLoadedOnce;
  bool get showInlineErrorBanner => _errorMessage != null && _hasLoadedOnce;

  List<Transaction> get filteredTransactions {
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

  double get totalRevenue {
    return filteredTransactions.fold(0.0, (sum, transaction) => sum + transaction.total);
  }

  int get totalTransactions {
    return filteredTransactions.length;
  }

  DatabaseService get databaseService => _databaseService;

  Future<void> initialize() async {
    await _initializeConnectivity();
    await _loadTransactions();
  }

  Future<void> _loadTransactions({bool isRefresh = false}) async {
    _transactionsSubscription?.cancel();

    if (isRefresh) {
      _isRefreshing = true;
      notifyListeners();
    } else {
      if (!_hasLoadedOnce) {
        _isLoading = true;
      }
      _isRetrying = _hasLoadedOnce;
      notifyListeners();
    }
    _errorMessage = null;

    _transactionsSubscription = _databaseService.getTransactionsStream().listen(
      (transactionsData) {
        _transactions = transactionsData.map(Transaction.fromFirebase).toList();
        _isLoading = false;
        _isRetrying = false;
        _isRefreshing = false;
        _errorMessage = null;
        _hasLoadedOnce = true;
        notifyListeners();
      },
      onError: (error) {
        final message = getFriendlyErrorMessage(
          error,
          fallbackMessage: 'Gagal memuat data transaksi.',
        );
        if (!isRefresh) {
          _isLoading = false;
          _isRetrying = false;
        }
        _isRefreshing = false;
        _errorMessage = message;
        notifyListeners();
      },
    );
  }

  Future<void> _initializeConnectivity() async {
    try {
      final results = await _connectivity.checkConnectivity();
      _handleConnectivityChange(results, emitNotify: false);
    } catch (_) {
      // Ignore connectivity check errors
    }

    _connectivitySubscription = _connectivity.onConnectivityChanged.listen(_handleConnectivityChange);
  }

  void _handleConnectivityChange(
    List<ConnectivityResult> results, {
    bool emitNotify = true,
  }) {
    final isOffline = results.isEmpty || results.every((result) => result == ConnectivityResult.none);
    _isOffline = isOffline;

    if (emitNotify) {
      notifyListeners();
    }

    if (!isOffline && _errorMessage != null && !_isRetrying) {
      retryLoadTransactions();
    }
  }

  Future<void> retryLoadTransactions() async {
    if (_isRetrying) return;

    _isRetrying = true;
    _errorMessage = null;
    notifyListeners();

    await _loadTransactions();
  }

  Future<void> refreshTransactions() async {
    await _loadTransactions(isRefresh: true);
  }

  void setSelectedFilter(String filter) {
    _selectedFilter = filter;
    if (filter == 'Rentang Tanggal') {
      _useDateRange = true;
    } else {
      _useDateRange = false;
    }
    notifyListeners();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void setSelectedPaymentMethod(String method) {
    _selectedPaymentMethod = method;
    notifyListeners();
  }

  void setSelectedPeriod(String period) {
    _selectedPeriod = period;
    notifyListeners();
  }

  void setDateRange(DateTime? start, DateTime? end) {
    _startDate = start;
    _endDate = end;
    _useDateRange = start != null && end != null;
    if (_useDateRange) {
      _selectedFilter = 'Rentang Tanggal';
    }
    notifyListeners();
  }

  String getPeriodText() {
    if (_useDateRange && _startDate != null && _endDate != null) {
      return '${_startDate!.day.toString().padLeft(2, '0')}/${_startDate!.month.toString().padLeft(2, '0')}/${_startDate!.year} - ${_endDate!.day.toString().padLeft(2, '0')}/${_endDate!.month.toString().padLeft(2, '0')}/${_endDate!.year}';
    }
    return _selectedFilter;
  }

  // Export methods
  Future<void> exportToPDF(BuildContext context) async {
    try {
      // Ensure locale is initialized
      await initializeDateFormatting('id_ID', null);
      
      final file = await ReportExportService.exportToPDF(
        transactions: filteredTransactions,
        periodText: getPeriodText(),
        totalRevenue: totalRevenue,
        totalTransactions: totalTransactions,
      );

      if (file == null) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Gagal membuat file PDF.'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      if (context.mounted) {
        DownloadSuccessDialog.show(
          context: context,
          filePath: file.path,
          fileName: file.path.split(Platform.pathSeparator).last,
          fileType: 'PDF',
          onShare: () async {
            try {
              await ReportExportService.shareFile(file, getPeriodText());
            } catch (e) {
              if (context.mounted) {
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
      }
    } catch (error) {
      if (context.mounted) {
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
  }

  Future<void> exportToExcel(BuildContext context) async {
    try {
      // Ensure locale is initialized
      await initializeDateFormatting('id_ID', null);
      
      final file = await ReportExportService.exportToExcel(
        transactions: filteredTransactions,
        periodText: getPeriodText(),
        totalRevenue: totalRevenue,
        totalTransactions: totalTransactions,
      );

      if (file == null) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Gagal membuat file Excel.'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      if (context.mounted) {
        DownloadSuccessDialog.show(
          context: context,
          filePath: file.path,
          fileName: file.path.split(Platform.pathSeparator).last,
          fileType: 'Excel',
          onShare: () async {
            try {
              await ReportExportService.shareFile(file, getPeriodText());
            } catch (e) {
              if (context.mounted) {
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
      }
    } catch (error) {
      if (context.mounted) {
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
  }

  // Transaction detail methods
  Future<void> showTransactionDetail(BuildContext context, Transaction transaction) async {
    try {
      final fullTransactionData = await _databaseService.getTransaction(transaction.id);

      if (!context.mounted) return;

      TransactionDetailModal.show(
        context,
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
          refreshTransactions();
        },
      );
    } catch (error) {
      if (!context.mounted) return;
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

  Future<void> quickPrint(BuildContext context, Transaction transaction) async {
    try {
      final fullTransactionData = await _databaseService.getTransaction(transaction.id);
      if (!context.mounted) return;

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
      if (!context.mounted) return;
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

  // Date range picker
  Future<void> openDateRangePicker(BuildContext context) async {
    await initializeDateFormatting('id_ID', null);
    
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: _startDate != null && _endDate != null
          ? DateTimeRange(start: _startDate!, end: _endDate!)
          : null,
      locale: const Locale('id', 'ID'),
      builder: (BuildContext context, Widget? child) {
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
      setDateRange(picked.start, picked.end);
    }
  }

  @override
  void dispose() {
    _transactionsSubscription?.cancel();
    _connectivitySubscription?.cancel();
    super.dispose();
  }
}

