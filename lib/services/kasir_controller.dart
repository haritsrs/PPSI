import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import '../models/product_model.dart';
import '../models/cart_item_model.dart';
import '../services/database_service.dart';
import '../utils/error_helper.dart';
import '../utils/security_utils.dart';

class KasirController extends ChangeNotifier {
  final DatabaseService _databaseService = DatabaseService();
  final Connectivity _connectivity = Connectivity();

  // Products
  List<Product> _products = [];
  List<String> _categories = ['Semua'];
  bool _isLoading = true;
  bool _isRetrying = false;
  bool _hasLoadedOnce = false;
  String? _errorMessage;
  bool _isOffline = false;

  // Cart
  List<CartItem> _cartItems = [];
  double _subtotal = 0.0;
  double _tax = 0.0;
  double _total = 0.0;

  // Filters
  String _selectedCategory = 'Semua';
  String _searchQuery = '';

  // Barcode
  String _barcodeBuffer = '';
  Timer? _barcodeResetTimer;

  // Subscriptions
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  StreamSubscription<List<Map<String, dynamic>>>? _productsSubscription;

  // Getters
  List<Product> get products => _products;
  List<String> get categories => _categories;
  bool get isLoading => _isLoading;
  bool get isRetrying => _isRetrying;
  bool get hasLoadedOnce => _hasLoadedOnce;
  String? get errorMessage => _errorMessage;
  bool get isOffline => _isOffline;
  List<CartItem> get cartItems => _cartItems;
  double get subtotal => _subtotal;
  double get tax => _tax;
  double get total => _total;
  String get selectedCategory => _selectedCategory;
  String get searchQuery => _searchQuery;
  String get barcodeBuffer => _barcodeBuffer;

  bool get showInitialLoader => _isLoading && !_hasLoadedOnce;
  bool get showFullErrorState => _errorMessage != null && !_hasLoadedOnce;
  bool get showInlineErrorBanner => _errorMessage != null && _hasLoadedOnce;

  List<Product> get filteredProducts {
    return _products.where((product) {
      final matchesCategory = _selectedCategory == 'Semua' || product.category == _selectedCategory;
      final matchesSearch = _searchQuery.isEmpty || 
          product.name.toLowerCase().contains(_searchQuery.toLowerCase());
      return matchesCategory && matchesSearch;
    }).toList();
  }

  Future<void> initialize() async {
    await _initializeConnectivity();
    await _loadProducts();
    await _loadCategories();
    _calculateTotals();
  }

  Future<void> _loadProducts() async {
    _productsSubscription?.cancel();

    _isLoading = !_hasLoadedOnce;
    _isRetrying = _hasLoadedOnce;
    _errorMessage = null;
    notifyListeners();

    _productsSubscription = _databaseService.getProductsStream().listen(
      (productsData) {
        final newProducts = productsData.map(Product.fromFirebase).toList();
        // Only update if products actually changed
        if (_products.length != newProducts.length ||
            !_products.every((p) => newProducts.any((np) => np.id == p.id && np.stock == p.stock && np.price == p.price))) {
          _products = newProducts;
          _isLoading = false;
          _isRetrying = false;
          _errorMessage = null;
          _hasLoadedOnce = true;
          notifyListeners();
        } else if (!_hasLoadedOnce) {
          // Still mark as loaded even if no changes
          _isLoading = false;
          _isRetrying = false;
          _errorMessage = null;
          _hasLoadedOnce = true;
          notifyListeners();
        }
      },
      onError: (error) {
        final message = getFriendlyErrorMessage(
          error,
          fallbackMessage: 'Gagal memuat data produk.',
        );
        _isLoading = false;
        _isRetrying = false;
        _errorMessage = message;
        notifyListeners();
      },
      cancelOnError: false,
    );
  }

  Future<void> _loadCategories() async {
    try {
      final categories = await _databaseService.getCategories();
      _categories = ['Semua', ...categories];
      notifyListeners();
    } catch (error) {
      _errorMessage = getFriendlyErrorMessage(
        error,
        fallbackMessage: 'Gagal memuat kategori produk.',
      );
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
      retryLoadProducts();
    }
  }

  Future<void> retryLoadProducts() async {
    if (_isRetrying) return;

    _isRetrying = true;
    _errorMessage = null;
    notifyListeners();

    await _loadProducts();
  }

  void setSelectedCategory(String category) {
    _selectedCategory = category;
    notifyListeners();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void addToCart(Product product) {
    if (product.stock <= 0) {
      return;
    }

    final existingItemIndex = _cartItems.indexWhere((item) => item.product.id == product.id);
    
    if (existingItemIndex != -1) {
      final currentQuantity = _cartItems[existingItemIndex].quantity;
      if (currentQuantity >= product.stock) {
        return;
      }
      _cartItems[existingItemIndex].quantity++;
    } else {
      _cartItems.add(CartItem(product: product, quantity: 1));
    }
    
    _calculateTotals();
    notifyListeners();
  }

  void removeFromCart(String productId) {
    _cartItems.removeWhere((item) => item.product.id == productId);
    _calculateTotals();
    notifyListeners();
  }

  void updateQuantity(String productId, int newQuantity) {
    final itemIndex = _cartItems.indexWhere((item) => item.product.id == productId);
    if (itemIndex != -1) {
      final product = _cartItems[itemIndex].product;
      if (newQuantity > product.stock) {
        return;
      }
      
      if (newQuantity <= 0) {
        _cartItems.removeAt(itemIndex);
      } else {
        _cartItems[itemIndex].quantity = newQuantity;
      }
      _calculateTotals();
      notifyListeners();
    }
  }

  void clearCart() {
    _cartItems.clear();
    _calculateTotals();
    notifyListeners();
  }

  void _calculateTotals() {
    _subtotal = _cartItems.fold(0.0, (sum, item) => sum + (item.product.price * item.quantity));
    _tax = _subtotal * 0.11; // 11% tax
    _total = _subtotal + _tax;
  }

  // Barcode scanning result
  String? _lastBarcodeNotFound;
  String? get lastBarcodeNotFound => _lastBarcodeNotFound;

  Product? findProductByBarcode(String barcode) {
    final normalizedCode = barcode.trim().toLowerCase();
    if (normalizedCode.isEmpty) return null;

    for (final product in _products) {
      final productBarcode = product.barcode.trim().toLowerCase();
      if (productBarcode.isNotEmpty && productBarcode == normalizedCode) {
        return product;
      }
    }
    return null;
  }

  /// Process a barcode character input
  /// Returns true if a product was found and added to cart
  bool handleBarcodeCharacter(String character) {
    _lastBarcodeNotFound = null;
    _barcodeBuffer += character;
    _barcodeResetTimer?.cancel();
    _barcodeResetTimer = Timer(const Duration(milliseconds: 120), () {
      final bufferedCode = _barcodeBuffer.trim();
      _barcodeBuffer = '';
      if (bufferedCode.isNotEmpty) {
        final product = findProductByBarcode(bufferedCode);
        if (product != null) {
          addToCart(product);
        } else {
          _lastBarcodeNotFound = bufferedCode;
          notifyListeners();
        }
      }
    });
    notifyListeners();
    return false; // Will be processed by timer
  }

  /// Check if current barcode buffer matches a product
  /// Used for delayed checking after character input
  bool checkBarcodeBuffer() {
    final bufferedCode = _barcodeBuffer.trim();
    if (bufferedCode.isEmpty) return false;
    
    final product = findProductByBarcode(bufferedCode);
    if (product != null) {
      addToCart(product);
      _barcodeBuffer = '';
      _lastBarcodeNotFound = null;
      notifyListeners();
      return true;
    } else {
      _lastBarcodeNotFound = bufferedCode;
      notifyListeners();
      return false;
    }
  }

  /// Handle Enter key press - process current barcode buffer
  /// Returns the found product, or null if not found
  Product? handleBarcodeEnter() {
    _barcodeResetTimer?.cancel();
    final code = _barcodeBuffer.trim();
    _barcodeBuffer = '';
    _lastBarcodeNotFound = null;
    Product? foundProduct;
    if (code.isNotEmpty) {
      foundProduct = findProductByBarcode(code);
      if (foundProduct != null) {
        addToCart(foundProduct);
      } else {
        _lastBarcodeNotFound = code;
      }
    }
    notifyListeners();
    return foundProduct;
  }

  void handleBarcodeBackspace() {
    _lastBarcodeNotFound = null;
    if (_barcodeBuffer.isNotEmpty) {
      _barcodeBuffer = _barcodeBuffer.substring(0, _barcodeBuffer.length - 1);
      notifyListeners();
    }
  }

  void clearBarcodeBuffer() {
    _barcodeBuffer = '';
    _lastBarcodeNotFound = null;
    _barcodeResetTimer?.cancel();
    notifyListeners();
  }

  DatabaseService get databaseService => _databaseService;

  Future<Map<String, dynamic>> processPaymentSuccess({
    required String paymentMethod,
    double? cashAmount,
    double? change,
    String? customerId,
    String? customerName,
    double discount = 0.0,
  }) async {
    // Prepare transaction items
    final transactionItems = _cartItems.map((item) => {
      'productId': item.product.id,
      'productName': SecurityUtils.sanitizeInput(item.product.name),
      'quantity': item.quantity,
      'price': item.product.price,
      'subtotal': item.product.price * item.quantity,
    }).toList();

    // Save transaction to Firebase
    final sanitizedPaymentMethod = SecurityUtils.sanitizeInput(paymentMethod);
    final sanitizedCustomerName = customerName != null ? SecurityUtils.sanitizeInput(customerName) : null;
    final transactionId = await _databaseService.addTransaction(
      items: transactionItems,
      subtotal: _subtotal,
      tax: _tax,
      total: _total - discount,
      paymentMethod: sanitizedPaymentMethod,
      cashAmount: cashAmount,
      change: change,
      customerId: customerId,
      customerName: sanitizedCustomerName,
    );

    // Create notification for successful transaction
    try {
      await _databaseService.addNotification(
        title: 'Transaksi Berhasil',
        message: 'Transaksi sebesar Rp ${_total.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')} berhasil diproses dengan metode $sanitizedPaymentMethod',
        type: 'transaction',
        data: {
          'transactionId': transactionId,
          'total': _total,
          'paymentMethod': sanitizedPaymentMethod,
        },
      );
    } catch (e) {
      // Notification creation failed, but transaction was successful
      // Log error but don't show to user
      debugPrint('Error creating notification: $e');
    }

    clearCart();

    // Return transaction data for printing
    return {
      'id': transactionId,
      'items': transactionItems,
      'subtotal': _subtotal,
      'tax': _tax,
      'total': _total,
      'paymentMethod': sanitizedPaymentMethod,
      'cashAmount': cashAmount,
      'change': change,
      'createdAt': DateTime.now().toIso8601String(),
    };
  }

  @override
  void dispose() {
    _productsSubscription?.cancel();
    _connectivitySubscription?.cancel();
    _barcodeResetTimer?.cancel();
    super.dispose();
  }
}

