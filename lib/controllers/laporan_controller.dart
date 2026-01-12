import 'dart:async';
import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import '../models/transaction_model.dart';
import '../services/database_service.dart';
import '../services/report_export_service.dart';
import '../utils/error_helper.dart';

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
  final List<String> _filters = [
    'Semua',
    'Hari Ini',
    'Minggu Ini',
    'Bulan Ini',
    'Kuartal Ini',
    'Tahun Ini',
    'Sepanjang Waktu',
    'Rentang Tanggal'
  ];
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
          case 'Kuartal Ini':
            final now = DateTime.now();
            final currentQuarter = ((now.month - 1) ~/ 3) + 1;
            final transactionQuarter = ((transaction.date.month - 1) ~/ 3) + 1;
            matchesDate = transaction.date.year == now.year &&
                   transactionQuarter == currentQuarter;
            break;
          case 'Tahun Ini':
            final now = DateTime.now();
            matchesDate = transaction.date.year == now.year;
            break;
          case 'Sepanjang Waktu':
            matchesDate = true;
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
    }).toList()
      ..sort((a, b) => b.date.compareTo(a.date)); // Sort chronologically (newest first)
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

    try {
      _transactionsSubscription = _databaseService.getTransactionsStream().listen(
        (transactionsData) {
          try {
            _transactions = transactionsData.map((data) {
              try {
                return Transaction.fromFirebase(data);
              } catch (e) {
                debugPrint('Error parsing transaction: $e, data: $data');
                rethrow;
              }
            }).toList();
            _isLoading = false;
            _isRetrying = false;
            _isRefreshing = false;
            _errorMessage = null;
            _hasLoadedOnce = true;
            notifyListeners();
          } catch (e) {
            debugPrint('Error processing transactions: $e');
            final message = getFriendlyErrorMessage(
              e,
              fallbackMessage: 'Gagal memproses data transaksi. [DIAG: ${e.toString()}]',
            );
            if (!isRefresh) {
              _isLoading = false;
              _isRetrying = false;
            }
            _isRefreshing = false;
            _errorMessage = message;
            notifyListeners();
          }
        },
        onError: (error) {
          debugPrint('Error in transactions stream: $error');
          final message = getFriendlyErrorMessage(
            error,
            fallbackMessage: 'Gagal memuat data transaksi. [DIAG: ${error.toString()}]',
          );
          if (!isRefresh) {
            _isLoading = false;
            _isRetrying = false;
          }
          _isRefreshing = false;
          _errorMessage = message;
          notifyListeners();
        },
        cancelOnError: false,
      );
    } catch (error) {
      debugPrint('Error setting up transactions stream: $error');
      final message = getFriendlyErrorMessage(
        error,
        fallbackMessage: 'Gagal menginisialisasi stream transaksi. [DIAG: ${error.toString()}]',
      );
      if (!isRefresh) {
        _isLoading = false;
        _isRetrying = false;
      }
      _isRefreshing = false;
      _errorMessage = message;
      notifyListeners();
    }
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

  // Export methods - return data, let page handle UI
  Future<File?> exportToPDF() async {
    try {
      final file = await ReportExportService.exportToPDF(
        transactions: filteredTransactions,
        periodText: getPeriodText(),
        totalRevenue: totalRevenue,
        totalTransactions: totalTransactions,
      );
      return file;
    } catch (error) {
      debugPrint('Error exporting PDF: $error');
      return null;
    }
  }

  Future<File?> exportToExcel() async {
    try {
      final file = await ReportExportService.exportToExcel(
        transactions: filteredTransactions,
        periodText: getPeriodText(),
        totalRevenue: totalRevenue,
        totalTransactions: totalTransactions,
        startDate: _startDate,
        endDate: _endDate,
      );
      return file;
    } catch (error) {
      debugPrint('Error exporting Excel: $error');
      return null;
    }
  }

  // Transaction detail methods - return data, let page handle UI
  Future<Map<String, dynamic>?> getTransactionDetail(String transactionId) async {
    try {
      if (transactionId.isEmpty) {
        debugPrint('Error: transactionId is empty [DIAG: empty_transaction_id]');
        return null;
      }
      final fullTransactionData = await _databaseService.getTransaction(transactionId);
      if (fullTransactionData == null) {
        debugPrint('Transaction not found: $transactionId [DIAG: transaction_not_found]');
      }
      return fullTransactionData;
    } catch (error) {
      debugPrint('Error getting transaction detail: $error [DIAG: ${error.toString()}]');
      return null;
    }
  }

  Future<Map<String, dynamic>?> getTransactionForPrint(String transactionId) async {
    try {
      final fullTransactionData = await _databaseService.getTransaction(transactionId);
      return fullTransactionData;
    } catch (error) {
      debugPrint('Error getting transaction for print: $error');
      return null;
    }
  }

  @override
  void dispose() {
    _transactionsSubscription?.cancel();
    _connectivitySubscription?.cancel();
    super.dispose();
  }
}

