import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../services/settings_controller.dart';
import 'settings_section.dart';
import 'setting_item.dart';

class NotificationsSettingsSection extends StatelessWidget {
  final SettingsController controller;

  const NotificationsSettingsSection({
    super.key,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return SettingsSection(
      title: "Notifikasi",
      icon: Icons.notifications_rounded,
      color: const Color(0xFFF59E0B),
      children: [
        SettingItem(
          icon: Icons.notifications_active_rounded,
          title: "Notifikasi",
          subtitle: "Aktifkan notifikasi",
          trailing: Switch(
            value: controller.notificationsEnabled,
            onChanged: (value) {
              controller.setNotificationsEnabled(value);
              HapticFeedback.lightImpact();
            },
            activeColor: const Color(0xFF6366F1),
          ),
        ),
        SettingItem(
          icon: Icons.volume_up_rounded,
          title: "Suara",
          subtitle: "Notifikasi suara",
          trailing: Switch(
            value: controller.soundEnabled,
            onChanged: (value) {
              controller.setSoundEnabled(value);
              HapticFeedback.lightImpact();
            },
            activeColor: const Color(0xFF6366F1),
          ),
        ),
        SettingItem(
          icon: Icons.vibration_rounded,
          title: "Getar",
          subtitle: "Haptic feedback",
          trailing: Switch(
            value: controller.hapticEnabled,
            onChanged: (value) {
              controller.setHapticEnabled(value);
              HapticFeedback.lightImpact();
            },
            activeColor: const Color(0xFF6366F1),
          ),
        ),
      ],
    );
  }
}

