import 'package:flutter/material.dart';

class NotificationRailDestinationHelper {
  static NavigationRailDestination build({
    required int unreadCount,
    required double unselectedIconSize,
    required double iconSize,
    required double fontScale,
    required double paddingScale,
  }) {
    return NavigationRailDestination(
      icon: _buildIcon(unselectedIconSize, unreadCount),
      selectedIcon: _buildIcon(iconSize, unreadCount),
      label: Text(
        'Notifikasi',
        style: TextStyle(
          fontSize: 12 * fontScale,
        ),
      ),
      padding: EdgeInsets.symmetric(
        vertical: 10 * paddingScale,
        horizontal: 10 * paddingScale,
      ),
    );
  }

  static Widget _buildIcon(double size, int unreadCount) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Icon(Icons.notifications_rounded, size: size),
        if (unreadCount > 0)
          Positioned(
            right: -4,
            top: -4,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
              ),
              constraints: const BoxConstraints(
                minWidth: 16,
                minHeight: 16,
              ),
              child: Text(
                unreadCount > 9 ? '9+' : unreadCount.toString(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
      ],
    );
  }
}
