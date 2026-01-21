import 'package:flutter/material.dart';
import '../../utils/responsive_helper.dart';
import '../../controllers/home_controller.dart';
import '../../widgets/gradient_app_bar.dart';
import 'home_drawer.dart';
import 'home_content.dart';
import 'notification_rail_destination.dart' as notification_helper;
import 'custom_app_bar.dart';
import '../../pages/produk_page.dart';
import '../../pages/kasir_page.dart';
import '../../pages/laporan_page.dart';
import '../../pages/account_page.dart';
import '../../pages/logout_page.dart';
import '../../pages/pengaturan_page.dart';
import '../../pages/notification_page.dart';

class HomeLandscapeLayout extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onItemTapped;
  final HomeController controller;
  final ScrollController homeScrollController;
  final Animation<double> fadeAnimation;
  final Animation<Offset> slideAnimation;

  const HomeLandscapeLayout({
    super.key,
    required this.selectedIndex,
    required this.onItemTapped,
    required this.controller,
    required this.homeScrollController,
    required this.fadeAnimation,
    required this.slideAnimation,
  });

  PreferredSizeWidget? _buildLandscapeAppBar() {
    switch (selectedIndex) {
      case 0:
        return CustomAppBar(controller: controller);
      case 1:
        return const GradientAppBar(
          title: "Produk & Stok",
          icon: Icons.inventory_2_rounded,
          automaticallyImplyLeading: false,
        );
      case 2:
        return const GradientAppBar(
          title: "Kasir",
          icon: Icons.point_of_sale_rounded,
          automaticallyImplyLeading: false,
        );
      case 3:
        return const GradientAppBar(
          title: "Laporan",
          icon: Icons.analytics_rounded,
          automaticallyImplyLeading: false,
        );
      default:
        return null;
    }
  }

  Widget _buildDrawer(BuildContext context) {
    return HomeDrawer(
      unreadNotificationsCount: controller.databaseService.getUnreadNotificationsCount(),
      onAccountTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const AccountPage()),
      ),
      onNotificationTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const NotificationPage()),
      ),
      onSettingsTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const PengaturanPage()),
      ),
      onLogoutTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const LogoutPage()),
      ),
    );
  }

  Widget _buildHomeContent(BuildContext context) {
    return HomeContent(
      controller: controller,
      scrollController: homeScrollController,
      fadeAnimation: fadeAnimation,
      slideAnimation: slideAnimation,
    );
  }

  Widget _buildPageStack(BuildContext context) {
    final mq = MediaQuery.of(context);
    final isLandscape = mq.orientation == Orientation.landscape;
    final isWidePortraitTablet = mq.orientation == Orientation.portrait && mq.size.width >= 840;
    final hideAppBars = isLandscape || isWidePortraitTablet;
    
    return IndexedStack(
      index: selectedIndex,
      children: [
        _buildHomeContent(context),
        ProdukPage(hideAppBar: hideAppBars),
        KasirPage(hideAppBar: hideAppBars),
        LaporanPage(hideAppBar: hideAppBars),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final showHomeChrome = selectedIndex == 0;
    final paddingScale = ResponsiveHelper.getPaddingScale(context);
    final iconScale = ResponsiveHelper.getIconScale(context);
    final fontScale = ResponsiveHelper.getFontScale(context);
    final isWideScreen = ResponsiveHelper.isWideScreen(context);
    final isHorizontal = ResponsiveHelper.isHorizontal(context);
    
    final screenWidth = MediaQuery.of(context).size.width;
    final shortestSide = MediaQuery.of(context).size.shortestSide;
    
    final baseIconSize = 24.0 * iconScale;
    final iconSize = baseIconSize * 1.15;
    final unselectedIconSize = baseIconSize;
    
    final extendedWidth = (screenWidth * 0.10).clamp(120.0, 160.0);
    final minWidth = (shortestSide * 0.12).clamp(72.0, 88.0);
    
    final horizontalMargin = 8 * paddingScale;
    final verticalMargin = 12 * paddingScale;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: _buildLandscapeAppBar(),
      drawer: showHomeChrome ? _buildDrawer(context) : null,
      body: SafeArea(
        child: Row(
          children: [
            Container(
              margin: EdgeInsets.symmetric(
                horizontal: horizontalMargin,
                vertical: verticalMargin,
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: StreamBuilder<int>(
                stream: controller.databaseService.getUnreadNotificationsCount(),
                builder: (context, snapshot) {
                  final unreadCount = snapshot.data ?? 0;
                  return NavigationRail(
                    selectedIndex: selectedIndex,
                    onDestinationSelected: onItemTapped,
                    extended: isWideScreen || isHorizontal,
                    minWidth: isWideScreen || isHorizontal ? extendedWidth : minWidth,
                    labelType: NavigationRailLabelType.none,
                    selectedIconTheme: IconThemeData(
                      color: const Color(0xFF6366F1),
                      size: iconSize,
                    ),
                    unselectedIconTheme: IconThemeData(
                      color: const Color(0xFF9CA3AF),
                      size: unselectedIconSize,
                    ),
                    selectedLabelTextStyle: TextStyle(
                      color: const Color(0xFF6366F1),
                      fontWeight: FontWeight.w700,
                      fontSize: 13 * fontScale,
                    ),
                    unselectedLabelTextStyle: TextStyle(
                      color: const Color(0xFF9CA3AF),
                      fontWeight: FontWeight.w500,
                      fontSize: 13 * fontScale,
                    ),
                    indicatorColor: const Color(0xFFEEF2FF),
                    backgroundColor: Colors.transparent,
                    useIndicator: true,
                    groupAlignment: -1.0,
                    destinations: [
                      NavigationRailDestination(
                        icon: Icon(Icons.home_rounded, size: unselectedIconSize),
                        selectedIcon: Icon(Icons.home_rounded, size: iconSize),
                        label: Text(
                          'Beranda',
                          style: TextStyle(fontSize: 12 * fontScale),
                        ),
                        padding: EdgeInsets.symmetric(
                          vertical: 10 * paddingScale,
                          horizontal: 10 * paddingScale,
                        ),
                      ),
                      NavigationRailDestination(
                        icon: Icon(Icons.store_rounded, size: unselectedIconSize),
                        selectedIcon: Icon(Icons.store_rounded, size: iconSize),
                        label: Text(
                          'Produk',
                          style: TextStyle(fontSize: 12 * fontScale),
                        ),
                        padding: EdgeInsets.symmetric(
                          vertical: 10 * paddingScale,
                          horizontal: 10 * paddingScale,
                        ),
                      ),
                      NavigationRailDestination(
                        icon: Icon(Icons.point_of_sale_rounded, size: unselectedIconSize),
                        selectedIcon: Icon(Icons.point_of_sale_rounded, size: iconSize),
                        label: Text(
                          'Kasir',
                          style: TextStyle(fontSize: 12 * fontScale),
                        ),
                        padding: EdgeInsets.symmetric(
                          vertical: 10 * paddingScale,
                          horizontal: 10 * paddingScale,
                        ),
                      ),
                      NavigationRailDestination(
                        icon: Icon(Icons.analytics_rounded, size: unselectedIconSize),
                        selectedIcon: Icon(Icons.analytics_rounded, size: iconSize),
                        label: Text(
                          'Laporan',
                          style: TextStyle(fontSize: 12 * fontScale),
                        ),
                        padding: EdgeInsets.symmetric(
                          vertical: 10 * paddingScale,
                          horizontal: 10 * paddingScale,
                        ),
                      ),
                      NavigationRailDestination(
                        icon: Icon(Icons.person_rounded, size: unselectedIconSize),
                        selectedIcon: Icon(Icons.person_rounded, size: iconSize),
                        label: Text(
                          'Akun',
                          style: TextStyle(fontSize: 12 * fontScale),
                        ),
                        padding: EdgeInsets.symmetric(
                          vertical: 10 * paddingScale,
                          horizontal: 10 * paddingScale,
                        ),
                      ),
                      notification_helper.NotificationRailDestinationHelper.build(
                        unreadCount: unreadCount,
                        unselectedIconSize: unselectedIconSize,
                        iconSize: iconSize,
                        fontScale: fontScale,
                        paddingScale: paddingScale,
                      ),
                      NavigationRailDestination(
                        icon: Icon(Icons.settings_rounded, size: unselectedIconSize),
                        selectedIcon: Icon(Icons.settings_rounded, size: iconSize),
                        label: Text(
                          'Pengaturan',
                          style: TextStyle(fontSize: 12 * fontScale),
                        ),
                        padding: EdgeInsets.symmetric(
                          vertical: 10 * paddingScale,
                          horizontal: 10 * paddingScale,
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
            SizedBox(width: 8 * paddingScale),
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: _buildPageStack(context),
              ),
            ),
            SizedBox(width: 12 * paddingScale),
          ],
        ),
      ),
    );
  }
}


