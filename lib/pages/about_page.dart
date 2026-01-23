import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../widgets/gradient_app_bar.dart';
import '../utils/haptic_helper.dart';

class AboutPage extends StatefulWidget {
  const AboutPage({super.key});

  @override
  State<AboutPage> createState() => _AboutPageState();
}

class _AboutPageState extends State<AboutPage> {
  String _version = '';
  String _buildNumber = '';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPackageInfo();
  }

  Future<void> _loadPackageInfo() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      setState(() {
        _version = packageInfo.version;
        _buildNumber = packageInfo.buildNumber;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _version = 'Unknown';
        _buildNumber = 'Unknown';
        _isLoading = false;
      });
    }
  }

  void _showLicensesDialog() {
    HapticHelper.lightImpact();
    showLicensePage(
      context: context,
      applicationName: 'PPSI (KiosDarma)',
      applicationVersion: 'v$_version (Build $_buildNumber)',
      applicationLegalese: '© 2024-2025 KiosDarma. All rights reserved.',
    );
  }

  void _showPrivacyPolicy() {
    HapticHelper.lightImpact();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Kebijakan Privasi'),
        content: const SingleChildScrollView(
          child: Text(
            'PPSI (KiosDarma) menghormati privasi pengguna. Data Anda disimpan secara lokal dan di Firebase untuk keperluan sinkronisasi.\n\n'
            'Kami tidak membagikan data Anda dengan pihak ketiga tanpa izin Anda.\n\n'
            'Untuk informasi lebih lanjut, silakan hubungi kami melalui email: support@kiosdarma.com',
            style: TextStyle(fontSize: 14),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Tutup'),
          ),
        ],
      ),
    );
  }

  void _showTermsOfService() {
    HapticHelper.lightImpact();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Syarat & Ketentuan'),
        content: const SingleChildScrollView(
          child: Text(
            'Dengan menggunakan aplikasi PPSI (KiosDarma), Anda setuju untuk:\n\n'
            '1. Menggunakan aplikasi sesuai dengan hukum yang berlaku\n'
            '2. Bertanggung jawab penuh atas data transaksi dan bisnis Anda\n'
            '3. Menjaga kerahasiaan kredensial akun Anda\n'
            '4. Melaporkan bug atau masalah keamanan yang ditemukan\n\n'
            'Kami berhak memperbarui syarat dan ketentuan ini dari waktu ke waktu.',
            style: TextStyle(fontSize: 14),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Tutup'),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem({
    required IconData icon,
    required String title,
    required String subtitle,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 5,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: const Color(0xFF6366F1).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: const Color(0xFF6366F1)),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1F2937),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            if (onTap != null)
              Icon(Icons.chevron_right, color: Colors.grey[400]),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: const GradientAppBar(
        title: "Tentang Aplikasi",
        icon: Icons.info_rounded,
        automaticallyImplyLeading: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  // App Logo
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
                    child: Column(
                      children: [
                        Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            color: const Color(0xFF6366F1).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Icon(
                            Icons.shopping_bag_rounded,
                            size: 60,
                            color: Color(0xFF6366F1),
                          ),
                        ),
                        const SizedBox(height: 20),
                        const Text(
                          'PPSI (KiosDarma)',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1F2937),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'v$_version (Build $_buildNumber)',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Aplikasi Point of Sale (POS) modern untuk bisnis Anda',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[700],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Developer Info
                  _buildInfoItem(
                    icon: Icons.business_rounded,
                    title: 'Dikembangkan oleh',
                    subtitle: 'KiosDarma Team',
                  ),
                  const SizedBox(height: 12),

                  // Contact
                  _buildInfoItem(
                    icon: Icons.email_rounded,
                    title: 'Hubungi Kami',
                    subtitle: 'support@kiosdarma.com',
                  ),
                  const SizedBox(height: 12),

                  // Website
                  _buildInfoItem(
                    icon: Icons.language_rounded,
                    title: 'Website',
                    subtitle: 'www.kiosdarma.com',
                  ),
                  const SizedBox(height: 24),

                  // Legal Section
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
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
                        const Text(
                          'Legal',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF1F2937),
                          ),
                        ),
                        const SizedBox(height: 12),
                        ListTile(
                          leading: const Icon(Icons.description_rounded, color: Color(0xFF6366F1)),
                          title: const Text('Lisensi Open Source'),
                          trailing: Icon(Icons.chevron_right, color: Colors.grey[400]),
                          onTap: _showLicensesDialog,
                        ),
                        const Divider(height: 1),
                        ListTile(
                          leading: const Icon(Icons.privacy_tip_rounded, color: Color(0xFF6366F1)),
                          title: const Text('Kebijakan Privasi'),
                          trailing: Icon(Icons.chevron_right, color: Colors.grey[400]),
                          onTap: _showPrivacyPolicy,
                        ),
                        const Divider(height: 1),
                        ListTile(
                          leading: const Icon(Icons.gavel_rounded, color: Color(0xFF6366F1)),
                          title: const Text('Syarat & Ketentuan'),
                          trailing: Icon(Icons.chevron_right, color: Colors.grey[400]),
                          onTap: _showTermsOfService,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Copyright
                  Text(
                    '© 2024-2025 KiosDarma. All rights reserved.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Made with ❤️ in Indonesia',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
