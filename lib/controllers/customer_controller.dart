import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/customer_model.dart';
import '../services/database_service.dart';
import '../utils/error_helper.dart';

class CustomerController extends ChangeNotifier {
  final DatabaseService _databaseService = DatabaseService();

  List<Customer> _customers = [];
  bool _isLoading = true;
  String? _errorMessage;

  // Filters
  String _searchQuery = '';
  String _selectedFilter = 'Semua';
  final List<String> _filterOptions = ['Semua', 'VIP', 'Gold', 'Silver', 'Bronze'];

  // Subscriptions
  StreamSubscription<List<Map<String, dynamic>>>? _customersSubscription;

  // Getters
  List<Customer> get customers => _customers;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String get searchQuery => _searchQuery;
  String get selectedFilter => _selectedFilter;
  List<String> get filterOptions => _filterOptions;

  // Computed getters
  List<Customer> get filteredCustomers {
    List<Customer> filtered = _customers;

    // Apply tier filter
    if (_selectedFilter != 'Semua') {
      filtered = filtered.where((customer) => customer.customerTier == _selectedFilter).toList();
    }

    // Apply search query
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((customer) {
        return customer.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
               customer.phone.contains(_searchQuery) ||
               customer.email.toLowerCase().contains(_searchQuery.toLowerCase()) ||
               customer.address.toLowerCase().contains(_searchQuery.toLowerCase());
      }).toList();
    }

    return filtered;
  }

  int get totalCustomers => _customers.length;
  int get vipCustomers => _customers.where((c) => c.customerTier == 'VIP').length;
  double get totalRevenue => _customers.fold(0.0, (sum, customer) => sum + customer.totalSpent);

  Future<void> initialize() async {
    await _loadCustomers();
  }

  Future<void> _loadCustomers() async {
    _customersSubscription?.cancel();

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    _customersSubscription = _databaseService.getCustomersStream().listen(
      (customersData) {
        _customers = customersData.map((data) => Customer.fromFirebase(data)).toList();
        _isLoading = false;
        _errorMessage = null;
        notifyListeners();
      },
      onError: (error) {
        _isLoading = false;
        _errorMessage = getFriendlyErrorMessage(
          error,
          fallbackMessage: 'Gagal memuat data pelanggan.',
        );
        notifyListeners();
      },
    );
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void setSelectedFilter(String filter) {
    _selectedFilter = filter;
    notifyListeners();
  }

  Future<void> addCustomer({
    required String name,
    required String phone,
    String email = '',
    String address = '',
    String notes = '',
  }) async {
    try {
      await _databaseService.addCustomer({
        'name': name.trim(),
        'phone': phone.trim(),
        'email': email.trim(),
        'address': address.trim(),
        'notes': notes.trim(),
      });
    } catch (error) {
      throw getFriendlyErrorMessage(
        error,
        fallbackMessage: 'Gagal menambahkan pelanggan.',
      );
    }
  }

  Future<void> updateCustomer(
    String customerId, {
    required String name,
    required String phone,
    String email = '',
    String address = '',
    String notes = '',
  }) async {
    try {
      await _databaseService.updateCustomer(customerId, {
        'name': name.trim(),
        'phone': phone.trim(),
        'email': email.trim(),
        'address': address.trim(),
        'notes': notes.trim(),
      });
    } catch (error) {
      throw getFriendlyErrorMessage(
        error,
        fallbackMessage: 'Gagal memperbarui pelanggan.',
      );
    }
  }

  Future<void> deleteCustomer(String customerId) async {
    try {
      await _databaseService.deleteCustomer(customerId);
    } catch (error) {
      throw getFriendlyErrorMessage(
        error,
        fallbackMessage: 'Gagal menghapus pelanggan.',
      );
    }
  }

  DatabaseService get databaseService => _databaseService;

  @override
  void dispose() {
    _customersSubscription?.cancel();
    super.dispose();
  }
}


