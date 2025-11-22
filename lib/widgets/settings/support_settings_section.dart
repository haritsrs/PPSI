import 'package:flutter/material.dart';
import '../../services/settings_controller.dart';
import 'settings_section.dart';
import 'setting_item.dart';
import 'settings_dialogs.dart';

class SupportSettingsSection extends StatelessWidget {
  final SettingsController controller;

  const SupportSettingsSection({
    super.key,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return SettingsSection(
      title: "Dukungan",
      icon: Icons.help_rounded,
      color: const Color(0xFF8B5CF6),
      children: [
        SettingItem(
          icon: Icons.help_center_rounded,
          title: "Bantuan",
          subtitle: "Pusat bantuan",
          onTap: () => HelpDialog.show(context),
        ),
        SettingItem(
          icon: Icons.info_rounded,
          title: "Tentang Aplikasi",
          subtitle: "Versi 1.0.0",
          onTap: () => SettingsAboutDialog.show(context),
        ),
        SettingItem(
          icon: Icons.logout_rounded,
          title: "Keluar",
          subtitle: "Logout dari aplikasi",
          onTap: () => LogoutDialog.show(context, controller),
        ),
      ],
    );
  }
}

