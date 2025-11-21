import 'package:flutter/material.dart';
import '../../services/xendit_service.dart';

class VirtualAccountPaymentDialog extends StatefulWidget {
  final Map<String, dynamic> vaData;
  final String bankName;
  final double total;
  final VoidCallback onPaymentVerified;
  final VoidCallback onCancel;

  const VirtualAccountPaymentDialog({
    super.key,
    required this.vaData,
    required this.bankName,
    required this.total,
    required this.onPaymentVerified,
    required this.onCancel,
  });

  @override
  State<VirtualAccountPaymentDialog> createState() => _VirtualAccountPaymentDialogState();
}

class _VirtualAccountPaymentDialogState extends State<VirtualAccountPaymentDialog> {
  final XenditService _xenditService = XenditService();
  bool _isChecking = false;
  String _status = 'PENDING';

  @override
  void initState() {
    super.initState();
    _startPolling();
  }

  void _startPolling() {
    Future.delayed(const Duration(seconds: 5), () {
      if (mounted) {
        _checkPaymentStatus();
      }
    });
  }

  Future<void> _checkPaymentStatus() async {
    try {
      setState(() {
        _isChecking = true;
      });

      final vaId = widget.vaData['id'] as String?;
      if (vaId != null) {
        final status = await _xenditService.getVirtualAccountStatus(vaId);
        final paymentStatus = status['status'] as String? ?? 'PENDING';

        setState(() {
          _status = paymentStatus;
          _isChecking = false;
        });

        if (paymentStatus == 'PAID' || paymentStatus == 'COMPLETED') {
          widget.onPaymentVerified();
        } else if (paymentStatus == 'PENDING' || paymentStatus == 'ACTIVE') {
          _startPolling();
        }
      }
    } catch (e) {
      setState(() {
        _isChecking = false;
      });
      _startPolling();
    }
  }

  String get _accountNumber {
    return widget.vaData['account_number'] as String? ?? '';
  }

  String? get _expirationDate {
    final exp = widget.vaData['expiration_date'];
    if (exp != null) {
      try {
        final date = DateTime.parse(exp as String);
        return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
      } catch (e) {
        return null;
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
      ),
      child: Container(
        padding: const EdgeInsets.all(24),
        constraints: const BoxConstraints(maxWidth: 400),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              "Virtual Account",
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: const Color(0xFF1F2937),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              widget.bankName,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(24),
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
                    'Nomor Virtual Account',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.white70,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _accountNumber,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Rp ${widget.total.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')}',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            if (_expirationDate != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.access_time_rounded, color: Colors.orange[700], size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Berlaku sampai: $_expirationDate',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.orange[700],
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 24),
            if (_isChecking)
              const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF6366F1)),
                    ),
                  ),
                  SizedBox(width: 12),
                  Text('Memeriksa status pembayaran...'),
                ],
              )
            else if (_status == 'PENDING' || _status == 'ACTIVE')
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.access_time_rounded, color: Colors.orange[700], size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Menunggu pembayaran...',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.orange[700],
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: widget.onCancel,
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.grey),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text('Batal'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _checkPaymentStatus,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6366F1),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text('Cek Status'),
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

