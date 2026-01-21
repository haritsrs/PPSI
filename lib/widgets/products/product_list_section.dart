import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../controllers/product_controller.dart';
import '../../models/product_model.dart';
import 'product_card.dart';
import 'product_dismissible_background.dart';

class ProductListSection extends StatelessWidget {
  final ProductController controller;
  final ScrollController scrollController;
  final VoidCallback onAddProduct;
  final VoidCallback onBulkUpdate;
  final Function(Product) onProductTap;
  final Function(Product) onEditProduct;
  final Function(Product) onDeleteProduct;
  final Function(Product) onEditStock;

  const ProductListSection({
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
    return Container(
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
                "Daftar Produk (${controller.filteredProducts.length})",
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
                      onBulkUpdate();
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
                      onAddProduct();
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
          controller.filteredProducts.isEmpty
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
                          controller.products.isEmpty
                              ? "Belum ada produk"
                              : "Tidak ada produk yang cocok",
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                color: Colors.grey[600],
                                fontWeight: FontWeight.w500,
                              ),
                          textAlign: TextAlign.center,
                        ),
                        if (controller.products.isEmpty) ...[
                          const SizedBox(height: 8),
                          ElevatedButton.icon(
                            onPressed: onAddProduct,
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
                  itemCount: controller.filteredProducts.length,
                  itemBuilder: (context, index) {
                    final product = controller.filteredProducts[index];
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
                        background: ProductDismissibleBackground(
                          color: Colors.blue.shade100,
                          icon: Icons.edit_rounded,
                          alignment: Alignment.centerLeft,
                          label: 'Edit',
                        ),
                        secondaryBackground: ProductDismissibleBackground(
                          color: Colors.red.shade100,
                          icon: Icons.delete_rounded,
                          alignment: Alignment.centerRight,
                          label: 'Hapus',
                        ),
                        confirmDismiss: (direction) async {
                          if (direction == DismissDirection.startToEnd) {
                            onEditProduct(product);
                          } else {
                            onDeleteProduct(product);
                          }
                          return false;
                        },
                        child: ProductCard(
                          product: product,
                          onTap: () => onProductTap(product),
                          onEdit: () => onEditProduct(product),
                          onDelete: () => onDeleteProduct(product),
                          onEditStock: () => onEditStock(product),
                        ),
                      ),
                    );
                  },
                ),
          if (controller.isPaginating)
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
          else if (!controller.hasMore && controller.filteredProducts.isNotEmpty)
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
    );
  }
}


