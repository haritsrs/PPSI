import 'package:flutter/material.dart';
import '../../controllers/kasir_controller.dart';

class CartFAB extends StatelessWidget {
  final KasirController controller;
  final VoidCallback onPressed;

  const CartFAB({
    super.key,
    required this.controller,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    if (controller.cartItems.isEmpty) return const SizedBox.shrink();

    return FloatingActionButton.extended(
      onPressed: onPressed,
      backgroundColor: const Color(0xFF6366F1),
      icon: Stack(
        children: [
          const Icon(Icons.shopping_cart_rounded, color: Colors.white),
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
                '${controller.cartItems.length}',
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
        'Keranjang (${controller.cartItems.length})',
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

