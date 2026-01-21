import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import '../models/product_model.dart';
import '../services/database_service.dart';
import '../utils/error_helper.dart';

class ProductController extends ChangeNotifier {
  static const int _pageSize = 25;

  final DatabaseService _databaseService = DatabaseService();
  final Connectivity _connectivity = Connectivity();

  // Products state
  List<Product> _products = [];
  bool _isLoading = true;
  bool _isRetrying = false;
  bool _hasLoadedOnce = false;
  bool _isPaginating = false;
  bool _isRefreshing = false;
  bool _hasMore = true;
  String? _lastProductKey;
  String? _errorMessage;
  bool _isOffline = false;

  // Filters
  String _selectedCategory = 'Semua';
  String _selectedFilter = 'Semua';
  String _searchQuery = '';
  
  List<String> _categories = ['Semua'];
  final List<String> _filters = ['Semua', 'Stok Rendah', 'Habis', 'Tersedia'];

  // Subscriptions
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  StreamSubscription<List<Map<String, dynamic>>>? _productsSubscription;

  // Getters
  List<Product> get products => _products;
  bool get isLoading => _isLoading;
  bool get isRetrying => _isRetrying;
  bool get hasLoadedOnce => _hasLoadedOnce;
  bool get isPaginating => _isPaginating;
  bool get isRefreshing => _isRefreshing;
  bool get hasMore => _hasMore;
  String? get errorMessage => _errorMessage;
  bool get isOffline => _isOffline;
  String get selectedCategory => _selectedCategory;
  String get selectedFilter => _selectedFilter;
  String get searchQuery => _searchQuery;
  List<String> get categories => _categories;
  List<String> get filters => _filters;

  bool get showInitialLoader => _isLoading && !_hasLoadedOnce;
  bool get showFullErrorState => _errorMessage != null && !_hasLoadedOnce;
  bool get showInlineErrorBanner => _errorMessage != null && _hasLoadedOnce;

  // Computed getters
  List<Product> get filteredProducts {
    return _products.where((product) {
      // Category filter
      if (_selectedCategory != 'Semua' && product.category != _selectedCategory) {
        return false;
      }
      
      // Stock filter
      switch (_selectedFilter) {
        case 'Stok Rendah':
          return product.isLowStock && !product.isOutOfStock;
        case 'Habis':
          return product.isOutOfStock;
        case 'Tersedia':
          return !product.isLowStock && !product.isOutOfStock;
        default:
          break;
      }
      
      // Search filter
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        return product.name.toLowerCase().contains(query) ||
               product.supplier.toLowerCase().contains(query) ||
               product.barcode.toLowerCase().contains(query) ||
               product.category.toLowerCase().contains(query);
      }
      
      return true;
    }).toList();
  }

  int get totalProducts => _products.length;
  int get lowStockCount => _products.where((product) => product.isLowStock && !product.isOutOfStock).length;
  int get outOfStockCount => _products.where((product) => product.isOutOfStock).length;
  double get totalStockValue => _products.fold(0.0, (sum, product) => sum + (product.price * product.stock));

  Future<void> initialize() async {
    await _initializeConnectivity();
    await loadInitialProducts();
    _startProductsStream();
  }

  void _startProductsStream() {
    _productsSubscription?.cancel();
    _productsSubscription = _databaseService.getProductsStream().listen(
      (productsData) {
        // Only update if we have loaded products (avoid updates during initial load)
        if (!_hasLoadedOnce) return;
        
        // Update existing products with new data from stream
        final streamProducts = productsData.map(Product.fromFirebase).toList();
        final streamProductsMap = {for (var p in streamProducts) p.id: p};
        
        bool hasChanges = false;
        // Update existing products in _products list
        for (int i = 0; i < _products.length; i++) {
          final updatedProduct = streamProductsMap[_products[i].id];
          if (updatedProduct != null && _products[i].stock != updatedProduct.stock) {
            _products[i] = updatedProduct;
            hasChanges = true;
          }
        }
        
        // Only notify if there were actual changes
        if (hasChanges) {
          _categories = _buildCategoriesFromProducts(_products);
          notifyListeners();
        }
      },
      onError: (error) {
        // Silently handle stream errors - don't log to avoid console spam
      },
      cancelOnError: false,
    );
  }

  Future<void> loadInitialProducts({bool isRefresh = false}) async {
    if (isRefresh) {
      _isRefreshing = true;
      _errorMessage = null;
      notifyListeners();
    } else {
      if (!_hasLoadedOnce) {
        _isLoading = true;
      }
      if (!_isRetrying) {
        _isRetrying = _hasLoadedOnce && _errorMessage != null;
      }
      _errorMessage = null;
      notifyListeners();
    }

    _lastProductKey = null;
    _hasMore = true;

    try {
      final result = await _databaseService.fetchProductsPage(limit: _pageSize);
      final fetchedProducts = result.items.map(Product.fromFirebase).toList();
      final updatedCategories = _buildCategoriesFromProducts(fetchedProducts);

      _products = fetchedProducts;
      _categories = updatedCategories;
      _isLoading = false;
      _isRetrying = false;
      _errorMessage = null;
      _hasLoadedOnce = true;
      _lastProductKey = result.lastKey;
      _hasMore = result.hasMore;
      _isRefreshing = false;
      notifyListeners();
    } catch (error) {
      final message = getFriendlyErrorMessage(
        error,
        fallbackMessage: 'Gagal memuat data produk.',
      );

      if (isRefresh) {
        _isRefreshing = false;
      } else {
        _isLoading = false;
        _isRetrying = false;
      }
      _errorMessage = message;
      notifyListeners();
    }
  }

  Future<void> _initializeConnectivity() async {
    try {
      final results = await _connectivity.checkConnectivity();
      _handleConnectivityChange(results, emitNotify: false);
    } catch (_) {
      // Ignore initial connectivity errors
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
      retryLoadProducts();
    }
  }

  Future<void> retryLoadProducts() async {
    if (_isRetrying) return;
    _isRetrying = true;
    _errorMessage = null;
    notifyListeners();
    await loadInitialProducts();
  }

  Future<void> refreshProducts() async {
    await loadInitialProducts(isRefresh: true);
  }

  Future<void> loadMoreProducts() async {
    if (!_hasMore || _isPaginating || _isLoading || _isRefreshing) return;
    if (_lastProductKey == null && _hasLoadedOnce && _products.isNotEmpty) return;

    _isPaginating = true;
    notifyListeners();

    try {
      final result = await _databaseService.fetchProductsPage(
        limit: _pageSize,
        startAfterKey: _lastProductKey,
      );
      final fetchedProducts = result.items.map(Product.fromFirebase).toList();

      if (fetchedProducts.isEmpty) {
        _hasMore = false;
        _isPaginating = false;
        notifyListeners();
        return;
      }

      final existingIds = _products.map((product) => product.id).toSet();
      final newProducts = fetchedProducts.where((product) => !existingIds.contains(product.id)).toList();
      if (newProducts.isNotEmpty) {
        _products = [..._products, ...newProducts];
        _categories = _buildCategoriesFromProducts(_products);
      }
      _lastProductKey = result.lastKey ?? _lastProductKey;
      _hasMore = result.hasMore;
      _isPaginating = false;
      notifyListeners();
    } catch (error) {
      final message = getFriendlyErrorMessage(
        error,
        fallbackMessage: 'Gagal memuat data produk tambahan.',
      );
      _isPaginating = false;
      _errorMessage ??= message;
      notifyListeners();
    }
  }

  List<String> _buildCategoriesFromProducts(List<Product> products) {
    final categories = <String>{};
    for (final product in products) {
      final category = product.category.trim();
      if (category.isNotEmpty) {
        categories.add(category);
      }
    }

    final sorted = categories.toList()..sort();
    return ['Semua', ...sorted];
  }

  void setSelectedCategory(String category) {
    _selectedCategory = category;
    notifyListeners();
  }

  void setSelectedFilter(String filter) {
    _selectedFilter = filter;
    notifyListeners();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  Future<void> deleteProduct(String productId) async {
    try {
      await _databaseService.deleteProduct(productId);
      _products.removeWhere((product) => product.id == productId);
      _categories = _buildCategoriesFromProducts(_products);
      notifyListeners();
    } catch (error) {
      throw getFriendlyErrorMessage(
        error,
        fallbackMessage: 'Gagal menghapus produk.',
      );
    }
  }

  DatabaseService get databaseService => _databaseService;

  @override
  void dispose() {
    _connectivitySubscription?.cancel();
    _productsSubscription?.cancel();
    super.dispose();
  }
}


