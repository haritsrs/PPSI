import '../utils/security_utils.dart';

/// Transaction model for reports page
class Transaction {
  final String id;
  final DateTime date;
  final String customerName;
  final int items;
  final double total;
  final String paymentMethod;
  final String status;

  Transaction({
    required this.id,
    required this.date,
    required this.customerName,
    required this.items,
    required this.total,
    required this.paymentMethod,
    required this.status,
  });

  factory Transaction.fromFirebase(Map<String, dynamic> data) {
    // Parse date from ISO string or timestamp
    DateTime date;
    if (data['createdAt'] != null) {
      try {
        date = DateTime.parse(data['createdAt'] as String);
      } catch (e) {
        date = DateTime.now();
      }
    } else {
      date = DateTime.now();
    }

    // Get items count
    final itemsList = data['items'] as List<dynamic>? ?? [];
    final itemsCount = itemsList.length;

    // Get customer name (if available, otherwise use default)
    final encryptionHelper = EncryptionHelper();
    String customerName = 'Pelanggan';
    if (data['customerName'] is String) {
      final rawName = data['customerName'] as String;
      if (data['customerNameEncrypted'] == true) {
        customerName = encryptionHelper.decryptIfPossible(rawName) ?? 'Pelanggan';
      } else {
        customerName = SecurityUtils.sanitizeInput(rawName);
      }
    }

    // Get payment method
    final paymentMethod = SecurityUtils.sanitizeInput(data['paymentMethod'] as String? ?? 'Cash');

    // Get total
    final total = (data['total'] as num?)?.toDouble() ?? 0.0;

    return Transaction(
      id: data['id'] as String? ?? data['key'] as String? ?? '',
      date: date,
      customerName: customerName,
      items: itemsCount,
      total: total,
      paymentMethod: paymentMethod,
      status: 'Selesai', // Default status
    );
  }
}

