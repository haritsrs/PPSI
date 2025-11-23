import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../controllers/settings_controller.dart';
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
                  await controller.setTaxEnabled(value);
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
          ],
        ),
      ],
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
}

