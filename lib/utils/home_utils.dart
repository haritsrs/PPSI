import 'package:flutter/material.dart';

/// Utility functions for home page

/// Formats a number as Indonesian currency format
String formatCurrency(int amount) {
  return amount.toString().replaceAllMapped(
    RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
    (Match m) => '${m[1]}.',
  );
}

/// Returns a time-based greeting in Indonesian
String getGreeting() {
  final hour = DateTime.now().hour;
  if (hour < 12) {
    return 'Selamat Pagi';
  } else if (hour < 17) {
    return 'Selamat Siang';
  } else {
    return 'Selamat Sore';
  }
}

/// Formats a date as relative time in Indonesian (e.g., "2 hari yang lalu")
String formatRelativeDate(DateTime date) {
  final now = DateTime.now();
  final difference = now.difference(date);
  
  if (difference.inDays > 0) {
    return '${difference.inDays} hari yang lalu';
  } else if (difference.inHours > 0) {
    return '${difference.inHours} jam yang lalu';
  } else if (difference.inMinutes > 0) {
    return '${difference.inMinutes} menit yang lalu';
  } else {
    return 'Baru saja';
  }
}

/// Shows a "Coming Soon" dialog
void showComingSoonDialog(BuildContext context, String feature) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.construction, color: Colors.orange[600]),
            const SizedBox(width: 8),
            const Text('Coming Soon'),
          ],
        ),
        content: Text('Fitur $feature akan segera hadir!'),
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

