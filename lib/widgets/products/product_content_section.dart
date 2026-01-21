import 'package:flutter/material.dart';
import '../../controllers/product_controller.dart';
import '../../models/product_model.dart';
import 'product_search_filter_section.dart';
import 'product_summary_section.dart';
import 'product_list_section.dart';
import 'product_status_banner.dart';

class ProductContentSection extends StatelessWidget {
  final ProductController controller;
  final ScrollController scrollController;
  final VoidCallback onAddProduct;
  final VoidCallback onBulkUpdate;
  final Function(Product) onProductTap;
  final Function(Product) onEditProduct;
  final Function(Product) onDeleteProduct;
  final Function(Product) onEditStock;

  const ProductContentSection({
    super.key,
    required this.controller,
    required this.scrollController,
    required this.onAddProduct,
    required this.onBulkUpdate,
    required this.onProductTap,
    required this.onEditProduct,
    required this.onDeleteProduct,
    required this.onEditStock,
  });

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: controller.refreshProducts,
      color: const Color(0xFF6366F1),
      displacement: 48,
      child: SingleChildScrollView(
        key: const ValueKey('products-content'),
        controller: scrollController,
        physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (controller.isOffline)
              ProductStatusBanner(
                color: Colors.orange,
                icon: Icons.wifi_off_rounded,
                message: 'Anda sedang offline. Beberapa data mungkin tidak terbaru.',
                trailing: TextButton(
                  onPressed: controller.isRetrying ? null : controller.retryLoadProducts,
                  child: Text(
                    'Segarkan',
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: Colors.orange[700],
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ),
              ),
            if (controller.showInlineErrorBanner)
              ProductStatusBanner(
                color: Colors.red,
                icon: Icons.error_outline_rounded,
                message: controller.errorMessage ?? 'Terjadi kesalahan.',
                trailing: TextButton(
                  onPressed: controller.isRetrying ? null : controller.retryLoadProducts,
                  child: Text(
                    'Coba Lagi',
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: Colors.red[600],
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ),
              ),
            if (controller.isRetrying && controller.hasLoadedOnce)
              ProductStatusBanner(
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
            ProductSearchFilterSection(controller: controller),
            const SizedBox(height: 24),
            ProductSummarySection(controller: controller),
            const SizedBox(height: 24),
            ProductListSection(
              controller: controller,
              scrollController: scrollController,
              onAddProduct: onAddProduct,
              onBulkUpdate: onBulkUpdate,
              onProductTap: onProductTap,
              onEditProduct: onEditProduct,
              onDeleteProduct: onDeleteProduct,
              onEditStock: onEditStock,
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}


