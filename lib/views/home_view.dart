import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../pages/kasir_page.dart';
import '../pages/laporan_page.dart';
import '../pages/produk_page.dart';
import '../pages/account_page.dart';
import '../pages/logout_page.dart';
import '../pages/pengaturan_page.dart';
import '../pages/notification_page.dart';
import '../utils/responsive_helper.dart';
import '../services/auth_service.dart';
import '../services/database_service.dart';
import '../utils/home_utils.dart';
import '../components/profile_header.dart';
import '../components/banner_carousel.dart';
import '../components/business_menu.dart';
import '../components/news_section.dart';
import '../components/custom_app_bar.dart';
import '../components/bottom_nav_bar.dart';

class HomeView extends StatefulWidget {
  const HomeView({super.key});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  int _selectedIndex = 0;
  User? _currentUser;
  List<String> _bannerImages = [];
  final DatabaseService _databaseService = DatabaseService();

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _loadBanners();
    _initializeAnimations();
    _listenToAuthChanges();
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

  void _listenToAuthChanges() {
    AuthService.authStateChanges.listen((User? user) {
      if (mounted) {
        setState(() {
          _currentUser = user;
        });
      }
    });
  }

  Future<void> _loadUserData() async {
    await AuthService.reloadUser();
    if (mounted) {
      setState(() {
        _currentUser = AuthService.currentUser;
      });
    }
  }

  Future<void> _loadBanners() async {
    setState(() {
      _bannerImages = [
        'assets/banners/banner1.png',
        'assets/banners/banner2.png',
        'assets/banners/banner3.png',
      ];
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _onItemTapped(int index) {
    HapticFeedback.lightImpact();

    if (_selectedIndex == index) {
      // TODO: Optionally scroll to top for the current tab.
      return;
    }

    setState(() {
      _selectedIndex = index;
    });
  }

  Widget? _buildDrawer(BuildContext context) {
    try {
      final mediaQuery = MediaQuery.maybeOf(context);
      if (mediaQuery == null) {
        return null; // Don't build drawer if MediaQuery is not available
      }
      
      final iconScale = ResponsiveHelper.getIconScale(context);
      final isTallPhoneLandscape = ResponsiveHelper.isTallPhoneInLandscape(context);
      
      // Only show drawer if it's a tall phone in landscape
      if (!isTallPhoneLandscape) {
        return null;
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
              // Drawer header
              Container(
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
                          fontSize: (Theme.of(context).textTheme.titleLarge?.fontSize ?? 22) * ResponsiveHelper.getFontScale(context),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Divider(color: Colors.white.withOpacity(0.2)),
              
              // Menu items
              Expanded(
                child: ListView(
                  padding: EdgeInsets.zero,
                  children: [
                    _buildDrawerItem(
                      context,
                      icon: Icons.person_rounded,
                      title: 'Akun',
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const AccountPage()),
                        );
                      },
                    ),
                    StreamBuilder<int>(
                      stream: _databaseService.getUnreadNotificationsCount(),
                      builder: (context, snapshot) {
                        final unreadCount = snapshot.data ?? 0;
                        return _buildDrawerItem(
                          context,
                          icon: Icons.notifications_rounded,
                          title: 'Notifikasi',
                          badge: unreadCount > 0 ? (unreadCount > 9 ? '9+' : unreadCount.toString()) : null,
                          onTap: () {
                            Navigator.pop(context);
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const NotificationPage(),
                              ),
                            );
                          },
                        );
                      },
                    ),
                    _buildDrawerItem(
                      context,
                      icon: Icons.settings_rounded,
                      title: 'Pengaturan',
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const PengaturanPage()),
                        );
                      },
                    ),
                    _buildDrawerItem(
                      context,
                      icon: Icons.logout_rounded,
                      title: 'Keluar',
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const LogoutPage()),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
    } catch (e) {
      // Return null if there's any error building the drawer
      return null;
    }
  }

  Widget _buildDrawerItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    String? badge,
  }) {
    final iconScale = ResponsiveHelper.getIconScale(context);
    
    return ListTile(
      leading: Container(
        padding: EdgeInsets.all(8 * iconScale),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.2),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: Colors.white, size: 24 * iconScale),
      ),
      title: Text(
        title,
        style: TextStyle(
          color: Colors.white,
          fontSize: 16 * ResponsiveHelper.getFontScale(context),
          fontWeight: FontWeight.w500,
        ),
      ),
      trailing: badge != null
          ? Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: const BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.all(Radius.circular(12)),
              ),
              child: Text(
                badge,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            )
          : null,
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
    );
  }

  Widget _buildHomeContent(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: SingleChildScrollView(
          padding: EdgeInsets.all(20 * ResponsiveHelper.getPaddingScale(context)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ProfileHeader(
                currentUser: _currentUser,
                databaseService: _databaseService,
              ),
              
              SizedBox(height: 32 * ResponsiveHelper.getPaddingScale(context)),

              BannerCarousel(bannerImages: _bannerImages),
              
              SizedBox(height: 32 * ResponsiveHelper.getPaddingScale(context)),

              BusinessMenu(
                onShowComingSoon: showComingSoonDialog,
              ),

              SizedBox(height: 32 * ResponsiveHelper.getPaddingScale(context)),

              const NewsSection(),
              
              SizedBox(height: 20 * ResponsiveHelper.getPaddingScale(context)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPageStack(BuildContext context) {
    return IndexedStack(
      index: _selectedIndex,
      children: [
        _buildHomeContent(context),
        const ProdukPage(),
        const KasirPage(),
        const LaporanPage(),
      ],
    );
  }

  Widget _buildLandscapeLayout(BuildContext context) {
    final showHomeChrome = _selectedIndex == 0;
    final paddingScale = ResponsiveHelper.getPaddingScale(context);
    final iconScale = ResponsiveHelper.getIconScale(context);
    final fontScale = ResponsiveHelper.getFontScale(context);
    final isWideScreen = ResponsiveHelper.isWideScreen(context);
    final isHorizontal = ResponsiveHelper.isHorizontal(context);
    
    // Dynamic scaling based on screen width percentage
    final screenWidth = MediaQuery.of(context).size.width;
    final shortestSide = MediaQuery.of(context).size.shortestSide;
    
    // Use percentage-based sizing instead of fixed pixels
    final baseIconSize = 24.0 * iconScale; // Smaller base, scales with iconScale
    final iconSize = baseIconSize * 1.15; // Selected icons slightly larger
    final unselectedIconSize = baseIconSize;
    
    // Dynamic width: ~8-10% of screen width, but with reasonable min/max
    final extendedWidth = (screenWidth * 0.10).clamp(120.0, 160.0);
    final minWidth = (shortestSide * 0.12).clamp(72.0, 88.0);
    
    // Reduced padding - less margin on left
    final horizontalMargin = 8 * paddingScale;
    final verticalMargin = 12 * paddingScale;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: showHomeChrome ? CustomAppBar(databaseService: _databaseService) : null,
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
              child: NavigationRail(
                selectedIndex: _selectedIndex,
                onDestinationSelected: _onItemTapped,
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
                      style: TextStyle(
                        fontSize: 12 * fontScale,
                      ),
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
                      style: TextStyle(
                        fontSize: 12 * fontScale,
                      ),
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
                      style: TextStyle(
                        fontSize: 12 * fontScale,
                      ),
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
                      style: TextStyle(
                        fontSize: 12 * fontScale,
                      ),
                    ),
                    padding: EdgeInsets.symmetric(
                      vertical: 10 * paddingScale,
                      horizontal: 10 * paddingScale,
                    ),
                  ),
                ],
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

  @override
  Widget build(BuildContext context) {
    final showHomeChrome = _selectedIndex == 0;
    final mq = MediaQuery.of(context);
    final isLandscape = mq.orientation == Orientation.landscape;
    final isWidePortraitTablet = mq.orientation == Orientation.portrait && mq.size.width >= 840;

    if (isLandscape || isWidePortraitTablet) {
      return _buildLandscapeLayout(context);
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: showHomeChrome ? CustomAppBar(databaseService: _databaseService) : null,
      drawer: showHomeChrome ? _buildDrawer(context) : null,
      body: _buildPageStack(context),
      bottomNavigationBar: CustomBottomNavBar(
        selectedIndex: _selectedIndex,
        onItemTapped: _onItemTapped,
      ),
    );
  }
}

