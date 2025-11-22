import 'package:flutter/material.dart';
import '../../services/settings_controller.dart';
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
          ],
        ),
      ],
    );
  }
}

