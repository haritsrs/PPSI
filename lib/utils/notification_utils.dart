import 'package:flutter/material.dart';

/// Utility functions for notification-related operations
class NotificationUtils {
  NotificationUtils._();

  /// Get icon for notification type
  static IconData getNotificationIcon(String type) {
    switch (type) {
      case 'transaction':
        return Icons.receipt_long_rounded;
      case 'product':
        return Icons.inventory_2_rounded;
      case 'stock':
        return Icons.warning_amber_rounded;
      default:
        return Icons.notifications_rounded;
    }
  }

  /// Get color for notification type
  static Color getNotificationColor(String type) {
    switch (type) {
      case 'transaction':
        return const Color(0xFF10B981);
      case 'product':
        return const Color(0xFF3B82F6);
      case 'stock':
        return const Color(0xFFF59E0B);
      default:
        return const Color(0xFF6366F1);
    }
  }

  /// Format DateTime to relative time string
  static String formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return '${difference.inDays} hari lalu';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} jam lalu';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} menit lalu';
    } else {
      return 'Baru saja';
    }
  }
}

