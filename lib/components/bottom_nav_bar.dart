import 'package:flutter/material.dart';
import '../utils/responsive_helper.dart';

class CustomBottomNavBar extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onItemTapped;

  const CustomBottomNavBar({
    super.key,
    required this.selectedIndex,
    required this.onItemTapped,
  });

  @override
  Widget build(BuildContext context) {
    final bottomNavHeight = ResponsiveHelper.getBottomNavBarHeight(context);
    final iconScale = ResponsiveHelper.getIconScale(context);
    final fontScale = ResponsiveHelper.getFontScale(context);
    final isTallPortrait =
        ResponsiveHelper.isVertical(context) && ResponsiveHelper.isTallScreen(context);

    final effectiveHeight = isTallPortrait ? 56.0 : bottomNavHeight;
    final effectiveIconSize = 24 * iconScale * (isTallPortrait ? 0.85 : 1.0);
    final effectiveFontSize = 12 * fontScale * (isTallPortrait ? 0.9 : 1.0);

    return SafeArea(
      top: false,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 16,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SizedBox(
          height: effectiveHeight,
          child: BottomNavigationBar(
            type: BottomNavigationBarType.fixed,
            backgroundColor: Colors.white,
            elevation: 0,
            currentIndex: selectedIndex,
            onTap: onItemTapped,
            selectedItemColor: const Color(0xFF6366F1),
            unselectedItemColor: const Color(0xFF9CA3AF),
            selectedLabelStyle: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: effectiveFontSize,
            ),
            unselectedLabelStyle: TextStyle(
              fontWeight: FontWeight.w500,
              fontSize: effectiveFontSize,
            ),
            iconSize: effectiveIconSize,
            items: [
              BottomNavigationBarItem(
                icon: Icon(Icons.home_rounded, size: effectiveIconSize),
                activeIcon: Icon(Icons.home_rounded, size: effectiveIconSize),
                label: "Beranda",
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.store_rounded, size: effectiveIconSize),
                activeIcon: Icon(Icons.store_rounded, size: effectiveIconSize),
                label: "Produk",
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.point_of_sale_rounded, size: effectiveIconSize),
                activeIcon:
                    Icon(Icons.point_of_sale_rounded, size: effectiveIconSize),
                label: "Kasir",
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.analytics_rounded, size: effectiveIconSize),
                activeIcon:
                    Icon(Icons.analytics_rounded, size: effectiveIconSize),
                label: "Laporan",
              ),
            ],
          ),
        ),
      ),
    );
  }
}

