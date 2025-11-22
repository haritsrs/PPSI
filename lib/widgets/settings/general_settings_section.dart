import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../services/settings_controller.dart';
import 'settings_section.dart';
import 'setting_item.dart';
import 'settings_dialogs.dart';

class GeneralSettingsSection extends StatelessWidget {
  final SettingsController controller;

  const GeneralSettingsSection({
    super.key,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return SettingsSection(
      title: "Umum",
      icon: Icons.tune_rounded,
      color: const Color(0xFF3B82F6),
      children: [
        SettingItem(
          icon: Icons.language_rounded,
          title: "Bahasa",
          subtitle: controller.selectedLanguage,
          onTap: () => LanguageDialog.show(context, controller),
        ),
        SettingItem(
          icon: Icons.attach_money_rounded,
          title: "Mata Uang",
          subtitle: controller.selectedCurrency,
          onTap: () => CurrencyDialog.show(context, controller),
        ),
        SettingItem(
          icon: Icons.dark_mode_rounded,
          title: "Mode Gelap",
          subtitle: "Tema aplikasi",
          trailing: Switch(
            value: controller.darkModeEnabled,
            onChanged: (value) {
              controller.setDarkModeEnabled(value);
              HapticFeedback.lightImpact();
            },
            activeColor: const Color(0xFF6366F1),
          ),
        ),
      ],
    );
  }
}

