import 'package:flutter/material.dart';
import '../../models/cart_item_model.dart';
import '../../utils/responsive_helper.dart';

class CartItemCard extends StatelessWidget {
  final CartItem item;
  final VoidCallback onRemove;
  final Function(int) onUpdateQuantity;

  const CartItemCard({
    super.key,
    required this.item,
    required this.onRemove,
    required this.onUpdateQuantity,
  });

  @override
  Widget build(BuildContext context) {
    final paddingScale = ResponsiveHelper.getPaddingScale(context);
    final iconScale = ResponsiveHelper.getIconScale(context);
    final fontSize = ResponsiveHelper.getFontScale(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 768;
    
    return Container(
      margin: EdgeInsets.only(bottom: 8 * paddingScale),
      padding: EdgeInsets.all(12 * paddingScale),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.grey.withOpacity(0.1),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: isMobile ? 40 : 50,
            height: isMobile ? 40 : 50,
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                item.product.image.isNotEmpty 
                    ? item.product.image 
                    : '📦',
                style: TextStyle(fontSize: isMobile ? 20 : 24),
              ),
            ),
          ),
          SizedBox(width: 8 * paddingScale),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  item.product.name,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF1F2937),
                    fontSize: (Theme.of(context).textTheme.titleSmall?.fontSize ?? 14) * fontSize,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 2 * paddingScale),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Rp ${item.product.price.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: const Color(0xFF6366F1),
                      fontWeight: FontWeight.w600,
                      fontSize: (Theme.of(context).textTheme.bodySmall?.fontSize ?? 12) * fontSize,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              GestureDetector(
                onTap: () => onUpdateQuantity(item.quantity - 1),
                child: Container(
                  width: 28 * paddingScale,
                  height: 28 * paddingScale,
                  decoration: BoxDecoration(
                    color: const Color(0xFF6366F1).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.remove_rounded,
                    color: const Color(0xFF6366F1),
                    size: 14 * iconScale,
                  ),
                ),
              ),
              SizedBox(width: 8 * paddingScale),
              Text(
                item.quantity.toString(),
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF1F2937),
                  fontSize: (Theme.of(context).textTheme.titleMedium?.fontSize ?? 16) * fontSize,
                ),
              ),
              SizedBox(width: 8 * paddingScale),
              GestureDetector(
                onTap: () => onUpdateQuantity(item.quantity + 1),
                child: Container(
                  width: 28 * paddingScale,
                  height: 28 * paddingScale,
                  decoration: BoxDecoration(
                    color: const Color(0xFF6366F1).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.add_rounded,
                    color: const Color(0xFF6366F1),
                    size: 14 * iconScale,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(width: 8 * paddingScale),
          GestureDetector(
            onTap: onRemove,
            child: Container(
              width: 28 * paddingScale,
              height: 28 * paddingScale,
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.delete_rounded,
                color: Colors.red,
                size: 14 * iconScale,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

