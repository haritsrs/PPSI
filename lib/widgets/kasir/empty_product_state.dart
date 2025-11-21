import 'package:flutter/material.dart';
import '../../controllers/kasir_controller.dart';

class EmptyProductState extends StatelessWidget {
  final KasirController controller;
  final VoidCallback onAddProduct;
  final double paddingScale;
  final double iconScale;

  const EmptyProductState({
    super.key,
    required this.controller,
    required this.onAddProduct,
    required this.paddingScale,
    required this.iconScale,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: 16 * paddingScale),
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
              controller.products.isEmpty ? "Belum ada produk" : "Tidak ada produk yang cocok",
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 8 * paddingScale),
            if (controller.products.isEmpty)
              ElevatedButton.icon(
                onPressed: onAddProduct,
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
          ],
        ),
      ),
    );
  }
}

