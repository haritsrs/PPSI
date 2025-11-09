import 'package:flutter/material.dart';
import '../utils/responsive_helper.dart';

class CustomBottomNavBar extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onItemTapped;
  final VoidCallback onScanTapped;

  const CustomBottomNavBar({
    super.key,
    required this.selectedIndex,
    required this.onItemTapped,
    required this.onScanTapped,
  });

  @override
  Widget build(BuildContext context) {
    final bottomNavHeight = ResponsiveHelper.getBottomNavBarHeight(context);
    final iconScale = ResponsiveHelper.getIconScale(context);
    
    return Container(
      height: bottomNavHeight + 20,
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
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          BottomNavigationBar(
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
              const BottomNavigationBarItem(
                icon: SizedBox.shrink(),
                label: "",
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
          // Center Floating Scan Button
          Positioned(
            left: MediaQuery.of(context).size.width / 2 - 32 * iconScale,
            top: -32 * iconScale,
            child: GestureDetector(
              onTap: onScanTapped,
              child: Container(
                width: 64 * iconScale,
                height: 64 * iconScale,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF6366F1).withOpacity(0.4),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.qr_code_scanner_rounded,
                  color: Colors.white,
                  size: 32 * iconScale,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

