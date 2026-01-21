import 'package:flutter/material.dart';

class EmptyNotificationState extends StatelessWidget {
  final bool hasNotifications;

  const EmptyNotificationState({
    super.key,
    this.hasNotifications = false,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.notifications_none_rounded,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            hasNotifications
                ? "Tidak ada notifikasi yang cocok"
                : "Tidak ada notifikasi",
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
          ),
        ],
      ),
    );
  }
}


