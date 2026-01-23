import 'package:flutter/material.dart';
import '../../models/product_model.dart';
import '../../utils/responsive_helper.dart';

class ProductListItem extends StatefulWidget {
  final Product product;
  final VoidCallback onAddToCart;
  final VoidCallback? onIncrement;
  final VoidCallback? onDecrement;
  final int quantity;
  final double paddingScale;
  final double iconScale;

  const ProductListItem({
    super.key,
    required this.product,
    required this.onAddToCart,
    this.onIncrement,
    this.onDecrement,
    this.quantity = 0,
    required this.paddingScale,
    required this.iconScale,
  });

  @override
  State<ProductListItem> createState() => _ProductListItemState();
}

class _ProductListItemState extends State<ProductListItem>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.98,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isOutOfStock = widget.product.stock <= 0;
    final fontSize = ResponsiveHelper.getFontScale(context);
    
    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) => _controller.reverse(),
      onTapCancel: () => _controller.reverse(),
      onTap: isOutOfStock ? null : widget.onAddToCart,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Opacity(
          opacity: isOutOfStock ? 0.6 : 1.0,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
              border: Border.all(
                color: isOutOfStock
                    ? Colors.red.withOpacity(0.18)
                    : const Color(0xFFE5E7EB),
                width: 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  height: 140,
                  margin: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3F4F6),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(
                      widget.product.image.isNotEmpty
                          ? widget.product.image
                          : '📦',
                      style: const TextStyle(fontSize: 56),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                        Text(
                          widget.product.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF111827),
                            fontSize: 15,
                            height: 1.3,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Rp ${widget.product.price.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')}',
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF545BFF),
                            fontSize: 20,
                            letterSpacing: -0.3,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: isOutOfStock
                                    ? Colors.red.withOpacity(0.12)
                                    : widget.product.stock > 10
                                        ? Colors.green.withOpacity(0.12)
                                        : Colors.orange.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                isOutOfStock
                                    ? 'Habis'
                                    : widget.product.stock > 10
                                        ? 'Stok: ${widget.product.stock}'
                                        : '${widget.product.stock}',
                                style: TextStyle(
                                  color: isOutOfStock
                                      ? Colors.red[700]
                                      : widget.product.stock > 10
                                          ? Colors.green[700]
                                          : Colors.orange[700],
                                  fontWeight: FontWeight.w700,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                            if (!isOutOfStock)
                              widget.quantity > 0
                                  ? Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        GestureDetector(
                                          onTap: widget.onDecrement,
                                          child: Container(
                                            padding: const EdgeInsets.all(6),
                                            decoration: BoxDecoration(
                                              color: Colors.white,
                                              borderRadius: BorderRadius.circular(8),
                                              border: Border.all(color: Colors.red.withOpacity(0.3)),
                                            ),
                                            child: Icon(Icons.remove_rounded, color: Colors.red[700], size: 16),
                                          ),
                                        ),
                                        Container(
                                          margin: const EdgeInsets.symmetric(horizontal: 8),
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFEEF2FF),
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Text(
                                            '${widget.quantity}',
                                            style: const TextStyle(
                                              color: Color(0xFF3B42F6),
                                              fontWeight: FontWeight.w800,
                                              fontSize: 15,
                                            ),
                                          ),
                                        ),
                                        GestureDetector(
                                          onTap: widget.onIncrement,
                                          child: Container(
                                            padding: const EdgeInsets.all(6),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFF545BFF),
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: const Icon(Icons.add_rounded, color: Colors.white, size: 16),
                                          ),
                                        ),
                                      ],
                                    )
                                  : Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF545BFF),
                                        borderRadius: BorderRadius.circular(10),
                                        boxShadow: [
                                          BoxShadow(
                                            color: const Color(0xFF545BFF).withOpacity(0.28),
                                            blurRadius: 12,
                                            offset: const Offset(0, 6),
                                          ),
                                        ],
                                      ),
                                      child: const Icon(Icons.add_rounded, color: Colors.white, size: 20),
                                    ),
                          ],
                        ),
                    ],
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


