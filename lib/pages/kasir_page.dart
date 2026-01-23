import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../controllers/kasir_controller.dart';
import '../models/cart_item_model.dart';
import '../services/barcode_scanner_service.dart';
import '../controllers/printer_controller.dart';
import '../utils/error_helper.dart';
import '../utils/snackbar_helper.dart';
import '../utils/haptic_helper.dart';
import '../widgets/pattern_background.dart';
import '../widgets/status_banner.dart';
import '../widgets/gradient_app_bar.dart';
import '../utils/responsive_helper.dart';
import '../widgets/kasir/product_list_item.dart';
import '../widgets/kasir/cart_panel.dart';
import '../widgets/kasir/add_product_dialog.dart';
import '../widgets/kasir/payment_modal.dart';
import '../widgets/kasir/transaction_success_dialog.dart';
import '../widgets/kasir/barcode_scanner_instructions_dialog.dart';
import '../widgets/kasir/error_state_widget.dart';
import '../widgets/kasir/empty_product_state.dart';
import '../widgets/kasir/search_and_category_section.dart';
import '../widgets/kasir/cart_fab.dart';

class KasirPage extends StatefulWidget {
  final bool hideAppBar;
  
  const KasirPage({super.key, this.hideAppBar = false});

  @override
  State<KasirPage> createState() => _KasirPageState();
}

class _KasirPageState extends State<KasirPage> with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _testBarcodeController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode(debugLabel: 'searchField');
  final FocusNode _testBarcodeFocusNode = FocusNode(debugLabel: 'testBarcodeScanner');
  late KasirController _controller;
  late BarcodeScannerService _barcodeScanner;
  bool _testModeEnabled = false;
  bool _barcodeScannerEnabled = true;
  bool _useCleanLayout = false;

  @override
  void initState() {
    super.initState();
    _controller = KasirController()..addListener(_onControllerChanged)..initialize();
    
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
    
    // Initialize barcode scanner service
    _barcodeScanner = BarcodeScannerService(
      onBarcodeDetected: (barcode) {
        if (barcode.isEmpty) {
          // Empty string means clear buffer
          _controller.clearBarcodeBuffer();
          return;
        }
        _controller.setBarcodeBuffer(barcode);
        Future.delayed(const Duration(milliseconds: 50), () {
          if (mounted) {
            final product = _controller.handleBarcodeEnter();
            if (product != null) {
              HapticHelper.lightImpact();
            }
          }
        });
      },
      onRefocusNeeded: () => _barcodeScanner.refocus(),
      onHapticFeedback: () => HapticHelper.lightImpact(),
      searchFocusNode: _searchFocusNode,
      testBarcodeFocusNode: _testBarcodeFocusNode,
      searchController: _searchController,
      testBarcodeController: _testBarcodeController,
    );
    _barcodeScanner.setEnabled(_barcodeScannerEnabled);
    _barcodeScanner.setTestMode(_testModeEnabled);

    _animationController.forward();
    _barcodeScanner.initializeFocus();
    
    // Load layout preference
    _loadLayoutPreference();
    
    // Attempt to auto-reconnect to printer when entering kasir page
    _attemptPrinterAutoReconnect();
  }
  
  /// Attempt to auto-reconnect to the previously configured printer
  Future<void> _attemptPrinterAutoReconnect() async {
    // This runs in the background; don't block the UI
    try {
      final printerController = PrinterController.instance;
      await printerController.autoReconnect(maxRetries: 2);
    } catch (e) {
      // Silently fail; user can manually reconnect in settings if needed
      if (kDebugMode) {
        print('Auto-reconnect attempt failed: $e');
      }
    }
  }

  void _onControllerChanged() {
    if (mounted) {
      setState(() {});
      // Handle barcode not found message
      if (_controller.lastBarcodeNotFound != null) {
        final barcode = _controller.lastBarcodeNotFound!;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            SnackbarHelper.showError(
              context,
              'Produk dengan barcode "$barcode" tidak ditemukan',
            );
          }
        });
      }
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _searchController.dispose();
    _testBarcodeController.dispose();
    _searchFocusNode.dispose();
    _testBarcodeFocusNode.dispose();
    _barcodeScanner.dispose();
    _controller.removeListener(_onControllerChanged);
    _controller.dispose();
    super.dispose();
  }


  Widget _buildProductListContent({
    required double paddingScale,
    required double iconScale,
  }) {
    final filteredProducts = _controller.filteredProducts;
    if (filteredProducts.isEmpty) {
      return EmptyProductState(
        controller: _controller,
        onAddProduct: _showAddProductDialog,
        paddingScale: paddingScale,
        iconScale: iconScale,
      );
    }

    return ListView.builder(
      padding: EdgeInsets.all(16 * paddingScale),
      itemCount: filteredProducts.length,
      itemBuilder: (context, index) {
        final product = filteredProducts[index];
        final cartItem = _controller.cartItems.firstWhere(
          (item) => item.product.id == product.id,
          orElse: () => CartItem(product: product, quantity: 0),
        );
        final quantity = cartItem.quantity;
        
        return ProductListItem(
          product: product,
          quantity: quantity,
          onAddToCart: () => _controller.addToCart(product),
          onIncrement: () => _controller.addToCart(product),
          onDecrement: () {
            if (quantity > 1) {
              _controller.updateQuantity(product.id, quantity - 1);
            } else {
              _controller.removeFromCart(product.id);
            }
          },
          paddingScale: paddingScale,
          iconScale: iconScale,
        );
      },
    );
  }

  void _handleRawKeyEvent(RawKeyEvent event) {
    _barcodeScanner.handleRawKeyEvent(
      event,
      getBarcodeBuffer: () => _controller.barcodeBuffer,
      setBarcodeBuffer: (char) => _controller.handleBarcodeCharacter(char),
      clearBarcodeBuffer: () => _controller.clearBarcodeBuffer(),
      handleBackspace: () => _controller.handleBarcodeBackspace(),
      handleEnter: () => _controller.handleBarcodeEnter(),
      checkBuffer: () => _controller.checkBarcodeBuffer(),
    );
  }

  void _showAddProductDialog() {
    showDialog(
      context: context,
      builder: (context) => AddProductDialog(
        onProductAdded: () {
          HapticHelper.lightImpact();
        },
      ),
    ).then((_) => _barcodeScanner.refocus());
  }

  void _showBarcodeScannerInstructions() {
    _barcodeScanner.unfocus();
    BarcodeScannerInstructionsDialog.show(context).then((_) {
      if (mounted) {
        _barcodeScanner.refocus();
      }
    });
  }

  void _toggleLayout() {
    setState(() {
      _useCleanLayout = !_useCleanLayout;
    });
    _saveLayoutPreference();
  }

  Future<void> _loadLayoutPreference() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedLayout = prefs.getBool('kasir_use_clean_layout') ?? false;
      if (mounted) {
        setState(() {
          _useCleanLayout = savedLayout;
        });
      }
    } catch (e) {
      if (kDebugMode) {
        print('Failed to load layout preference: $e');
      }
    }
  }

  Future<void> _saveLayoutPreference() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('kasir_use_clean_layout', _useCleanLayout);
    } catch (e) {
      if (kDebugMode) {
        print('Failed to save layout preference: $e');
      }
    }
  }

  void _showPaymentModal() {
    if (_controller.cartItems.isEmpty) {
      SnackbarHelper.showInfo(
        context,
        'Keranjang kosong! Tambahkan produk terlebih dahulu.',
      );
      return;
    }

    // Unfocus barcode scanner when opening payment modal to allow text input
    // Also temporarily disable auto-refocus to prevent focus stealing
    if (_barcodeScannerEnabled) {
      _barcodeScanner.unfocus();
      // Temporarily disable the scanner to prevent it from stealing focus
      _barcodeScanner.setEnabled(false);
    }

    // Reload tax settings before opening payment modal to ensure fresh values
    _controller.reloadTaxSettings();
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AnimatedBuilder(
        animation: _controller,
        builder: (context, child) => PaymentModal(
          total: _controller.total,
          cartItems: _controller.cartItems,
          databaseService: _controller.databaseService,
          onPaymentSuccess: _handlePaymentSuccess,
        ),
      ),
    ).then((_) {
      // Re-enable and refocus scanner after modal closes (if it was enabled before)
      if (_barcodeScannerEnabled) {
        _barcodeScanner.setEnabled(true);
        Future.delayed(const Duration(milliseconds: 300), () {
          if (mounted && _barcodeScannerEnabled) {
            _barcodeScanner.refocus();
          }
        });
      }
    });
  }

  Future<void> _handlePaymentSuccess({
    required String paymentMethod,
    double? cashAmount,
    double? change,
    String? customerId,
    String? customerName,
    double? discount = 0.0,
  }) async {
    try {
      final transactionData = await _controller.processPaymentSuccess(
        paymentMethod: paymentMethod,
        cashAmount: cashAmount,
        change: change,
        customerId: customerId,
        customerName: customerName,
        discount: discount ?? 0.0,
      );

      Navigator.pop(context);

      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => TransactionSuccessDialog(
            total: _controller.total,
            transactionId: transactionData['id'] as String,
            transactionData: transactionData,
            onClose: () => Navigator.pop(context),
          ),
        );
      }
    } catch (error) {
      if (!mounted) return;
      Navigator.pop(context);
      
      // Extract full error details for display
      final appException = toAppException(
        error,
        fallbackMessage: 'Gagal memproses pembayaran.',
      );
      
      SnackbarHelper.showError(
        context,
        appException.message,
        details: appException.details,
        forceDialog: true, // Always show dialog for transaction errors
      );
      
      debugPrint('Payment processing error: $error');
    }
  }

  @override
  Widget build(BuildContext context) {
    final paddingScale = ResponsiveHelper.getPaddingScale(context);
    final iconScale = ResponsiveHelper.getIconScale(context);
    final mediaQuery = MediaQuery.of(context);
    final isLandscape = mediaQuery.size.width > mediaQuery.size.height;
    final isMobileWidth = mediaQuery.size.width < 900;
    final useCleanLayout = !isMobileWidth && isLandscape && _useCleanLayout;
    
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: widget.hideAppBar ? null : GradientAppBar(
        title: "Kasir",
        icon: Icons.point_of_sale_rounded,
        toolbarHeight: 56,
        automaticallyImplyLeading: false,
        actions: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 4 * paddingScale),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Help button - always visible
                IconButton(
                  onPressed: () {
                    HapticHelper.lightImpact();
                    _showBarcodeScannerInstructions();
                  },
                  icon: Icon(Icons.help_outline_rounded, color: Colors.white, size: 22 * iconScale),
                  tooltip: 'Panduan Kasir',
                  padding: EdgeInsets.all(8 * paddingScale),
                  constraints: const BoxConstraints(),
                ),
                // Add product button - always visible
                IconButton(
                  onPressed: () {
                    HapticHelper.lightImpact();
                    _showAddProductDialog();
                  },
                  icon: Icon(Icons.add_rounded, color: Colors.white, size: 22 * iconScale),
                  tooltip: 'Tambah Produk',
                  padding: EdgeInsets.all(8 * paddingScale),
                  constraints: const BoxConstraints(),
                ),
                // Barcode scanner toggle button - always visible
                IconButton(
                  onPressed: () {
                    HapticHelper.lightImpact();
                    setState(() {
                      _barcodeScannerEnabled = !_barcodeScannerEnabled;
                      _barcodeScanner.setEnabled(_barcodeScannerEnabled);
                    });
                  },
                  icon: Icon(
                    // Use qr_code_scanner as there's no specific barcode icon in Material Icons
                    // qr_code_2 is a variant that's closer to barcode appearance
                    _barcodeScannerEnabled ? Icons.qr_code_2_rounded : Icons.qr_code_2_outlined,
                    color: _barcodeScannerEnabled ? Colors.green[300] : Colors.white70,
                    size: 22 * iconScale,
                  ),
                  tooltip: _barcodeScannerEnabled ? 'Nonaktifkan Barcode Scanner' : 'Aktifkan Barcode Scanner',
                  padding: EdgeInsets.all(8 * paddingScale),
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ),
        ],
      ),
      body: _testModeEnabled
          ? PatternBackground(
              patternType: PatternType.dots,
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: useCleanLayout
                      ? _buildCleanHorizontalLayout(context, paddingScale, iconScale)
                      : _buildDesktopLayout(
                          context,
                          paddingScale,
                          iconScale,
                          isLandscape,
                          isMobileWidth,
                        ),
                ),
              ),
            )
          : Focus(
              autofocus: true,
              canRequestFocus: true,
              skipTraversal: true,
              onFocusChange: (hasFocus) {
                if (!hasFocus && mounted && !_testModeEnabled && _barcodeScannerEnabled && !_searchFocusNode.hasFocus) {
                  _barcodeScanner.refocus();
                }
              },
              child: RawKeyboardListener(
                focusNode: _barcodeScanner.barcodeFocusNode,
                autofocus: true,
                onKey: _handleRawKeyEvent,
                child: PatternBackground(
                  patternType: PatternType.dots,
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: SlideTransition(
                      position: _slideAnimation,
                      child: useCleanLayout
                          ? _buildCleanHorizontalLayout(context, paddingScale, iconScale)
                          : _buildDesktopLayout(
                              context,
                              paddingScale,
                              iconScale,
                              isLandscape,
                              isMobileWidth,
                            ),
                    ),
                  ),
                ),
              ),
            ),
      floatingActionButton: useCleanLayout ? null : CartFAB(
        controller: _controller,
        onPressed: _showCartBottomSheet,
      ),
    );
  }

  Widget _buildDesktopLayout(
    BuildContext context,
    double paddingScale,
    double iconScale,
    bool isLandscape,
    bool isMobileWidth,
  ) {
    return Column(
      children: [
        // Test Barcode Input Field (for debugging)
        if (_testModeEnabled)
          Container(
            margin: EdgeInsets.all(8 * paddingScale),
            padding: EdgeInsets.all(12 * paddingScale),
            decoration: BoxDecoration(
              color: Colors.orange[50],
              border: Border.all(color: Colors.orange, width: 2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.bug_report, color: Colors.orange[700], size: 20),
                    SizedBox(width: 8),
                    Text(
                      'TEST MODE - Barcode Scanner Input',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.orange[900],
                        fontSize: 14,
                      ),
                    ),
                    Spacer(),
                    IconButton(
                      icon: Icon(Icons.close, size: 18),
                      onPressed: () {
                        setState(() {
                          _testModeEnabled = false;
                          _testBarcodeController.clear();
                          _barcodeScanner.setTestMode(false);
                        });
                      },
                      tooltip: 'Disable Test Mode',
                      padding: EdgeInsets.all(4),
                      constraints: BoxConstraints(),
                    ),
                  ],
                ),
                SizedBox(height: 8),
                TextField(
                  controller: _testBarcodeController,
                  focusNode: _testBarcodeFocusNode,
                  autofocus: true,
                  enableInteractiveSelection: false, // Prevent text selection for barcode scanner
                  decoration: InputDecoration(
                    hintText: 'Scan barcode here or type manually...',
                    hintStyle: TextStyle(fontSize: 12),
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    suffixIcon: IconButton(
                      icon: Icon(Icons.clear, size: 18),
                      onPressed: () {
                        _testBarcodeController.clear();
                        _controller.clearBarcodeBuffer();
                      },
                    ),
                  ),
                  style: TextStyle(fontSize: 14),
                  onSubmitted: (value) {
                    if (value.isNotEmpty) {
                      _controller.setBarcodeBuffer(value);
                      final product = _controller.handleBarcodeEnter();
                      if (product != null) {
                        HapticHelper.lightImpact();
                      }
                      _testBarcodeController.clear();
                    }
                    _barcodeScanner.refocusTestScanner();
                  },
                ),
                SizedBox(height: 4),
                Text(
                  'Buffer: "${_controller.barcodeBuffer}"',
                  style: TextStyle(fontSize: 11, color: Colors.grey[700]),
                ),
              ],
            ),
          ),
        SearchAndCategorySection(
          controller: _controller,
          searchController: _searchController,
          searchFocusNode: _searchFocusNode,
          paddingScale: paddingScale,
          iconScale: iconScale,
          useCleanLayout: _useCleanLayout,
          onToggleLayout: (!isMobileWidth && isLandscape) ? _toggleLayout : null,
        ),
        
        // Products List
        Expanded(
          child: Column(
            children: [
              if (_controller.isOffline)
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16 * paddingScale),
                  child: StatusBanner(
                    color: Colors.orange,
                    icon: Icons.wifi_off_rounded,
                    message: 'Anda sedang offline. Data produk mungkin tidak terbaru.',
                    trailing: TextButton(
                      onPressed: _controller.isRetrying ? null : _controller.retryLoadProducts,
                      child: Text(
                        'Segarkan',
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                              color: Colors.orange[700],
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ),
                  ),
                ),
              if (_controller.showInlineErrorBanner)
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16 * paddingScale),
                  child: StatusBanner(
                    color: Colors.red,
                    icon: Icons.error_outline_rounded,
                    message: _controller.errorMessage ?? 'Terjadi kesalahan.',
                    trailing: TextButton(
                      onPressed: _controller.isRetrying ? null : _controller.retryLoadProducts,
                      child: Text(
                        'Coba Lagi',
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                              color: Colors.red[600],
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ),
                  ),
                ),
              if (_controller.isRetrying && _controller.hasLoadedOnce)
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16 * paddingScale),
                  child: StatusBanner(
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
                ),
              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 250),
                  child: _controller.showInitialLoader
                      ? const Center(
                          key: ValueKey('kasir-products-loader-desktop'),
                          child: CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF6366F1)),
                          ),
                        )
                      : _controller.showFullErrorState
                          ? ErrorStateWidget(controller: _controller)
                          : _buildProductListContent(
                              paddingScale: paddingScale,
                              iconScale: iconScale,
                            ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildProductGridContent({
    required double paddingScale,
    required double iconScale,
  }) {
    final filteredProducts = _controller.filteredProducts;
    if (filteredProducts.isEmpty) {
      return EmptyProductState(
        controller: _controller,
        onAddProduct: _showAddProductDialog,
        paddingScale: paddingScale,
        iconScale: iconScale,
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        const cardWidth = 240.0;
        int crossAxisCount = (constraints.maxWidth / cardWidth).floor().clamp(2, 5);

        return GridView.builder(
          padding: const EdgeInsets.all(16),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            childAspectRatio: 0.82,
          ),
          itemCount: filteredProducts.length,
          itemBuilder: (context, index) {
            final product = filteredProducts[index];
            final cartItem = _controller.cartItems.firstWhere(
              (item) => item.product.id == product.id,
              orElse: () => CartItem(product: product, quantity: 0),
            );
            final quantity = cartItem.quantity;

            return ProductListItem(
              product: product,
              quantity: quantity,
              onAddToCart: () => _controller.addToCart(product),
              onIncrement: () => _controller.addToCart(product),
              onDecrement: () {
                if (quantity > 1) {
                  _controller.updateQuantity(product.id, quantity - 1);
                } else {
                  _controller.removeFromCart(product.id);
                }
              },
              paddingScale: 1.0,
              iconScale: 1.0,
            );
          },
        );
      },
    );
  }

  Widget _buildCleanHorizontalLayout(BuildContext context, double paddingScale, double iconScale) {
    const cartWidth = 380.0;

    return Row(
      children: [
        Expanded(
          child: Column(
            children: [
              SearchAndCategorySection(
                controller: _controller,
                searchController: _searchController,
                searchFocusNode: _searchFocusNode,
                paddingScale: paddingScale,
                iconScale: iconScale,
                useCleanLayout: _useCleanLayout,
                onToggleLayout: _toggleLayout,
              ),
              if (_controller.isOffline)
                Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16 * paddingScale),
                      child: StatusBanner(
                        color: Colors.orange,
                        icon: Icons.wifi_off_rounded,
                        message: 'Anda sedang offline. Data produk mungkin tidak terbaru.',
                        trailing: TextButton(
                          onPressed: _controller.isRetrying ? null : _controller.retryLoadProducts,
                          child: Text(
                            'Segarkan',
                            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                                  color: Colors.orange[700],
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                        ),
                      ),
                    ),
              if (_controller.showInlineErrorBanner)
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16 * paddingScale),
                      child: StatusBanner(
                        color: Colors.red,
                        icon: Icons.error_outline_rounded,
                        message: _controller.errorMessage ?? 'Terjadi kesalahan.',
                        trailing: TextButton(
                          onPressed: _controller.isRetrying ? null : _controller.retryLoadProducts,
                          child: Text(
                            'Coba Lagi',
                            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                                  color: Colors.red[600],
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                        ),
                      ),
                    ),
              if (_controller.isRetrying && _controller.hasLoadedOnce)
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16 * paddingScale),
                      child: StatusBanner(
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
                    ),
              const SizedBox(height: 8),
              Expanded(
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 250),
                      child: _controller.showInitialLoader
                          ? const Center(
                              key: ValueKey('kasir-products-loader-clean'),
                              child: CircularProgressIndicator(
                                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF6366F1)),
                              ),
                            )
                          : _controller.showFullErrorState
                              ? ErrorStateWidget(controller: _controller)
                              : _buildProductGridContent(
                                  paddingScale: paddingScale,
                                  iconScale: iconScale,
                                ),
                    ),
              ),
            ],
          ),
        ),
        SizedBox(
          width: cartWidth,
          height: double.infinity,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 24,
                  offset: const Offset(-4, 0),
                ),
              ],
            ),
            child: CartPanel(
            cartItems: _controller.cartItems,
            customItems: _controller.customItems,
            subtotal: _controller.subtotal,
            tax: _controller.tax,
            total: _controller.total,
            onRemoveItem: _controller.removeFromCart,
            onUpdateQuantity: _controller.updateQuantity,
            onRemoveCustomItem: _controller.removeCustomItem,
            onUpdateCustomItemQuantity: _controller.updateCustomItemQuantity,
            onAddCustomItem: _controller.addCustomItem,
            onClearCart: () {
              _controller.clearCart();
              HapticHelper.lightImpact();
            },
            onCheckout: _showPaymentModal,
            hideCheckout: false,
          ),
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
        builder: (context, scrollController) => AnimatedBuilder(
          animation: _controller,
          builder: (context, child) => Container(
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
                    cartItems: _controller.cartItems,
                    customItems: _controller.customItems,
                    subtotal: _controller.subtotal,
                    tax: _controller.tax,
                    total: _controller.total,
                    onRemoveItem: _controller.removeFromCart,
                    onUpdateQuantity: _controller.updateQuantity,
                    onRemoveCustomItem: _controller.removeCustomItem,
                    onUpdateCustomItemQuantity: _controller.updateCustomItemQuantity,
                    onAddCustomItem: _controller.addCustomItem,
                    onClearCart: () {
                      _controller.clearCart();
                      HapticHelper.lightImpact();
                    },
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
      ),
    );
  }
}


