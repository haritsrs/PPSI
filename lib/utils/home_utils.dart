import 'package:flutter/material.dart';

/// Utility functions for home page

/// Formats a number as Indonesian currency format
String formatCurrency(num amount) {
  return amount.toStringAsFixed(0).replaceAllMapped(
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

/// Formats a DateTime to "dd/MM/yyyy HH:mm" format
String formatDateTime(DateTime dateTime) {
  return "${dateTime.day.toString().padLeft(2, '0')}/${dateTime.month.toString().padLeft(2, '0')}/${dateTime.year} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}";
}

/// Formats a DateTime to "dd/MM/yyyy" format
String formatDate(DateTime date) {
  return "${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}";
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


