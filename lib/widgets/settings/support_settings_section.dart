import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../../controllers/settings_controller.dart';
import '../../utils/snackbar_helper.dart';
import 'settings_section.dart';
import 'setting_item.dart';
import 'settings_dialogs.dart';

class SupportSettingsSection extends StatefulWidget {
  final SettingsController controller;

  const SupportSettingsSection({
    super.key,
    required this.controller,
  });

  @override
  State<SupportSettingsSection> createState() => _SupportSettingsSectionState();
}

class _SupportSettingsSectionState extends State<SupportSettingsSection> {
  String _version = 'Loading...';

  @override
  void initState() {
    super.initState();
    _loadVersion();
  }

  Future<void> _loadVersion() async {
    final packageInfo = await PackageInfo.fromPlatform();
    if (mounted) {
      setState(() {
        _version = 'Versi ${packageInfo.version}';
      });
    }
  }

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
          onTap: () {
            SnackbarHelper.showInfo(context, 'Pusat bantuan akan segera hadir!');
          },
        ),
        SettingItem(
          icon: Icons.info_rounded,
          title: "Tentang Aplikasi",
          subtitle: _version,
          onTap: () => SettingsAboutDialog.show(context),
        ),
        SettingItem(
          icon: Icons.logout_rounded,
          title: "Keluar",
          subtitle: "Logout dari aplikasi",
          onTap: () => LogoutDialog.show(context, widget.controller),
        ),
      ],
    );
  }
}


