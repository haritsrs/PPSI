import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import 'account_action_tile.dart';

class AccountActionsSection extends StatelessWidget {
  final User? currentUser;
  final VoidCallback onChangePassword;
  final VoidCallback onVerifyEmail;
  final VoidCallback onCheckVerification;
  final VoidCallback onLogout;

  const AccountActionsSection({
    super.key,
    required this.currentUser,
    required this.onChangePassword,
    required this.onVerifyEmail,
    required this.onCheckVerification,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Tindakan",
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: const Color(0xFF1F2937),
            ),
          ),
          const SizedBox(height: 16),
          AccountActionTile(
            icon: Icons.lock_rounded,
            title: "Ubah Password",
            subtitle: "Ganti password akun Anda",
            color: const Color(0xFF3B82F6),
            onTap: () {
              HapticFeedback.lightImpact();
              onChangePassword();
            },
          ),
          const Divider(height: 32),
          AccountActionTile(
            icon: Icons.verified_user_rounded,
            title: "Verifikasi Email",
            subtitle: currentUser?.emailVerified == true
                ? "Email sudah terverifikasi"
                : "Verifikasi email Anda",
            color: currentUser?.emailVerified == true
                ? Colors.green
                : const Color(0xFFF59E0B),
            onTap: currentUser?.emailVerified == true
                ? () {
                    HapticFeedback.lightImpact();
                    onCheckVerification();
                  }
                : () {
                    HapticFeedback.lightImpact();
                    onVerifyEmail();
                  },
          ),
          const Divider(height: 32),
          AccountActionTile(
            icon: Icons.logout_rounded,
            title: "Keluar",
            subtitle: "Logout dari akun Anda",
            color: const Color(0xFFEF4444),
            onTap: () {
              HapticFeedback.lightImpact();
              onLogout();
            },
          ),
        ],
      ),
    );
  }
}


