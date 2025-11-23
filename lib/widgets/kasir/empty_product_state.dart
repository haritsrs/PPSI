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
      child: Padding(
        padding: EdgeInsets.all(32 * paddingScale),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.inventory_2_outlined,
              size: 80 * iconScale,
              color: Colors.grey[400],
            ),
            SizedBox(height: 24 * paddingScale),
            Text(
              'Belum ada produk',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Colors.grey[700],
                    fontWeight: FontWeight.w600,
                  ),
            ),
            SizedBox(height: 8 * paddingScale),
            Text(
              'Tambahkan produk pertama Anda untuk memulai',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 32 * paddingScale),
            ElevatedButton.icon(
              onPressed: onAddProduct,
              icon: Icon(Icons.add_rounded, size: 20 * iconScale),
              label: const Text('Tambah Produk'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6366F1),
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(
                  horizontal: 24 * paddingScale,
                  vertical: 14 * paddingScale,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

