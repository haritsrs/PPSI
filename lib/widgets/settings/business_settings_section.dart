import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../controllers/settings_controller.dart';
import '../../services/storage_service.dart';
import '../../services/auth_service.dart';
import '../../utils/error_helper.dart';
import '../../utils/snackbar_helper.dart';
import 'settings_section.dart';
import 'setting_item.dart';
import 'printer_settings_section.dart';

class BusinessSettingsSection extends StatelessWidget {
  final SettingsController controller;

  const BusinessSettingsSection({
    super.key,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        PrinterSettingsSection(controller: controller),
        const SizedBox(height: 16),
        SettingsSection(
          title: "Bisnis",
          icon: Icons.business_rounded,
          color: const Color(0xFF10B981),
          children: [
            SettingItem(
              icon: Icons.location_on_rounded,
              title: "Alamat Toko",
              subtitle: controller.storeAddress.trim().isEmpty
                  ? "Belum diatur"
                  : controller.storeAddress,
              onTap: () => _showStoreAddressDialog(context, controller),
            ),
            SettingItem(
              icon: Icons.phone_rounded,
              title: "Nomor Telepon Toko",
              subtitle: controller.storePhone.trim().isEmpty
                  ? "Belum diatur"
                  : controller.storePhone,
              onTap: () => _showStorePhoneDialog(context, controller),
            ),
            SettingItem(
              icon: Icons.qr_code_scanner_rounded,
              title: "Scanner Barcode",
              subtitle: "Aktifkan scanner",
              trailing: Switch(
                value: controller.barcodeScannerEnabled,
                onChanged: (value) async {
                  await controller.setBarcodeScannerEnabled(value);
                },
                activeColor: const Color(0xFF6366F1),
              ),
            ),
            SettingItem(
              icon: Icons.receipt_long_rounded,
              title: "Aktifkan Pajak",
              subtitle: controller.taxEnabled 
                  ? "Pajak ${(controller.taxRate * 100).toStringAsFixed(0)}% ${controller.taxInclusive ? 'termasuk' : 'dikenakan'}"
                  : "Pajak tidak aktif",
              trailing: Switch(
                value: controller.taxEnabled,
                onChanged: (value) async {
                  if (!value) {
                    // Show informational popup when disabling tax
                    _showTaxDisableWarning(context, controller);
                  } else {
                    await controller.setTaxEnabled(value);
                  }
                },
                activeColor: const Color(0xFF6366F1),
              ),
            ),
            if (controller.taxEnabled) ...[
              SettingItem(
                icon: Icons.percent_rounded,
                title: "Tarif Pajak",
                subtitle: "${(controller.taxRate * 100).toStringAsFixed(1)}%",
                onTap: () => _showTaxRateDialog(context, controller),
              ),
              SettingItem(
                icon: Icons.calculate_rounded,
                title: "Tipe Pajak",
                subtitle: controller.taxInclusive 
                    ? "Pajak sudah termasuk dalam harga" 
                    : "Pajak ditambahkan pada harga",
                trailing: Switch(
                  value: controller.taxInclusive,
                  onChanged: (value) async {
                    await controller.setTaxInclusive(value);
                  },
                  activeColor: const Color(0xFF6366F1),
                ),
              ),
            ],
            SettingItem(
              icon: Icons.qr_code_rounded,
              title: "QR Code Pembayaran",
              subtitle: controller.customQRCodeUrl != null && controller.customQRCodeUrl!.isNotEmpty
                  ? "QR code sudah dikonfigurasi"
                  : "Unggah QR code untuk pembayaran",
              onTap: () => _showQRCodeDialog(context, controller),
            ),
          ],
        ),
      ],
    );
  }

  void _showStoreAddressDialog(BuildContext context, SettingsController controller) {
    final addressController = TextEditingController(text: controller.storeAddress);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Atur Alamat Toko'),
        content: TextField(
          controller: addressController,
          keyboardType: TextInputType.streetAddress,
          textInputAction: TextInputAction.done,
          maxLines: 3,
          decoration: const InputDecoration(
            labelText: 'Alamat',
            hintText: 'Contoh: Jl. Merdeka No. 10, Jakarta',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () async {
              final value = addressController.text.trim();
              await controller.setStoreAddress(value);
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }

  void _showStorePhoneDialog(BuildContext context, SettingsController controller) {
    final phoneController = TextEditingController(text: controller.storePhone);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Atur Nomor Telepon Toko'),
        content: TextField(
          controller: phoneController,
          keyboardType: TextInputType.phone,
          textInputAction: TextInputAction.done,
          decoration: const InputDecoration(
            labelText: 'Nomor Telepon',
            hintText: 'Contoh: 0812xxxxxxx',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () async {
              final value = phoneController.text.trim();
              await controller.setStorePhone(value);
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }

  void _showTaxRateDialog(BuildContext context, SettingsController controller) {
    final TextEditingController rateController = TextEditingController(
      text: (controller.taxRate * 100).toStringAsFixed(1),
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Atur Tarif Pajak'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Masukkan tarif pajak (persentase):'),
            const SizedBox(height: 16),
            TextField(
              controller: rateController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
              ],
              decoration: const InputDecoration(
                labelText: 'Tarif Pajak (%)',
                hintText: '11.0',
                suffixText: '%',
                border: OutlineInputBorder(),
              ),
              autofocus: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              final rateText = rateController.text.trim();
              if (rateText.isNotEmpty) {
                final rate = double.tryParse(rateText);
                if (rate != null && rate >= 0 && rate <= 100) {
                  controller.setTaxRate(rate / 100);
                  Navigator.pop(context);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Tarif pajak harus antara 0% dan 100%'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }

  void _showTaxDisableWarning(BuildContext context, SettingsController controller) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.info_outline, color: Colors.orange),
            const SizedBox(width: 8),
            const Text('Informasi Pajak'),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Sebaiknya pajak tetap diaktifkan untuk memastikan pencatatan yang akurat.',
              style: TextStyle(fontSize: 14),
            ),
            SizedBox(height: 12),
            Text(
              'Catatan: Kewajiban perpajakan tetap menjadi tanggung jawab pemilik usaha sesuai peraturan yang berlaku.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () async {
              await controller.setTaxEnabled(false);
              if (context.mounted) Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
            ),
            child: const Text('Tetap Nonaktifkan'),
          ),
        ],
      ),
    );
  }

  void _showQRCodeDialog(BuildContext context, SettingsController controller) {
    showDialog(
      context: context,
      builder: (context) => _QRCodeManagementDialog(controller: controller),
    );
  }
}

class _QRCodeManagementDialog extends StatefulWidget {
  final SettingsController controller;

  const _QRCodeManagementDialog({required this.controller});

  @override
  State<_QRCodeManagementDialog> createState() => _QRCodeManagementDialogState();
}

class _QRCodeManagementDialogState extends State<_QRCodeManagementDialog> {
  bool _isUploading = false;
  bool _isDeleting = false;

  Future<void> _pickAndUploadQRCode(ImageSource source) async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? pickedFile = await picker.pickImage(source: source);

      if (pickedFile == null) return;

      setState(() {
        _isUploading = true;
      });

      final user = AuthService.currentUser;
      if (user == null) {
        throw Exception('User tidak terautentikasi');
      }

      final imageFile = File(pickedFile.path);
      
      // Delete old QR code if exists
      final oldUrl = widget.controller.customQRCodeUrl;
      if (oldUrl != null && oldUrl.isNotEmpty) {
        try {
          await StorageService.deleteCustomQRCode(oldUrl);
        } catch (e) {
          // Ignore deletion errors, continue with upload
          debugPrint('Error deleting old QR code: $e');
        }
      }

      // Upload new QR code
      final downloadUrl = await StorageService.uploadCustomQRCode(
        imageFile: imageFile,
        userId: user.uid,
      );

      // Save URL to settings
      await widget.controller.setCustomQRCodeUrl(downloadUrl);

      if (mounted) {
        Navigator.pop(context);
        SnackbarHelper.showSuccess(context, 'QR code berhasil diunggah');
      }
    } catch (e) {
      if (mounted) {
        final message = getFriendlyErrorMessage(
          e,
          fallbackMessage: 'Gagal mengunggah QR code.',
        );
        SnackbarHelper.showError(context, message);
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUploading = false;
        });
      }
    }
  }

  Future<void> _deleteQRCode() async {
    try {
      setState(() {
        _isDeleting = true;
      });

      final url = widget.controller.customQRCodeUrl;
      if (url != null && url.isNotEmpty) {
        await StorageService.deleteCustomQRCode(url);
      }

      await widget.controller.setCustomQRCodeUrl(null);

      if (mounted) {
        Navigator.pop(context);
        SnackbarHelper.showSuccess(context, 'QR code berhasil dihapus');
      }
    } catch (e) {
      if (mounted) {
        final message = getFriendlyErrorMessage(
          e,
          fallbackMessage: 'Gagal menghapus QR code.',
        );
        SnackbarHelper.showError(context, message);
      }
    } finally {
      if (mounted) {
        setState(() {
          _isDeleting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasQRCode = widget.controller.customQRCodeUrl != null &&
        widget.controller.customQRCodeUrl!.isNotEmpty;

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text('Kelola QR Code Pembayaran'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (hasQRCode) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: Image.network(
                  widget.controller.customQRCodeUrl!,
                  width: 250,
                  height: 250,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      width: 250,
                      height: 250,
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.error_outline,
                        size: 48,
                        color: Colors.grey,
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
            ] else ...[
              Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: const Column(
                  children: [
                    Icon(Icons.qr_code_rounded, size: 64, color: Colors.grey),
                    SizedBox(height: 16),
                    Text(
                      'Belum ada QR code',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],
            if (_isUploading) ...[
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              const Text('Mengunggah QR code...'),
            ] else if (_isDeleting) ...[
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              const Text('Menghapus QR code...'),
            ] else ...[
              ListTile(
                leading: const Icon(Icons.camera_alt_rounded),
                title: const Text('Ambil dari Kamera'),
                onTap: () => _pickAndUploadQRCode(ImageSource.camera),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_rounded),
                title: const Text('Pilih dari Galeri'),
                onTap: () => _pickAndUploadQRCode(ImageSource.gallery),
              ),
              if (hasQRCode)
                ListTile(
                  leading: const Icon(Icons.delete_rounded, color: Colors.red),
                  title: const Text('Hapus QR Code', style: TextStyle(color: Colors.red)),
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Hapus QR Code?'),
                        content: const Text('Apakah Anda yakin ingin menghapus QR code ini?'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Batal'),
                          ),
                          ElevatedButton(
                            onPressed: () {
                              Navigator.pop(context);
                              _deleteQRCode();
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              foregroundColor: Colors.white,
                            ),
                            child: const Text('Hapus'),
                          ),
                        ],
                      ),
                    );
                  },
                ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Tutup'),
        ),
      ],
    );
  }
}


