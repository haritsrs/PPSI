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
            margin: EdgeInsets.only(bottom: 12 * widget.paddingScale),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
              border: Border.all(
                color: isOutOfStock 
                    ? Colors.red.withOpacity(0.2)
                    : Colors.grey.withOpacity(0.1),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(12),
                      bottomLeft: Radius.circular(12),
                    ),
                  ),
                  child: Center(
                    child: Text(
                      widget.product.image.isNotEmpty 
                          ? widget.product.image 
                          : '📦',
                      style: const TextStyle(fontSize: 64),
                    ),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.all(16 * widget.paddingScale),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          widget.product.name,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF1F2937),
                            fontSize: 16 * fontSize,
                            height: 1.3,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: 8 * widget.paddingScale),
                        Text(
                          'Rp ${widget.product.price.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')}',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF6366F1),
                            fontSize: 20 * fontSize,
                          ),
                        ),
                        SizedBox(height: 8 * widget.paddingScale),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 10 * widget.paddingScale,
                                vertical: 6 * widget.paddingScale,
                              ),
                              decoration: BoxDecoration(
                                color: isOutOfStock
                                    ? Colors.red.withOpacity(0.1)
                                    : widget.product.stock > 10 
                                        ? Colors.green.withOpacity(0.1)
                                        : Colors.orange.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                isOutOfStock 
                                    ? 'Habis'
                                    : 'Stok: ${widget.product.stock}',
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: isOutOfStock
                                      ? Colors.red[700]
                                      : widget.product.stock > 10 
                                          ? Colors.green[700]
                                          : Colors.orange[700],
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13 * fontSize,
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
                                            padding: EdgeInsets.all(8 * widget.paddingScale),
                                            decoration: BoxDecoration(
                                              color: Colors.red.withOpacity(0.1),
                                              borderRadius: BorderRadius.circular(8),
                                              border: Border.all(
                                                color: Colors.red.withOpacity(0.3),
                                                width: 1,
                                              ),
                                            ),
                                            child: Icon(
                                              Icons.remove_rounded,
                                              color: Colors.red[700],
                                              size: 20 * widget.iconScale,
                                            ),
                                          ),
                                        ),
                                        Container(
                                          margin: EdgeInsets.symmetric(horizontal: 8 * widget.paddingScale),
                                          padding: EdgeInsets.symmetric(
                                            horizontal: 12 * widget.paddingScale,
                                            vertical: 6 * widget.paddingScale,
                                          ),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFF6366F1).withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(8),
                                            border: Border.all(
                                              color: const Color(0xFF6366F1).withOpacity(0.3),
                                              width: 1,
                                            ),
                                          ),
                                          child: Text(
                                            '${widget.quantity}',
                                            style: TextStyle(
                                              color: const Color(0xFF6366F1),
                                              fontWeight: FontWeight.w700,
                                              fontSize: 16 * widget.paddingScale,
                                            ),
                                          ),
                                        ),
                                        GestureDetector(
                                          onTap: widget.onIncrement,
                                          child: Container(
                                            padding: EdgeInsets.all(8 * widget.paddingScale),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFF6366F1),
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: Icon(
                                              Icons.add_rounded,
                                              color: Colors.white,
                                              size: 20 * widget.iconScale,
                                            ),
                                          ),
                                        ),
                                      ],
                                    )
                                  : Container(
                                      padding: EdgeInsets.all(10 * widget.paddingScale),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF6366F1),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Icon(
                                        Icons.add_rounded,
                                        color: Colors.white,
                                        size: 24 * widget.iconScale,
                                      ),
                                    ),
                          ],
                        ),
                      ],
                    ),
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


