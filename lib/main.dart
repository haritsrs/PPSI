import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'pages/kasir_page.dart';
import 'pages/laporan_page.dart';
import 'pages/produk_page.dart';
import 'pages/pelanggan_page.dart';
import 'pages/pengaturan_page.dart';
import 'pages/auth_wrapper.dart';
import 'pages/account_page.dart';
import 'pages/logout_page.dart';
import 'pages/scanner_page.dart';
import 'pages/notification_page.dart';
import 'utils/responsive_helper.dart';
import 'firebase_options.dart';
import 'services/auth_service.dart';
import 'services/database_service.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

// Import future pages (for modularity)
// Example: import 'pages/overview_page.dart';
// We'll add these later as the app grows

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load(fileName: ".env"); // must come before using XenditService
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const KiosDarmaApp());
}

class KiosDarmaApp extends StatelessWidget {
  const KiosDarmaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'KiosDarma',
      theme: ThemeData(
        primarySwatch: Colors.indigo,
        fontFamily: 'Inter',
        textTheme: const TextTheme(
          headlineLarge: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.5,
          ),
          headlineMedium: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.25,
          ),
          headlineSmall: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w600,
            letterSpacing: 0,
          ),
          titleLarge: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w600,
            letterSpacing: 0,
          ),
          titleMedium: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            letterSpacing: 0.15,
          ),
          titleSmall: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            letterSpacing: 0.1,
          ),
          bodyLarge: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w400,
            letterSpacing: 0.15,
          ),
          bodyMedium: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w400,
            letterSpacing: 0.25,
          ),
          bodySmall: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w400,
            letterSpacing: 0.4,
          ),
        ),
      ),
      // Routing setup: AuthWrapper handles authentication state
      home: const AuthWrapper(),
      routes: {
        '/home': (context) => const HomePage(),
        // '/catalog': (context) => const CatalogPage(),
        // '/cart': (context) => const CartPage(),
        // '/profile': (context) => const ProfilePage(),
      },
      debugShowCheckedModeBanner: false,
    );
  }
}

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
  int _currentBannerIndex = 0;
  User? _currentUser;
  List<String> _bannerImages = [];
  final DatabaseService _databaseService = DatabaseService();

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _loadBanners();
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
    
    // Listen to auth state changes
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
    // Load banner images from assets/banners folder
    // For now, we'll use a placeholder approach
    // In a real app, you might load from Firebase Storage or a server
    setState(() {
      _bannerImages = [
        // Placeholder banners - you can add actual banner images to assets/banners/
        'assets/banners/banner1.png',
        // 'assets/banners/banner2.png',
        // 'assets/banners/banner3.png',
      ];
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    
    // Add haptic feedback
    HapticFeedback.lightImpact();
    
    // Navigate to different sections
    switch (index) {
      case 0:
        // Already on home
        break;
      case 1:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const ProdukPage()),
        );
        break;
      case 2:
        // Scan button - handled separately
        _showComingSoon(context, 'Scan Barcode');
        break;
      case 3:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const KasirPage()),
        );
        break;
      case 4:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const LaporanPage()),
        );
        break;
    }
  }

  void _onScanTapped() {
    HapticFeedback.mediumImpact();
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ScannerPage()),
    );
  }

  // Helper method to format currency
  String _formatCurrency(int amount) {
    return amount.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]}.',
    );
  }


  void _showComingSoon(BuildContext context, String feature) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              Icon(Icons.construction, color: Colors.orange[600]),
              const SizedBox(width: 8),
              Text('Coming Soon'),
            ],
          ),
          content: Text('Fitur $feature akan segera hadir!'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final appBarHeight = ResponsiveHelper.getAppBarHeight(context);
    final iconScale = ResponsiveHelper.getIconScale(context);
    final bottomNavHeight = ResponsiveHelper.getBottomNavBarHeight(context);
    
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(appBarHeight),
        child: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          toolbarHeight: appBarHeight,
          systemOverlayStyle: SystemUiOverlayStyle.dark,
          flexibleSpace: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          title: Row(
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
          ),
          actions: [
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
                stream: _databaseService.getUnreadNotificationsCount(),
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
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: SingleChildScrollView(
            padding: EdgeInsets.all(20 * ResponsiveHelper.getPaddingScale(context)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Profile Header: Real User Profile with Photo
                Builder(
                  builder: (context) {
                    final iconScale = ResponsiveHelper.getIconScale(context);
                    final paddingScale = ResponsiveHelper.getPaddingScale(context);
                    final fontScale = ResponsiveHelper.getFontScale(context);
                    
                    // Get user name from current user
                    final userName = _currentUser?.displayName ?? 
                                    _currentUser?.email?.split('@')[0] ?? 
                                    'Pengguna';
                    
                    // Get time-based greeting
                    final hour = DateTime.now().hour;
                    String greeting;
                    if (hour < 12) {
                      greeting = 'Selamat Pagi';
                    } else if (hour < 17) {
                      greeting = 'Selamat Siang';
                    } else {
                      greeting = 'Selamat Sore';
                    }
                    
                    // Store balance will be loaded from StreamBuilder
                    
                    return GestureDetector(
                      onTap: () {
                        HapticFeedback.lightImpact();
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const AccountPage()),
                        );
                      },
                      child: Container(
                        width: double.infinity,
                        padding: EdgeInsets.all(24 * paddingScale),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF6366F1), Color(0xFF8B5CF6), Color(0xFFEC4899)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF6366F1).withOpacity(0.4),
                              blurRadius: 24,
                              offset: const Offset(0, 12),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Profile Section with Photo
                            Row(
                              children: [
                                // Profile Photo
                                GestureDetector(
                                  onTap: () {
                                    HapticFeedback.lightImpact();
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(builder: (context) => const AccountPage()),
                                    );
                                  },
                                  child: Container(
                                    width: 60 * iconScale,
                                    height: 60 * iconScale,
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.25),
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: Colors.white.withOpacity(0.5),
                                        width: 2,
                                      ),
                                    ),
                                    child: _currentUser?.photoURL != null
                                        ? ClipOval(
                                            child: Image.network(
                                              _currentUser!.photoURL!,
                                              fit: BoxFit.cover,
                                              errorBuilder: (context, error, stackTrace) {
                                                return Icon(
                                                  Icons.person_rounded,
                                                  color: Colors.white,
                                                  size: 30 * iconScale,
                                                );
                                              },
                                            ),
                                          )
                                        : Icon(
                                            Icons.person_rounded,
                                            color: Colors.white,
                                            size: 30 * iconScale,
                                          ),
                                  ),
                                ),
                                SizedBox(width: 16 * paddingScale),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        "$greeting, $userName! 👋",
                                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w700,
                                          fontSize: (Theme.of(context).textTheme.headlineSmall?.fontSize ?? 24) * fontScale,
                                        ),
                                      ),
                                      SizedBox(height: 4 * paddingScale),
                                      Text(
                                        _currentUser?.email ?? 'Pengguna',
                                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                          color: Colors.white.withOpacity(0.9),
                                          fontWeight: FontWeight.w500,
                                          fontSize: (Theme.of(context).textTheme.bodyMedium?.fontSize ?? 14) * fontScale,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: EdgeInsets.all(8 * iconScale),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.25),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Icon(
                                    Icons.arrow_forward_ios_rounded,
                                    color: Colors.white,
                                    size: 16 * iconScale,
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 24 * paddingScale),
                            
                            // Store Balance Summary
                            StreamBuilder<double>(
                              stream: _databaseService.getStoreBalanceStream(),
                              builder: (context, balanceSnapshot) {
                                return StreamBuilder<double>(
                                  stream: _databaseService.getTodayRevenueStream(),
                                  builder: (context, todaySnapshot) {
                                    return StreamBuilder<double>(
                                      stream: _databaseService.getYesterdayRevenueStream(),
                                      builder: (context, yesterdaySnapshot) {
                                        final storeBalance = balanceSnapshot.data ?? 0.0;
                                        final todayRevenue = todaySnapshot.data ?? 0.0;
                                        final yesterdayRevenue = yesterdaySnapshot.data ?? 0.0;
                                        
                                        String growthPercent = '0.0';
                                        bool isPositiveGrowth = true;
                                        
                                        if (yesterdayRevenue > 0) {
                                          final growth = ((todayRevenue - yesterdayRevenue) / yesterdayRevenue) * 100;
                                          growthPercent = growth.toStringAsFixed(1);
                                          isPositiveGrowth = growth >= 0;
                                        } else if (todayRevenue > 0) {
                                          growthPercent = '100.0';
                                          isPositiveGrowth = true;
                                        }
                                        
                                        return Container(
                                          padding: EdgeInsets.all(20 * paddingScale),
                                          decoration: BoxDecoration(
                                            color: Colors.white.withOpacity(0.2),
                                            borderRadius: BorderRadius.circular(20),
                                            border: Border.all(
                                              color: Colors.white.withOpacity(0.3),
                                              width: 1,
                                            ),
                                          ),
                                          child: Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      "Saldo Toko",
                                                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                                        color: Colors.white.withOpacity(0.9),
                                                        fontWeight: FontWeight.w500,
                                                        fontSize: (Theme.of(context).textTheme.bodyMedium?.fontSize ?? 14) * fontScale,
                                                      ),
                                                    ),
                                                    SizedBox(height: 8 * paddingScale),
                                                    Text(
                                                      "Rp ${_formatCurrency(storeBalance.toInt())}",
                                                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                                        color: Colors.white,
                                                        fontWeight: FontWeight.w800,
                                                        fontSize: (Theme.of(context).textTheme.headlineMedium?.fontSize ?? 28) * fontScale,
                                                      ),
                                                    ),
                                                    SizedBox(height: 8 * paddingScale),
                                                    // Mini Growth Indicator
                                                    if (yesterdayRevenue > 0 || todayRevenue > 0)
                                                      Container(
                                                        padding: EdgeInsets.symmetric(
                                                          horizontal: 12 * paddingScale,
                                                          vertical: 6 * paddingScale,
                                                        ),
                                                        decoration: BoxDecoration(
                                                          color: isPositiveGrowth 
                                                              ? Colors.green.withOpacity(0.25)
                                                              : Colors.red.withOpacity(0.25),
                                                          borderRadius: BorderRadius.circular(12),
                                                        ),
                                                        child: Row(
                                                          mainAxisSize: MainAxisSize.min,
                                                          children: [
                                                            Icon(
                                                              isPositiveGrowth 
                                                                  ? Icons.trending_up_rounded
                                                                  : Icons.trending_down_rounded,
                                                              color: Colors.white,
                                                              size: 16 * iconScale,
                                                            ),
                                                            SizedBox(width: 6 * paddingScale),
                                                            Text(
                                                              "${isPositiveGrowth ? '+' : ''}$growthPercent% dari kemarin",
                                                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                                                color: Colors.white,
                                                                fontWeight: FontWeight.w700,
                                                                fontSize: (Theme.of(context).textTheme.bodySmall?.fontSize ?? 12) * fontScale,
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                  ],
                                                ),
                                              ),
                                              Container(
                                                padding: EdgeInsets.all(16 * iconScale),
                                                decoration: BoxDecoration(
                                                  color: Colors.white.withOpacity(0.25),
                                                  borderRadius: BorderRadius.circular(18),
                                                ),
                                                child: Icon(
                                                  Icons.show_chart_rounded,
                                                  color: Colors.white,
                                                  size: 40 * iconScale,
                                                ),
                                              ),
                                            ],
                                          ),
                                        );
                                      },
                                    );
                                  },
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
                
                SizedBox(height: 32 * ResponsiveHelper.getPaddingScale(context)),

                // Banner Carousel
                Builder(
                  builder: (context) {
                    final paddingScale = ResponsiveHelper.getPaddingScale(context);
                    
                    if (_bannerImages.isEmpty) {
                      // Show placeholder if no banners
                      return Container(
                        height: 180 * paddingScale,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              const Color(0xFF6366F1).withOpacity(0.1),
                              const Color(0xFF8B5CF6).withOpacity(0.1),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: const Color(0xFF6366F1).withOpacity(0.2),
                            width: 2,
                            style: BorderStyle.solid,
                          ),
                        ),
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.image_rounded,
                                size: 48,
                                color: const Color(0xFF6366F1).withOpacity(0.5),
                              ),
                              SizedBox(height: 8 * paddingScale),
                              Text(
                                'Tambahkan banner promosi di assets/banners/',
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: const Color(0xFF6B7280),
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      );
                    }
                    
                    return Column(
                      children: [
                        CarouselSlider.builder(
                          itemCount: _bannerImages.length,
                          itemBuilder: (context, index, realIndex) {
                            return Container(
                              margin: EdgeInsets.symmetric(horizontal: 4 * paddingScale),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.1),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(20),
                                child: Image.asset(
                                  _bannerImages[index],
                                  fit: BoxFit.cover,
                                  width: double.infinity,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Container(
                                      color: Colors.grey[200],
                                      child: const Center(
                                        child: Icon(Icons.error_outline, color: Colors.grey),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            );
                          },
                          options: CarouselOptions(
                            height: 180 * paddingScale,
                            autoPlay: true,
                            autoPlayInterval: const Duration(seconds: 3),
                            autoPlayAnimationDuration: const Duration(milliseconds: 800),
                            autoPlayCurve: Curves.fastOutSlowIn,
                            enlargeCenterPage: true,
                            enlargeFactor: 0.2,
                            viewportFraction: 0.9,
                            onPageChanged: (index, reason) {
                              setState(() {
                                _currentBannerIndex = index;
                              });
                            },
                          ),
                        ),
                        if (_bannerImages.length > 1) ...[
                          SizedBox(height: 12 * paddingScale),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: List.generate(
                              _bannerImages.length,
                              (index) => Container(
                                width: 8,
                                height: 8,
                                margin: EdgeInsets.symmetric(horizontal: 4 * paddingScale),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: _currentBannerIndex == index
                                      ? const Color(0xFF6366F1)
                                      : const Color(0xFF6366F1).withOpacity(0.3),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ],
                    );
                  },
                ),
                
                SizedBox(height: 32 * ResponsiveHelper.getPaddingScale(context)),

                // Menu Bisnis / Kelola Usaha Kamu - Horizontal Scrolling Container
                Builder(
                  builder: (context) {
                    final fontScale = ResponsiveHelper.getFontScale(context);
                    final paddingScale = ResponsiveHelper.getPaddingScale(context);
                    
                    final menuItems = [
                      {
                        'icon': Icons.inventory_2_rounded,
                        'label': 'Stok',
                        'color': const Color(0xFF3B82F6),
                        'onTap': () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const ProdukPage()),
                          );
                        },
                      },
                      {
                        'icon': Icons.language_rounded,
                        'label': 'Website',
                        'color': const Color(0xFF8B5CF6),
                        'onTap': () => _showComingSoon(context, 'Website'),
                      },
                      {
                        'icon': Icons.people_rounded,
                        'label': 'Pelanggan',
                        'color': const Color(0xFFEF4444),
                        'onTap': () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const PelangganPage()),
                          );
                        },
                      },
                      {
                        'icon': Icons.local_offer_rounded,
                        'label': 'Promo',
                        'color': const Color(0xFFF59E0B),
                        'onTap': () => _showComingSoon(context, 'Promo'),
                      },
                      {
                        'icon': Icons.payment_rounded,
                        'label': 'Pembayaran',
                        'color': const Color(0xFF10B981),
                        'onTap': () => _showComingSoon(context, 'Pembayaran'),
                      },
                      {
                        'icon': Icons.more_horiz_rounded,
                        'label': 'More',
                        'color': const Color(0xFF6B7280),
                        'onTap': () => _showComingSoon(context, 'More'),
                      },
                    ];
                    
                    return Container(
                      padding: EdgeInsets.all(20 * paddingScale),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Menu Bisnis / Kelola Usaha Kamu",
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              color: const Color(0xFF1F2937),
                              fontWeight: FontWeight.w700,
                              fontSize: (Theme.of(context).textTheme.titleLarge?.fontSize ?? 22) * fontScale,
                            ),
                          ),
                          SizedBox(height: 20 * paddingScale),
                          SizedBox(
                            height: 120 * paddingScale,
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              padding: EdgeInsets.symmetric(horizontal: 4 * paddingScale),
                              itemCount: menuItems.length,
                              itemBuilder: (context, index) {
                                final item = menuItems[index];
                                return Container(
                                  width: 100 * paddingScale,
                                  margin: EdgeInsets.only(
                                    right: 16 * paddingScale,
                                  ),
                                  child: HomeFeature(
                                    icon: item['icon'] as IconData,
                                    label: item['label'] as String,
                                    color: item['color'] as Color,
                                    onTap: item['onTap'] as VoidCallback,
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),

                SizedBox(height: 32 * ResponsiveHelper.getPaddingScale(context)),

                // News Section for Updates
                Builder(
                  builder: (context) {
                    final fontScale = ResponsiveHelper.getFontScale(context);
                    final paddingScale = ResponsiveHelper.getPaddingScale(context);
                    final iconScale = ResponsiveHelper.getIconScale(context);
                    
                    // Mock news data - replace with real data from API/database
                    final newsItems = [
                      {
                        'title': 'Update Fitur Baru',
                        'description': 'Sekarang Anda dapat mengelola stok dengan lebih mudah dan efisien.',
                        'date': '2 jam yang lalu',
                        'icon': Icons.new_releases_rounded,
                        'color': const Color(0xFF6366F1),
                      },
                      {
                        'title': 'Promo Bulan Ini',
                        'description': 'Dapatkan diskon spesial untuk pembelian pertama di aplikasi kami.',
                        'date': '1 hari yang lalu',
                        'icon': Icons.local_offer_rounded,
                        'color': const Color(0xFFF59E0B),
                      },
                      {
                        'title': 'Tips Mengelola Bisnis',
                        'description': 'Pelajari cara mengoptimalkan pendapatan Anda dengan fitur laporan yang lengkap.',
                        'date': '3 hari yang lalu',
                        'icon': Icons.tips_and_updates_rounded,
                        'color': const Color(0xFF10B981),
                      },
                    ];
                    
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.newspaper_rounded,
                                  color: const Color(0xFF6366F1),
                                  size: 24 * iconScale,
                                ),
                                SizedBox(width: 8 * paddingScale),
                                Text(
                                  "Berita & Update",
                                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                    color: const Color(0xFF1F2937),
                                    fontWeight: FontWeight.w700,
                                    fontSize: (Theme.of(context).textTheme.titleLarge?.fontSize ?? 22) * fontScale,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        SizedBox(height: 16 * paddingScale),
                        ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: newsItems.length,
                          separatorBuilder: (context, index) => SizedBox(height: 12 * paddingScale),
                          itemBuilder: (context, index) {
                            final news = newsItems[index];
                            return Container(
                              padding: EdgeInsets.all(16 * paddingScale),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.05),
                                    blurRadius: 10,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                                border: Border.all(
                                  color: (news['color'] as Color).withOpacity(0.1),
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    padding: EdgeInsets.all(12 * paddingScale),
                                    decoration: BoxDecoration(
                                      color: (news['color'] as Color).withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Icon(
                                      news['icon'] as IconData,
                                      color: news['color'] as Color,
                                      size: 24 * iconScale,
                                    ),
                                  ),
                                  SizedBox(width: 12 * paddingScale),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          news['title'] as String,
                                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                            color: const Color(0xFF1F2937),
                                            fontWeight: FontWeight.w600,
                                            fontSize: (Theme.of(context).textTheme.titleMedium?.fontSize ?? 16) * fontScale,
                                          ),
                                        ),
                                        SizedBox(height: 4 * paddingScale),
                                        Text(
                                          news['description'] as String,
                                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                            color: const Color(0xFF6B7280),
                                            fontSize: (Theme.of(context).textTheme.bodySmall?.fontSize ?? 12) * fontScale,
                                          ),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        SizedBox(height: 8 * paddingScale),
                                        Row(
                                          children: [
                                            Icon(
                                              Icons.access_time_rounded,
                                              size: 12 * iconScale,
                                              color: const Color(0xFF9CA3AF),
                                            ),
                                            SizedBox(width: 4 * paddingScale),
                                            Text(
                                              news['date'] as String,
                                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                                color: const Color(0xFF9CA3AF),
                                                fontSize: (Theme.of(context).textTheme.bodySmall?.fontSize ?? 12) * fontScale,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ],
                    );
                  },
                ),
                SizedBox(height: 20 * ResponsiveHelper.getPaddingScale(context)),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: Container(
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
              currentIndex: _selectedIndex,
              onTap: _onItemTapped,
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
                onTap: _onScanTapped,
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
      ),
    );
  }
}

class HomeFeature extends StatefulWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const HomeFeature({
    super.key,
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  State<HomeFeature> createState() => _HomeFeatureState();
}

class _HomeFeatureState extends State<HomeFeature>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final iconScale = ResponsiveHelper.getIconScale(context);
    
    return LayoutBuilder(
      builder: (context, constraints) {
        // Calculate icon size based on actual container constraints
        final actualIconSize = (constraints.maxWidth * 0.35 * iconScale).clamp(20.0, 36.0);
        final actualPadding = (actualIconSize * 0.5).clamp(10.0, 16.0);
        
        return GestureDetector(
          onTapDown: (_) => _controller.forward(),
          onTapUp: (_) => _controller.reverse(),
          onTapCancel: () => _controller.reverse(),
          onTap: widget.onTap,
          child: ScaleTransition(
            scale: _scaleAnimation,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: widget.color.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
                border: Border.all(
                  color: widget.color.withOpacity(0.1),
                  width: 1,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: EdgeInsets.all(actualPadding),
                    decoration: BoxDecoration(
                      color: widget.color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(
                      widget.icon,
                      color: widget.color,
                      size: actualIconSize,
                    ),
                  ),
                  SizedBox(height: 8 * ResponsiveHelper.getPaddingScale(context)),
                  Text(
                    widget.label,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: const Color(0xFF374151),
                      fontWeight: FontWeight.w600,
                      fontSize: (Theme.of(context).textTheme.bodySmall?.fontSize ?? 12) * ResponsiveHelper.getFontScale(context),
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class SummaryCard extends StatefulWidget {
  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color color;
  final bool trend;

  const SummaryCard({
    super.key,
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.trend,
  });

  @override
  State<SummaryCard> createState() => _SummaryCardState();
}

class _SummaryCardState extends State<SummaryCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.98,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) => _controller.reverse(),
      onTapCancel: () => _controller.reverse(),
      onTap: () {
        HapticFeedback.lightImpact();
        // TODO: Navigate to detailed view
      },
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: widget.color.withOpacity(0.1),
                blurRadius: 15,
                offset: const Offset(0, 5),
              ),
            ],
            border: Border.all(
              color: widget.color.withOpacity(0.1),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                height: 56,
                width: 56,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      widget.color.withOpacity(0.1),
                      widget.color.withOpacity(0.05),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  widget.icon,
                  color: widget.color,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: const Color(0xFF374151),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.subtitle,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    widget.value,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF1F2937),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        widget.trend ? Icons.trending_up_rounded : Icons.trending_down_rounded,
                        color: widget.trend ? Colors.green[600] : Colors.red[600],
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        widget.trend ? "Naik" : "Turun",
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: widget.trend ? Colors.green[600] : Colors.red[600],
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class FeatureCard extends StatelessWidget {
  final String icon;
  final String title;
  final String desc;

  const FeatureCard({
    super.key,
    required this.icon,
    required this.title,
    required this.desc,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 280,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 4))
        ],
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Text(icon, style: const TextStyle(fontSize: 36)),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            desc,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.black54),
          ),
        ],
      ),
    );
  }
}

