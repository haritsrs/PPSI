import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../../controllers/settings_controller.dart';

class LanguageDialog extends StatelessWidget {
  final SettingsController controller;

  const LanguageDialog({
    super.key,
    required this.controller,
  });

  static Future<void> show(BuildContext context, SettingsController controller) {
    return showDialog(
      context: context,
      builder: (context) => LanguageDialog(controller: controller),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          Icon(Icons.language_rounded, color: Colors.blue[600]),
          const SizedBox(width: 8),
          const Text('Pilih Bahasa'),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: controller.languages.map((language) {
          return RadioListTile<String>(
            title: Text(language),
            value: language,
            groupValue: controller.selectedLanguage,
            onChanged: (value) async {
              await controller.setLanguage(value!);
              if (context.mounted) {
                Navigator.pop(context);
              }
            },
          );
        }).toList(),
      ),
    );
  }
}

class CurrencyDialog extends StatelessWidget {
  final SettingsController controller;

  const CurrencyDialog({
    super.key,
    required this.controller,
  });

  static Future<void> show(BuildContext context, SettingsController controller) {
    return showDialog(
      context: context,
      builder: (context) => CurrencyDialog(controller: controller),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          Icon(Icons.attach_money_rounded, color: Colors.green[600]),
          const SizedBox(width: 8),
          const Text('Pilih Mata Uang'),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: controller.currencies.map((currency) {
          return RadioListTile<String>(
            title: Text(currency),
            value: currency,
            groupValue: controller.selectedCurrency,
            onChanged: (value) async {
              await controller.setCurrency(value!);
              if (context.mounted) {
                Navigator.pop(context);
              }
            },
          );
        }).toList(),
      ),
    );
  }
}

class PrinterDialog extends StatelessWidget {
  final SettingsController controller;

  const PrinterDialog({
    super.key,
    required this.controller,
  });

  static Future<void> show(BuildContext context, SettingsController controller) {
    return showDialog(
      context: context,
      builder: (context) => PrinterDialog(controller: controller),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          Icon(Icons.print_rounded, color: Colors.orange[600]),
          const SizedBox(width: 8),
          const Text('Pilih Printer'),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: controller.printers.map((printer) {
          return RadioListTile<String>(
            title: Text(printer),
            value: printer,
            groupValue: controller.selectedPrinter,
            onChanged: (value) async {
              await controller.setPrinter(value!);
              if (context.mounted) {
                Navigator.pop(context);
              }
            },
          );
        }).toList(),
      ),
    );
  }
}

class EditProfileDialog extends StatelessWidget {
  const EditProfileDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog(
      context: context,
      builder: (context) => const EditProfileDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          Icon(Icons.edit_rounded, color: Colors.blue[600]),
          const SizedBox(width: 8),
          const Text('Edit Profil'),
        ],
      ),
      content: const Text('Fitur edit profil akan segera hadir!'),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('OK'),
        ),
      ],
    );
  }
}

class ChangePasswordDialog extends StatelessWidget {
  const ChangePasswordDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog(
      context: context,
      builder: (context) => const ChangePasswordDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          Icon(Icons.lock_rounded, color: Colors.red[600]),
          const SizedBox(width: 8),
          const Text('Ubah Password'),
        ],
      ),
      content: const Text('Fitur ubah password akan segera hadir!'),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('OK'),
        ),
      ],
    );
  }
}

class HelpDialog extends StatelessWidget {
  const HelpDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog(
      context: context,
      builder: (context) => const HelpDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          Icon(Icons.help_center_rounded, color: Colors.purple[600]),
          const SizedBox(width: 8),
          const Text('Bantuan'),
        ],
      ),
      content: const Text('Pusat bantuan akan segera hadir!'),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('OK'),
        ),
      ],
    );
  }
}

class SettingsAboutDialog extends StatelessWidget {
  const SettingsAboutDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog(
      context: context,
      builder: (context) => const SettingsAboutDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          Icon(Icons.info_rounded, color: Colors.blue[600]),
          const SizedBox(width: 8),
          const Text('Tentang Aplikasi'),
        ],
      ),
      content: FutureBuilder<PackageInfo>(
        future: PackageInfo.fromPlatform(),
        builder: (context, snapshot) {
          final version = snapshot.hasData ? snapshot.data!.version : 'Loading...';
          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('KiosDarma v$version'),
              const SizedBox(height: 8),
              const Text('Aplikasi manajemen toko modern dengan fitur lengkap untuk kasir, stok, dan laporan.'),
              const SizedBox(height: 16),
              const Text('© 2024 KiosDarma. All rights reserved.'),
            ],
          );
        },
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('OK'),
        ),
      ],
    );
  }
}

class LogoutDialog extends StatelessWidget {
  final SettingsController controller;

  const LogoutDialog({
    super.key,
    required this.controller,
  });

  static Future<void> show(BuildContext context, SettingsController controller) {
    return showDialog(
      context: context,
      builder: (context) => LogoutDialog(controller: controller),
    );
  }

  Future<void> _handleLogout(BuildContext context) async {
    Navigator.of(context).pop();
    try {
      await controller.signOut();
      // The AuthWrapper will automatically redirect to login page
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal keluar: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          Icon(Icons.logout_rounded, color: Colors.red[600]),
          const SizedBox(width: 8),
          const Text('Keluar'),
        ],
      ),
      content: const Text('Apakah Anda yakin ingin keluar dari aplikasi?'),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Batal'),
        ),
        ElevatedButton(
          onPressed: () => _handleLogout(context),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
          ),
          child: const Text('Keluar'),
        ),
      ],
    );
  }
}

class ResetSettingsDialog extends StatelessWidget {
  final SettingsController controller;

  const ResetSettingsDialog({
    super.key,
    required this.controller,
  });

  static Future<void> show(BuildContext context, SettingsController controller) {
    return showDialog(
      context: context,
      builder: (context) => ResetSettingsDialog(controller: controller),
    );
  }

  void _handleReset(BuildContext context) {
    Navigator.of(context).pop();
    controller.resetToDefaults();
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pengaturan berhasil direset'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          Icon(Icons.refresh_rounded, color: Colors.orange[600]),
          const SizedBox(width: 8),
          const Text('Reset Pengaturan'),
        ],
      ),
      content: const Text('Apakah Anda yakin ingin mereset semua pengaturan ke default?'),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Batal'),
        ),
        ElevatedButton(
          onPressed: () => _handleReset(context),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.orange,
            foregroundColor: Colors.white,
          ),
          child: const Text('Reset'),
        ),
      ],
    );
  }
}


