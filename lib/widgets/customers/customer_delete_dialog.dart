import 'package:flutter/material.dart';
import '../../models/customer_model.dart';

class CustomerDeleteDialog extends StatelessWidget {
  final Customer customer;
  final Future<void> Function() onConfirm;

  const CustomerDeleteDialog({
    super.key,
    required this.customer,
    required this.onConfirm,
  });

  static Future<bool?> show(
    BuildContext context, {
    required Customer customer,
    required Future<void> Function() onConfirm,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (context) => CustomerDeleteDialog(
        customer: customer,
        onConfirm: onConfirm,
      ),
    );
  }

  Future<void> _handleDelete(BuildContext context) async {
    Navigator.of(context).pop();
    try {
      await onConfirm();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Pelanggan berhasil dihapus'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
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
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          Icon(Icons.warning_rounded, color: Colors.red[600]),
          const SizedBox(width: 8),
          const Text('Hapus Pelanggan'),
        ],
      ),
      content: Text(
        'Apakah Anda yakin ingin menghapus pelanggan "${customer.name}"? Tindakan ini tidak dapat dibatalkan.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Batal'),
        ),
        ElevatedButton(
          onPressed: () => _handleDelete(context),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
          ),
          child: const Text('Hapus'),
        ),
      ],
    );
  }
}


