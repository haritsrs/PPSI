import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/custom_item_model.dart';
import '../../utils/currency_input_formatter.dart';

/// Dialog for adding custom items with user-defined name, price, and quantity
class CustomItemDialog extends StatefulWidget {
  final Function(CustomItem) onAdd;

  const CustomItemDialog({
    super.key,
    required this.onAdd,
  });

  /// Show the dialog and return the created CustomItem (if any)
  static Future<CustomItem?> show(BuildContext context, {required Function(CustomItem) onAdd}) {
    return showDialog<CustomItem>(
      context: context,
      builder: (context) => CustomItemDialog(onAdd: onAdd),
    );
  }

  @override
  State<CustomItemDialog> createState() => _CustomItemDialogState();
}

class _CustomItemDialogState extends State<CustomItemDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _priceController = TextEditingController();
  final _quantityController = TextEditingController(text: '1');

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _quantityController.dispose();
    super.dispose();
  }

  void _handleAdd() {
    if (_formKey.currentState?.validate() ?? false) {
      // Parse price (remove dots used as thousand separators)
      final priceText = _priceController.text.replaceAll('.', '');
      final price = double.tryParse(priceText) ?? 0;
      final quantity = int.tryParse(_quantityController.text) ?? 1;

      final customItem = CustomItem(
        id: 'custom_${DateTime.now().millisecondsSinceEpoch}',
        name: _nameController.text.trim(),
        price: price,
        quantity: quantity,
      );

      widget.onAdd(customItem);
      Navigator.of(context).pop(customItem);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF6366F1).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.add_shopping_cart_rounded,
              color: Color(0xFF6366F1),
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          const Text('Tambah Item Custom'),
        ],
      ),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Nama Item *',
                  hintText: 'Contoh: Jasa Service',
                  prefixIcon: Icon(Icons.label_outline),
                  border: OutlineInputBorder(),
                ),
                textCapitalization: TextCapitalization.words,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Nama item harus diisi';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _priceController,
                decoration: const InputDecoration(
                  labelText: 'Harga *',
                  hintText: 'Contoh: 50.000',
                  prefixIcon: Icon(Icons.attach_money),
                  prefixText: 'Rp ',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  CurrencyInputFormatter(),
                ],
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Harga harus diisi';
                  }
                  final price = double.tryParse(value.replaceAll('.', '')) ?? 0;
                  if (price <= 0) {
                    return 'Harga harus lebih dari 0';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _quantityController,
                decoration: const InputDecoration(
                  labelText: 'Jumlah',
                  hintText: '1',
                  prefixIcon: Icon(Icons.numbers),
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                validator: (value) {
                  if (value != null && value.isNotEmpty) {
                    final qty = int.tryParse(value) ?? 0;
                    if (qty <= 0) {
                      return 'Jumlah harus lebih dari 0';
                    }
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Batal'),
        ),
        ElevatedButton.icon(
          onPressed: _handleAdd,
          icon: const Icon(Icons.add, size: 18),
          label: const Text('Tambah'),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF6366F1),
            foregroundColor: Colors.white,
          ),
        ),
      ],
    );
  }
}

