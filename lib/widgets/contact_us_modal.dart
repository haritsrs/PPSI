import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../utils/responsive_helper.dart';

class ContactUsModal extends StatelessWidget {
  const ContactUsModal({super.key});

  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => const ContactUsModal(),
    );
  }

  Future<void> _launchEmail() async {
    try {
      final Uri emailUri = Uri(
        scheme: 'mailto',
        path: 'haritssetiono23@gmail.com',
        query: 'subject=Kontak dari Aplikasi KiosDarma',
      );
      if (await canLaunchUrl(emailUri)) {
        await launchUrl(emailUri);
      }
    } catch (e) {
      // Handle error silently
    }
  }

  Future<void> _launchWhatsApp() async {
    try {
      final Uri whatsappUri = Uri.parse('https://wa.me/62812894773692');
      if (await canLaunchUrl(whatsappUri)) {
        await launchUrl(whatsappUri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      // Handle error silently
    }
  }

  @override
  Widget build(BuildContext context) {
    final fontScale = ResponsiveHelper.getFontScale(context);
    final paddingScale = ResponsiveHelper.getPaddingScale(context);
    final iconScale = ResponsiveHelper.getIconScale(context);

    return Container(
      height: MediaQuery.of(context).size.height * 0.6,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: Column(
        children: [
          // Handle
          Container(
            margin: EdgeInsets.only(top: 12 * paddingScale),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: EdgeInsets.all(24 * paddingScale),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(12 * paddingScale),
                  decoration: BoxDecoration(
                    color: const Color(0xFF6366F1).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.contact_support_rounded,
                    color: const Color(0xFF6366F1),
                    size: 28 * iconScale,
                  ),
                ),
                SizedBox(width: 16 * paddingScale),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Hubungi Developer',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              color: const Color(0xFF1F2937),
                              fontWeight: FontWeight.w700,
                              fontSize:
                                  (Theme.of(context).textTheme.titleLarge?.fontSize ?? 22) * fontScale,
                            ),
                      ),
                      SizedBox(height: 4 * paddingScale),
                      Text(
                        'Butuh bantuan? Hubungi kami',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: const Color(0xFF9CA3AF),
                              fontSize:
                                  (Theme.of(context).textTheme.bodySmall?.fontSize ?? 12) * fontScale,
                            ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),

          Divider(height: 1, color: Colors.grey[200]),

          // Content
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(24 * paddingScale),
              child: Column(
                children: [
                  _buildContactOption(
                    context,
                    icon: Icons.email_rounded,
                    title: 'Email',
                    subtitle: 'haritssetiono23@gmail.com',
                    color: const Color(0xFF6366F1),
                    onTap: _launchEmail,
                    paddingScale: paddingScale,
                    iconScale: iconScale,
                    fontScale: fontScale,
                  ),
                  SizedBox(height: 16 * paddingScale),
                  _buildContactOption(
                    context,
                    icon: Icons.chat_rounded,
                    title: 'WhatsApp',
                    subtitle: '+62 812-8947-73692',
                    color: const Color(0xFF25D366),
                    onTap: _launchWhatsApp,
                    paddingScale: paddingScale,
                    iconScale: iconScale,
                    fontScale: fontScale,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactOption(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
    required double paddingScale,
    required double iconScale,
    required double fontScale,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: EdgeInsets.all(20 * paddingScale),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: color.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(12 * paddingScale),
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: Colors.white,
                size: 24 * iconScale,
              ),
            ),
            SizedBox(width: 16 * paddingScale),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: const Color(0xFF1F2937),
                          fontWeight: FontWeight.w600,
                          fontSize:
                              (Theme.of(context).textTheme.titleMedium?.fontSize ?? 16) * fontScale,
                        ),
                  ),
                  SizedBox(height: 4 * paddingScale),
                  Text(
                    subtitle,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey[600],
                          fontSize:
                              (Theme.of(context).textTheme.bodyMedium?.fontSize ?? 14) * fontScale,
                        ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios_rounded,
              color: color,
              size: 16 * iconScale,
            ),
          ],
        ),
      ),
    );
  }
}

