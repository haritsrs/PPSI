import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class PengaturanPage extends StatefulWidget {
  const PengaturanPage({super.key});

  @override
  State<PengaturanPage> createState() => _PengaturanPageState();
}

class _PengaturanPageState extends State<PengaturanPage> with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  
  // Settings state
  bool _notificationsEnabled = true;
  bool _soundEnabled = true;
  bool _hapticEnabled = true;
  bool _darkModeEnabled = false;
  bool _autoBackupEnabled = true;
  bool _offlineModeEnabled = false;
  bool _printerEnabled = true;
  bool _barcodeScannerEnabled = true;
  
  String _selectedLanguage = 'Bahasa Indonesia';
  String _selectedCurrency = 'IDR (Rupiah)';
  String _selectedPrinter = 'Default Printer';
  
  final List<String> _languages = ['Bahasa Indonesia', 'English', '中文'];
  final List<String> _currencies = ['IDR (Rupiah)', 'USD (Dollar)', 'EUR (Euro)'];
  final List<String> _printers = ['Default Printer', 'Thermal Printer', 'Bluetooth Printer'];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));
    
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle.dark,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.settings_rounded,
                color: Colors.white,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              "Pengaturan",
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              onPressed: () {
                HapticFeedback.lightImpact();
                _showResetDialog();
              },
              icon: const Icon(Icons.refresh_rounded, color: Colors.white),
            ),
          ),
        ],
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Profile Section
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Icon(
                          Icons.person_rounded,
                          color: Colors.white,
                          size: 30,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Harits",
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF1F2937),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              "Admin KiosDarma",
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Colors.grey[600],
                              ),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFF10B981).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                "Premium",
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: const Color(0xFF10B981),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () {
                          HapticFeedback.lightImpact();
                          _showEditProfileDialog();
                        },
                        icon: const Icon(
                          Icons.edit_rounded,
                          color: Color(0xFF6366F1),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // General Settings
                _buildSettingsSection(
                  title: "Umum",
                  icon: Icons.tune_rounded,
                  color: const Color(0xFF3B82F6),
                  children: [
                    _buildSettingItem(
                      icon: Icons.language_rounded,
                      title: "Bahasa",
                      subtitle: _selectedLanguage,
                      onTap: () => _showLanguageDialog(),
                    ),
                    _buildSettingItem(
                      icon: Icons.attach_money_rounded,
                      title: "Mata Uang",
                      subtitle: _selectedCurrency,
                      onTap: () => _showCurrencyDialog(),
                    ),
                    _buildSettingItem(
                      icon: Icons.dark_mode_rounded,
                      title: "Mode Gelap",
                      subtitle: "Tema aplikasi",
                      trailing: Switch(
                        value: _darkModeEnabled,
                        onChanged: (value) {
                          setState(() {
                            _darkModeEnabled = value;
                          });
                          HapticFeedback.lightImpact();
                        },
                        activeColor: const Color(0xFF6366F1),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Notifications Settings
                _buildSettingsSection(
                  title: "Notifikasi",
                  icon: Icons.notifications_rounded,
                  color: const Color(0xFFF59E0B),
                  children: [
                    _buildSettingItem(
                      icon: Icons.notifications_active_rounded,
                      title: "Notifikasi",
                      subtitle: "Aktifkan notifikasi",
                      trailing: Switch(
                        value: _notificationsEnabled,
                        onChanged: (value) {
                          setState(() {
                            _notificationsEnabled = value;
                          });
                          HapticFeedback.lightImpact();
                        },
                        activeColor: const Color(0xFF6366F1),
                      ),
                    ),
                    _buildSettingItem(
                      icon: Icons.volume_up_rounded,
                      title: "Suara",
                      subtitle: "Notifikasi suara",
                      trailing: Switch(
                        value: _soundEnabled,
                        onChanged: (value) {
                          setState(() {
                            _soundEnabled = value;
                          });
                          HapticFeedback.lightImpact();
                        },
                        activeColor: const Color(0xFF6366F1),
                      ),
                    ),
                    _buildSettingItem(
                      icon: Icons.vibration_rounded,
                      title: "Getar",
                      subtitle: "Haptic feedback",
                      trailing: Switch(
                        value: _hapticEnabled,
                        onChanged: (value) {
                          setState(() {
                            _hapticEnabled = value;
                          });
                          HapticFeedback.lightImpact();
                        },
                        activeColor: const Color(0xFF6366F1),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Business Settings
                _buildSettingsSection(
                  title: "Bisnis",
                  icon: Icons.business_rounded,
                  color: const Color(0xFF10B981),
                  children: [
                    _buildSettingItem(
                      icon: Icons.print_rounded,
                      title: "Printer",
                      subtitle: _selectedPrinter,
                      onTap: () => _showPrinterDialog(),
                    ),
                    _buildSettingItem(
                      icon: Icons.print_rounded,
                      title: "Aktifkan Printer",
                      subtitle: "Cetak struk otomatis",
                      trailing: Switch(
                        value: _printerEnabled,
                        onChanged: (value) {
                          setState(() {
                            _printerEnabled = value;
                          });
                          HapticFeedback.lightImpact();
                        },
                        activeColor: const Color(0xFF6366F1),
                      ),
                    ),
                    _buildSettingItem(
                      icon: Icons.qr_code_scanner_rounded,
                      title: "Scanner Barcode",
                      subtitle: "Aktifkan scanner",
                      trailing: Switch(
                        value: _barcodeScannerEnabled,
                        onChanged: (value) {
                          setState(() {
                            _barcodeScannerEnabled = value;
                          });
                          HapticFeedback.lightImpact();
                        },
                        activeColor: const Color(0xFF6366F1),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Data & Security Settings
                _buildSettingsSection(
                  title: "Data & Keamanan",
                  icon: Icons.security_rounded,
                  color: const Color(0xFFEF4444),
                  children: [
                    _buildSettingItem(
                      icon: Icons.backup_rounded,
                      title: "Backup Otomatis",
                      subtitle: "Backup data harian",
                      trailing: Switch(
                        value: _autoBackupEnabled,
                        onChanged: (value) {
                          setState(() {
                            _autoBackupEnabled = value;
                          });
                          HapticFeedback.lightImpact();
                        },
                        activeColor: const Color(0xFF6366F1),
                      ),
                    ),
                    _buildSettingItem(
                      icon: Icons.cloud_off_rounded,
                      title: "Mode Offline",
                      subtitle: "Bekerja tanpa internet",
                      trailing: Switch(
                        value: _offlineModeEnabled,
                        onChanged: (value) {
                          setState(() {
                            _offlineModeEnabled = value;
                          });
                          HapticFeedback.lightImpact();
                        },
                        activeColor: const Color(0xFF6366F1),
                      ),
                    ),
                    _buildSettingItem(
                      icon: Icons.lock_rounded,
                      title: "Ubah Password",
                      subtitle: "Keamanan akun",
                      onTap: () => _showChangePasswordDialog(),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Support & About
                _buildSettingsSection(
                  title: "Dukungan",
                  icon: Icons.help_rounded,
                  color: const Color(0xFF8B5CF6),
                  children: [
                    _buildSettingItem(
                      icon: Icons.help_center_rounded,
                      title: "Bantuan",
                      subtitle: "Pusat bantuan",
                      onTap: () => _showHelpDialog(),
                    ),
                    _buildSettingItem(
                      icon: Icons.info_rounded,
                      title: "Tentang Aplikasi",
                      subtitle: "Versi 1.0.0",
                      onTap: () => _showAboutDialog(),
                    ),
                    _buildSettingItem(
                      icon: Icons.logout_rounded,
                      title: "Keluar",
                      subtitle: "Logout dari aplikasi",
                      onTap: () => _showLogoutDialog(),
                    ),
                  ],
                ),

                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSettingsSection({
    required String title,
    required IconData icon,
    required Color color,
    required List<Widget> children,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    icon,
                    color: color,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF1F2937),
                  ),
                ),
              ],
            ),
          ),
          ...children,
        ],
      ),
    );
  }

  Widget _buildSettingItem({
    required IconData icon,
    required String title,
    required String subtitle,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFF6366F1).withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: const Color(0xFF6366F1),
            size: 20,
          ),
        ),
        title: Text(
          title,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            fontWeight: FontWeight.w600,
            color: const Color(0xFF1F2937),
          ),
        ),
        subtitle: Text(
          subtitle,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Colors.grey[600],
          ),
        ),
        trailing: trailing ?? const Icon(Icons.chevron_right_rounded, color: Colors.grey),
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(vertical: 8),
      ),
    );
  }

  void _showLanguageDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
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
            children: _languages.map((language) {
              return RadioListTile<String>(
                title: Text(language),
                value: language,
                groupValue: _selectedLanguage,
                onChanged: (value) {
                  setState(() {
                    _selectedLanguage = value!;
                  });
                  Navigator.pop(context);
                },
              );
            }).toList(),
          ),
        );
      },
    );
  }

  void _showCurrencyDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
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
            children: _currencies.map((currency) {
              return RadioListTile<String>(
                title: Text(currency),
                value: currency,
                groupValue: _selectedCurrency,
                onChanged: (value) {
                  setState(() {
                    _selectedCurrency = value!;
                  });
                  Navigator.pop(context);
                },
              );
            }).toList(),
          ),
        );
      },
    );
  }

  void _showPrinterDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
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
            children: _printers.map((printer) {
              return RadioListTile<String>(
                title: Text(printer),
                value: printer,
                groupValue: _selectedPrinter,
                onChanged: (value) {
                  setState(() {
                    _selectedPrinter = value!;
                  });
                  Navigator.pop(context);
                },
              );
            }).toList(),
          ),
        );
      },
    );
  }

  void _showEditProfileDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
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
      },
    );
  }

  void _showChangePasswordDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
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
      },
    );
  }

  void _showHelpDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
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
      },
    );
  }

  void _showAboutDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              Icon(Icons.info_rounded, color: Colors.blue[600]),
              const SizedBox(width: 8),
              const Text('Tentang Aplikasi'),
            ],
          ),
          content: const Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('KiosDarma v1.0.0'),
              SizedBox(height: 8),
              Text('Aplikasi manajemen toko modern dengan fitur lengkap untuk kasir, stok, dan laporan.'),
              SizedBox(height: 16),
              Text('© 2024 KiosDarma. All rights reserved.'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
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
              onPressed: () {
                Navigator.of(context).pop();
                // TODO: Implement logout functionality
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Berhasil keluar dari aplikasi'),
                    backgroundColor: Colors.green,
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Keluar'),
            ),
          ],
        );
      },
    );
  }

  void _showResetDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
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
              onPressed: () {
                Navigator.of(context).pop();
                setState(() {
                  _notificationsEnabled = true;
                  _soundEnabled = true;
                  _hapticEnabled = true;
                  _darkModeEnabled = false;
                  _autoBackupEnabled = true;
                  _offlineModeEnabled = false;
                  _printerEnabled = true;
                  _barcodeScannerEnabled = true;
                  _selectedLanguage = 'Bahasa Indonesia';
                  _selectedCurrency = 'IDR (Rupiah)';
                  _selectedPrinter = 'Default Printer';
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Pengaturan berhasil direset'),
                    backgroundColor: Colors.green,
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
              ),
              child: const Text('Reset'),
            ),
          ],
        );
      },
    );
  }
}
