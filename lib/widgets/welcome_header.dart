import 'package:flutter/material.dart';
import '../utils/responsive_helper.dart';

/// Reusable welcome header widget
class WelcomeHeader extends StatelessWidget {
  final String userName;
  final IconData icon;

  const WelcomeHeader({
    super.key,
    required this.userName,
    this.icon = Icons.waving_hand_rounded,
  });

  @override
  Widget build(BuildContext context) {
    final fontScale = ResponsiveHelper.getFontScale(context);
    final paddingScale = ResponsiveHelper.getPaddingScale(context);
    final iconScale = ResponsiveHelper.getIconScale(context);

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(24 * paddingScale),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6366F1).withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: Colors.white,
            size: 48 * iconScale,
          ),
          SizedBox(height: 12 * paddingScale),
          Text(
            "Selamat Datang, $userName!",
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: (Theme.of(context).textTheme.titleLarge?.fontSize ?? 22) * fontScale,
                ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

