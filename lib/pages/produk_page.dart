import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/product_controller.dart';
import '../models/product_model.dart';
import '../utils/snackbar_helper.dart';
import '../utils/haptic_helper.dart';
import '../widgets/responsive_page.dart';
import '../widgets/loading_skeletons.dart';
import '../widgets/products/product_app_bar.dart';
import '../widgets/products/product_content_section.dart';
import '../widgets/products/product_error_state.dart';
import '../widgets/products/product_detail_modal.dart';
import '../widgets/products/product_delete_dialog.dart';
import '../widgets/products/dialogs/stock_history_dialog.dart';
import '../widgets/products/dialogs/bulk_stock_update_dialog.dart';
import '../widgets/products/dialogs/add_edit_product_dialog.dart';
import '../widgets/products/dialogs/edit_stock_dialog.dart';
import '../widgets/products/scan_barcode_dialog.dart';

class ProdukPage extends StatefulWidget {
  const ProdukPage({super.key});

  @override
  State<ProdukPage> createState() => _ProdukPageState();
}

class _ProdukPageState extends State<ProdukPage> with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  
  late ProductController _controller;
  late final ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _controller = ProductController()
      ..addListener(_onControllerChanged)
      ..initialize();
    
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
  }

  void _onControllerChanged() {
    if (mounted) setState(() {});
  }

  void _onScroll() {
    if (!_scrollController.hasClients || _controller.isPaginating || !_controller.hasMore) return;
    final position = _scrollController.position;
    if (!position.hasPixels || position.maxScrollExtent <= 0) return;
    final threshold = position.maxScrollExtent - position.pixels;
    if (threshold <= 320) {
      _controller.loadMoreProducts();
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    _controller.removeListener(_onControllerChanged);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Handle error messages
    if (_controller.errorMessage != null && !_controller.isLoading) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        SnackbarHelper.showError(context, _controller.errorMessage!);
      });
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: ProductAppBar(
        onScan: _showScanDialog,
        onAddProduct: _showAddProductDialog,
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            child: ResponsivePage(
              child: _controller.showInitialLoader
                  ? const SingleChildScrollView(
                      key: ValueKey('products-loader'),
                      physics: AlwaysScrollableScrollPhysics(),
                      child: ProductListSkeleton(),
                    )
                  : _controller.showFullErrorState
                      ? ProductErrorState(controller: _controller)
                      : ProductContentSection(
                          controller: _controller,
                          scrollController: _scrollController,
                          onAddProduct: _showAddProductDialog,
                          onBulkUpdate: _showBulkStockUpdateDialog,
                          onProductTap: _showProductDetail,
                          onEditProduct: _showEditProductDialog,
                          onDeleteProduct: _showDeleteConfirmDialog,
                          onEditStock: _showEditStockDialog,
                        ),
            ),
          ),
        ),
      ),
    );
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
        databaseService: _controller.databaseService,
      ),
    );
  }

  void _showBulkStockUpdateDialog() {
    showDialog(
      context: context,
      builder: (context) => BulkStockUpdateDialog(
        products: _controller.products,
        databaseService: _controller.databaseService,
        onSaved: () {
          _controller.refreshProducts();
          HapticHelper.lightImpact();
        },
      ),
    );
  }

  void _showAddProductDialog() {
    showDialog(
      context: context,
      builder: (context) => AddEditProductDialog(
        onSaved: () {
          _controller.refreshProducts();
          HapticHelper.lightImpact();
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
          _controller.refreshProducts();
          HapticHelper.lightImpact();
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
          _controller.refreshProducts();
          HapticHelper.lightImpact();
        },
      ),
    );
  }

  void _showDeleteConfirmDialog(Product product) {
    ProductDeleteDialog.show(context, product, _controller);
  }

  void _showScanDialog() {
    ScanBarcodeDialog.show(context);
  }
}
