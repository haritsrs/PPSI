import 'package:flutter/material.dart';
import '../../services/product_controller.dart';
import '../summary_card.dart';

class ProductSummarySection extends StatelessWidget {
  final ProductController controller;

  const ProductSummarySection({
    super.key,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: SummaryCard(
                title: "Total Produk",
                value: controller.totalProducts.toDouble(),
                icon: Icons.inventory_2_rounded,
                color: const Color(0xFF3B82F6),
                isCurrency: false,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: SummaryCard(
                title: "Stok Rendah",
                value: controller.lowStockCount.toDouble(),
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
              child: SummaryCard(
                title: "Stok Habis",
                value: controller.outOfStockCount.toDouble(),
                icon: Icons.inventory_rounded,
                color: const Color(0xFFEF4444),
                isCurrency: false,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: SummaryCard(
                title: "Nilai Stok",
                value: controller.totalStockValue,
                icon: Icons.attach_money_rounded,
                color: const Color(0xFF10B981),
                isCurrency: true,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

