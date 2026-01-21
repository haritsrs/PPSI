import 'package:flutter/material.dart';
import '../models/transaction_model.dart';
import '../services/database_service.dart';
import '../utils/home_utils.dart';

/// Reusable transaction detail modal widget
class TransactionDetailModal extends StatefulWidget {
  final Transaction transaction;
  final Map<String, dynamic>? fullTransactionData;
  final VoidCallback? onPrint;
  final DatabaseService databaseService;
  final VoidCallback? onCancelled;

  const TransactionDetailModal({
    super.key,
    required this.transaction,
    this.fullTransactionData,
    this.onPrint,
    required this.databaseService,
    this.onCancelled,
  });

  static void show(
    BuildContext context, {
    required Transaction transaction,
    Map<String, dynamic>? fullTransactionData,
    VoidCallback? onPrint,
    required DatabaseService databaseService,
    VoidCallback? onCancelled,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => TransactionDetailModal(
        transaction: transaction,
        fullTransactionData: fullTransactionData,
        onPrint: onPrint,
        databaseService: databaseService,
        onCancelled: onCancelled,
      ),
    );
  }

  @override
  State<TransactionDetailModal> createState() => _TransactionDetailModalState();
}

class _TransactionDetailModalState extends State<TransactionDetailModal> {
  bool _isLoading = false;
  String _currentStatus = '';

  @override
  void initState() {
    super.initState();
    _currentStatus = widget.transaction.status;
  }

  List<Map<String, dynamic>> _getItemsList() {
    if (widget.fullTransactionData == null) return [];
    final items = widget.fullTransactionData!['items'];
    if (items is List) {
      return items.map((e) {
        if (e is Map) {
          // Convert any Map type (including LinkedMap from Firebase) to Map<String, dynamic>
          return Map<String, dynamic>.from(e);
        }
        return <String, dynamic>{};
      }).toList();
    }
    return [];
  }

  String _formatItemPrice(double price) {
    return 'Rp ${price.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')}';
  }

  Future<void> _cancelTransaction() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.warning_rounded, color: Colors.orange),
            SizedBox(width: 8),
            Text('Batalkan Transaksi'),
          ],
        ),
        content: const Text(
            'Apakah Anda yakin ingin membatalkan transaksi ini? Stok produk akan dikembalikan.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Ya, Batalkan'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() {
      _isLoading = true;
    });

    try {
      await widget.databaseService.cancelTransaction(widget.transaction.id);
      if (mounted) {
        setState(() {
          _currentStatus = 'Dibatalkan';
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Transaksi berhasil dibatalkan'),
            backgroundColor: Colors.green,
          ),
        );
        widget.onCancelled?.call();
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final canCancel = _currentStatus != 'Dibatalkan' && _currentStatus != 'Dikembalikan';

    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: Column(
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.all(24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Detail Transaksi",
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF1F2937),
                      ),
                ),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.grey.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.close_rounded,
                      color: Colors.grey,
                      size: 20,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Transaction Details
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildDetailRow("ID Transaksi", widget.transaction.id),
                    _buildDetailRow("Tanggal", formatDateTime(widget.transaction.date)),
                    _buildDetailRow("Pelanggan", widget.transaction.customerName),
                    _buildItemsList(),
                    _buildDetailRow("Metode Pembayaran", widget.transaction.paymentMethod),
                    _buildDetailRow("Status", _currentStatus),
                    const SizedBox(height: 16),
                    Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        Text(
                          "Total Transaksi",
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                color: Colors.white70,
                                fontWeight: FontWeight.w500,
                              ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Rp ${formatCurrency(widget.transaction.total)}',
                          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                      ],
                    ),
                  ),

                    const SizedBox(height: 24),

                    // Action Buttons
                    Row(
                      children: [
                        if (widget.onPrint != null)
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: widget.onPrint,
                              icon: const Icon(Icons.print_rounded),
                              label: const Text('Cetak'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF6366F1),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ),
                        if (canCancel && widget.onPrint != null) const SizedBox(width: 12),
                        if (canCancel)
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: _isLoading ? null : _cancelTransaction,
                              icon: _isLoading
                                  ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                      ),
                                    )
                                  : const Icon(Icons.cancel_rounded),
                              label: const Text('Batalkan'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Colors.grey,
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              color: Color(0xFF1F2937),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItemsList() {
    final items = _getItemsList();
    if (items.isEmpty) {
      return _buildDetailRow("Jumlah Item", "${widget.transaction.items} item");
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Daftar Item",
            style: TextStyle(
              color: Colors.grey,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(8),
            ),
            padding: const EdgeInsets.all(12),
            child: Column(
              children: items.asMap().entries.map((entry) {
                final item = entry.value;
                final isLast = entry.key == items.length - 1;
                final name = item['name'] ?? item['productName'] ?? 'Item';
                final qty = item['quantity'] ?? 1;
                final price = (item['price'] ?? item['subtotal'] ?? 0).toDouble();
                final subtotal = price * qty;
                final isCustom = item['isCustom'] == true;

                return Column(
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                name,
                                style: TextStyle(
                                  color: const Color(0xFF1F2937),
                                  fontWeight: FontWeight.w600,
                                  fontStyle: isCustom ? FontStyle.italic : FontStyle.normal,
                                ),
                              ),
                              Text(
                                '${_formatItemPrice(price)} x $qty',
                                style: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          _formatItemPrice(subtotal),
                          style: const TextStyle(
                            color: Color(0xFF1F2937),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    if (!isLast)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Divider(height: 1, color: Colors.grey.shade300),
                      ),
                  ],
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}


