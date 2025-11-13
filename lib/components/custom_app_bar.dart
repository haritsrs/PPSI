import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../utils/responsive_helper.dart';
import '../services/database_service.dart';
import '../pages/account_page.dart';
import '../pages/logout_page.dart';
import '../pages/pengaturan_page.dart';
import '../pages/notification_page.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final DatabaseService databaseService;
  final VoidCallback? onMenuPressed;

  const CustomAppBar({
    super.key,
    required this.databaseService,
    this.onMenuPressed,
  });

  @override
  Size get preferredSize {
    // Default height, will be overridden by toolbarHeight
    return const Size.fromHeight(kToolbarHeight);
  }

  @override
  Widget build(BuildContext context) {
    final appBarHeight = ResponsiveHelper.getAppBarHeight(context);
    final iconScale = ResponsiveHelper.getIconScale(context);
    final isVertical = ResponsiveHelper.isVertical(context);
    final isTallPhoneLandscape = ResponsiveHelper.isTallPhoneInLandscape(context);
    
    return PreferredSize(
      preferredSize: Size.fromHeight(appBarHeight),
      child: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        toolbarHeight: appBarHeight,
        systemOverlayStyle: SystemUiOverlayStyle.light.copyWith(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
          statusBarBrightness: Brightness.dark,
        ),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        leading: isTallPhoneLandscape
            ? Container(
                margin: EdgeInsets.all(8 * iconScale),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: IconButton(
                  onPressed: onMenuPressed ?? () {
                    try {
                      final scaffoldState = Scaffold.maybeOf(context);
                      scaffoldState?.openDrawer();
                    } catch (e) {
                      // Silently fail if drawer is not available
                    }
                  },
                  icon: Icon(Icons.menu_rounded, color: Colors.white, size: 24 * iconScale),
                  iconSize: 24 * iconScale,
                  padding: EdgeInsets.all(8 * iconScale),
                  tooltip: 'Menu',
                ),
              )
            : null,
        title: Row(
          mainAxisSize: MainAxisSize.min,
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
                  width: 24 * iconScale,
                  height: 24 * iconScale,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    return Icon(
                      Icons.store_rounded,
                      color: Colors.white,
                      size: 24 * iconScale,
                    );
                  },
                ),
              ),
            ),
            // Only show text when not in vertical/portrait mode and not tall phone in landscape
            if (!isVertical && !isTallPhoneLandscape) ...[
              SizedBox(width: 12 * iconScale),
              Text(
                "KiosDarma",
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: (Theme.of(context).textTheme.titleLarge?.fontSize ?? 22) * ResponsiveHelper.getFontScale(context),
                ),
              ),
            ],
          ],
        ),
        actions: isTallPhoneLandscape
            ? [] // Hide all actions when hamburger menu is shown
            : [
          Container(
            margin: EdgeInsets.only(right: 8 * iconScale),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              onPressed: () {
                HapticFeedback.lightImpact();
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const AccountPage()),
                );
              },
              icon: Icon(Icons.person_rounded, color: Colors.white, size: 24 * iconScale),
              iconSize: 24 * iconScale,
              padding: EdgeInsets.all(8 * iconScale),
              tooltip: 'Akun',
            ),
          ),
          Container(
            margin: EdgeInsets.only(right: 8 * iconScale),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: StreamBuilder<int>(
              stream: databaseService.getUnreadNotificationsCount(),
              builder: (context, snapshot) {
                final unreadCount = snapshot.data ?? 0;
                return Stack(
                  children: [
                    IconButton(
                      onPressed: () {
                        HapticFeedback.lightImpact();
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const NotificationPage(),
                          ),
                        );
                      },
                      icon: Icon(Icons.notifications_rounded, color: Colors.white, size: 24 * iconScale),
                      iconSize: 24 * iconScale,
                      padding: EdgeInsets.all(8 * iconScale),
                      tooltip: 'Notifikasi',
                    ),
                    if (unreadCount > 0)
                      Positioned(
                        right: 8 * iconScale,
                        top: 8 * iconScale,
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
              },
            ),
          ),
          Container(
            margin: EdgeInsets.only(right: 8 * iconScale),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              onPressed: () {
                HapticFeedback.lightImpact();
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const LogoutPage()),
                );
              },
              icon: Icon(Icons.logout_rounded, color: Colors.white, size: 24 * iconScale),
              iconSize: 24 * iconScale,
              padding: EdgeInsets.all(8 * iconScale),
              tooltip: 'Keluar',
            ),
          ),
          Container(
            margin: EdgeInsets.only(right: 16 * iconScale),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              onPressed: () {
                HapticFeedback.lightImpact();
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const PengaturanPage()),
                );
              },
              icon: Icon(Icons.settings_rounded, color: Colors.white, size: 24 * iconScale),
              iconSize: 24 * iconScale,
              padding: EdgeInsets.all(8 * iconScale),
              tooltip: 'Pengaturan',
            ),
          ),
        ],
      ),
    );
  }
}

