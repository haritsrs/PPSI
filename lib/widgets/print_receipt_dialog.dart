import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/receipt_service.dart';
import '../services/settings_service.dart';
import '../services/auth_service.dart';
import '../controllers/printer_controller.dart';
import '../utils/snackbar_helper.dart';

class PrintReceiptDialog extends StatefulWidget {
  final String transactionId;
  final Map<String, dynamic> transactionData;

  const PrintReceiptDialog({
    super.key,
    required this.transactionId,
    required this.transactionData,
  });

  @override
  State<PrintReceiptDialog> createState() => _PrintReceiptDialogState();
}

class _PrintReceiptDialogState extends State<PrintReceiptDialog> {
  bool _isLoading = false;
  late PrinterService _printerService;
  bool _printerConnected = false;
  String? _printType;

  @override
  void initState() {
    super.initState();
    _printerService = PrinterService();
    _printerService.addListener(_onPrinterServiceChanged);
    _checkPrinterConnection();
  }

  @override
  void dispose() {
    // Only remove listener, don't dispose the service
    // This keeps the printer connected across widget lifecycles
    _printerService.removeListener(_onPrinterServiceChanged);
    super.dispose();
  }

  void _onPrinterServiceChanged() {
    if (mounted) {
      setState(() {
        _printerConnected = _printerService.isConnected;
      });
    }
  }

  void _checkPrinterConnection() {
    setState(() {
      _printerConnected = _printerService.isConnected;
      // Auto-select default option: thermal if connected, otherwise PDF
      if (_printType == null) {
        _printType = _printerConnected ? 'thermal' : 'pdf';
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          Icon(Icons.print_rounded, color: Colors.blue[600]),
          const SizedBox(width: 8),
          const Text('Cetak Struk'),
        ],
      ),
          content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Pilih metode pencetakan:',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          // Thermal Print Option
          if (_printerConnected)
            _buildPrintOption(
              icon: Icons.receipt_long_rounded,
              title: 'Cetak Thermal (Cepat)',
              subtitle: 'Cetak langsung ke printer thermal yang terhubung',
              color: Colors.green,
              printType: 'thermal',
            ),
          if (_printerConnected) const SizedBox(height: 12),
          // PDF Print Option
          _buildPrintOption(
            icon: Icons.picture_as_pdf_rounded,
            title: 'Cetak PDF',
            subtitle: 'Gunakan printer sistem (semua jenis printer)',
            color: Colors.blue,
            printType: 'pdf',
          ),
          if (!_printerConnected) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange[200]!),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline_rounded, color: Colors.orange[700], size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Printer thermal tidak terhubung. Silakan hubungkan printer di Pengaturan.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.orange[900],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
          child: const Text('Batal'),
        ),
        if (_printType != null)
          ElevatedButton.icon(
            onPressed: _isLoading ? null : () => _handlePrint(context, _printType!),
            icon: _isLoading
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Icon(
                    _printType == 'thermal' ? Icons.receipt_long_rounded : Icons.picture_as_pdf_rounded,
                    size: 18,
                  ),
            label: Text(_printType == 'thermal' ? 'Cetak Thermal' : 'Cetak PDF'),
            style: ElevatedButton.styleFrom(
              backgroundColor: _printType == 'thermal' ? Colors.green : const Color(0xFF6366F1),
              foregroundColor: Colors.white,
            ),
          ),
      ],
    );
  }

  Color _getDarkColor(Color color) {
    // Return a darker shade of the color
    if (color == Colors.green) return Colors.green[900]!;
    if (color == Colors.blue) return Colors.blue[900]!;
    if (color == Colors.orange) return Colors.orange[900]!;
    // Fallback: darken the color manually
    return Color.fromRGBO(
      (color.red * 0.7).round().clamp(0, 255),
      (color.green * 0.7).round().clamp(0, 255),
      (color.blue * 0.7).round().clamp(0, 255),
      1.0,
    );
  }

  Widget _buildPrintOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required String printType,
  }) {
    final isSelected = _printType == printType;
    return InkWell(
      onTap: _isLoading ? null : () {
        setState(() {
          _printType = printType;
        });
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.15) : color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? color : color.withOpacity(0.3),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: _getDarkColor(color),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey[700],
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(Icons.check_circle_rounded, color: color, size: 24)
            else
              Icon(Icons.circle_outlined, color: Colors.grey[400], size: 24),
          ],
        ),
      ),
    );
  }

  Future<void> _handlePrint(BuildContext context, String printType) async {
    setState(() {
      _isLoading = true;
    });

    try {
      final storeAddress = await SettingsService.getSetting<String>(
        SettingsService.keyStoreAddress,
        '',
      );
      final storePhone = await SettingsService.getSetting<String>(
        SettingsService.keyStorePhone,
        '',
      );
      final storeName = AuthService.currentUser?.displayName?.trim().isNotEmpty == true
          ? AuthService.currentUser!.displayName!.trim()
          : 'Toko Saya';


      // Parse transaction data
      final items = widget.transactionData['items'] as List<dynamic>? ?? [];
      final itemsList = items.map((item) => Map<String, dynamic>.from(item as Map)).toList();
      
      DateTime date;
      try {
        date = DateTime.parse(widget.transactionData['createdAt'] as String);
      } catch (e) {
        date = DateTime.now();
      }

      if (printType == 'thermal') {
        // Thermal Print - Fast direct printing
        // Check if printer is still connected
        if (!_printerService.isConnected) {
          throw Exception('Printer tidak terhubung. Silakan hubungkan printer terlebih dahulu.');
        }

        // Generate QR code data with transaction info
        // Format: Store info + transaction details for easy access
        final qrCodeData = 'TRX:${widget.transactionId}|DATE:${date.toIso8601String()}|TOTAL:${(widget.transactionData['total'] as num?)?.toDouble() ?? 0.0}';
        
        // Get discount if present
        final discount = (widget.transactionData['discount'] as num?)?.toDouble() ?? 0.0;
        
        // Generate ESC/POS receipt bytes
        final receiptBytes = await ReceiptService.generateESCPOSReceipt(
          transactionId: widget.transactionId,
          date: date,
          customerName: widget.transactionData['customerName'] as String?,
          items: itemsList,
          subtotal: (widget.transactionData['subtotal'] as num?)?.toDouble() ?? 0.0,
          tax: (widget.transactionData['tax'] as num?)?.toDouble() ?? 0.0,
          total: (widget.transactionData['total'] as num?)?.toDouble() ?? 0.0,
          paymentMethod: widget.transactionData['paymentMethod'] as String? ?? 'Cash',
          cashAmount: (widget.transactionData['cashAmount'] as num?)?.toDouble(),
          change: (widget.transactionData['change'] as num?)?.toDouble(),
          storeName: storeName,
          storeAddress: storeAddress,
          storePhone: storePhone,
          qrCodeData: qrCodeData,
          discount: discount,
        );

        // Print to thermal printer
        await _printerService.printBytes(receiptBytes);
        
        if (mounted) {
          Navigator.of(context).pop();
          SnackbarHelper.showSuccess(
            context,
            'Struk berhasil dicetak ke printer thermal',
          );
        }
      } else {
        // PDF Print - Works with any printer
        Navigator.of(context).pop();
        
        final pdf = await ReceiptService.generatePDFReceipt(
          transactionId: widget.transactionId,
          date: date,
          customerName: widget.transactionData['customerName'] as String?,
          items: itemsList,
          subtotal: (widget.transactionData['subtotal'] as num?)?.toDouble() ?? 0.0,
          tax: (widget.transactionData['tax'] as num?)?.toDouble() ?? 0.0,
          total: (widget.transactionData['total'] as num?)?.toDouble() ?? 0.0,
          paymentMethod: widget.transactionData['paymentMethod'] as String? ?? 'Cash',
          cashAmount: (widget.transactionData['cashAmount'] as num?)?.toDouble(),
          change: (widget.transactionData['change'] as num?)?.toDouble(),
          storeName: storeName,
          storeAddress: storeAddress,
          storePhone: storePhone,
        );

        await ReceiptService.printPDFReceipt(pdf);
        
        if (context.mounted) {
          SnackbarHelper.showSuccess(
            context,
            'Struk berhasil dikirim ke printer',
          );
        }
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      
      if (context.mounted) {
        SnackbarHelper.showError(
          context,
          'Gagal mencetak: $e',
        );
      }
    }
  }
}


