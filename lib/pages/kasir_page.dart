import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../controllers/kasir_controller.dart';
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
  const KasirPage({super.key});

  @override
  State<KasirPage> createState() => _KasirPageState();
}

class _KasirPageState extends State<KasirPage> with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _barcodeFocusNode = FocusNode(skipTraversal: true, debugLabel: 'barcodeScanner');
  late KasirController _controller;

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
    
    _animationController.forward();
    _refocusScanner();
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
    _barcodeFocusNode.dispose();
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
        return ProductListItem(
          product: product,
          onAddToCart: () => _controller.addToCart(product),
          paddingScale: paddingScale,
          iconScale: iconScale,
        );
      },
    );
  }

  void _refocusScanner() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _barcodeFocusNode.requestFocus();
      }
    });
  }

  void _handleRawKeyEvent(RawKeyEvent event) {
    if (event is! RawKeyDownEvent) return;

    final logicalKey = event.logicalKey;

    if (logicalKey == LogicalKeyboardKey.enter || logicalKey == LogicalKeyboardKey.numpadEnter) {
      final product = _controller.handleBarcodeEnter();
      if (product != null) {
        HapticHelper.lightImpact();
      }
      _refocusScanner();
      return;
    }

    if (logicalKey == LogicalKeyboardKey.backspace) {
      _controller.handleBarcodeBackspace();
      return;
    }

    final character = event.character;
    if (character != null && character.isNotEmpty) {
      final codeUnit = character.codeUnitAt(0);
      if (codeUnit >= 32 && codeUnit != 127) {
        _controller.handleBarcodeCharacter(character);
        // Check barcode buffer after a short delay
        Future.delayed(const Duration(milliseconds: 150), () {
          if (mounted) {
            final found = _controller.checkBarcodeBuffer();
            if (found) {
              HapticHelper.lightImpact();
            }
            _refocusScanner();
          }
        });
      }
    }
  }

  void _showAddProductDialog() {
    showDialog(
      context: context,
      builder: (context) => AddProductDialog(
        onProductAdded: () {
          HapticHelper.lightImpact();
        },
      ),
    ).then((_) => _refocusScanner());
  }

  void _showBarcodeScannerInstructions() {
    showDialog(
      context: context,
      builder: (context) => const BarcodeScannerInstructionsDialog(),
    ).then((_) => _refocusScanner());
  }

  void _showPaymentModal() {
    if (_controller.cartItems.isEmpty) {
      SnackbarHelper.showInfo(
        context,
        'Keranjang kosong! Tambahkan produk terlebih dahulu.',
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => PaymentModal(
        total: _controller.total,
        cartItems: _controller.cartItems,
        databaseService: _controller.databaseService,
        onPaymentSuccess: _handlePaymentSuccess,
      ),
    ).then((_) => _refocusScanner());
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
      final message = getFriendlyErrorMessage(
        error,
        fallbackMessage: 'Gagal memproses pembayaran.',
      );
      SnackbarHelper.showError(context, message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final paddingScale = ResponsiveHelper.getPaddingScale(context);
    final iconScale = ResponsiveHelper.getIconScale(context);
    
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: GradientAppBar(
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
                IconButton(
                  onPressed: () {
                    HapticHelper.lightImpact();
                    _showBarcodeScannerInstructions();
                  },
                  icon: Icon(Icons.help_outline_rounded, color: Colors.white, size: 22 * iconScale),
                  tooltip: 'Cara Menggunakan Barcode Scanner',
                  padding: EdgeInsets.all(8 * paddingScale),
                  constraints: const BoxConstraints(),
                ),
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
                IconButton(
                  onPressed: () {
                    HapticHelper.lightImpact();
                    _showPaymentModal();
                  },
                  icon: Icon(Icons.payment_rounded, color: Colors.white, size: 22 * iconScale),
                  tooltip: 'Pembayaran',
                  padding: EdgeInsets.all(8 * paddingScale),
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ),
        ],
      ),
      body: RawKeyboardListener(
        focusNode: _barcodeFocusNode,
        autofocus: true,
        onKey: _handleRawKeyEvent,
        child: PatternBackground(
          patternType: PatternType.dots,
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: SlideTransition(
              position: _slideAnimation,
              child: _buildDesktopLayout(context, paddingScale, iconScale),
            ),
          ),
        ),
      ),
      floatingActionButton: CartFAB(
        controller: _controller,
        onPressed: _showCartBottomSheet,
      ),
    );
  }

  Widget _buildDesktopLayout(BuildContext context, double paddingScale, double iconScale) {
    return Column(
      children: [
        SearchAndCategorySection(
          controller: _controller,
          searchController: _searchController,
          paddingScale: paddingScale,
          iconScale: iconScale,
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
                  cartItems: _controller.cartItems,
                  subtotal: _controller.subtotal,
                  tax: _controller.tax,
                  total: _controller.total,
                  onRemoveItem: _controller.removeFromCart,
                  onUpdateQuantity: _controller.updateQuantity,
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
    );
  }
}

