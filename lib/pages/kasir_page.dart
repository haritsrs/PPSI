import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/kasir_controller.dart';
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
  final FocusNode _barcodeFocusNode = FocusNode(skipTraversal: true, debugLabel: 'barcodeScanner');
  final FocusNode _searchFocusNode = FocusNode(debugLabel: 'searchField');
  final FocusNode _testBarcodeFocusNode = FocusNode(debugLabel: 'testBarcodeScanner');
  late KasirController _controller;
  DateTime? _lastSearchInputTime;
  String _lastSearchValue = '';
  Timer? _testBarcodeProcessTimer;
  Timer? _searchBarcodeTimer;
  bool _testModeEnabled = false; // Disable test mode - use automatic barcode scanning
  bool _barcodeScannerEnabled = true; // Barcode scanner listening toggle

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
    
    // Add listener to search focus node to refocus barcode scanner when search loses focus
    _searchFocusNode.addListener(() {
      if (!_searchFocusNode.hasFocus && mounted && !_testModeEnabled && _barcodeScannerEnabled) {
        // Search field lost focus, refocus barcode scanner (only if not in test mode and scanner enabled)
        Future.delayed(const Duration(milliseconds: 150), () {
          if (mounted && !_testModeEnabled && _barcodeScannerEnabled) {
            _refocusScanner();
          }
        });
      }
    });
    
    // Add listener to barcode focus node to maintain focus automatically
    _barcodeFocusNode.addListener(() {
      if (!_barcodeFocusNode.hasFocus && mounted && !_testModeEnabled && _barcodeScannerEnabled) {
        // Barcode scanner lost focus, refocus it automatically (only if scanner enabled)
        Future.delayed(const Duration(milliseconds: 100), () {
          if (mounted && !_testModeEnabled && _barcodeScannerEnabled && !_searchFocusNode.hasFocus && !_testBarcodeFocusNode.hasFocus) {
            _barcodeFocusNode.requestFocus();
          }
        });
      }
    });
    
    // Add listener to search controller to detect barcode scanner input
    // Barcode scanners send input very rapidly (all characters in quick succession)
    Timer? _searchBarcodeTimer;
    _searchController.addListener(() {
      if (!_testModeEnabled) {
        // Only process barcode in search field if test mode is disabled
        final currentValue = _searchController.text;
        final now = DateTime.now();
        
        // If search field has focus and input is coming in rapidly, it might be a barcode scanner
        if (_searchFocusNode.hasFocus && _lastSearchInputTime != null) {
          final timeSinceLastInput = now.difference(_lastSearchInputTime!);
          // If characters are coming in faster than 50ms apart, it's likely a barcode scanner
          if (timeSinceLastInput < const Duration(milliseconds: 50) && 
              currentValue.length > _lastSearchValue.length) {
            // Cancel previous timer
            _searchBarcodeTimer?.cancel();
            
            // Wait for input to settle (barcode scanners send all chars quickly)
            _searchBarcodeTimer = Timer(const Duration(milliseconds: 500), () {
              if (mounted && !_testModeEnabled) {
                final fullBarcode = _searchController.text.trim();
                if (fullBarcode.isNotEmpty && fullBarcode.length >= 3) {
                  // Process the complete barcode
                  _controller.setBarcodeBuffer(fullBarcode);
                  Future.delayed(const Duration(milliseconds: 50), () {
                    if (mounted) {
                      final product = _controller.handleBarcodeEnter();
                      if (product != null) {
                        HapticHelper.lightImpact();
                        // Clear search field and refocus barcode scanner
                        _searchController.clear();
                        _searchFocusNode.unfocus();
                        _refocusScanner();
                      }
                    }
                  });
                }
              }
            });
          }
        }
        
        _lastSearchInputTime = now;
        _lastSearchValue = currentValue;
      }
    });
    
    // Setup test barcode input field listener - simplified approach
    _testBarcodeController.addListener(() {
      if (!_testModeEnabled) return;
      
      final currentValue = _testBarcodeController.text;
      
      // Cancel previous timer
      _testBarcodeProcessTimer?.cancel();
      
      if (currentValue.isEmpty) {
        // Field cleared
        _controller.clearBarcodeBuffer();
        return;
      }
      
      // Wait for input to settle (barcode scanners send all chars quickly)
      _testBarcodeProcessTimer = Timer(const Duration(milliseconds: 300), () {
        if (mounted && _testModeEnabled) {
          final fullBarcode = _testBarcodeController.text.trim();
          if (fullBarcode.isNotEmpty && fullBarcode.length >= 3) {
            // Set the complete barcode and process it
            _controller.setBarcodeBuffer(fullBarcode);
            final product = _controller.handleBarcodeEnter();
            
            if (product != null) {
              HapticHelper.lightImpact();
              // Clear test field after successful scan
              _testBarcodeController.clear();
              _refocusTestScanner();
            }
          }
        }
      });
    });
    
    _animationController.forward();
    // Ensure barcode scanner gets focus immediately for automatic scanning
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        if (_testModeEnabled) {
          _refocusTestScanner();
        } else if (_barcodeScannerEnabled) {
          // Give focus to barcode scanner immediately for automatic scanning (only if enabled)
          Future.delayed(const Duration(milliseconds: 200), () {
            if (mounted && !_testModeEnabled && _barcodeScannerEnabled) {
              _barcodeFocusNode.requestFocus();
            }
          });
        }
      }
    });
  }
  
  void _refocusTestScanner() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _testModeEnabled) {
        _testBarcodeFocusNode.requestFocus();
      }
    });
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
    _barcodeFocusNode.dispose();
    _searchFocusNode.dispose();
    _testBarcodeFocusNode.dispose();
    _testBarcodeProcessTimer?.cancel();
    _searchBarcodeTimer?.cancel();
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
      if (mounted && !_testModeEnabled && _barcodeScannerEnabled) {
        // Only refocus if test mode is disabled and scanner is enabled
        // Request focus with delay to ensure other widgets have processed their events
        Future.delayed(const Duration(milliseconds: 50), () {
          if (mounted && !_testModeEnabled && _barcodeScannerEnabled && !_searchFocusNode.hasFocus) {
            _barcodeFocusNode.requestFocus();
          }
        });
      }
    });
  }

  void _handleRawKeyEvent(RawKeyEvent event) {
    if (event is! RawKeyDownEvent) return;

    // If barcode scanner is disabled, ignore barcode input
    if (!_barcodeScannerEnabled) {
      return;
    }

    final logicalKey = event.logicalKey;

    // If search field has focus, only handle Enter key for barcode completion
    // All other input goes to the search field
    if (_searchFocusNode.hasFocus) {
      if (logicalKey == LogicalKeyboardKey.enter || logicalKey == LogicalKeyboardKey.numpadEnter) {
        // Enter key pressed in search field - check if we have barcode buffer
        if (_controller.barcodeBuffer.isNotEmpty) {
          final product = _controller.handleBarcodeEnter();
          if (product != null) {
            HapticHelper.lightImpact();
            // Clear search and refocus scanner
            _searchController.clear();
            _searchFocusNode.unfocus();
            if (_barcodeScannerEnabled) {
              _refocusScanner();
            }
          }
        }
      }
      // For all other keys when search has focus, let TextField handle them
      return;
    }

    // Process barcode scanner input when barcode focus node has focus
    // This is the main handler for barcode scanning

    // Handle Enter key - complete barcode scan
    if (logicalKey == LogicalKeyboardKey.enter || logicalKey == LogicalKeyboardKey.numpadEnter) {
      if (_controller.barcodeBuffer.isNotEmpty) {
        final product = _controller.handleBarcodeEnter();
        if (product != null) {
          HapticHelper.lightImpact();
        }
      }
      if (_barcodeScannerEnabled) {
        _refocusScanner();
      }
      return;
    }

    // Handle backspace - remove last character from barcode buffer
    if (logicalKey == LogicalKeyboardKey.backspace) {
      _controller.handleBarcodeBackspace();
      return;
    }

    // Handle character input - add to barcode buffer
    final character = event.character;
    if (character != null && character.isNotEmpty) {
      final codeUnit = character.codeUnitAt(0);
      // Accept printable characters (32-126), excluding DEL (127)
      if (codeUnit >= 32 && codeUnit != 127) {
        _controller.handleBarcodeCharacter(character);
        // Wait a bit for more characters (barcode scanners send them rapidly)
        // Then check if buffer matches a product
        Future.delayed(const Duration(milliseconds: 300), () {
          if (mounted && _barcodeScannerEnabled) {
            final found = _controller.checkBarcodeBuffer();
            if (found) {
              HapticHelper.lightImpact();
            }
            if (_barcodeScannerEnabled) {
              _refocusScanner();
            }
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
    // Unfocus scanner before showing dialog to prevent conflicts
    _barcodeFocusNode.unfocus();
    
    BarcodeScannerInstructionsDialog.show(context).then((_) {
      // Refocus scanner after dialog closes
      if (mounted) {
        Future.delayed(const Duration(milliseconds: 100), () {
          if (mounted) {
            _refocusScanner();
          }
        });
      }
    });
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
                    setState(() {
                      _barcodeScannerEnabled = !_barcodeScannerEnabled;
                      if (_barcodeScannerEnabled) {
                        // Enable scanner - refocus barcode scanner
                        _refocusScanner();
                      } else {
                        // Disable scanner - unfocus barcode scanner
                        _barcodeFocusNode.unfocus();
                      }
                    });
                  },
                  icon: Icon(
                    _barcodeScannerEnabled ? Icons.qr_code_scanner_rounded : Icons.qr_code_scanner_outlined,
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
                  child: _buildDesktopLayout(context, paddingScale, iconScale),
                ),
              ),
            )
          : Focus(
              autofocus: true,
              canRequestFocus: true,
              skipTraversal: true,
              onFocusChange: (hasFocus) {
                // Automatically maintain focus for barcode scanning (only if enabled)
                if (!hasFocus && mounted && !_testModeEnabled && _barcodeScannerEnabled && !_searchFocusNode.hasFocus) {
                  Future.delayed(const Duration(milliseconds: 50), () {
                    if (mounted && !_testModeEnabled && _barcodeScannerEnabled && !_searchFocusNode.hasFocus) {
                      _barcodeFocusNode.requestFocus();
                    }
                  });
                }
              },
              child: RawKeyboardListener(
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
                          _refocusScanner();
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
                    _refocusTestScanner();
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
      ),
    );
  }
}

