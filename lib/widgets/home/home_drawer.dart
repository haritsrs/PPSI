import 'package:flutter/material.dart';
import '../../utils/responsive_helper.dart';
import '../home/drawer_item.dart';

class HomeDrawer extends StatelessWidget {
  final Stream<int>? unreadNotificationsCount;
  final VoidCallback onAccountTap;
  final VoidCallback onNotificationTap;
  final VoidCallback onSettingsTap;
  final VoidCallback onLogoutTap;

  const HomeDrawer({
    super.key,
    this.unreadNotificationsCount,
    required this.onAccountTap,
    required this.onNotificationTap,
    required this.onSettingsTap,
    required this.onLogoutTap,
  });

  @override
  Widget build(BuildContext context) {
    try {
      final mediaQuery = MediaQuery.maybeOf(context);
      if (mediaQuery == null) {
        return const SizedBox.shrink();
      }

      final iconScale = ResponsiveHelper.getIconScale(context);
      final isTallPhoneLandscape = ResponsiveHelper.isTallPhoneInLandscape(context);

      if (!isTallPhoneLandscape) {
        return const SizedBox.shrink();
      }

      return Drawer(
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: SafeArea(
            child: Column(
              children: [
                _buildHeader(context, iconScale),
                Divider(color: Colors.white.withOpacity(0.2)),
                Expanded(
                  child: _buildMenuItems(context),
                ),
              ],
            ),
          ),
        ),
      );
    } catch (e) {
      return const SizedBox.shrink();
    }
  }

  Widget _buildHeader(BuildContext context, double iconScale) {
    return Container(
      padding: EdgeInsets.all(20 * iconScale),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(8 * iconScale),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.asset(
                'assets/images/logo.png',
                width: 32 * iconScale,
                height: 32 * iconScale,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  return Icon(
                    Icons.store_rounded,
                    color: Colors.white,
                    size: 32 * iconScale,
                  );
                },
              ),
            ),
          ),
          SizedBox(width: 12 * iconScale),
          Expanded(
            child: Text(
              "KiosDarma",
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: (Theme.of(context).textTheme.titleLarge?.fontSize ?? 22) *
                        ResponsiveHelper.getFontScale(context),
                  ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItems(BuildContext context) {
    return ListView(
      padding: EdgeInsets.zero,
      children: [
        DrawerItem(
          icon: Icons.person_rounded,
          title: 'Akun',
          onTap: () {
            Navigator.pop(context);
            onAccountTap();
          },
        ),
        if (unreadNotificationsCount != null)
          StreamBuilder<int>(
            stream: unreadNotificationsCount,
            builder: (context, snapshot) {
              final unreadCount = snapshot.data ?? 0;
              return DrawerItem(
                icon: Icons.notifications_rounded,
                title: 'Notifikasi',
                badge: unreadCount > 0 ? (unreadCount > 9 ? '9+' : unreadCount.toString()) : null,
                onTap: () {
                  Navigator.pop(context);
                  onNotificationTap();
                },
              );
            },
          )
        else
          DrawerItem(
            icon: Icons.notifications_rounded,
            title: 'Notifikasi',
            onTap: () {
              Navigator.pop(context);
              onNotificationTap();
            },
          ),
        DrawerItem(
          icon: Icons.settings_rounded,
          title: 'Pengaturan',
          onTap: () {
            Navigator.pop(context);
            onSettingsTap();
          },
        ),
        DrawerItem(
          icon: Icons.logout_rounded,
          title: 'Keluar',
          onTap: () {
            Navigator.pop(context);
            onLogoutTap();
          },
        ),
      ],
    );
  }
}

