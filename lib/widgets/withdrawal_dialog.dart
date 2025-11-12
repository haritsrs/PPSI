import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/database_service.dart';
import '../utils/responsive_helper.dart';

class WithdrawalDialog extends StatefulWidget {
  final double currentBalance;
  final DatabaseService databaseService;

  const WithdrawalDialog({
    super.key,
    required this.currentBalance,
    required this.databaseService,
  });

  @override
  State<WithdrawalDialog> createState() => _WithdrawalDialogState();
}

class _WithdrawalDialogState extends State<WithdrawalDialog> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _bankNameController = TextEditingController();
  final _accountNumberController = TextEditingController();
  final _accountHolderController = TextEditingController();
  final _notesController = TextEditingController();
  
  bool _isProcessing = false;
  String _selectedBank = 'BCA';
  
  final List<String> _banks = [
    'BCA',
    'BNI',
    'BRI',
    'Mandiri',
    'CIMB Niaga',
    'Bank Danamon',
    'Bank Permata',
    'Bank BTPN',
    'Bank OCBC',
    'Bank Maybank',
    'Bank UOB',
    'Bank DBS',
    'Bank Jago',
    'Bank Seabank',
    'Bank Neo Commerce',
    'Bank Allo',
    'Lainnya',
  ];

  @override
  void dispose() {
    _amountController.dispose();
    _bankNameController.dispose();
    _accountNumberController.dispose();
    _accountHolderController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _handleQuickAmount(double amount) {
    setState(() {
      if (amount <= widget.currentBalance) {
        _amountController.text = amount.toStringAsFixed(0);
      } else {
        _amountController.text = widget.currentBalance.toStringAsFixed(0);
      }
    });
    HapticFeedback.lightImpact();
  }

  Future<void> _submitWithdrawal() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final amount = double.tryParse(_amountController.text.replaceAll('.', '').replaceAll(',', '.')) ?? 0.0;
    
    if (amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Jumlah harus lebih dari 0'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (amount > widget.currentBalance) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Jumlah pencairan melebihi saldo toko'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (amount < 10000) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Minimum pencairan adalah Rp 10.000'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _isProcessing = true;
    });

    try {
      final bankName = _selectedBank == 'Lainnya' 
          ? _bankNameController.text.trim() 
          : _selectedBank;
      
      if (bankName.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Nama bank harus diisi'),
            backgroundColor: Colors.red,
          ),
        );
        setState(() {
          _isProcessing = false;
        });
        return;
      }

      await widget.databaseService.addWithdrawal(
        amount: amount,
        bankName: bankName,
        accountNumber: _accountNumberController.text.trim(),
        accountHolderName: _accountHolderController.text.trim(),
        notes: _notesController.text.trim(),
      );

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Permintaan pencairan sebesar Rp ${amount.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')} berhasil diajukan'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
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
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final paddingScale = ResponsiveHelper.getPaddingScale(context);
    final iconScale = ResponsiveHelper.getIconScale(context);
    final fontScale = ResponsiveHelper.getFontScale(context);
    
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
      ),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 700),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: EdgeInsets.all(20 * paddingScale),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(8 * iconScale),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.25),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.account_balance_wallet_rounded,
                      color: Colors.white,
                      size: 24 * iconScale,
                    ),
                  ),
                  SizedBox(width: 12 * paddingScale),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Pencairan Saldo',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: (Theme.of(context).textTheme.titleLarge?.fontSize ?? 20) * fontScale,
                          ),
                        ),
                        SizedBox(height: 4 * paddingScale),
                        Text(
                          'Saldo tersedia: Rp ${widget.currentBalance.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')}',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: (Theme.of(context).textTheme.bodySmall?.fontSize ?? 12) * fontScale,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(
                      Icons.close_rounded,
                      color: Colors.white,
                      size: 24 * iconScale,
                    ),
                  ),
                ],
              ),
            ),
            
            // Form
            Flexible(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(20 * paddingScale),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Amount Input
                      Text(
                        'Jumlah Pencairan',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          fontSize: (Theme.of(context).textTheme.titleMedium?.fontSize ?? 16) * fontScale,
                        ),
                      ),
                      SizedBox(height: 8 * paddingScale),
                      TextFormField(
                        controller: _amountController,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        decoration: InputDecoration(
                          hintText: 'Masukkan jumlah pencairan',
                          prefixText: 'Rp ',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: Colors.grey[50],
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Jumlah harus diisi';
                          }
                          final amount = double.tryParse(value.replaceAll('.', '').replaceAll(',', '.')) ?? 0.0;
                          if (amount <= 0) {
                            return 'Jumlah harus lebih dari 0';
                          }
                          if (amount > widget.currentBalance) {
                            return 'Jumlah melebihi saldo toko';
                          }
                          if (amount < 10000) {
                            return 'Minimum pencairan adalah Rp 10.000';
                          }
                          return null;
                        },
                      ),
                      SizedBox(height: 12 * paddingScale),
                      
                      // Quick Amount Buttons
                      Wrap(
                        spacing: 8 * paddingScale,
                        runSpacing: 8 * paddingScale,
                        children: [
                          _buildQuickAmountButton('25%', widget.currentBalance * 0.25),
                          _buildQuickAmountButton('50%', widget.currentBalance * 0.5),
                          _buildQuickAmountButton('75%', widget.currentBalance * 0.75),
                          _buildQuickAmountButton('100%', widget.currentBalance),
                        ],
                      ),
                      
                      SizedBox(height: 24 * paddingScale),
                      
                      // Bank Selection
                      Text(
                        'Bank Tujuan',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          fontSize: (Theme.of(context).textTheme.titleMedium?.fontSize ?? 16) * fontScale,
                        ),
                      ),
                      SizedBox(height: 8 * paddingScale),
                      DropdownButtonFormField<String>(
                        value: _selectedBank,
                        decoration: InputDecoration(
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: Colors.grey[50],
                        ),
                        items: _banks.map((bank) {
                          return DropdownMenuItem(
                            value: bank,
                            child: Text(bank),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedBank = value!;
                          });
                        },
                      ),
                      
                      // Custom Bank Name (if Lainnya is selected)
                      if (_selectedBank == 'Lainnya') ...[
                        SizedBox(height: 12 * paddingScale),
                        TextFormField(
                          controller: _bankNameController,
                          decoration: InputDecoration(
                            hintText: 'Masukkan nama bank',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            filled: true,
                            fillColor: Colors.grey[50],
                          ),
                          validator: (value) {
                            if (_selectedBank == 'Lainnya' && (value == null || value.isEmpty)) {
                              return 'Nama bank harus diisi';
                            }
                            return null;
                          },
                        ),
                      ],
                      
                      SizedBox(height: 16 * paddingScale),
                      
                      // Account Number
                      Text(
                        'Nomor Rekening',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          fontSize: (Theme.of(context).textTheme.titleMedium?.fontSize ?? 16) * fontScale,
                        ),
                      ),
                      SizedBox(height: 8 * paddingScale),
                      TextFormField(
                        controller: _accountNumberController,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        decoration: InputDecoration(
                          hintText: 'Masukkan nomor rekening',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: Colors.grey[50],
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Nomor rekening harus diisi';
                          }
                          if (value.length < 8) {
                            return 'Nomor rekening minimal 8 digit';
                          }
                          return null;
                        },
                      ),
                      
                      SizedBox(height: 16 * paddingScale),
                      
                      // Account Holder Name
                      Text(
                        'Nama Pemilik Rekening',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          fontSize: (Theme.of(context).textTheme.titleMedium?.fontSize ?? 16) * fontScale,
                        ),
                      ),
                      SizedBox(height: 8 * paddingScale),
                      TextFormField(
                        controller: _accountHolderController,
                        decoration: InputDecoration(
                          hintText: 'Masukkan nama pemilik rekening',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: Colors.grey[50],
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Nama pemilik rekening harus diisi';
                          }
                          return null;
                        },
                      ),
                      
                      SizedBox(height: 16 * paddingScale),
                      
                      // Notes (Optional)
                      Text(
                        'Catatan (Opsional)',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          fontSize: (Theme.of(context).textTheme.titleMedium?.fontSize ?? 16) * fontScale,
                        ),
                      ),
                      SizedBox(height: 8 * paddingScale),
                      TextFormField(
                        controller: _notesController,
                        maxLines: 3,
                        decoration: InputDecoration(
                          hintText: 'Tambahkan catatan jika perlu',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: Colors.grey[50],
                        ),
                      ),
                      
                      SizedBox(height: 24 * paddingScale),
                      
                      // Submit Button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _isProcessing ? null : _submitWithdrawal,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF6366F1),
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(vertical: 16 * paddingScale),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: _isProcessing
                              ? SizedBox(
                                  height: 20 * iconScale,
                                  width: 20 * iconScale,
                                  child: const CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                  ),
                                )
                              : Text(
                                  'Ajukan Pencairan',
                                  style: TextStyle(
                                    fontSize: 16 * fontScale,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickAmountButton(String label, double amount) {
    final fontScale = ResponsiveHelper.getFontScale(context);
    
    return OutlinedButton(
      onPressed: () => _handleQuickAmount(amount),
      style: OutlinedButton.styleFrom(
        side: BorderSide(color: const Color(0xFF6366F1).withOpacity(0.5)),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: const Color(0xFF6366F1),
          fontSize: 12 * fontScale,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

