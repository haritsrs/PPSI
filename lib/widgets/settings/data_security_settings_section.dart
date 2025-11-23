import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../services/settings_controller.dart';
import '../../utils/snackbar_helper.dart';
import 'settings_section.dart';
import 'setting_item.dart';

class DataSecuritySettingsSection extends StatelessWidget {
  final SettingsController controller;

  const DataSecuritySettingsSection({
    super.key,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return SettingsSection(
      title: "Data & Keamanan",
      icon: Icons.security_rounded,
      color: const Color(0xFFEF4444),
      children: [
        SettingItem(
          icon: Icons.backup_rounded,
          title: "Backup Otomatis",
          subtitle: "Backup data harian",
          trailing: Switch(
            value: controller.autoBackupEnabled,
            onChanged: (value) {
              SnackbarHelper.showInfo(context, 'Fitur backup otomatis akan segera hadir!');
            },
            activeColor: const Color(0xFF6366F1),
          ),
        ),
        SettingItem(
          icon: Icons.cloud_off_rounded,
          title: "Mode Offline",
          subtitle: "Bekerja tanpa internet",
          trailing: Switch(
            value: controller.offlineModeEnabled,
            onChanged: (value) {
              SnackbarHelper.showInfo(context, 'Fitur mode offline akan segera hadir!');
            },
            activeColor: const Color(0xFF6366F1),
          ),
        ),
        SettingItem(
          icon: Icons.backup_rounded,
          title: "Backup Sekarang",
          subtitle: "Lakukan backup manual",
          onTap: () {
            SnackbarHelper.showInfo(context, 'Fitur backup akan segera hadir!');
          },
        ),
        SettingItem(
          icon: Icons.lock_rounded,
          title: "Ubah Password",
          subtitle: "Keamanan akun",
          onTap: () {
            SnackbarHelper.showInfo(context, 'Fitur ubah password akan segera hadir!');
          },
        ),
      ],
    );
  }
}

