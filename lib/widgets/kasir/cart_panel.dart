import 'package:flutter/material.dart';
import '../../models/cart_item_model.dart';
import '../../models/custom_item_model.dart';
import '../../utils/responsive_helper.dart';
import 'cart_item_card.dart';
import 'custom_item_card.dart';
import 'custom_item_dialog.dart';

class CartPanel extends StatelessWidget {
  final List<CartItem> cartItems;
  final List<CustomItem> customItems;
  final double subtotal;
  final double tax;
  final double total;
  final Function(String) onRemoveItem;
  final Function(String, int) onUpdateQuantity;
  final Function(CustomItem) onAddCustomItem;
  final Function(String) onRemoveCustomItem;
  final Function(String, int) onUpdateCustomItemQuantity;
  final VoidCallback onClearCart;
  final VoidCallback onCheckout;

  const CartPanel({
    super.key,
    required this.cartItems,
    required this.customItems,
    required this.subtotal,
    required this.tax,
    required this.total,
    required this.onRemoveItem,
    required this.onUpdateQuantity,
    required this.onAddCustomItem,
    required this.onRemoveCustomItem,
    required this.onUpdateCustomItemQuantity,
    required this.onClearCart,
    required this.onCheckout,
  });

  @override
  Widget build(BuildContext context) {
    final paddingScale = ResponsiveHelper.getPaddingScale(context);
    final iconScale = ResponsiveHelper.getIconScale(context);
    
    return Column(
      children: [
        Container(
          padding: EdgeInsets.symmetric(
            horizontal: 16 * paddingScale,
            vertical: 12 * paddingScale,
          ),
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  "Keranjang",
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 20,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (cartItems.isNotEmpty)
                GestureDetector(
                  onTap: onClearCart,
                  child: Container(
                    padding: EdgeInsets.all(6 * paddingScale),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.clear_all_rounded,
                      color: Colors.white,
                      size: 18 * iconScale,
                    ),
                  ),
                ),
            ],
          ),
        ),
        Flexible(
          child: cartItems.isEmpty && customItems.isEmpty
              ? SingleChildScrollView(
                  child: Padding(
                    padding: EdgeInsets.all(24 * paddingScale),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: EdgeInsets.all(24 * paddingScale),
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.shopping_cart_outlined,
                            size: 72 * iconScale,
                            color: Colors.grey[600],
                          ),
                        ),
                        SizedBox(height: 20 * paddingScale),
                        Text(
                          "Keranjang kosong",
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: Colors.grey[800],
                            fontWeight: FontWeight.w600,
                            fontSize: 18,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: 8 * paddingScale),
                        Text(
                          "Tambahkan produk untuk memulai transaksi",
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                )
              : ListView.builder(
                  padding: EdgeInsets.all(16 * paddingScale),
                  itemCount: cartItems.length + customItems.length,
                  itemBuilder: (context, index) {
                    if (index < cartItems.length) {
                      final item = cartItems[index];
                      return CartItemCard(
                        item: item,
                        onRemove: () => onRemoveItem(item.product.id),
                        onUpdateQuantity: (quantity) => onUpdateQuantity(item.product.id, quantity),
                      );
                    } else {
                      final customItem = customItems[index - cartItems.length];
                      return CustomItemCard(
                        item: customItem,
                        onRemove: () => onRemoveCustomItem(customItem.id),
                        onUpdateQuantity: (quantity) => onUpdateCustomItemQuantity(customItem.id, quantity),
                      );
                    }
                  },
                ),
        ),
        if (cartItems.isNotEmpty || customItems.isNotEmpty) ...[
          Container(
            padding: EdgeInsets.all(16 * paddingScale),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              border: Border(
                top: BorderSide(
                  color: Colors.grey.withOpacity(0.2),
                  width: 1,
                ),
              ),
            ),
            child: Column(
              children: [
                _buildBillRow(context, "Subtotal", subtotal, paddingScale),
                SizedBox(height: 8 * paddingScale),
                _buildTaxRow(context, tax, paddingScale),
                SizedBox(height: 12 * paddingScale),
                Container(
                  padding: EdgeInsets.symmetric(vertical: 12 * paddingScale),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: const Color(0xFF6366F1).withOpacity(0.2),
                      width: 1,
                    ),
                  ),
                  child: _buildBillRow(context, "Total", total, paddingScale, isTotal: true),
                ),
                SizedBox(height: 16 * paddingScale),
                // Add custom item button
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => CustomItemDialog.show(context, onAdd: onAddCustomItem),
                    icon: Icon(Icons.add, size: 18 * iconScale),
                    label: const Text('Tambah Item Custom'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF6366F1),
                      side: const BorderSide(color: Color(0xFF6366F1)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: EdgeInsets.symmetric(vertical: 12 * paddingScale),
                    ),
                  ),
                ),
                SizedBox(height: 12 * paddingScale),
                SizedBox(
                  width: double.infinity,
                  height: 50 * paddingScale,
                  child: ElevatedButton(
                    onPressed: onCheckout,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6366F1),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.payment_rounded, size: 18 * iconScale),
                        SizedBox(width: 8 * paddingScale),
                        Flexible(
                          child: Text(
                            "Bayar Sekarang",
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildBillRow(BuildContext context, String label, double amount, double paddingScale, {bool isTotal = false}) {
    final fontSize = ResponsiveHelper.getFontScale(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Flexible(
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: isTotal ? const Color(0xFF1F2937) : Colors.grey[600],
              fontWeight: isTotal ? FontWeight.w600 : FontWeight.w500,
              fontSize: (Theme.of(context).textTheme.bodyMedium?.fontSize ?? 14) * fontSize,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        Flexible(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerRight,
            child: Text(
              'Rp ${amount.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')}',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: isTotal ? const Color(0xFF6366F1) : const Color(0xFF1F2937),
                fontWeight: isTotal ? FontWeight.w700 : FontWeight.w600,
                fontSize: (Theme.of(context).textTheme.bodyMedium?.fontSize ?? 14) * fontSize,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTaxRow(BuildContext context, double amount, double paddingScale) {
    final fontSize = ResponsiveHelper.getFontScale(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Flexible(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "Pajak",
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                  fontSize: (Theme.of(context).textTheme.bodyMedium?.fontSize ?? 14) * fontSize,
                ),
              ),
              const SizedBox(width: 4),
              GestureDetector(
                onTap: () => _showTaxInfoDialog(context),
                child: Icon(
                  Icons.info_outline,
                  size: 16 * fontSize,
                  color: Colors.grey[500],
                ),
              ),
            ],
          ),
        ),
        Flexible(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerRight,
            child: Text(
              'Rp ${amount.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')}',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: const Color(0xFF1F2937),
                fontWeight: FontWeight.w600,
                fontSize: (Theme.of(context).textTheme.bodyMedium?.fontSize ?? 14) * fontSize,
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _showTaxInfoDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.info_outline, color: const Color(0xFF6366F1)),
            const SizedBox(width: 8),
            const Text('Informasi Pajak'),
          ],
        ),
        content: const Text(
          'Pajak dapat diaktifkan, dinonaktifkan, atau diubah tarifnya melalui menu Pengaturan → Bisnis → Pajak.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Mengerti'),
          ),
        ],
      ),
    );
  }
}


