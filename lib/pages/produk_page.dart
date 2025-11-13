import 'dart:async';
import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import '../models/product_model.dart';
import '../services/database_service.dart';
import '../services/storage_service.dart';
import '../utils/error_helper.dart';
import '../utils/security_utils.dart';
import '../widgets/loading_skeletons.dart';
import 'produk_page_dialogs.dart';

class ProdukPage extends StatefulWidget {
  const ProdukPage({super.key});

  @override
  State<ProdukPage> createState() => _ProdukPageState();
}

class _ProdukPageState extends State<ProdukPage> with TickerProviderStateMixin {
  static const int _pageSize = 25;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  
  final DatabaseService _databaseService = DatabaseService();
  final TextEditingController _searchController = TextEditingController();
  late final ScrollController _scrollController;
  
  String _selectedCategory = 'Semua';
  String _selectedFilter = 'Semua';
  String _searchQuery = '';
  
  List<String> _categories = ['Semua'];
  final List<String> _filters = ['Semua', 'Stok Rendah', 'Habis', 'Tersedia'];
  
  // Products from Firebase
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
  Timer? _searchDebounce;

  bool get _showInitialLoader => _isLoading && !_hasLoadedOnce;
  bool get _showFullErrorState => _errorMessage != null && !_hasLoadedOnce;
  bool get _showInlineErrorBanner => _errorMessage != null && _hasLoadedOnce;

  final Connectivity _connectivity = Connectivity();
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;

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
    
    _scrollController = ScrollController()
      ..addListener(_onScroll);
    _animationController.forward();
    _initializeConnectivity();
    _loadInitialProducts();
  }

  @override
  void dispose() {
    _connectivitySubscription?.cancel();
    _animationController.dispose();
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    _searchController.dispose();
    _searchDebounce?.cancel();
    super.dispose();
  }

  Future<void> _loadInitialProducts({bool isRefresh = false}) async {
    if (!mounted) return;

    if (isRefresh) {
      setState(() {
        _isRefreshing = true;
        _errorMessage = null;
      });
    } else {
      setState(() {
        if (!_hasLoadedOnce) {
          _isLoading = true;
        }
        if (!_isRetrying) {
          _isRetrying = _hasLoadedOnce && _errorMessage != null;
        }
        _errorMessage = null;
      });
    }

    _lastProductKey = null;
    _hasMore = true;

    try {
      final result = await _databaseService.fetchProductsPage(limit: _pageSize);
      final fetchedProducts = result.items.map(Product.fromFirebase).toList();
      final updatedCategories = _buildCategoriesFromProducts(fetchedProducts);

      if (!mounted) return;
      setState(() {
        _products = fetchedProducts;
        _categories = updatedCategories;
        _isLoading = false;
        _isRetrying = false;
        _errorMessage = null;
        _hasLoadedOnce = true;
        _lastProductKey = result.lastKey;
        _hasMore = result.hasMore;
        _isRefreshing = false;
      });
    } catch (error) {
      final message = getFriendlyErrorMessage(
        error,
        fallbackMessage: 'Gagal memuat data produk.',
      );

      if (!mounted) return;
      setState(() {
        if (isRefresh) {
          _isRefreshing = false;
        } else {
          _isLoading = false;
          _isRetrying = false;
        }
        _errorMessage = message;
      });
    }
  }

  Future<void> _initializeConnectivity() async {
    try {
      final results = await _connectivity.checkConnectivity();
      _handleConnectivityChange(results, emitSetState: false);
    } catch (_) {
      // Ignore initial connectivity errors
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
      _retryLoadProducts();
    }
  }

  Future<void> _retryLoadProducts() async {
    if (_isRetrying) return;
    setState(() {
      _isRetrying = true;
      _errorMessage = null;
    });
    await _loadInitialProducts();
  }

  Future<void> _refreshProducts() async {
    await _loadInitialProducts(isRefresh: true);
  }

  Future<void> _loadMoreProducts() async {
    if (!_hasMore || _isPaginating || _isLoading || _isRefreshing) return;
    if (_lastProductKey == null && _hasLoadedOnce && _products.isNotEmpty) return;

    setState(() {
      _isPaginating = true;
    });

    try {
      final result = await _databaseService.fetchProductsPage(
        limit: _pageSize,
        startAfterKey: _lastProductKey,
      );
      final fetchedProducts = result.items.map(Product.fromFirebase).toList();

      if (!mounted) return;

      if (fetchedProducts.isEmpty) {
        setState(() {
          _hasMore = false;
          _isPaginating = false;
        });
        return;
      }

      setState(() {
        final existingIds = _products.map((product) => product.id).toSet();
        final newProducts = fetchedProducts.where((product) => !existingIds.contains(product.id)).toList();
        if (newProducts.isNotEmpty) {
          _products = [..._products, ...newProducts];
          _categories = _buildCategoriesFromProducts(_products);
        }
        _lastProductKey = result.lastKey ?? _lastProductKey;
        _hasMore = result.hasMore;
        _isPaginating = false;
      });
    } catch (error) {
      final message = getFriendlyErrorMessage(
        error,
        fallbackMessage: 'Gagal memuat data produk tambahan.',
      );
      if (!mounted) return;
      setState(() {
        _isPaginating = false;
        _errorMessage ??= message;
      });
    }
  }

  void _onScroll() {
    if (!_scrollController.hasClients || _isPaginating || !_hasMore) return;
    final position = _scrollController.position;
    if (!position.hasPixels || position.maxScrollExtent <= 0) return;
    final threshold = position.maxScrollExtent - position.pixels;
    if (threshold <= 320) {
      _loadMoreProducts();
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

  void _onSearchChanged(String value) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 250), () {
      if (!mounted) return;
      setState(() {
        _searchQuery = value;
      });
    });
  }

  void _clearSearch() {
    _searchDebounce?.cancel();
    _searchController.clear();
    if (!mounted) return;
    setState(() {
      _searchQuery = '';
    });
  }

  Widget _buildDismissBackground({
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
        border: Border.all(
          color: color.withOpacity(0.3),
        ),
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

  Widget _buildErrorState() {
    return Center(
      key: const ValueKey('products-error'),
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
              'Tidak dapat memuat data produk',
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
              onPressed: _isRetrying ? null : _retryLoadProducts,
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

  Widget _buildContent() {
    return RefreshIndicator(
      onRefresh: _refreshProducts,
      color: const Color(0xFF6366F1),
      displacement: 48,
      child: SingleChildScrollView(
        key: const ValueKey('products-content'),
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
          if (_isOffline)
            _buildStatusBanner(
              color: Colors.orange,
              icon: Icons.wifi_off_rounded,
              message: 'Anda sedang offline. Beberapa data mungkin tidak terbaru.',
              trailing: TextButton(
                onPressed: _isRetrying ? null : _retryLoadProducts,
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
                onPressed: _isRetrying ? null : _retryLoadProducts,
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
              message: 'Menyegarkan data produk...',
              trailing: const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF2563EB)),
                ),
              ),
            ),
                      // Search and Filter Section
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
                              "Cari & Filter Produk",
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF1F2937),
                              ),
                            ),
                            const SizedBox(height: 16),
                            // Search Bar
                            TextField(
                              controller: _searchController,
                              onChanged: _onSearchChanged,
                              decoration: InputDecoration(
                                hintText: 'Cari produk, supplier, atau barcode...',
                                prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF6366F1)),
                                suffixIcon: _searchQuery.isNotEmpty
                                    ? IconButton(
                                        onPressed: _clearSearch,
                                        tooltip: 'Bersihkan pencarian',
                                        icon: const Icon(Icons.clear_rounded, color: Color(0xFF6366F1)),
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
                            const SizedBox(height: 16),
                            // Category Filter
                            Text(
                              "Kategori",
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF374151),
                              ),
                            ),
                            const SizedBox(height: 8),
                            SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Row(
                                children: _categories.map((category) {
                                  final isSelected = _selectedCategory == category;
                                  return GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        _selectedCategory = category;
                                      });
                                      HapticFeedback.lightImpact();
                                    },
                                    child: Container(
                                      margin: const EdgeInsets.only(right: 8),
                                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                      decoration: BoxDecoration(
                                        color: isSelected ? const Color(0xFF6366F1) : Colors.grey[100],
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Text(
                                        category,
                                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                          color: isSelected ? Colors.white : Colors.grey[600],
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),
                            ),
                            const SizedBox(height: 16),
                            // Stock Filter
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  "Filter Stok",
                                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFF374151),
                                  ),
                                ),
                                DropdownButton<String>(
                                  value: _selectedFilter,
                                  onChanged: (String? newValue) {
                                    setState(() {
                                      _selectedFilter = newValue!;
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
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Summary Cards
                      Row(
                        children: [
                          Expanded(
                            child: _buildSummaryCard(
                              title: "Total Produk",
                              value: _products.length.toDouble(),
                              icon: Icons.inventory_2_rounded,
                              color: const Color(0xFF3B82F6),
                              isCurrency: false,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildSummaryCard(
                              title: "Stok Rendah",
                              value: _lowStockCount.toDouble(),
                              icon: Icons.warning_amber_rounded,
                              color: const Color(0xFFF59E0B),
                              isCurrency: false,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      Row(
                        children: [
                          Expanded(
                            child: _buildSummaryCard(
                  title: "Stok Habis",
                              value: _outOfStockCount.toDouble(),
                  icon: Icons.inventory_rounded,
                              color: const Color(0xFFEF4444),
                              isCurrency: false,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildSummaryCard(
                              title: "Nilai Stok",
                              value: _calculateTotalStockValue(),
                              icon: Icons.attach_money_rounded,
                              color: const Color(0xFF10B981),
                              isCurrency: true,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),

          // Additional existing content continues...
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
                      "Daftar Produk (${_filteredProducts.length})",
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF1F2937),
                          ),
                    ),
                    Row(
                      children: [
                        TextButton.icon(
                          onPressed: () {
                            HapticFeedback.lightImpact();
                            _showBulkStockUpdateDialog();
                          },
                          icon: const Icon(Icons.inventory_2_rounded, size: 18),
                          label: const Text('Update Bulk'),
                          style: TextButton.styleFrom(
                            foregroundColor: const Color(0xFF10B981),
                            backgroundColor: const Color(0xFF10B981).withOpacity(0.1),
                          ),
                        ),
                        const SizedBox(width: 8),
                        TextButton.icon(
                          onPressed: () {
                            HapticFeedback.lightImpact();
                            _showAddProductDialog();
                          },
                          icon: const Icon(Icons.add_rounded, size: 18),
                          label: const Text('Tambah Produk'),
                          style: TextButton.styleFrom(
                            foregroundColor: const Color(0xFF6366F1),
                            backgroundColor: const Color(0xFF6366F1).withOpacity(0.1),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _filteredProducts.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(32.0),
                          child: Column(
                            children: [
                              Icon(
                                Icons.inventory_2_outlined,
                                size: 64,
                                color: Colors.grey[400],
                              ),
                              const SizedBox(height: 16),
                              Text(
                                _products.isEmpty
                                    ? "Belum ada produk"
                                    : "Tidak ada produk yang cocok",
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                      color: Colors.grey[600],
                                      fontWeight: FontWeight.w500,
                                    ),
                                textAlign: TextAlign.center,
                              ),
                              if (_products.isEmpty) ...[
                                const SizedBox(height: 8),
                                ElevatedButton.icon(
                                  onPressed: _showAddProductDialog,
                                  icon: const Icon(Icons.add_rounded),
                                  label: const Text('Tambah Produk Pertama'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF6366F1),
                                    foregroundColor: Colors.white,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      )
                    : ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        cacheExtent: 540,
                        itemCount: _filteredProducts.length,
                        itemBuilder: (context, index) {
                          final product = _filteredProducts[index];
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
                              key: ValueKey('product-${product.id}'),
                              background: _buildDismissBackground(
                                color: Colors.blue.shade100,
                                icon: Icons.edit_rounded,
                                alignment: Alignment.centerLeft,
                                label: 'Edit',
                              ),
                              secondaryBackground: _buildDismissBackground(
                                color: Colors.red.shade100,
                                icon: Icons.delete_rounded,
                                alignment: Alignment.centerRight,
                                label: 'Hapus',
                              ),
                              confirmDismiss: (direction) async {
                                if (direction == DismissDirection.startToEnd) {
                                  _showEditProductDialog(product);
                                } else {
                                  _showDeleteConfirmDialog(product);
                                }
                                return false;
                              },
                              child: ProductCard(
                                product: product,
                                onTap: () => _showProductDetail(product),
                                onEdit: () => _showEditProductDialog(product),
                                onDelete: () => _showDeleteConfirmDialog(product),
                                onEditStock: () => _showEditStockDialog(product),
                              ),
                            ),
                          );
                        },
                      ),
                if (_isPaginating)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: Center(
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF6366F1)),
                        ),
                      ),
                    ),
                  )
                else if (!_hasMore && _filteredProducts.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Center(
                      child: Text(
                        'Semua data sudah ditampilkan',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.grey[500],
                            ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    ),
  );
  }

  List<Product> get _filteredProducts {
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

  int get _lowStockCount {
    return _products.where((product) => product.isLowStock && !product.isOutOfStock).length;
  }

  int get _outOfStockCount {
    return _products.where((product) => product.isOutOfStock).length;
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
                Icons.inventory_2_rounded,
                          color: Colors.white,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
                                Text(
              "Produk & Stok",
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: Colors.white,
                                    fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
                                      onPressed: () {
                                        HapticFeedback.lightImpact();
                _showScanDialog();
              },
              icon: const Icon(Icons.qr_code_scanner_rounded, color: Colors.white),
              tooltip: 'Scan Barcode',
            ),
          ),
          Container(
            margin: const EdgeInsets.only(right: 16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
                                      onPressed: () {
                                        HapticFeedback.lightImpact();
                                        _showAddProductDialog();
                                      },
              icon: const Icon(Icons.add_rounded, color: Colors.white),
              tooltip: 'Tambah Produk',
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
            child: _showInitialLoader
          ? const SingleChildScrollView(
              key: ValueKey('products-loader'),
              physics: AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.all(20),
              child: ProductListSkeleton(),
            )
                : _showFullErrorState
                    ? _buildErrorState()
                    : _buildContent(),
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
    final displayValue = isCurrency
        ? 'Rp ${value.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')}'
        : value.toStringAsFixed(0);
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
              if (color == const Color(0xFFF59E0B) || color == const Color(0xFFEF4444))
                Icon(
                  Icons.warning_rounded,
                  color: color,
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
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            child: Text(
              displayValue,
              key: ValueKey('$title-$displayValue'),
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF1F2937),
                  ),
            ),
          ),
        ],
      ),
    );
  }

  double _calculateTotalStockValue() {
    return _products.fold(0.0, (sum, product) => sum + (product.price * product.stock));
  }

  void _showProductDetail(Product product) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => ProductDetailModal(
        product: product,
        onEdit: () {
          Navigator.pop(context);
          _showEditProductDialog(product);
        },
        onEditStock: () {
          Navigator.pop(context);
          _showEditStockDialog(product);
        },
        onViewHistory: () {
          Navigator.pop(context);
          _showStockHistoryDialog(product);
        },
      ),
    );
  }

  void _showStockHistoryDialog(Product product) {
    showDialog(
      context: context,
      builder: (context) => StockHistoryDialog(
        product: product,
        databaseService: _databaseService,
      ),
    );
  }

  void _showBulkStockUpdateDialog() {
    showDialog(
      context: context,
      builder: (context) => BulkStockUpdateDialog(
        products: _products,
        databaseService: _databaseService,
        onSaved: () {
          _refreshProducts();
          HapticFeedback.lightImpact();
        },
      ),
    );
  }

  void _showAddProductDialog() {
    showDialog(
      context: context,
      builder: (context) => AddEditProductDialog(
        onSaved: () {
          _refreshProducts();
          HapticFeedback.lightImpact();
        },
      ),
    );
  }

  void _showEditProductDialog(Product product) {
    showDialog(
      context: context,
      builder: (context) => AddEditProductDialog(
        product: product,
        onSaved: () {
          _refreshProducts();
          HapticFeedback.lightImpact();
        },
      ),
    );
  }

  void _showEditStockDialog(Product product) {
    showDialog(
      context: context,
      builder: (context) => EditStockDialog(
        product: product,
        onSaved: () {
          _refreshProducts();
          HapticFeedback.lightImpact();
        },
      ),
    );
  }

  void _showDeleteConfirmDialog(Product product) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Hapus Produk'),
        content: Text('Apakah Anda yakin ingin menghapus "${product.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await _databaseService.deleteProduct(product.id);
                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Produk berhasil dihapus'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error deleting product: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }

  void _showScanDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.qr_code_scanner_rounded, color: Colors.purple[600]),
            const SizedBox(width: 8),
            const Text('Scan Barcode'),
          ],
        ),
        content: const Text('Fitur scan barcode akan segera hadir!'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}

class ProductCard extends StatelessWidget {
  final Product product;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onEditStock;

  const ProductCard({
    super.key,
    required this.product,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
    required this.onEditStock,
  });

  @override
  Widget build(BuildContext context) {
    Color statusColor;
    
    if (product.isOutOfStock) {
      statusColor = const Color(0xFFEF4444);
    } else if (product.isLowStock) {
      statusColor = const Color(0xFFF59E0B);
    } else {
      statusColor = const Color(0xFF10B981);
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: statusColor.withOpacity(0.2),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            // Product Image/Emoji
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: product.imageUrl.isNotEmpty
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: CachedNetworkImage(
                        imageUrl: product.imageUrl,
                        fit: BoxFit.cover,
                        memCacheHeight: 220,
                        memCacheWidth: 220,
                        fadeInDuration: const Duration(milliseconds: 200),
                        placeholder: (context, url) => const Center(
                          child: SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        ),
                        errorWidget: (context, url, error) => Center(
                          child: Text(
                            product.image.isNotEmpty ? product.image : '📦',
                            style: const TextStyle(fontSize: 32),
                          ),
                        ),
                      ),
                    )
                  : Center(
                      child: Text(
                        product.image.isNotEmpty ? product.image : '📦',
                        style: const TextStyle(fontSize: 32),
                      ),
                    ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF1F2937),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${product.supplier.isNotEmpty ? product.supplier : "Tidak ada supplier"} • ${product.category}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Stok: ${product.stock} • Min: ${product.minStock}',
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
                  'Rp ${product.price.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')}',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF6366F1),
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    product.stockStatus,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: statusColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    GestureDetector(
                      onTap: onEditStock,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Icon(
                          Icons.inventory_rounded,
                          color: Colors.blue,
                          size: 16,
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    GestureDetector(
                      onTap: onEdit,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: const Color(0xFF6366F1).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Icon(
                          Icons.edit_rounded,
                          color: Color(0xFF6366F1),
                          size: 16,
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    GestureDetector(
                      onTap: onDelete,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Icon(
                          Icons.delete_rounded,
                          color: Colors.red,
                          size: 16,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class ProductDetailModal extends StatelessWidget {
  final Product product;
  final VoidCallback onEdit;
  final VoidCallback onEditStock;
  final VoidCallback onViewHistory;

  const ProductDetailModal({
    super.key,
    required this.product,
    required this.onEdit,
    required this.onEditStock,
    required this.onViewHistory,
  });

  @override
  Widget build(BuildContext context) {
    Color statusColor;
    
    if (product.isOutOfStock) {
      statusColor = const Color(0xFFEF4444);
    } else if (product.isLowStock) {
      statusColor = const Color(0xFFF59E0B);
    } else {
      statusColor = const Color(0xFF10B981);
    }

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
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
                  "Detail Produk",
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
          
          // Product Image/Emoji
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: statusColor.withOpacity(0.3),
                width: 2,
              ),
            ),
            child: product.imageUrl.isNotEmpty
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(18),
                    child: CachedNetworkImage(
                      imageUrl: product.imageUrl,
                      fit: BoxFit.cover,
                      memCacheHeight: 320,
                      memCacheWidth: 320,
                      fadeInDuration: const Duration(milliseconds: 200),
                      placeholder: (context, url) => const Center(
                        child: SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ),
                      errorWidget: (context, url, error) => Center(
                        child: Text(
                          product.image.isNotEmpty ? product.image : '📦',
                          style: const TextStyle(fontSize: 64),
                        ),
                      ),
                    ),
                  )
                : Center(
                    child: Text(
                      product.image.isNotEmpty ? product.image : '📦',
                      style: const TextStyle(fontSize: 64),
                    ),
                  ),
          ),
          
          const SizedBox(height: 24),
          
          // Product Details
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildDetailRow("ID Produk", product.id),
                  _buildDetailRow("Nama", product.name),
                  _buildDetailRow("Deskripsi", product.description.isNotEmpty ? product.description : "Tidak ada deskripsi"),
                  _buildDetailRow("Kategori", product.category),
                  _buildDetailRow("Supplier", product.supplier.isNotEmpty ? product.supplier : "Tidak ada supplier"),
                  _buildDetailRow("Barcode", product.barcode.isNotEmpty ? product.barcode : "Tidak ada barcode"),
                  _buildDetailRow("Stok Saat Ini", "${product.stock} unit"),
                  _buildDetailRow("Stok Minimum", "${product.minStock} unit"),
                  _buildDetailRow("Status", product.stockStatus),
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [statusColor, statusColor.withOpacity(0.8)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        Text(
                          "Harga Satuan",
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: Colors.white70,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Rp ${product.price.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')}',
                          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: onEditStock,
                          icon: const Icon(Icons.inventory_rounded),
                          label: const Text('Edit Stok'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: onEdit,
                          icon: const Icon(Icons.edit_rounded),
                          label: const Text('Edit Produk'),
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
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: onViewHistory,
                      icon: const Icon(Icons.history_rounded),
                      label: const Text('Riwayat Stok'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF6366F1),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        side: const BorderSide(color: Color(0xFF6366F1)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Colors.grey,
              fontWeight: FontWeight.w500,
            ),
          ),
          Flexible(
            child: Text(
              value,
              style: const TextStyle(
                color: Color(0xFF1F2937),
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }
}

// Add/Edit Product Dialog
class AddEditProductDialog extends StatefulWidget {
  final Product? product;
  final VoidCallback onSaved;

  const AddEditProductDialog({
    super.key,
    this.product,
    required this.onSaved,
  });

  @override
  State<AddEditProductDialog> createState() => _AddEditProductDialogState();
}

class _AddEditProductDialogState extends State<AddEditProductDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _stockController = TextEditingController();
  final _minStockController = TextEditingController();
  final _supplierController = TextEditingController();
  final _categoryController = TextEditingController();
  final _barcodeController = TextEditingController();
  
  String _selectedEmoji = '📦';
  bool _isLoading = false;
  File? _selectedImageFile;
  String? _imageUrl;
  bool _isUploadingImage = false;
  
  final DatabaseService _databaseService = DatabaseService();
  final ImagePicker _imagePicker = ImagePicker();
  
  // Popular emojis for products
  final List<String> _emojiCategories = [
    '🍔', '🍕', '🍟', '🌮', '🌯', '🥗', '🍛', '🍜', '🍝', '🍱',
    '🍣', '🍤', '🍗', '🍖', '🥩', '🍳', '🧀', '🥚', '🥞', '🧇',
    '🥐', '🍞', '🥖', '🥨', '🧈', '🥓', '🥪', '🌭', '🍿', '🥜',
    '🍫', '🍬', '🍭', '🍮', '🍯', '🧁', '🍰', '🎂', '🍪', '🍩',
    '☕', '🍵', '🥤', '🧃', '🧉', '🍶', '🍺', '🍻', '🥂', '🍷',
    '🧊', '🥛', '🍼', '🍾', '🧂', '🥢', '🍴', '🥄', '🔪', '🍽️',
    '📦', '🛒', '🛍️', '💰', '💎', '🎁', '🎀', '🏷️',
  ];

  @override
  void initState() {
    super.initState();
    if (widget.product != null) {
      _nameController.text = widget.product!.name;
      _descriptionController.text = widget.product!.description;
      _priceController.text = widget.product!.price.toStringAsFixed(0);
      _stockController.text = widget.product!.stock.toString();
      _minStockController.text = widget.product!.minStock.toString();
      _supplierController.text = widget.product!.supplier;
      _categoryController.text = widget.product!.category;
      _barcodeController.text = widget.product!.barcode;
      _selectedEmoji = widget.product!.image.isNotEmpty ? widget.product!.image : '📦';
      _imageUrl = widget.product!.imageUrl.isNotEmpty ? widget.product!.imageUrl : null;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _stockController.dispose();
    _minStockController.dispose();
    _supplierController.dispose();
    _categoryController.dispose();
    _barcodeController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 2048,
        maxHeight: 2048,
        imageQuality: 90,
      );

      if (image != null) {
        setState(() {
          _selectedImageFile = File(image.path);
          _imageUrl = null; // Clear existing URL when new image is selected
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error picking image: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _takePhoto() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.camera,
        maxWidth: 2048,
        maxHeight: 2048,
        imageQuality: 90,
      );

      if (image != null) {
        setState(() {
          _selectedImageFile = File(image.path);
          _imageUrl = null; // Clear existing URL when new image is selected
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error taking photo: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _showImageSourceDialog() async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Pilih Sumber Gambar'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library_rounded),
              title: const Text('Galeri'),
              onTap: () {
                Navigator.pop(context);
                _pickImage();
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt_rounded),
              title: const Text('Kamera'),
              onTap: () {
                Navigator.pop(context);
                _takePhoto();
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _deleteImage() async {
    if (_imageUrl != null && widget.product != null) {
      // Delete from Firebase Storage
      try {
        await StorageService.deleteProductImage(_imageUrl!);
      } catch (error) {
        if (mounted) {
          final message = getFriendlyErrorMessage(
            error,
            fallbackMessage: 'Gagal menghapus gambar produk.',
          );
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(message),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    }
    
    setState(() {
      _selectedImageFile = null;
      _imageUrl = null;
    });
  }

  double? _tryParsePrice(String value) {
    final sanitized = SecurityUtils.sanitizeNumber(value);
    if (sanitized.isEmpty) return null;
    final normalized = sanitized.replaceAll('.', '').replaceAll(',', '.');
    return double.tryParse(normalized);
  }

  double _parsePrice(String value) => _tryParsePrice(value) ?? 0;

  int? _tryParseInt(String value) {
    final sanitized = SecurityUtils.sanitizeNumber(value).replaceAll(RegExp(r'[^0-9-]'), '');
    if (sanitized.isEmpty) return null;
    return int.tryParse(sanitized);
  }

  int _parseInt(String value) => _tryParseInt(value) ?? 0;

  Future<void> _saveProduct() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      String finalImageUrl = _imageUrl ?? '';
      
      // Upload new image if selected
      if (_selectedImageFile != null) {
        setState(() {
          _isUploadingImage = true;
        });
        
        try {
          // Delete old image if exists
          if (widget.product != null && widget.product!.imageUrl.isNotEmpty) {
            await StorageService.deleteProductImage(widget.product!.imageUrl);
          }
          
          // Get product ID (use existing or generate new)
          final productId = widget.product?.id ?? DateTime.now().millisecondsSinceEpoch.toString();
          
          // Upload new image
          finalImageUrl = await StorageService.uploadProductImage(
            imageFile: _selectedImageFile!,
            productId: productId,
          );
        } catch (error) {
          if (mounted) {
            final message = getFriendlyErrorMessage(
              error,
              fallbackMessage: 'Gagal mengunggah gambar produk.',
            );
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(message),
                backgroundColor: Colors.orange,
              ),
            );
          }
        } finally {
          setState(() {
            _isUploadingImage = false;
          });
        }
      }

      final productData = {
        'name': SecurityUtils.sanitizeInput(_nameController.text),
        'description': SecurityUtils.sanitizeInput(_descriptionController.text),
        'price': _parsePrice(_priceController.text),
        'stock': _parseInt(_stockController.text),
        'minStock': _parseInt(_minStockController.text),
        'supplier': SecurityUtils.sanitizeInput(_supplierController.text),
        'category': SecurityUtils.sanitizeInput(_categoryController.text),
        'barcode': SecurityUtils.sanitizeInput(_barcodeController.text),
        'image': _selectedEmoji,
        'imageUrl': finalImageUrl,
      };

      String productId;
      if (widget.product != null) {
        // Update existing product
        productId = widget.product!.id;
        await _databaseService.updateProduct(productId, productData);
      } else {
        // Add new product
        productId = await _databaseService.addProduct(productData);
        
        // If we have a new image but product ID wasn't available before, re-upload with correct ID
        if (_selectedImageFile != null && finalImageUrl.isEmpty) {
          try {
            finalImageUrl = await StorageService.uploadProductImage(
              imageFile: _selectedImageFile!,
              productId: productId,
            );
            await _databaseService.updateProduct(productId, {'imageUrl': finalImageUrl});
          } catch (error) {
            if (mounted) {
              final message = getFriendlyErrorMessage(
                error,
                fallbackMessage: 'Gagal memperbarui gambar produk.',
              );
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(message),
                  backgroundColor: Colors.orange,
                ),
              );
            }
          }
        }
      }

      if (mounted) {
        Navigator.pop(context);
        widget.onSaved();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.product != null 
                ? 'Produk berhasil diperbarui!' 
                : 'Produk berhasil ditambahkan!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (error) {
      if (mounted) {
        final message = getFriendlyErrorMessage(
          error,
          fallbackMessage: 'Gagal menyimpan data produk.',
        );
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
      ),
      child: Container(
        constraints: BoxConstraints(
          maxWidth: 600,
          maxHeight: MediaQuery.of(context).size.height * 0.9,
        ),
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    widget.product != null ? "Edit Produk" : "Tambah Produk",
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF1F2937),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              
              // Scrollable content
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Image Upload Section
                      Text(
                        "Gambar Produk",
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.grey.withOpacity(0.2),
                          ),
                        ),
                        child: Column(
                          children: [
                            // Image Preview
                            GestureDetector(
                              onTap: _showImageSourceDialog,
                              child: Container(
                                width: 120,
                                height: 120,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: const Color(0xFF6366F1).withOpacity(0.3),
                                    width: 2,
                                  ),
                                ),
                                child: _isUploadingImage
                                    ? const Center(
                                        child: CircularProgressIndicator(),
                                      )
                                    : _selectedImageFile != null
                                        ? ClipRRect(
                                            borderRadius: BorderRadius.circular(14),
                                            child: Image.file(
                                              _selectedImageFile!,
                                              fit: BoxFit.cover,
                                            ),
                                          )
                                        : _imageUrl != null && _imageUrl!.isNotEmpty
                                            ? ClipRRect(
                                                borderRadius: BorderRadius.circular(14),
                                                child: CachedNetworkImage(
                                                  imageUrl: _imageUrl!,
                                                  fit: BoxFit.cover,
                                                  memCacheHeight: 320,
                                                  memCacheWidth: 320,
                                                  fadeInDuration: const Duration(milliseconds: 200),
                                                  placeholder: (context, url) => const Center(
                                                    child: SizedBox(
                                                      width: 24,
                                                      height: 24,
                                                      child: CircularProgressIndicator(strokeWidth: 2),
                                                    ),
                                                  ),
                                                  errorWidget: (context, url, error) => Center(
                                                    child: Text(
                                                      _selectedEmoji,
                                                      style: const TextStyle(fontSize: 48),
                                                    ),
                                                  ),
                                                ),
                                              )
                                            : Center(
                                                child: Column(
                                                  mainAxisAlignment: MainAxisAlignment.center,
                                                  children: [
                                                    Text(
                                                      _selectedEmoji,
                                                      style: const TextStyle(fontSize: 48),
                                                    ),
                                                    const SizedBox(height: 4),
                                                    const Icon(
                                                      Icons.add_photo_alternate_rounded,
                                                      size: 20,
                                                      color: Colors.grey,
                                                    ),
                                                  ],
                                                ),
                                              ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                ElevatedButton.icon(
                                  onPressed: _isUploadingImage ? null : _showImageSourceDialog,
                                  icon: const Icon(Icons.add_photo_alternate_rounded, size: 18),
                                  label: const Text('Unggah Gambar'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF6366F1),
                                    foregroundColor: Colors.white,
                                  ),
                                ),
                                if ((_selectedImageFile != null || (_imageUrl != null && _imageUrl!.isNotEmpty)) && !_isUploadingImage) ...[
                                  const SizedBox(width: 8),
                                  IconButton(
                                    onPressed: _deleteImage,
                                    icon: const Icon(Icons.delete_rounded),
                                    color: Colors.red,
                                    tooltip: 'Hapus Gambar',
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      
                      // Emoji Selector
                      Text(
                        "Pilih Emoji",
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.grey.withOpacity(0.2),
                          ),
                        ),
                        child: Column(
                          children: [
                            // Selected Emoji Preview
                            Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: const Color(0xFF6366F1).withOpacity(0.3),
                                  width: 2,
                                ),
                              ),
                              child: Center(
                                child: Text(
                                  _selectedEmoji,
                                  style: const TextStyle(fontSize: 48),
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            // Emoji Grid
                            SizedBox(
                              height: 200,
                              child: GridView.builder(
                                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 10,
                                  crossAxisSpacing: 8,
                                  mainAxisSpacing: 8,
                                ),
                                itemCount: _emojiCategories.length,
                                itemBuilder: (context, index) {
                                  final emoji = _emojiCategories[index];
                                  final isSelected = _selectedEmoji == emoji;
                                  
                                  return GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        _selectedEmoji = emoji;
                                      });
                                      HapticFeedback.lightImpact();
                                    },
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: isSelected 
                                            ? const Color(0xFF6366F1).withOpacity(0.2)
                                            : Colors.white,
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                          color: isSelected 
                                              ? const Color(0xFF6366F1)
                                              : Colors.grey.withOpacity(0.2),
                                          width: isSelected ? 2 : 1,
                                        ),
                                      ),
                                      child: Center(
                                        child: Text(
                                          emoji,
                                          style: const TextStyle(fontSize: 24),
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      
                      // Product Name
                      TextFormField(
                        controller: _nameController,
                        decoration: InputDecoration(
                          labelText: 'Nama Produk *',
                          hintText: 'Masukkan nama produk',
                          prefixIcon: const Icon(Icons.inventory_2_rounded),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Nama produk wajib diisi';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      
                      // Description
                      TextFormField(
                        controller: _descriptionController,
                        decoration: InputDecoration(
                          labelText: 'Deskripsi',
                          hintText: 'Masukkan deskripsi produk',
                          prefixIcon: const Icon(Icons.description_rounded),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        maxLines: 2,
                      ),
                      const SizedBox(height: 16),
                      
                      // Price and Stock in Row
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _priceController,
                              decoration: InputDecoration(
                                labelText: 'Harga *',
                                hintText: '0',
                                prefixText: 'Rp ',
                                prefixIcon: const Icon(Icons.attach_money_rounded),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              keyboardType: TextInputType.number,
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Harga wajib diisi';
                                }
                                final parsed = _tryParsePrice(value);
                                if (parsed == null || parsed <= 0) {
                                  return 'Harga tidak valid';
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: TextFormField(
                              controller: _stockController,
                              decoration: InputDecoration(
                                labelText: 'Stok *',
                                hintText: '0',
                                prefixIcon: const Icon(Icons.inventory_rounded),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              keyboardType: TextInputType.number,
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Stok wajib diisi';
                                }
                                final parsed = _tryParseInt(value);
                                if (parsed == null || parsed < 0) {
                                  return 'Stok tidak valid';
                                }
                                return null;
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      
                      // Min Stock and Supplier
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _minStockController,
                              decoration: InputDecoration(
                                labelText: 'Stok Minimum *',
                                hintText: '10',
                                prefixIcon: const Icon(Icons.warning_amber_rounded),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              keyboardType: TextInputType.number,
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Stok minimum wajib diisi';
                                }
                                final parsed = _tryParseInt(value);
                                if (parsed == null || parsed < 0) {
                                  return 'Stok minimum tidak valid';
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: TextFormField(
                              controller: _supplierController,
                              decoration: InputDecoration(
                                labelText: 'Supplier',
                                hintText: 'Nama supplier',
                                prefixIcon: const Icon(Icons.business_rounded),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      
                      // Category and Barcode
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _categoryController,
                              decoration: InputDecoration(
                                labelText: 'Kategori *',
                                hintText: 'Makanan, Minuman, dll',
                                prefixIcon: const Icon(Icons.category_rounded),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Kategori wajib diisi';
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: TextFormField(
                              controller: _barcodeController,
                              decoration: InputDecoration(
                                labelText: 'Barcode',
                                hintText: 'Scan atau masukkan barcode',
                                prefixIcon: const Icon(Icons.qr_code_rounded),
                                border: OutlineInputBorder(
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
              
              const SizedBox(height: 24),
              
              // Save Button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveProduct,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6366F1),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.save_rounded),
                            const SizedBox(width: 8),
                            Text(
                              widget.product != null ? "Simpan Perubahan" : "Simpan Produk",
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Edit Stock Dialog
class EditStockDialog extends StatefulWidget {
  final Product product;
  final VoidCallback onSaved;

  const EditStockDialog({
    super.key,
    required this.product,
    required this.onSaved,
  });

  @override
  State<EditStockDialog> createState() => _EditStockDialogState();
}

class _EditStockDialogState extends State<EditStockDialog> {
  final _formKey = GlobalKey<FormState>();
  final _stockController = TextEditingController();
  final _notesController = TextEditingController();
  String _selectedReason = 'Manual Adjustment';
  bool _isLoading = false;
  final DatabaseService _databaseService = DatabaseService();

  final List<String> _adjustmentReasons = [
    'Manual Adjustment',
    'Stock Opname',
    'Pembelian',
    'Retur dari Supplier',
    'Retur dari Pelanggan',
    'Kerusakan',
    'Kadaluarsa',
    'Hilang',
    'Lainnya',
  ];

  @override
  void initState() {
    super.initState();
    _stockController.text = widget.product.stock.toString();
  }

  @override
  void dispose() {
    _stockController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _updateStock() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final newStock = int.parse(_stockController.text.trim());
      await _databaseService.updateProductStock(
        widget.product.id,
        newStock,
        reason: _selectedReason,
        notes: _notesController.text.trim(),
      );

      if (mounted) {
        Navigator.pop(context);
        widget.onSaved();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Stok berhasil diperbarui!'),
            backgroundColor: Colors.green,
          ),
        );
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
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
      ),
      child: Container(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Edit Stok",
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF1F2937),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                widget.product.name,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _stockController,
                decoration: InputDecoration(
                  labelText: 'Stok Baru',
                  hintText: 'Masukkan jumlah stok',
                  prefixIcon: const Icon(Icons.inventory_rounded),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Stok wajib diisi';
                  }
                  if (int.tryParse(value) == null || int.parse(value) < 0) {
                    return 'Stok tidak valid';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedReason,
                decoration: InputDecoration(
                  labelText: 'Alasan Penyesuaian',
                  prefixIcon: const Icon(Icons.info_rounded),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                items: _adjustmentReasons.map((reason) {
                  return DropdownMenuItem<String>(
                    value: reason,
                    child: Text(reason),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedReason = value!;
                  });
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _notesController,
                decoration: InputDecoration(
                  labelText: 'Catatan (Opsional)',
                  hintText: 'Tambahkan catatan untuk penyesuaian stok',
                  prefixIcon: const Icon(Icons.note_rounded),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Batal'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _updateStock,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF6366F1),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : const Text('Simpan'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
