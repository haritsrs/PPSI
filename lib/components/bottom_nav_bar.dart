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
    
    return Container(
      height: bottomNavHeight,
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.transparent,
        elevation: 0,
        currentIndex: selectedIndex,
        onTap: onItemTapped,
        selectedItemColor: const Color(0xFF6366F1),
        unselectedItemColor: const Color(0xFF9CA3AF),
        selectedLabelStyle: TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 12 * ResponsiveHelper.getFontScale(context),
        ),
        unselectedLabelStyle: TextStyle(
          fontWeight: FontWeight.w500,
          fontSize: 12 * ResponsiveHelper.getFontScale(context),
        ),
        iconSize: 24 * iconScale,
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_rounded, size: 24 * iconScale),
            activeIcon: Icon(Icons.home_rounded, size: 24 * iconScale),
            label: "Beranda",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.store_rounded, size: 24 * iconScale),
            activeIcon: Icon(Icons.store_rounded, size: 24 * iconScale),
            label: "Produk",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.point_of_sale_rounded, size: 24 * iconScale),
            activeIcon: Icon(Icons.point_of_sale_rounded, size: 24 * iconScale),
            label: "Kasir",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.analytics_rounded, size: 24 * iconScale),
            activeIcon: Icon(Icons.analytics_rounded, size: 24 * iconScale),
            label: "Laporan",
          ),
        ],
      ),
    );
  }
}

