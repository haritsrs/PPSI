import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/cart_item_model.dart';
import '../../models/payment_method_model.dart';
import '../../services/database_service.dart';
import '../../services/xendit_service.dart';
import '../../services/settings_service.dart';
import '../../utils/error_helper.dart';
import '../../utils/currency_input_formatter.dart';
import 'qris_payment_dialog.dart';
import 'virtual_account_bank_selection_dialog.dart';
import 'virtual_account_payment_dialog.dart';
import 'custom_qr_payment_dialog.dart';

class PaymentModal extends StatefulWidget {
  final double total;
  final List<CartItem> cartItems;
  final DatabaseService databaseService;
  final Function({
    required String paymentMethod,
    double? cashAmount,
    double? change,
    String? customerId,
    String? customerName,
    double? discount,
  }) onPaymentSuccess;

  const PaymentModal({
    super.key,
    required this.total,
    required this.cartItems,
    required this.databaseService,
    required this.onPaymentSuccess,
  });

  @override
  State<PaymentModal> createState() => _PaymentModalState();
}

class _PaymentModalState extends State<PaymentModal> {
  // Temporarily disable Xendit payments
  static const bool _xenditEnabled = false;

  String _selectedPaymentMethod = 'Cash';
  final TextEditingController _cashController = TextEditingController();
  final TextEditingController _discountController = TextEditingController();
  double _cashAmount = 0.0;
  double _change = 0.0;
  double _discount = 0.0;
  String? _selectedCustomerId;
  String? _selectedCustomerName;
  List<Map<String, dynamic>> _customers = [];
  final FocusNode _cashFocusNode = FocusNode();

  List<PaymentMethod> get _paymentMethods {
    final methods = [
      PaymentMethod(id: 'Cash', name: 'Tunai', icon: Icons.money_rounded),
    ];
    
    if (_xenditEnabled) {
      methods.addAll([
        PaymentMethod(id: 'QRIS', name: 'QRIS', icon: Icons.qr_code_rounded),
        PaymentMethod(id: 'VirtualAccount', name: 'Virtual Account', icon: Icons.account_balance_rounded),
      ]);
    } else {
      methods.add(
        PaymentMethod(id: 'CustomQR', name: 'QR Code', icon: Icons.qr_code_rounded),
      );
    }
    
    return methods;
  }

  final XenditService _xenditService = XenditService();
  bool _isProcessingPayment = false;

  @override
  void initState() {
    super.initState();
    // Reset all state to ensure fresh start for each transaction
    _selectedPaymentMethod = 'Cash';
    _cashAmount = 0.0;
    _change = 0.0;
    _discount = 0.0;
    _selectedCustomerId = null;
    _selectedCustomerName = null;
    _isProcessingPayment = false;
    _cashController.clear();
    _discountController.clear();
    
    _loadCustomers();
    _discountController.addListener(_calculateDiscount);
  }

  Future<void> _loadCustomers() async {
    try {
      widget.databaseService.getCustomersStream().listen((customers) {
        if (mounted) {
          setState(() {
            _customers = customers;
          });
        }
      });
    } catch (e) {
      // Handle error silently
    }
  }

  void _calculateDiscount() {
    setState(() {
      _discount = CurrencyInputFormatter.parseFormattedCurrency(_discountController.text) ?? 0.0;
      if (_discount > widget.total) {
        _discount = widget.total;
        final formatted = widget.total.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.');
        _discountController.text = formatted;
      }
      if (_selectedPaymentMethod == 'Cash') {
        _calculateChange();
      }
    });
  }

  double get _finalTotal {
    return (widget.total - _discount).clamp(0.0, double.infinity);
  }

  @override
  void dispose() {
    _cashController.dispose();
    _cashFocusNode.dispose();
    _discountController.removeListener(_calculateDiscount);
    _discountController.dispose();
    super.dispose();
  }

  void _calculateChange() {
    setState(() {
      _cashAmount = CurrencyInputFormatter.parseFormattedCurrency(_cashController.text) ?? 0.0;
      _change = _cashAmount - _finalTotal;
    });
  }

  Widget _buildPaymentMethodButton({
    required PaymentMethod method,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          height: 70,
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF6366F1) : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? const Color(0xFF6366F1) : Colors.grey[300]!,
              width: isSelected ? 2.5 : 1.5,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: const Color(0xFF6366F1).withOpacity(0.4),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                      spreadRadius: 1,
                    ),
                  ]
                : [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                method.icon,
                color: isSelected ? Colors.white : const Color(0xFF6366F1),
                size: 28,
              ),
              const SizedBox(height: 6),
              Flexible(
                child: Text(
                  method.name,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: isSelected ? Colors.white : const Color(0xFF1F2937),
                        fontWeight: FontWeight.w700,
                        fontSize: 11,
                      ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _processPayment() async {
    if (_selectedPaymentMethod == 'Cash') {
      if (_cashAmount < _finalTotal) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Jumlah uang tidak mencukupi! Kurang Rp ${(_finalTotal - _cashAmount).toStringAsFixed(0)}'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
      widget.onPaymentSuccess(
        paymentMethod: _selectedPaymentMethod,
        cashAmount: _cashAmount,
        change: _change > 0 ? _change : null,
        customerId: _selectedCustomerId,
        customerName: _selectedCustomerName,
        discount: _discount,
      );
      return;
    }

    setState(() {
      _isProcessingPayment = true;
    });

    try {
      if (_selectedPaymentMethod == 'QRIS' && _xenditEnabled) {
        await _processQRISPayment();
      } else if (_selectedPaymentMethod == 'VirtualAccount' && _xenditEnabled) {
        await _processVirtualAccountPayment();
      } else if (_selectedPaymentMethod == 'CustomQR') {
        await _processCustomQRPayment();
      }
    } catch (error) {
      setState(() {
        _isProcessingPayment = false;
      });
      if (!mounted) return;
      final message = getFriendlyErrorMessage(
        error,
        fallbackMessage: 'Pembayaran gagal diproses.',
      );
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _processQRISPayment() async {
    if (!_xenditEnabled) return;
    
    try {
      final referenceId = 'TXN-${DateTime.now().millisecondsSinceEpoch}';
      final expiredAt = DateTime.now().add(const Duration(hours: 24)).toIso8601String();

      final qrisResponse = await _xenditService.createQRIS(
        amount: _finalTotal,
        referenceId: referenceId,
        callbackUrl: 'https://api.xendit.co/qr_codes/callback',
        expiredAt: expiredAt,
      );

      setState(() {
        _isProcessingPayment = false;
      });

      if (mounted) {
        Navigator.pop(context);
        _showQRISPaymentDialog(qrisResponse, referenceId, _finalTotal);
      }
    } catch (e) {
      setState(() {
        _isProcessingPayment = false;
      });
      rethrow;
    }
  }

  Future<void> _processVirtualAccountPayment() async {
    if (mounted) {
      Navigator.pop(context);
      _showVirtualAccountBankSelection();
    }
  }

  void _showQRISPaymentDialog(Map<String, dynamic> qrisData, String referenceId, double total) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => QRISPaymentDialog(
        qrisData: qrisData,
        referenceId: referenceId,
        total: total,
        onPaymentVerified: () {
          widget.onPaymentSuccess(
            paymentMethod: 'QRIS',
            cashAmount: null,
            change: null,
            customerId: _selectedCustomerId,
            customerName: _selectedCustomerName,
            discount: _discount,
          );
        },
        onCancel: () {
          // Handle cancel
        },
      ),
    );
  }

  void _showVirtualAccountBankSelection() {
    showDialog(
      context: context,
      builder: (context) => VirtualAccountBankSelectionDialog(
        total: widget.total,
        onBankSelected: (bankCode, bankName) async {
          Navigator.pop(context);
          await _createVirtualAccount(bankCode, bankName);
        },
      ),
    );
  }

  Future<void> _createVirtualAccount(String bankCode, String bankName) async {
    if (!_xenditEnabled) return;
    
    try {
      setState(() {
        _isProcessingPayment = true;
      });

      final externalId = 'VA-${DateTime.now().millisecondsSinceEpoch}';
      final expiredAt = DateTime.now().add(const Duration(days: 1));

      final vaResponse = await _xenditService.createVirtualAccount(
        externalId: externalId,
        bankCode: bankCode,
        name: 'KiosDarma Payment',
        amount: _finalTotal,
        expiredAt: expiredAt,
      );

      setState(() {
        _isProcessingPayment = false;
      });

      if (mounted) {
        _showVirtualAccountPaymentDialog(vaResponse, bankName, _finalTotal);
      }
    } catch (error) {
      setState(() {
        _isProcessingPayment = false;
      });
      if (!mounted) return;
      final message = getFriendlyErrorMessage(
        error,
        fallbackMessage: 'Gagal membuat Virtual Account.',
      );
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _processCustomQRPayment() async {
    try {
      setState(() {
        _isProcessingPayment = false;
      });

      // Load custom QR code URL from settings
      final qrCodeUrl = await SettingsService.getSetting<String>(
        SettingsService.keyCustomQRCodeUrl,
        '',
      );

      if (qrCodeUrl.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('QR code belum dikonfigurasi. Silakan atur QR code di Pengaturan > Bisnis.'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }

      if (mounted) {
        Navigator.pop(context);
        _showCustomQRPaymentDialog(qrCodeUrl, _finalTotal);
      }
    } catch (e) {
      setState(() {
        _isProcessingPayment = false;
      });
      if (!mounted) return;
      final message = getFriendlyErrorMessage(
        e,
        fallbackMessage: 'Gagal memproses pembayaran QR code.',
      );
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showCustomQRPaymentDialog(String qrImageUrl, double total) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => CustomQRPaymentDialog(
        qrImageUrl: qrImageUrl,
        total: total,
        onPaymentConfirmed: () {
          widget.onPaymentSuccess(
            paymentMethod: 'CustomQR',
            cashAmount: null,
            change: null,
            customerId: _selectedCustomerId,
            customerName: _selectedCustomerName,
            discount: _discount,
          );
        },
        onCancel: () {
          // Handle cancel
        },
      ),
    );
  }

  void _showVirtualAccountPaymentDialog(Map<String, dynamic> vaData, String bankName, double total) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => VirtualAccountPaymentDialog(
        vaData: vaData,
        bankName: bankName,
        total: total,
        onPaymentVerified: () {
          widget.onPaymentSuccess(
            paymentMethod: 'VirtualAccount',
            cashAmount: null,
            change: null,
            customerId: _selectedCustomerId,
            customerName: _selectedCustomerName,
            discount: _discount,
          );
        },
        onCancel: () {
          // Handle cancel
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: Column(
        children: [
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Pembayaran",
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
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      Text(
                        "Total Pembayaran",
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: Colors.white70,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Rp ${_finalTotal.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')}',
                        style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      if (_discount > 0) ...[
                        const SizedBox(height: 8),
                        Text(
                          'Diskon: Rp ${_discount.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')}',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey[200]!),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Metode Pembayaran",
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF1F2937),
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: _paymentMethods.asMap().entries.map((entry) {
                          final index = entry.key;
                          final method = entry.value;
                          return Expanded(
                            child: Padding(
                              padding: EdgeInsets.only(
                                right: index < _paymentMethods.length - 1 ? 12 : 0,
                              ),
                              child: _buildPaymentMethodButton(
                                method: method,
                                isSelected: _selectedPaymentMethod == method.id,
                                onTap: () {
                                  setState(() {
                                    _selectedPaymentMethod = method.id;
                                    if (method.id == 'Cash') {
                                      _calculateChange();
                                    }
                                  });
                                  HapticFeedback.lightImpact();
                                },
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Pelanggan (Opsional)",
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF1F2937),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: DropdownButton<String>(
                      value: _selectedCustomerId,
                      isExpanded: true,
                      hint: const Text('Pilih pelanggan atau biarkan kosong'),
                      underline: Container(),
                      items: [
                        const DropdownMenuItem<String>(
                          value: null,
                          child: Text('Tanpa Pelanggan'),
                        ),
                        ..._customers.map((customer) {
                          return DropdownMenuItem<String>(
                            value: customer['id'] as String,
                            child: Text(customer['name'] as String? ?? 'Unknown'),
                          );
                        }),
                      ],
                      onChanged: (value) {
                        setState(() {
                          _selectedCustomerId = value;
                          if (value != null) {
                            final customer = _customers.firstWhere((c) => c['id'] == value);
                            _selectedCustomerName = customer['name'] as String?;
                          } else {
                            _selectedCustomerName = null;
                          }
                        });
                      },
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    "Diskon / Kupon",
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF1F2937),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _discountController,
                    decoration: InputDecoration(
                      hintText: 'Masukkan jumlah diskon (Rp)',
                      prefixIcon: const Icon(Icons.discount_rounded, color: Color(0xFF6366F1)),
                      suffixText: 'Rp',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: const Color(0xFFF8FAFC),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                  if (_selectedPaymentMethod == 'Cash' && !_isProcessingPayment) ...[
                    const SizedBox(height: 24),
                    Text(
                      "Jumlah Uang",
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF1F2937),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _cashController,
                      focusNode: _cashFocusNode,
                      inputFormatters: [CurrencyInputFormatter()],
                      onChanged: (_) => _calculateChange(),
                      keyboardType: TextInputType.number,
                      enabled: !_isProcessingPayment,
                      autofocus: false,
                      canRequestFocus: true,
                      onTap: () {
                        // Ensure this field can get focus when tapped
                        // Request focus after a small delay to ensure it's not stolen
                        Future.delayed(const Duration(milliseconds: 50), () {
                          if (mounted && _cashFocusNode.canRequestFocus) {
                            _cashFocusNode.requestFocus();
                          }
                        });
                      },
                      decoration: InputDecoration(
                        hintText: 'Masukkan jumlah uang',
                        hintStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey[500],
                        ),
                        prefixText: 'Rp ',
                        prefixStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: const Color(0xFF6366F1),
                          fontWeight: FontWeight.w600,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey[300]!),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xFF6366F1), width: 2),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey[300]!),
                        ),
                        disabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey[300]!),
                        ),
                        filled: true,
                        fillColor: const Color(0xFFF8FAFC),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 16,
                        ),
                      ),
                    ),
                    if (_change > 0) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: Colors.green.withOpacity(0.2),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.money_rounded,
                              color: Colors.green,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Kembalian: Rp ${_change.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')}',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Colors.green[700],
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
          if (_isProcessingPayment) ...[
            const SizedBox(height: 24),
            const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF6366F1)),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Memproses pembayaran...',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[600],
              ),
            ),
          ],
          if (!_isProcessingPayment)
            Container(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              color: Colors.white,
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _processPayment,
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
                      Icon(
                        _selectedPaymentMethod == 'Cash'
                            ? Icons.payment_rounded
                            : _selectedPaymentMethod == 'QRIS'
                                ? Icons.qr_code_rounded
                                : _selectedPaymentMethod == 'VirtualAccount'
                                    ? Icons.account_balance_rounded
                                    : Icons.qr_code_rounded,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _selectedPaymentMethod == 'Cash'
                            ? "Proses Pembayaran"
                            : _selectedPaymentMethod == 'QRIS'
                                ? "Buat QRIS"
                                : _selectedPaymentMethod == 'VirtualAccount'
                                    ? "Buat Virtual Account"
                                    : "Tampilkan QR Code",
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
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
}

