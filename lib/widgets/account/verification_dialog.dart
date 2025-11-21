import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class VerificationDialog extends StatelessWidget {
  final User? currentUser;
  final VoidCallback onSendEmail;
  final VoidCallback onCheckStatus;

  const VerificationDialog({
    super.key,
    required this.currentUser,
    required this.onSendEmail,
    required this.onCheckStatus,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          Icon(Icons.verified_user_rounded, color: Colors.orange[600]),
          const SizedBox(width: 8),
          const Text('Verifikasi Email'),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Kami akan mengirimkan email verifikasi ke alamat email Anda.',
          ),
          const SizedBox(height: 16),
          if (currentUser?.email != null)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.email_rounded, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      currentUser!.email!,
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Batal'),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.of(context).pop();
            onSendEmail();
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF6366F1),
            foregroundColor: Colors.white,
          ),
          child: const Text('Kirim Email'),
        ),
        if (currentUser?.emailVerified == false)
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              onCheckStatus();
            },
            child: const Text('Cek Status'),
          ),
      ],
    );
  }
}

