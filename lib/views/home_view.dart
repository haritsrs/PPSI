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

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: showHomeChrome ? CustomAppBar(databaseService: _databaseService) : null,
      drawer: showHomeChrome ? _buildDrawer(context) : null,
      body: SafeArea(
        child: Row(
          children: [
            Container(
              margin: EdgeInsets.symmetric(
                horizontal: 12 * paddingScale,
                vertical: 16 * paddingScale,
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
                extended: ResponsiveHelper.isWideScreen(context),
                labelType: ResponsiveHelper.isWideScreen(context)
                    ? NavigationRailLabelType.none
                    : NavigationRailLabelType.selected,
                selectedIconTheme: const IconThemeData(
                  color: Color(0xFF6366F1),
                  size: 28,
                ),
                unselectedIconTheme: const IconThemeData(
                  color: Color(0xFF9CA3AF),
                  size: 24,
                ),
                selectedLabelTextStyle: const TextStyle(
                  color: Color(0xFF6366F1),
                  fontWeight: FontWeight.w700,
                ),
                unselectedLabelTextStyle: const TextStyle(
                  color: Color(0xFF9CA3AF),
                  fontWeight: FontWeight.w500,
                ),
                indicatorColor: const Color(0xFFEEF2FF),
                destinations: const [
                  NavigationRailDestination(
                    icon: Icon(Icons.home_rounded),
                    label: Text('Beranda'),
                  ),
                  NavigationRailDestination(
                    icon: Icon(Icons.store_rounded),
                    label: Text('Produk'),
                  ),
                  NavigationRailDestination(
                    icon: Icon(Icons.point_of_sale_rounded),
                    label: Text('Kasir'),
                  ),
                  NavigationRailDestination(
                    icon: Icon(Icons.analytics_rounded),
                    label: Text('Laporan'),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: _buildPageStack(context),
              ),
            ),
            SizedBox(width: 16 * paddingScale),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final showHomeChrome = _selectedIndex == 0;
    final isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;

    if (isLandscape) {
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

