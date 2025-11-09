import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../services/database_service.dart';
import '../services/xendit_service.dart';
import '../widgets/pattern_background.dart';
import '../utils/responsive_helper.dart';

class KasirPage extends StatefulWidget {
  const KasirPage({super.key});

  @override
  State<KasirPage> createState() => _KasirPageState();
}

class _KasirPageState extends State<KasirPage> with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  
  final TextEditingController _searchController = TextEditingController();
  final DatabaseService _databaseService = DatabaseService();
  
  String _selectedCategory = 'Semua';
  String _searchQuery = '';
  
  // Cart data
  List<CartItem> _cartItems = [];
  double _subtotal = 0.0;
  double _tax = 0.0;
  double _total = 0.0;
  
  // Products from Firebase
  List<Product> _products = [];
  List<String> _categories = ['Semua'];
  bool _isLoading = true;

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
    _loadProducts();
    _loadCategories();
    _calculateTotals();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadProducts() async {
    setState(() {
      _isLoading = true;
    });

    try {
      _databaseService.getProductsStream().listen((productsData) {
        setState(() {
          _products = productsData.map((data) => Product.fromFirebase(data)).toList();
          _isLoading = false;
        });
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading products: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _loadCategories() async {
    try {
      final categories = await _databaseService.getCategories();
      setState(() {
        _categories = ['Semua', ...categories];
      });
    } catch (e) {
      // Handle error silently or show a message
    }
  }

  void _calculateTotals() {
    _subtotal = _cartItems.fold(0.0, (sum, item) => sum + (item.product.price * item.quantity));
    _tax = _subtotal * 0.11; // 11% tax
    _total = _subtotal + _tax;
  }

  void _addToCart(Product product) {
    if (product.stock <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Produk habis!'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      final existingItemIndex = _cartItems.indexWhere((item) => item.product.id == product.id);
      
      if (existingItemIndex != -1) {
        final currentQuantity = _cartItems[existingItemIndex].quantity;
        if (currentQuantity >= product.stock) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Stok tidak mencukupi!'),
              backgroundColor: Colors.orange,
            ),
          );
          return;
        }
        _cartItems[existingItemIndex].quantity++;
      } else {
        _cartItems.add(CartItem(product: product, quantity: 1));
      }
      
      _calculateTotals();
      HapticFeedback.lightImpact();
    });
  }

  void _removeFromCart(String productId) {
    setState(() {
      _cartItems.removeWhere((item) => item.product.id == productId);
      _calculateTotals();
      HapticFeedback.lightImpact();
    });
  }

  void _updateQuantity(String productId, int newQuantity) {
    setState(() {
      final itemIndex = _cartItems.indexWhere((item) => item.product.id == productId);
      if (itemIndex != -1) {
        final product = _cartItems[itemIndex].product;
        if (newQuantity > product.stock) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Stok tidak mencukupi!'),
              backgroundColor: Colors.orange,
            ),
          );
          return;
        }
        
        if (newQuantity <= 0) {
          _cartItems.removeAt(itemIndex);
        } else {
          _cartItems[itemIndex].quantity = newQuantity;
        }
        _calculateTotals();
        HapticFeedback.lightImpact();
      }
    });
  }

  void _clearCart() {
    setState(() {
      _cartItems.clear();
      _calculateTotals();
      HapticFeedback.lightImpact();
    });
  }

  List<Product> get _filteredProducts {
    return _products.where((product) {
      final matchesCategory = _selectedCategory == 'Semua' || product.category == _selectedCategory;
      final matchesSearch = _searchQuery.isEmpty || 
          product.name.toLowerCase().contains(_searchQuery.toLowerCase());
      return matchesCategory && matchesSearch;
    }).toList();
  }

  void _showAddProductDialog() {
    showDialog(
      context: context,
      builder: (context) => AddProductDialog(
        onProductAdded: () {
          _loadCategories();
          HapticFeedback.lightImpact();
        },
      ),
    );
  }

  void _showPaymentModal() {
    if (_cartItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Keranjang kosong! Tambahkan produk terlebih dahulu.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => PaymentModal(
        total: _total,
        cartItems: _cartItems,
        onPaymentSuccess: _handlePaymentSuccess,
      ),
    );
  }

  Future<void> _handlePaymentSuccess({
    required String paymentMethod,
    double? cashAmount,
    double? change,
  }) async {
    try {
      // Prepare transaction items
      final transactionItems = _cartItems.map((item) => {
        'productId': item.product.id,
        'productName': item.product.name,
        'quantity': item.quantity,
        'price': item.product.price,
        'subtotal': item.product.price * item.quantity,
      }).toList();

      // Save transaction to Firebase
      final transactionId = await _databaseService.addTransaction(
        items: transactionItems,
        subtotal: _subtotal,
        tax: _tax,
        total: _total,
        paymentMethod: paymentMethod,
        cashAmount: cashAmount,
        change: change,
      );

      // Create notification for successful transaction
      try {
        await _databaseService.addNotification(
          title: 'Transaksi Berhasil',
          message: 'Transaksi sebesar Rp ${_total.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')} berhasil diproses dengan metode $paymentMethod',
          type: 'transaction',
          data: {
            'transactionId': transactionId,
            'total': _total,
            'paymentMethod': paymentMethod,
          },
        );
      } catch (e) {
        // Notification creation failed, but transaction was successful
        // Log error but don't show to user
        print('Error creating notification: $e');
      }

      setState(() {
        _cartItems.clear();
        _calculateTotals();
      });
      
      Navigator.pop(context);
      
      // Show success dialog
      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => TransactionSuccessDialog(
            total: _total,
            onClose: () {
              Navigator.pop(context);
            },
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error processing payment: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 768;
    final isTablet = screenWidth >= 768 && screenWidth < 1024;
    
    // Responsive grid columns
    final crossAxisCount = isMobile ? 2 : (isTablet ? 3 : 4);
    final paddingScale = ResponsiveHelper.getPaddingScale(context);
    final iconScale = ResponsiveHelper.getIconScale(context);
    
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
              padding: EdgeInsets.all(8 * paddingScale),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.point_of_sale_rounded,
                color: Colors.white,
                size: 24 * iconScale,
              ),
            ),
            SizedBox(width: 12 * paddingScale),
            Flexible(
              child: Text(
                "Kasir",
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        actions: [
          Container(
            margin: EdgeInsets.only(right: 8 * paddingScale),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              onPressed: () {
                HapticFeedback.lightImpact();
                _showAddProductDialog();
              },
              icon: Icon(Icons.add_rounded, color: Colors.white, size: 24 * iconScale),
              tooltip: 'Tambah Produk',
            ),
          ),
          Container(
            margin: EdgeInsets.only(right: 16 * paddingScale),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              onPressed: () {
                HapticFeedback.lightImpact();
                _showPaymentModal();
              },
              icon: Icon(Icons.payment_rounded, color: Colors.white, size: 24 * iconScale),
              tooltip: 'Pembayaran',
            ),
          ),
        ],
      ),
      body: PatternBackground(
        patternType: PatternType.dots,
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: isMobile
                ? _buildMobileLayout(context, crossAxisCount, paddingScale, iconScale)
                : _buildDesktopLayout(context, crossAxisCount, paddingScale, iconScale, screenWidth),
          ),
        ),
      ),
      floatingActionButton: isMobile && _cartItems.isNotEmpty
          ? FloatingActionButton.extended(
              onPressed: _showCartBottomSheet,
              backgroundColor: const Color(0xFF6366F1),
              icon: Stack(
                children: [
                  const Icon(Icons.shopping_cart_rounded, color: Colors.white),
                  if (_cartItems.isNotEmpty)
                    Positioned(
                      right: 0,
                      top: 0,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 16,
                          minHeight: 16,
                        ),
                        child: Text(
                          '${_cartItems.length}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              ),
              label: Text(
                'Keranjang (${_cartItems.length})',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            )
          : null,
    );
  }

  Widget _buildMobileLayout(BuildContext context, int crossAxisCount, double paddingScale, double iconScale) {
    return Column(
      children: [
        // Search and Category Section
        Container(
          padding: EdgeInsets.all(16 * paddingScale),
          child: Column(
            children: [
              // Search Bar
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: TextField(
                  controller: _searchController,
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value;
                    });
                  },
                  decoration: InputDecoration(
                    hintText: 'Cari produk...',
                    hintStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey[500],
                    ),
                    prefixIcon: Icon(
                      Icons.search_rounded,
                      color: const Color(0xFF6366F1),
                      size: 24 * iconScale,
                    ),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 16 * paddingScale,
                      vertical: 12 * paddingScale,
                    ),
                  ),
                ),
              ),
              SizedBox(height: 12 * paddingScale),
              
              // Category Tabs
              SizedBox(
                height: 40 * paddingScale,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _categories.length,
                  itemBuilder: (context, index) {
                    final category = _categories[index];
                    final isSelected = _selectedCategory == category;
                    
                    return Container(
                      margin: EdgeInsets.only(right: 8 * paddingScale),
                      child: FilterChip(
                        label: Text(
                          category,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: isSelected ? Colors.white : const Color(0xFF6366F1),
                            fontWeight: FontWeight.w600,
                            fontSize: 12 * ResponsiveHelper.getFontScale(context),
                          ),
                        ),
                        selected: isSelected,
                        onSelected: (selected) {
                          setState(() {
                            _selectedCategory = category;
                          });
                          HapticFeedback.lightImpact();
                        },
                        backgroundColor: Colors.white,
                        selectedColor: const Color(0xFF6366F1),
                        checkmarkColor: Colors.white,
                        side: BorderSide(
                          color: isSelected ? const Color(0xFF6366F1) : Colors.grey[300]!,
                          width: 1,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
        
        // Products Grid
        Expanded(
          child: _isLoading
              ? const Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF6366F1)),
                  ),
                )
              : _filteredProducts.isEmpty
                  ? Center(
                      child: SingleChildScrollView(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.inventory_2_outlined,
                              size: 64 * iconScale,
                              color: Colors.grey[400],
                            ),
                            SizedBox(height: 16 * paddingScale),
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
                            SizedBox(height: 8 * paddingScale),
                            if (_products.isEmpty)
                              Padding(
                                padding: EdgeInsets.symmetric(horizontal: 16 * paddingScale),
                                child: ElevatedButton.icon(
                                  onPressed: _showAddProductDialog,
                                  icon: Icon(Icons.add_rounded, size: 20 * iconScale),
                                  label: const Text('Tambah Produk Pertama'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF6366F1),
                                    foregroundColor: Colors.white,
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 16 * paddingScale,
                                      vertical: 12 * paddingScale,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    )
                  : GridView.builder(
                      padding: EdgeInsets.all(16 * paddingScale),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: crossAxisCount,
                        crossAxisSpacing: 12 * paddingScale,
                        mainAxisSpacing: 12 * paddingScale,
                        childAspectRatio: 0.75,
                      ),
                      itemCount: _filteredProducts.length,
                      itemBuilder: (context, index) {
                        final product = _filteredProducts[index];
                        return ProductCard(
                          product: product,
                          onAddToCart: () => _addToCart(product),
                        );
                      },
                    ),
        ),
      ],
    );
  }

  Widget _buildDesktopLayout(BuildContext context, int crossAxisCount, double paddingScale, double iconScale, double screenWidth) {
    final cartWidth = screenWidth > 1400 ? 450.0 : 400.0;
    
    return Row(
      children: [
        // Left side - Products
        Expanded(
          flex: 2,
          child: Column(
            children: [
              // Search and Category Section
              Container(
                padding: EdgeInsets.all(20 * paddingScale),
                child: Column(
                  children: [
                    // Search Bar
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: TextField(
                        controller: _searchController,
                        onChanged: (value) {
                          setState(() {
                            _searchQuery = value;
                          });
                        },
                        decoration: InputDecoration(
                          hintText: 'Cari produk...',
                          hintStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.grey[500],
                          ),
                          prefixIcon: Icon(
                            Icons.search_rounded,
                            color: const Color(0xFF6366F1),
                            size: 24 * iconScale,
                          ),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 20 * paddingScale,
                            vertical: 16 * paddingScale,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 16 * paddingScale),
                    
                    // Category Tabs
                    SizedBox(
                      height: 40 * paddingScale,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: _categories.length,
                        itemBuilder: (context, index) {
                          final category = _categories[index];
                          final isSelected = _selectedCategory == category;
                          
                          return Container(
                            margin: EdgeInsets.only(right: 12 * paddingScale),
                            child: FilterChip(
                              label: Text(
                                category,
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: isSelected ? Colors.white : const Color(0xFF6366F1),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              selected: isSelected,
                              onSelected: (selected) {
                                setState(() {
                                  _selectedCategory = category;
                                });
                                HapticFeedback.lightImpact();
                              },
                              backgroundColor: Colors.white,
                              selectedColor: const Color(0xFF6366F1),
                              checkmarkColor: Colors.white,
                              side: BorderSide(
                                color: isSelected ? const Color(0xFF6366F1) : Colors.grey[300]!,
                                width: 1,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
              
              // Products Grid
              Expanded(
                child: _isLoading
                    ? const Center(
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF6366F1)),
                        ),
                      )
                    : _filteredProducts.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.inventory_2_outlined,
                                  size: 64 * iconScale,
                                  color: Colors.grey[400],
                                ),
                                SizedBox(height: 16 * paddingScale),
                                Text(
                                  _products.isEmpty
                                      ? "Belum ada produk"
                                      : "Tidak ada produk yang cocok",
                                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    color: Colors.grey[600],
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                SizedBox(height: 8 * paddingScale),
                                if (_products.isEmpty)
                                  ElevatedButton.icon(
                                    onPressed: _showAddProductDialog,
                                    icon: Icon(Icons.add_rounded, size: 20 * iconScale),
                                    label: const Text('Tambah Produk Pertama'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF6366F1),
                                      foregroundColor: Colors.white,
                                    ),
                                  ),
                              ],
                            ),
                          )
                        : GridView.builder(
                            padding: EdgeInsets.symmetric(horizontal: 20 * paddingScale),
                            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: crossAxisCount,
                              crossAxisSpacing: 16 * paddingScale,
                              mainAxisSpacing: 16 * paddingScale,
                              childAspectRatio: 0.8,
                            ),
                            itemCount: _filteredProducts.length,
                            itemBuilder: (context, index) {
                              final product = _filteredProducts[index];
                              return ProductCard(
                                product: product,
                                onAddToCart: () => _addToCart(product),
                              );
                            },
                          ),
              ),
            ],
          ),
        ),
        
        // Right side - Cart
        Container(
          width: cartWidth,
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 20,
                offset: const Offset(-5, 0),
              ),
            ],
          ),
          child: CartPanel(
            cartItems: _cartItems,
            subtotal: _subtotal,
            tax: _tax,
            total: _total,
            onRemoveItem: _removeFromCart,
            onUpdateQuantity: _updateQuantity,
            onClearCart: _clearCart,
            onCheckout: _showPaymentModal,
          ),
        ),
      ],
    );
  }

  void _showCartBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
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
              // Cart Panel
              Expanded(
                child: CartPanel(
                  cartItems: _cartItems,
                  subtotal: _subtotal,
                  tax: _tax,
                  total: _total,
                  onRemoveItem: _removeFromCart,
                  onUpdateQuantity: _updateQuantity,
                  onClearCart: _clearCart,
                  onCheckout: () {
                    Navigator.pop(context);
                    _showPaymentModal();
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ProductCard extends StatefulWidget {
  final Product product;
  final VoidCallback onAddToCart;

  const ProductCard({
    super.key,
    required this.product,
    required this.onAddToCart,
  });

  @override
  State<ProductCard> createState() => _ProductCardState();
}

class _ProductCardState extends State<ProductCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isOutOfStock = widget.product.stock <= 0;
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 768;
    final paddingScale = ResponsiveHelper.getPaddingScale(context);
    final fontSize = ResponsiveHelper.getFontScale(context);
    
    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) => _controller.reverse(),
      onTapCancel: () => _controller.reverse(),
      onTap: isOutOfStock ? null : widget.onAddToCart,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Opacity(
          opacity: isOutOfStock ? 0.5 : 1.0,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
              border: Border.all(
                color: isOutOfStock 
                    ? Colors.red.withOpacity(0.3)
                    : Colors.grey.withOpacity(0.1),
                width: 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Product Image/Emoji
                Expanded(
                  flex: 3,
                  child: Container(
                    width: double.infinity,
                    constraints: const BoxConstraints(minHeight: 80),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(20),
                        topRight: Radius.circular(20),
                      ),
                    ),
                    child: Center(
                      child: Text(
                        widget.product.image.isNotEmpty 
                            ? widget.product.image 
                            : '📦',
                        style: TextStyle(fontSize: isMobile ? 36 : 48),
                      ),
                    ),
                  ),
                ),
                
                // Product Info
                Expanded(
                  flex: 2,
                  child: Padding(
                    padding: EdgeInsets.all(8 * paddingScale),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Flexible(
                          child: Text(
                            widget.product.name,
                            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF1F2937),
                              fontSize: (Theme.of(context).textTheme.titleSmall?.fontSize ?? 14) * fontSize,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        SizedBox(height: 4 * paddingScale),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'Rp ${widget.product.price.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')}',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF6366F1),
                              fontSize: (Theme.of(context).textTheme.titleMedium?.fontSize ?? 16) * fontSize,
                            ),
                          ),
                        ),
                        const Spacer(),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Flexible(
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                alignment: Alignment.centerLeft,
                                child: Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 6 * paddingScale,
                                    vertical: 3 * paddingScale,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isOutOfStock
                                        ? Colors.red.withOpacity(0.1)
                                        : widget.product.stock > 10 
                                            ? Colors.green.withOpacity(0.1)
                                            : Colors.orange.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    isOutOfStock 
                                        ? 'Habis'
                                        : 'Stok: ${widget.product.stock}',
                                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: isOutOfStock
                                          ? Colors.red[700]
                                          : widget.product.stock > 10 
                                              ? Colors.green[700]
                                              : Colors.orange[700],
                                      fontWeight: FontWeight.w500,
                                      fontSize: (Theme.of(context).textTheme.bodySmall?.fontSize ?? 12) * fontSize,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ),
                            ),
                            if (!isOutOfStock)
                              Container(
                                padding: EdgeInsets.all(4 * paddingScale),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF6366F1).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(
                                  Icons.add_rounded,
                                  color: const Color(0xFF6366F1),
                                  size: 14 * paddingScale,
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
          ),
        ),
      ),
    );
  }
}

class CartPanel extends StatelessWidget {
  final List<CartItem> cartItems;
  final double subtotal;
  final double tax;
  final double total;
  final Function(String) onRemoveItem;
  final Function(String, int) onUpdateQuantity;
  final VoidCallback onClearCart;
  final VoidCallback onCheckout;

  const CartPanel({
    super.key,
    required this.cartItems,
    required this.subtotal,
    required this.tax,
    required this.total,
    required this.onRemoveItem,
    required this.onUpdateQuantity,
    required this.onClearCart,
    required this.onCheckout,
  });

  @override
  Widget build(BuildContext context) {
    final paddingScale = ResponsiveHelper.getPaddingScale(context);
    final iconScale = ResponsiveHelper.getIconScale(context);
    
    return Column(
      children: [
        // Cart Header
        Container(
          padding: EdgeInsets.all(16 * paddingScale),
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  "Keranjang",
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (cartItems.isNotEmpty)
                GestureDetector(
                  onTap: onClearCart,
                  child: Container(
                    padding: EdgeInsets.all(6 * paddingScale),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.clear_all_rounded,
                      color: Colors.white,
                      size: 18 * iconScale,
                    ),
                  ),
                ),
            ],
          ),
        ),
        
        // Cart Items
        Expanded(
          child: cartItems.isEmpty
              ? Center(
                  child: Padding(
                    padding: EdgeInsets.all(16 * paddingScale),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.shopping_cart_outlined,
                          size: 64 * iconScale,
                          color: Colors.grey[400],
                        ),
                        SizedBox(height: 16 * paddingScale),
                        Text(
                          "Keranjang kosong",
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w500,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: 8 * paddingScale),
                        Text(
                          "Tambahkan produk untuk memulai transaksi",
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.grey[500],
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                )
              : ListView.builder(
                  padding: EdgeInsets.all(16 * paddingScale),
                  itemCount: cartItems.length,
                  itemBuilder: (context, index) {
                    final item = cartItems[index];
                    return CartItemCard(
                      item: item,
                      onRemove: () => onRemoveItem(item.product.id),
                      onUpdateQuantity: (quantity) => onUpdateQuantity(item.product.id, quantity),
                    );
                  },
                ),
        ),
        
        // Bill Summary
        if (cartItems.isNotEmpty) ...[
          Container(
            padding: EdgeInsets.all(16 * paddingScale),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              border: Border(
                top: BorderSide(
                  color: Colors.grey.withOpacity(0.2),
                  width: 1,
                ),
              ),
            ),
            child: Column(
              children: [
                _buildBillRow(context, "Subtotal", subtotal, paddingScale),
                SizedBox(height: 8 * paddingScale),
                _buildBillRow(context, "Pajak (11%)", tax, paddingScale),
                SizedBox(height: 12 * paddingScale),
                Container(
                  padding: EdgeInsets.symmetric(vertical: 12 * paddingScale),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: const Color(0xFF6366F1).withOpacity(0.2),
                      width: 1,
                    ),
                  ),
                  child: _buildBillRow(context, "Total", total, paddingScale, isTotal: true),
                ),
                SizedBox(height: 16 * paddingScale),
                SizedBox(
                  width: double.infinity,
                  height: 50 * paddingScale,
                  child: ElevatedButton(
                    onPressed: onCheckout,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6366F1),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.payment_rounded, size: 18 * iconScale),
                        SizedBox(width: 8 * paddingScale),
                        Flexible(
                          child: Text(
                            "Bayar Sekarang",
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildBillRow(BuildContext context, String label, double amount, double paddingScale, {bool isTotal = false}) {
    final fontSize = ResponsiveHelper.getFontScale(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Flexible(
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: isTotal ? const Color(0xFF1F2937) : Colors.grey[600],
              fontWeight: isTotal ? FontWeight.w600 : FontWeight.w500,
              fontSize: (Theme.of(context).textTheme.bodyMedium?.fontSize ?? 14) * fontSize,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        Flexible(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerRight,
            child: Text(
              'Rp ${amount.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')}',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: isTotal ? const Color(0xFF6366F1) : const Color(0xFF1F2937),
                fontWeight: isTotal ? FontWeight.w700 : FontWeight.w600,
                fontSize: (Theme.of(context).textTheme.bodyMedium?.fontSize ?? 14) * fontSize,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class CartItemCard extends StatelessWidget {
  final CartItem item;
  final VoidCallback onRemove;
  final Function(int) onUpdateQuantity;

  const CartItemCard({
    super.key,
    required this.item,
    required this.onRemove,
    required this.onUpdateQuantity,
  });

  @override
  Widget build(BuildContext context) {
    final paddingScale = ResponsiveHelper.getPaddingScale(context);
    final iconScale = ResponsiveHelper.getIconScale(context);
    final fontSize = ResponsiveHelper.getFontScale(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 768;
    
    return Container(
      margin: EdgeInsets.only(bottom: 8 * paddingScale),
      padding: EdgeInsets.all(12 * paddingScale),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.grey.withOpacity(0.1),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Product Image
          Container(
            width: isMobile ? 40 : 50,
            height: isMobile ? 40 : 50,
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                item.product.image.isNotEmpty 
                    ? item.product.image 
                    : '📦',
                style: TextStyle(fontSize: isMobile ? 20 : 24),
              ),
            ),
          ),
          SizedBox(width: 8 * paddingScale),
          
          // Product Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  item.product.name,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF1F2937),
                    fontSize: (Theme.of(context).textTheme.titleSmall?.fontSize ?? 14) * fontSize,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 2 * paddingScale),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Rp ${item.product.price.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: const Color(0xFF6366F1),
                      fontWeight: FontWeight.w600,
                      fontSize: (Theme.of(context).textTheme.bodySmall?.fontSize ?? 12) * fontSize,
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Quantity Controls
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              GestureDetector(
                onTap: () => onUpdateQuantity(item.quantity - 1),
                child: Container(
                  width: 28 * paddingScale,
                  height: 28 * paddingScale,
                  decoration: BoxDecoration(
                    color: const Color(0xFF6366F1).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.remove_rounded,
                    color: const Color(0xFF6366F1),
                    size: 14 * iconScale,
                  ),
                ),
              ),
              SizedBox(width: 8 * paddingScale),
              Text(
                item.quantity.toString(),
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF1F2937),
                  fontSize: (Theme.of(context).textTheme.titleMedium?.fontSize ?? 16) * fontSize,
                ),
              ),
              SizedBox(width: 8 * paddingScale),
              GestureDetector(
                onTap: () => onUpdateQuantity(item.quantity + 1),
                child: Container(
                  width: 28 * paddingScale,
                  height: 28 * paddingScale,
                  decoration: BoxDecoration(
                    color: const Color(0xFF6366F1).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.add_rounded,
                    color: const Color(0xFF6366F1),
                    size: 14 * iconScale,
                  ),
                ),
              ),
            ],
          ),
          
          SizedBox(width: 8 * paddingScale),
          
          // Remove Button
          GestureDetector(
            onTap: onRemove,
            child: Container(
              width: 28 * paddingScale,
              height: 28 * paddingScale,
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.delete_rounded,
                color: Colors.red,
                size: 14 * iconScale,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class PaymentModal extends StatefulWidget {
  final double total;
  final List<CartItem> cartItems;
  final Function({
    required String paymentMethod,
    double? cashAmount,
    double? change,
  }) onPaymentSuccess;

  const PaymentModal({
    super.key,
    required this.total,
    required this.cartItems,
    required this.onPaymentSuccess,
  });

  @override
  State<PaymentModal> createState() => _PaymentModalState();
}

class _PaymentModalState extends State<PaymentModal> {
  String _selectedPaymentMethod = 'Cash';
  final TextEditingController _cashController = TextEditingController();
  double _cashAmount = 0.0;
  double _change = 0.0;

  final List<PaymentMethod> _paymentMethods = [
    PaymentMethod(id: 'Cash', name: 'Tunai', icon: Icons.money_rounded),
    PaymentMethod(id: 'QRIS', name: 'QRIS', icon: Icons.qr_code_rounded),
    PaymentMethod(id: 'VirtualAccount', name: 'Virtual Account', icon: Icons.account_balance_rounded),
  ];

  final XenditService _xenditService = XenditService();
  bool _isProcessingPayment = false;

  @override
  void dispose() {
    _cashController.dispose();
    super.dispose();
  }

  void _calculateChange() {
    setState(() {
      _cashAmount = double.tryParse(_cashController.text) ?? 0.0;
      _change = _cashAmount - widget.total;
    });
  }

  Future<void> _processPayment() async {
    if (_selectedPaymentMethod == 'Cash') {
      if (_cashAmount < widget.total) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Jumlah uang tidak mencukupi!'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
      // Process cash payment immediately
      widget.onPaymentSuccess(
        paymentMethod: _selectedPaymentMethod,
        cashAmount: _cashAmount,
        change: _change > 0 ? _change : null,
      );
      return;
    }

    setState(() {
      _isProcessingPayment = true;
    });

    try {
      if (_selectedPaymentMethod == 'QRIS') {
        await _processQRISPayment();
      } else if (_selectedPaymentMethod == 'VirtualAccount') {
        await _processVirtualAccountPayment();
      }
    } catch (e) {
      setState(() {
        _isProcessingPayment = false;
      });
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

  Future<void> _processQRISPayment() async {
    try {
      final referenceId = 'TXN-${DateTime.now().millisecondsSinceEpoch}';
      final expiredAt = DateTime.now().add(const Duration(hours: 24)).toIso8601String();

      final qrisResponse = await _xenditService.createQRIS(
        amount: widget.total,
        referenceId: referenceId,
        callbackUrl: 'https://api.xendit.co/qr_codes/callback',
        expiredAt: expiredAt,
      );

      setState(() {
        _isProcessingPayment = false;
      });

      if (mounted) {
        Navigator.pop(context); // Close payment modal
        _showQRISPaymentDialog(qrisResponse, referenceId);
      }
    } catch (e) {
      setState(() {
        _isProcessingPayment = false;
      });
      rethrow;
    }
  }

  Future<void> _processVirtualAccountPayment() async {
    if (mounted) {
      Navigator.pop(context); // Close payment modal
      _showVirtualAccountBankSelection();
    }
  }

  void _showQRISPaymentDialog(Map<String, dynamic> qrisData, String referenceId) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => QRISPaymentDialog(
        qrisData: qrisData,
        referenceId: referenceId,
        total: widget.total,
        onPaymentVerified: () {
          widget.onPaymentSuccess(
            paymentMethod: 'QRIS',
            cashAmount: null,
            change: null,
          );
        },
        onCancel: () {
          // Handle cancel
        },
      ),
    );
  }

  void _showVirtualAccountBankSelection() {
    showDialog(
      context: context,
      builder: (context) => VirtualAccountBankSelectionDialog(
        total: widget.total,
        onBankSelected: (bankCode, bankName) async {
          Navigator.pop(context);
          await _createVirtualAccount(bankCode, bankName);
        },
      ),
    );
  }

  Future<void> _createVirtualAccount(String bankCode, String bankName) async {
    try {
      setState(() {
        _isProcessingPayment = true;
      });

      final externalId = 'VA-${DateTime.now().millisecondsSinceEpoch}';
      final expiredAt = DateTime.now().add(const Duration(days: 1));

      final vaResponse = await _xenditService.createVirtualAccount(
        externalId: externalId,
        bankCode: bankCode,
        name: 'KiosDarma Payment',
        amount: widget.total,
        expiredAt: expiredAt,
      );

      setState(() {
        _isProcessingPayment = false;
      });

      if (mounted) {
        _showVirtualAccountPaymentDialog(vaResponse, bankName);
      }
    } catch (e) {
      setState(() {
        _isProcessingPayment = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error creating Virtual Account: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showVirtualAccountPaymentDialog(Map<String, dynamic> vaData, String bankName) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => VirtualAccountPaymentDialog(
        vaData: vaData,
        bankName: bankName,
        total: widget.total,
        onPaymentVerified: () {
          widget.onPaymentSuccess(
            paymentMethod: 'VirtualAccount',
            cashAmount: null,
            change: null,
          );
        },
        onCancel: () {
          // Handle cancel
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
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
                  "Pembayaran",
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
          
          // Total Amount
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 24),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                Text(
                  "Total Pembayaran",
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Colors.white70,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Rp ${widget.total.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')}',
                  style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Payment Methods
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Metode Pembayaran",
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF1F2937),
                  ),
                ),
                const SizedBox(height: 16),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 3,
                  ),
                  itemCount: _paymentMethods.length,
                  itemBuilder: (context, index) {
                    final method = _paymentMethods[index];
                    final isSelected = _selectedPaymentMethod == method.id;
                    
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedPaymentMethod = method.id;
                        });
                        HapticFeedback.lightImpact();
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: isSelected ? const Color(0xFF6366F1) : Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected ? const Color(0xFF6366F1) : Colors.grey[300]!,
                            width: 2,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              method.icon,
                              color: isSelected ? Colors.white : const Color(0xFF6366F1),
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              method.name,
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: isSelected ? Colors.white : const Color(0xFF1F2937),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          
          // Payment Processing Indicator
          if (_isProcessingPayment) ...[
            const SizedBox(height: 24),
            const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF6366F1)),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Memproses pembayaran...',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[600],
              ),
            ),
          ],

          // Cash Input (if Cash selected)
          if (_selectedPaymentMethod == 'Cash' && !_isProcessingPayment) ...[
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Jumlah Uang",
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF1F2937),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _cashController,
                    onChanged: (_) => _calculateChange(),
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      hintText: 'Masukkan jumlah uang',
                      hintStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey[500],
                      ),
                      prefixText: 'Rp ',
                      prefixStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: const Color(0xFF6366F1),
                        fontWeight: FontWeight.w600,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey[300]!),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFF6366F1), width: 2),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 16,
                      ),
                    ),
                  ),
                  if (_change > 0) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: Colors.green.withOpacity(0.2),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.money_rounded,
                            color: Colors.green,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Kembalian: Rp ${_change.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')}',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Colors.green[700],
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
          
          const Spacer(),
          
          // Pay Button
          if (!_isProcessingPayment)
            Padding(
              padding: const EdgeInsets.all(24),
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _processPayment,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6366F1),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        _selectedPaymentMethod == 'QRIS'
                            ? Icons.qr_code_rounded
                            : _selectedPaymentMethod == 'VirtualAccount'
                                ? Icons.account_balance_rounded
                                : Icons.payment_rounded,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _selectedPaymentMethod == 'Cash'
                            ? "Proses Pembayaran"
                            : _selectedPaymentMethod == 'QRIS'
                                ? "Buat QRIS"
                                : "Buat Virtual Account",
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class TransactionSuccessDialog extends StatelessWidget {
  final double total;
  final VoidCallback onClose;

  const TransactionSuccessDialog({
    super.key,
    required this.total,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
      ),
      child: Container(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Success Icon
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(40),
              ),
              child: const Icon(
                Icons.check_circle_rounded,
                color: Colors.green,
                size: 48,
              ),
            ),
            const SizedBox(height: 24),
            
            // Success Message
            Text(
              "Transaksi Berhasil!",
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: const Color(0xFF1F2937),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              "Pembayaran sebesar",
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Rp ${total.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')}',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: const Color(0xFF6366F1),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "telah berhasil diproses",
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 32),
            
            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      // TODO: Print receipt
                      HapticFeedback.lightImpact();
                    },
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFF6366F1)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.print_rounded, size: 18),
                        const SizedBox(width: 8),
                        Text(
                          "Cetak Struk",
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: const Color(0xFF6366F1),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: onClose,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6366F1),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: Text(
                      "Selesai",
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
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
}

class AddProductDialog extends StatefulWidget {
  final VoidCallback onProductAdded;

  const AddProductDialog({
    super.key,
    required this.onProductAdded,
  });

  @override
  State<AddProductDialog> createState() => _AddProductDialogState();
}

class _AddProductDialogState extends State<AddProductDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _priceController = TextEditingController();
  final _stockController = TextEditingController();
  final _categoryController = TextEditingController();
  final _barcodeController = TextEditingController();
  
  String _selectedEmoji = '📦';
  bool _isLoading = false;
  
  final DatabaseService _databaseService = DatabaseService();
  
  // Popular emojis for products
  final List<String> _emojiCategories = [
    '🍔', '🍕', '🍟', '🌮', '🌯', '🥗', '🍛', '🍜', '🍝', '🍱',
    '🍣', '🍤', '🍗', '🍖', '🥩', '🍳', '🧀', '🥚', '🥞', '🧇',
    '🥐', '🍞', '🥖', '🥨', '🧈', '🥓', '🥪', '🌭', '🍿', '🥜',
    '🍫', '🍬', '🍭', '🍮', '🍯', '🧁', '🍰', '🎂', '🍪', '🍩',
    '☕', '🍵', '🥤', '🧃', '🧉', '🍶', '🍺', '🍻', '🥂', '🍷',
    '🧊', '🥛', '🍼', '🍾', '🧂', '🥢', '🍴', '🥄', '🔪', '🍽️',
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _stockController.dispose();
    _categoryController.dispose();
    _barcodeController.dispose();
    super.dispose();
  }

  Future<void> _saveProduct() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final productData = {
        'name': _nameController.text.trim(),
        'price': double.parse(_priceController.text.trim()),
        'stock': int.parse(_stockController.text.trim()),
        'category': _categoryController.text.trim(),
        'barcode': _barcodeController.text.trim(),
        'image': _selectedEmoji,
        'description': '',
        'minStock': 10,
        'supplier': '',
        'imageUrl': '',
      };

      await _databaseService.addProduct(productData);

      if (mounted) {
        Navigator.pop(context);
        widget.onProductAdded();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Produk berhasil ditambahkan!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error adding product: $e'),
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
        constraints: const BoxConstraints(maxWidth: 600, maxHeight: 800),
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Tambah Produk",
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
                    labelText: 'Nama Produk',
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
                
                // Price and Stock in Row
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _priceController,
                        decoration: InputDecoration(
                          labelText: 'Harga',
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
                          if (double.tryParse(value) == null || double.parse(value) <= 0) {
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
                          labelText: 'Stok',
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
                          if (int.tryParse(value) == null || int.parse(value) < 0) {
                            return 'Stok tidak valid';
                          }
                          return null;
                        },
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
                          labelText: 'Kategori',
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
                          labelText: 'Barcode (Opsional)',
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
                                "Simpan Produk",
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
      ),
    );
  }
}

// Data Models
class Product {
  final String id;
  final String name;
  final double price;
  final String category;
  final String image;
  final int stock;

  Product({
    required this.id,
    required this.name,
    required this.price,
    required this.category,
    required this.image,
    required this.stock,
  });

  factory Product.fromFirebase(Map<String, dynamic> data) {
    return Product(
      id: data['id'] as String? ?? '',
      name: data['name'] as String? ?? '',
      price: (data['price'] as num?)?.toDouble() ?? 0.0,
      category: data['category'] as String? ?? '',
      image: data['image'] as String? ?? '📦',
      stock: (data['stock'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toFirebase() {
    return {
      'name': name,
      'price': price,
      'category': category,
      'image': image,
      'stock': stock,
    };
  }
}

class CartItem {
  final Product product;
  int quantity;

  CartItem({
    required this.product,
    required this.quantity,
  });
}

class PaymentMethod {
  final String id;
  final String name;
  final IconData icon;

  PaymentMethod({
    required this.id,
    required this.name,
    required this.icon,
  });
}

// QRIS Payment Dialog
class QRISPaymentDialog extends StatefulWidget {
  final Map<String, dynamic> qrisData;
  final String referenceId;
  final double total;
  final VoidCallback onPaymentVerified;
  final VoidCallback onCancel;

  const QRISPaymentDialog({
    super.key,
    required this.qrisData,
    required this.referenceId,
    required this.total,
    required this.onPaymentVerified,
    required this.onCancel,
  });

  @override
  State<QRISPaymentDialog> createState() => _QRISPaymentDialogState();
}

class _QRISPaymentDialogState extends State<QRISPaymentDialog> {
  final XenditService _xenditService = XenditService();
  bool _isChecking = false;
  String _status = 'PENDING';

  @override
  void initState() {
    super.initState();
    _startPolling();
  }

  void _startPolling() {
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        _checkPaymentStatus();
      }
    });
  }

  Future<void> _checkPaymentStatus() async {
    try {
      setState(() {
        _isChecking = true;
      });

      final qrId = widget.qrisData['id'] as String?;
      if (qrId != null) {
        final status = await _xenditService.getQRISStatus(qrId);
        final paymentStatus = status['status'] as String? ?? 'PENDING';

        setState(() {
          _status = paymentStatus;
          _isChecking = false;
        });

        if (paymentStatus == 'SUCCEEDED' || paymentStatus == 'COMPLETED') {
          widget.onPaymentVerified();
        } else if (paymentStatus == 'PENDING') {
          _startPolling();
        }
      }
    } catch (e) {
      setState(() {
        _isChecking = false;
      });
      // Continue polling even if check fails
      _startPolling();
    }
  }

  String get _qrString {
    return widget.qrisData['qr_string'] as String? ?? '';
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
      ),
      child: Container(
        padding: const EdgeInsets.all(24),
        constraints: const BoxConstraints(maxWidth: 400),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              "Scan QRIS untuk Pembayaran",
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: const Color(0xFF1F2937),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Rp ${widget.total.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')}',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
                color: const Color(0xFF6366F1),
              ),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Colors.grey.withOpacity(0.2),
                  width: 1,
                ),
              ),
              child: QrImageView(
                data: _qrString,
                version: QrVersions.auto,
                size: 250,
                backgroundColor: Colors.white,
              ),
            ),
            const SizedBox(height: 24),
            if (_isChecking)
              const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF6366F1)),
                    ),
                  ),
                  SizedBox(width: 12),
                  Text('Memeriksa status pembayaran...'),
                ],
              )
            else if (_status == 'PENDING')
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.access_time_rounded, color: Colors.orange[700], size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Menunggu pembayaran...',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.orange[700],
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: widget.onCancel,
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.grey),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text('Batal'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _checkPaymentStatus,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6366F1),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text('Cek Status'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// Virtual Account Bank Selection Dialog
class VirtualAccountBankSelectionDialog extends StatelessWidget {
  final double total;
  final Function(String bankCode, String bankName) onBankSelected;

  const VirtualAccountBankSelectionDialog({
    super.key,
    required this.total,
    required this.onBankSelected,
  });

  @override
  Widget build(BuildContext context) {
    final xenditService = XenditService();
    final banks = xenditService.getAvailableBanks();

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
      ),
      child: Container(
        padding: const EdgeInsets.all(24),
        constraints: const BoxConstraints(maxWidth: 400),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              "Pilih Bank",
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: const Color(0xFF1F2937),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Rp ${total.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')}',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
                color: const Color(0xFF6366F1),
              ),
            ),
            const SizedBox(height: 24),
            ListView.builder(
              shrinkWrap: true,
              itemCount: banks.length,
              itemBuilder: (context, index) {
                final bank = banks[index];
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ElevatedButton(
                    onPressed: () {
                      onBankSelected(bank['code']!, bank['name']!);
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: const Color(0xFF1F2937),
                      elevation: 0,
                      side: BorderSide(
                        color: Colors.grey.withOpacity(0.3),
                        width: 1,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF6366F1).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.account_balance_rounded,
                            color: Color(0xFF6366F1),
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            bank['name']!,
                            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const Icon(Icons.arrow_forward_ios_rounded, size: 16),
                      ],
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Batal'),
            ),
          ],
        ),
      ),
    );
  }
}

// Virtual Account Payment Dialog
class VirtualAccountPaymentDialog extends StatefulWidget {
  final Map<String, dynamic> vaData;
  final String bankName;
  final double total;
  final VoidCallback onPaymentVerified;
  final VoidCallback onCancel;

  const VirtualAccountPaymentDialog({
    super.key,
    required this.vaData,
    required this.bankName,
    required this.total,
    required this.onPaymentVerified,
    required this.onCancel,
  });

  @override
  State<VirtualAccountPaymentDialog> createState() => _VirtualAccountPaymentDialogState();
}

class _VirtualAccountPaymentDialogState extends State<VirtualAccountPaymentDialog> {
  final XenditService _xenditService = XenditService();
  bool _isChecking = false;
  String _status = 'PENDING';

  @override
  void initState() {
    super.initState();
    _startPolling();
  }

  void _startPolling() {
    Future.delayed(const Duration(seconds: 5), () {
      if (mounted) {
        _checkPaymentStatus();
      }
    });
  }

  Future<void> _checkPaymentStatus() async {
    try {
      setState(() {
        _isChecking = true;
      });

      final vaId = widget.vaData['id'] as String?;
      if (vaId != null) {
        final status = await _xenditService.getVirtualAccountStatus(vaId);
        final paymentStatus = status['status'] as String? ?? 'PENDING';

        setState(() {
          _status = paymentStatus;
          _isChecking = false;
        });

        if (paymentStatus == 'PAID' || paymentStatus == 'COMPLETED') {
          widget.onPaymentVerified();
        } else if (paymentStatus == 'PENDING' || paymentStatus == 'ACTIVE') {
          _startPolling();
        }
      }
    } catch (e) {
      setState(() {
        _isChecking = false;
      });
      _startPolling();
    }
  }

  String get _accountNumber {
    return widget.vaData['account_number'] as String? ?? '';
  }

  String? get _expirationDate {
    final exp = widget.vaData['expiration_date'];
    if (exp != null) {
      try {
        final date = DateTime.parse(exp as String);
        return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
      } catch (e) {
        return null;
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
      ),
      child: Container(
        padding: const EdgeInsets.all(24),
        constraints: const BoxConstraints(maxWidth: 400),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              "Virtual Account",
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: const Color(0xFF1F2937),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              widget.bankName,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  Text(
                    'Nomor Virtual Account',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.white70,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _accountNumber,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Rp ${widget.total.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')}',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            if (_expirationDate != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.access_time_rounded, color: Colors.orange[700], size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Berlaku sampai: $_expirationDate',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.orange[700],
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 24),
            if (_isChecking)
              const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF6366F1)),
                    ),
                  ),
                  SizedBox(width: 12),
                  Text('Memeriksa status pembayaran...'),
                ],
              )
            else if (_status == 'PENDING' || _status == 'ACTIVE')
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.access_time_rounded, color: Colors.orange[700], size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Menunggu pembayaran...',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.orange[700],
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: widget.onCancel,
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.grey),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text('Batal'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _checkPaymentStatus,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6366F1),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text('Cek Status'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
