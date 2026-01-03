import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../controllers/settings_controller.dart';
import '../../utils/snackbar_helper.dart';
import '../../main.dart';
import 'settings_section.dart';
import 'setting_item.dart';

class GeneralSettingsSection extends StatelessWidget {
  final SettingsController controller;

  const GeneralSettingsSection({
    super.key,
    required this.controller,
  });

  String _getUIScaleLabel(String preset) {
    switch (preset) {
      case 'small': return 'Kecil (90%)';
      case 'large': return 'Besar (115%)';
      case 'extra_large': return 'Sangat Besar (130%)';
      default: return 'Normal (100%)';
    }
  }

  void _showUIScaleDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ukuran Tampilan'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Pilih ukuran teks dan elemen UI:'),
            const SizedBox(height: 16),
            ...['small', 'normal', 'large', 'extra_large'].map((preset) {
              return RadioListTile<String>(
                title: Text(_getUIScaleLabel(preset)),
                value: preset,
                groupValue: controller.uiScalePreset,
                onChanged: (value) async {
                  if (value != null) {
                    await controller.setUIScalePreset(value);
                    KiosDarmaApp.updateUIScale(value);
                    if (context.mounted) Navigator.pop(context);
                  }
                },
              );
            }),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SettingsSection(
      title: "Umum",
      icon: Icons.tune_rounded,
      color: const Color(0xFF3B82F6),
      children: [
        SettingItem(
          icon: Icons.text_fields_rounded,
          title: "Ukuran Tampilan",
          subtitle: _getUIScaleLabel(controller.uiScalePreset),
          onTap: () => _showUIScaleDialog(context),
        ),
        SettingItem(
          icon: Icons.language_rounded,
          title: "Bahasa",
          subtitle: controller.selectedLanguage,
          onTap: () {
            SnackbarHelper.showInfo(context, 'Fitur bahasa akan segera hadir!');
          },
        ),
        SettingItem(
          icon: Icons.attach_money_rounded,
          title: "Mata Uang",
          subtitle: controller.selectedCurrency,
          onTap: () {
            SnackbarHelper.showInfo(context, 'Fitur mata uang akan segera hadir!');
          },
        ),
        SettingItem(
          icon: Icons.dark_mode_rounded,
          title: "Mode Gelap",
          subtitle: "Tema aplikasi",
          trailing: Switch(
            value: controller.darkModeEnabled,
            onChanged: (value) {
              SnackbarHelper.showInfo(context, 'Fitur mode gelap akan segera hadir!');
            },
            activeColor: const Color(0xFF6366F1),
          ),
        ),
      ],
    );
  }
}

