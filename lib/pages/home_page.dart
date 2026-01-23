import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'kasir_page.dart';
import 'laporan_page.dart';
import 'produk_page.dart';
import 'account_page.dart';
import 'logout_page.dart';
import 'pengaturan_page.dart';
import 'notification_page.dart';
import '../controllers/home_controller.dart';
import '../widgets/home/custom_app_bar.dart';
import '../widgets/home/bottom_nav_bar.dart';
import '../widgets/home/home_drawer.dart';
import '../widgets/home/home_content.dart';
import '../widgets/home/home_landscape_layout.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  int _selectedIndex = 0;
  late HomeController _controller;
  final ScrollController _homeScrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _controller = HomeController()
      ..addListener(_onControllerChanged)
      ..initialize();
    _initializeAnimations();
  }

  void _onControllerChanged() {
    if (mounted) setState(() {});
  }

  void _initializeAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));
    
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _homeScrollController.dispose();
    _controller.removeListener(_onControllerChanged);
    _controller.dispose();
    super.dispose();
  }

  void _onItemTapped(int index) {
    HapticFeedback.lightImpact();

    // Handle navigation to separate pages (Akun, Notifikasi, Pengaturan)
    if (index == 4) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const AccountPage()),
      );
      return;
    } else if (index == 5) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const NotificationPage()),
      );
      return;
    } else if (index == 6) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const PengaturanPage()),
      );
      return;
    }

    if (_selectedIndex == index) {
      // Scroll to top for the current tab
      if (index == 0 && _homeScrollController.hasClients) {
        _homeScrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
      return;
    }

    setState(() {
      _selectedIndex = index;
    });
  }

  Widget _buildPageStack(BuildContext context) {
    final mq = MediaQuery.of(context);
    final isLandscape = mq.orientation == Orientation.landscape;
    final isWidePortraitTablet = mq.orientation == Orientation.portrait && mq.size.width >= 840;
    final hideAppBars = isLandscape || isWidePortraitTablet;
    
    return IndexedStack(
      index: _selectedIndex,
      children: [
        HomeContent(
          controller: _controller,
          scrollController: _homeScrollController,
          fadeAnimation: _fadeAnimation,
          slideAnimation: _slideAnimation,
        ),
        ProdukPage(hideAppBar: hideAppBars),
        KasirPage(hideAppBar: hideAppBars),
        LaporanPage(hideAppBar: hideAppBars),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final showHomeChrome = _selectedIndex == 0;
    final mq = MediaQuery.of(context);
    final isLandscape = mq.orientation == Orientation.landscape;
    final isWidePortraitTablet = mq.orientation == Orientation.portrait && mq.size.width >= 840;
    final isMobileWidth = mq.size.width < 900;

    // Use desktop/tablet layout only when the screen is wide enough
    if (!isMobileWidth && (isLandscape || isWidePortraitTablet)) {
      return HomeLandscapeLayout(
        selectedIndex: _selectedIndex,
        onItemTapped: _onItemTapped,
        controller: _controller,
        homeScrollController: _homeScrollController,
        fadeAnimation: _fadeAnimation,
        slideAnimation: _slideAnimation,
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: showHomeChrome ? CustomAppBar(controller: _controller) : null,
      drawer: showHomeChrome ? HomeDrawer(
        unreadNotificationsCount: _controller.databaseService.getUnreadNotificationsCount(),
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
      ) : null,
      body: _buildPageStack(context),
      bottomNavigationBar: CustomBottomNavBar(
        selectedIndex: _selectedIndex,
        onItemTapped: _onItemTapped,
      ),
    );
  }
}


