import 'package:flutter/material.dart';
import '../../../models/product_model.dart';
import '../../../services/database_service.dart';
import '../../../utils/security_utils.dart';

class BulkStockUpdateDialog extends StatefulWidget {
  final List<Product> products;
  final DatabaseService databaseService;
  final VoidCallback onSaved;

  const BulkStockUpdateDialog({
    super.key,
    required this.products,
    required this.databaseService,
    required this.onSaved,
  });

  @override
  State<BulkStockUpdateDialog> createState() => _BulkStockUpdateDialogState();
}

class _BulkStockUpdateDialogState extends State<BulkStockUpdateDialog> {
  final Map<String, TextEditingController> _stockControllers = {};
  final Map<String, bool> _selectedProducts = {};
  String _selectedReason = 'Bulk Update';
  final TextEditingController _notesController = TextEditingController();
  bool _isLoading = false;

  final List<String> _adjustmentReasons = [
    'Bulk Update',
    'Stock Opname',
    'Pembelian',
    'Retur dari Supplier',
    'Lainnya',
  ];

  @override
  void initState() {
    super.initState();
    for (final product in widget.products) {
      _stockControllers[product.id] = TextEditingController(text: product.stock.toString());
      _selectedProducts[product.id] = false;
    }
  }

  @override
  void dispose() {
    for (final controller in _stockControllers.values) {
      controller.dispose();
    }
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _saveBulkUpdate() async {
    final updates = <Map<String, String>>[];
    final sanitizedReason = SecurityUtils.sanitizeInput(_selectedReason);
    final sanitizedNotes = SecurityUtils.sanitizeInput(_notesController.text);
    
    for (final entry in _selectedProducts.entries) {
      if (entry.value) {
        final productId = entry.key;
        final controller = _stockControllers[productId];
        if (controller != null && controller.text.isNotEmpty) {
          final stockText = SecurityUtils.sanitizeNumber(controller.text).replaceAll(RegExp(r'[^0-9]'), '');
          final stock = int.tryParse(stockText);
          if (stock != null && stock >= 0) {
            updates.add({
              'productId': productId,
              'stock': stock.toString(),
              'reason': sanitizedReason.isEmpty ? 'Bulk Update' : sanitizedReason,
              'notes': sanitizedNotes,
            });
          }
        }
      }
    }

    if (updates.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pilih setidaknya satu produk untuk diupdate'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await widget.databaseService.bulkUpdateStock(updates);
      if (mounted) {
        Navigator.pop(context);
        widget.onSaved();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${updates.length} produk berhasil diupdate'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Container(
        constraints: BoxConstraints(
          maxWidth: 700,
          maxHeight: MediaQuery.of(context).size.height * 0.9,
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Update Stok Bulk",
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF1F2937),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
            const SizedBox(height: 24),
            // Reason and Notes
            DropdownButtonFormField<String>(
              value: _selectedReason,
              decoration: InputDecoration(
                labelText: 'Alasan Penyesuaian',
                prefixIcon: const Icon(Icons.info_rounded),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              items: _adjustmentReasons.map((reason) {
                return DropdownMenuItem<String>(
                  value: reason,
                  child: Text(reason),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedReason = value!;
                });
              },
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _notesController,
              decoration: InputDecoration(
                labelText: 'Catatan (Opsional)',
                hintText: 'Catatan untuk semua update',
                prefixIcon: const Icon(Icons.note_rounded),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 24),
            // Product List
            Expanded(
              child: ListView.builder(
                itemCount: widget.products.length,
                itemBuilder: (context, index) {
                  final product = widget.products[index];
                  final isSelected = _selectedProducts[product.id] ?? false;
                  final controller = _stockControllers[product.id]!;
                  
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected ? const Color(0xFF6366F1) : Colors.grey[300]!,
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Checkbox(
                          value: isSelected,
                          onChanged: (value) {
                            setState(() {
                              _selectedProducts[product.id] = value ?? false;
                            });
                          },
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                product.name,
                                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Stok saat ini: ${product.stock}',
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(
                          width: 100,
                          child: TextField(
                            controller: controller,
                            enabled: isSelected,
                            decoration: InputDecoration(
                              labelText: 'Stok Baru',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            ),
                            keyboardType: TextInputType.number,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Batal'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _saveBulkUpdate,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6366F1),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Text('Simpan Update'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}


