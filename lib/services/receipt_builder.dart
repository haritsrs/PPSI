import 'dart:typed_data';
import 'printer_commands.dart';

/// Receipt builder for 58mm thermal printers
/// Formats receipts with proper width and layout
class ReceiptBuilder {
  static const int paperWidth = 384; // 58mm at 203 DPI
  static const int maxCharsPerLine = 32; // Approximate for 58mm

  final List<List<int>> _sections = [];

  /// Add business header
  ReceiptBuilder addHeader({
    required String storeName,
    String? address,
    String? phone,
    Uint8List? logoBytes,
  }) {
    final commands = <int>[];
    
    // Logo (if provided)
    if (logoBytes != null) {
      // Logo will be handled separately in printer_service
      // For now, just add a placeholder
    }
    
    // Dense header (left-aligned, minimal spacing)
    commands.addAll(PrinterCommands.align(TextAlign.left));
    commands.addAll(PrinterCommands.bold(true));
    commands.addAll(PrinterCommands.textLine(storeName));
    commands.addAll(PrinterCommands.bold(false));

    if (address != null && address.trim().isNotEmpty) {
      commands.addAll(PrinterCommands.textLine(address.trim()));
    }
    if (phone != null && phone.trim().isNotEmpty) {
      commands.addAll(PrinterCommands.textLine(phone.trim()));
    }
    
    _sections.add(commands);
    return this;
  }

  /// Add transaction info
  Future<ReceiptBuilder> addTransactionInfo({
    required String transactionId,
    required DateTime date,
    String? customerName,
  }) async {
    final commands = <int>[];
    
    // Format date manually to avoid locale initialization issues
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year.toString();
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    final dateString = '$day/$month/$year $hour:$minute';
    
    commands.addAll(PrinterCommands.align(TextAlign.left));
    
    // Dense transaction info
    commands.addAll(PrinterCommands.text('ID: $transactionId'));
    commands.addAll(PrinterCommands.feed());
    commands.addAll(PrinterCommands.text('Tgl: $dateString'));
    commands.addAll(PrinterCommands.feed());
    
    // Customer name (if provided)
    if (customerName != null && customerName.isNotEmpty) {
      commands.addAll(PrinterCommands.text('Plg: $customerName'));
      commands.addAll(PrinterCommands.feed());
    }
    
    _sections.add(commands);
    return this;
  }

  /// Add item list
  ReceiptBuilder addItems(List<Map<String, dynamic>> items) {
    final commands = <int>[];
    
    commands.addAll(PrinterCommands.align(TextAlign.left));
    
    for (final item in items) {
      // Support both 'name' and 'productName' fields for backward compatibility
      final name = (item['productName'] as String?) ?? 
                   (item['name'] as String?) ?? 
                   'Item';
      final quantity = (item['quantity'] as num?)?.toInt() ?? 0;
      final price = (item['price'] as num?)?.toDouble() ?? 0.0;
      final itemTotal = quantity * price;

      // Single line: name x qty | total
      final left = _truncateText('${name.trim()} x$quantity', maxCharsPerLine - 1 - _formatCurrency(itemTotal).length);
      final right = _formatCurrency(itemTotal);
      final line = _formatItemLine('$left|', right);
      commands.addAll(PrinterCommands.text(line));
      commands.addAll(PrinterCommands.feed());
    }
    
    _sections.add(commands);
    return this;
  }

  /// Add totals section
  ReceiptBuilder addTotals({
    required double subtotal,
    required double tax,
    required double total,
    double discount = 0.0,
  }) {
    final commands = <int>[];
    
    commands.addAll(PrinterCommands.align(TextAlign.left));
    
    // Subtotal
    commands.addAll(PrinterCommands.text(_formatTotalLine('Subtotal', subtotal)));
    commands.addAll(PrinterCommands.feed());
    
    // Tax (only show if > 0)
    if (tax > 0) {
      commands.addAll(PrinterCommands.text(_formatTotalLine('Pajak', tax)));
      commands.addAll(PrinterCommands.feed());
    }
    
    // Discount (if applicable)
    if (discount > 0) {
      commands.addAll(PrinterCommands.text(_formatTotalLine('Diskon', discount)));
      commands.addAll(PrinterCommands.feed());
    }
    
    // Total (bold, compact)
    commands.addAll(PrinterCommands.bold(true));
    commands.addAll(PrinterCommands.text(_formatTotalLine('TOTAL', total)));
    commands.addAll(PrinterCommands.bold(false));
    commands.addAll(PrinterCommands.feed());
    
    _sections.add(commands);
    return this;
  }

  /// Add payment info
  ReceiptBuilder addPaymentInfo({
    required String paymentMethod,
    double? cashAmount,
    double? change,
  }) {
    final commands = <int>[];
    
    commands.addAll(PrinterCommands.align(TextAlign.left));
    
    // Payment method
    commands.addAll(PrinterCommands.text('Pembayaran: '));
    commands.addAll(PrinterCommands.bold(true));
    commands.addAll(PrinterCommands.text(_formatPaymentMethod(paymentMethod)));
    commands.addAll(PrinterCommands.bold(false));
    commands.addAll(PrinterCommands.feed());
    
    // Cash amount (if provided)
    if (cashAmount != null) {
      commands.addAll(PrinterCommands.text('Tunai: '));
      commands.addAll(PrinterCommands.text(_formatCurrency(cashAmount)));
      commands.addAll(PrinterCommands.feed());
    }
    
    // Change (if provided and > 0)
    if (change != null && change > 0) {
      commands.addAll(PrinterCommands.text('Kembalian: '));
      commands.addAll(PrinterCommands.text(_formatCurrency(change)));
      commands.addAll(PrinterCommands.feed());
    }
    
    _sections.add(commands);
    return this;
  }

  /// Add QR code
  ReceiptBuilder addQRCode(String data, {String? label}) {
    final commands = <int>[];
    
    commands.addAll(PrinterCommands.emptyLines(1));
    commands.addAll(PrinterCommands.align(TextAlign.center));
    
    if (label != null) {
      commands.addAll(PrinterCommands.textLine(label));
      commands.addAll(PrinterCommands.emptyLines(1));
    }
    
    // QR code
    commands.addAll(PrinterCommands.qrCode(data, size: 6));
    commands.addAll(PrinterCommands.emptyLines(2));
    
    _sections.add(commands);
    return this;
  }

  /// Add footer
  ReceiptBuilder addFooter({String? thankYouMessage}) {
    final commands = <int>[];

    commands.addAll(PrinterCommands.emptyLines(1));
    commands.addAll(PrinterCommands.align(TextAlign.left));
    commands.addAll(PrinterCommands.bold(true));
    commands.addAll(PrinterCommands.textLine(thankYouMessage ?? 'Terima Kasih'));
    commands.addAll(PrinterCommands.bold(false));
    
    _sections.add(commands);
    return this;
  }

  /// Add custom section
  ReceiptBuilder addSection(List<int> commands) {
    _sections.add(commands);
    return this;
  }

  /// Build final receipt bytes
  List<int> build() {
    return PrinterCommands.buildReceipt(_sections);
  }

  /// Reset builder
  void reset() {
    _sections.clear();
  }

  // Helper methods

  String _formatCurrency(double value) {
    return 'Rp ${value.toStringAsFixed(0).replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]}.',
    )}';
  }

  String _formatPaymentMethod(String method) {
    switch (method.toLowerCase()) {
      case 'cash':
        return 'Tunai';
      case 'card':
        return 'Kartu';
      case 'qris':
        return 'QRIS';
      default:
        return method;
    }
  }

  String _formatItemLine(String left, String right) {
    final leftLen = left.length;
    final rightLen = right.length;
    final totalLen = maxCharsPerLine;
    final spaces = ' ' * (totalLen - leftLen - rightLen);
    return '$left$spaces$right';
  }

  String _formatTotalLine(String label, double value) {
    final labelText = label.padRight(12);
    final valueText = _formatCurrency(value);
    return '$labelText$valueText';
  }

  String _truncateText(String text, int maxLength) {
    if (text.length <= maxLength) return text;
    return '${text.substring(0, maxLength - 3)}...';
  }
}

