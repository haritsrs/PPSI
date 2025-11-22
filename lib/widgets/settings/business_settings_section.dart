import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../services/settings_controller.dart';
import 'settings_section.dart';
import 'setting_item.dart';
import 'settings_dialogs.dart';

class BusinessSettingsSection extends StatelessWidget {
  final SettingsController controller;

  const BusinessSettingsSection({
    super.key,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return SettingsSection(
      title: "Bisnis",
      icon: Icons.business_rounded,
      color: const Color(0xFF10B981),
      children: [
        SettingItem(
          icon: Icons.print_rounded,
          title: "Printer",
          subtitle: controller.selectedPrinter,
          onTap: () => PrinterDialog.show(context, controller),
        ),
        SettingItem(
          icon: Icons.print_rounded,
          title: "Aktifkan Printer",
          subtitle: "Cetak struk otomatis",
          trailing: Switch(
            value: controller.printerEnabled,
            onChanged: (value) {
              controller.setPrinterEnabled(value);
              HapticFeedback.lightImpact();
            },
            activeColor: const Color(0xFF6366F1),
          ),
        ),
        SettingItem(
          icon: Icons.qr_code_scanner_rounded,
          title: "Scanner Barcode",
          subtitle: "Aktifkan scanner",
          trailing: Switch(
            value: controller.barcodeScannerEnabled,
            onChanged: (value) {
              controller.setBarcodeScannerEnabled(value);
              HapticFeedback.lightImpact();
            },
            activeColor: const Color(0xFF6366F1),
          ),
        ),
      ],
    );
  }
}

