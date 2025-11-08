import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'pages/kasir_page.dart';
import 'pages/laporan_page.dart';
import 'pages/produk_page.dart';
import 'pages/pelanggan_page.dart';
import 'pages/pengaturan_page.dart';
import 'pages/auth_wrapper.dart';
import 'pages/account_page.dart';
import 'pages/logout_page.dart';
import 'pages/scanner_page.dart';
import 'utils/responsive_helper.dart';
import 'firebase_options.dart';
import 'services/auth_service.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'firebase_options.dart'; // your generated file

// Import future pages (for modularity)
// Example: import 'pages/overview_page.dart';
// We'll add these later as the app grows

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables
  await dotenv.load(fileName: ".env");

  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Run your main app
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

  @override
  void initState() {
    super.initState();
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

  // Helper method to build popular product card
  Widget _buildPopularProductCard(
    BuildContext context,
    String name,
    String price,
    String sold,
    IconData icon,
    Color color,
  ) {
    final paddingScale = ResponsiveHelper.getPaddingScale(context);
    final fontScale = ResponsiveHelper.getFontScale(context);
    final iconScale = ResponsiveHelper.getIconScale(context);
    
    return Container(
      width: 200 * paddingScale,
      padding: EdgeInsets.all(20 * paddingScale),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.15),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
        border: Border.all(
          color: color.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(12 * paddingScale),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: color,
              size: 32 * iconScale,
            ),
          ),
          SizedBox(height: 16 * paddingScale),
          Text(
            name,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: const Color(0xFF1F2937),
              fontWeight: FontWeight.w700,
              fontSize: (Theme.of(context).textTheme.titleMedium?.fontSize ?? 16) * fontScale,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          SizedBox(height: 8 * paddingScale),
          Text(
            price,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
              fontSize: (Theme.of(context).textTheme.titleSmall?.fontSize ?? 14) * fontScale,
            ),
          ),
          SizedBox(height: 4 * paddingScale),
          Row(
            children: [
              Icon(
                Icons.shopping_bag_rounded,
                size: 14 * iconScale,
                color: const Color(0xFF6B7280),
              ),
              SizedBox(width: 4 * paddingScale),
              Text(
                sold,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: const Color(0xFF6B7280),
                  fontWeight: FontWeight.w500,
                  fontSize: (Theme.of(context).textTheme.bodySmall?.fontSize ?? 12) * fontScale,
                ),
              ),
            ],
          ),
        ],
      ),
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
              child: IconButton(
                onPressed: () {
                  HapticFeedback.lightImpact();
                  _showComingSoon(context, 'Notifikasi');
                },
                icon: Icon(Icons.notifications_rounded, color: Colors.white, size: 24 * iconScale),
                iconSize: 24 * iconScale,
                padding: EdgeInsets.all(8 * iconScale),
                tooltip: 'Notifikasi',
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
                // Enhanced Header: Personalized Greeting + Motivational Revenue Summary + Growth Indicator
                Builder(
                  builder: (context) {
                    final iconScale = ResponsiveHelper.getIconScale(context);
                    final paddingScale = ResponsiveHelper.getPaddingScale(context);
                    final fontScale = ResponsiveHelper.getFontScale(context);
                    
                    // Get user name from auth service
                    final userName = AuthService.currentUser?.displayName ?? 
                                    AuthService.currentUser?.email?.split('@')[0] ?? 
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
                    
                    // Mock revenue data (replace with real data later)
                    final todayRevenue = 1250000;
                    final yesterdayRevenue = 1110000;
                    final growthPercent = ((todayRevenue - yesterdayRevenue) / yesterdayRevenue * 100).toStringAsFixed(1);
                    final isPositiveGrowth = todayRevenue >= yesterdayRevenue;
                    
                    return Container(
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
                          // Personalized Greeting
                          Row(
                            children: [
                              Container(
                                padding: EdgeInsets.all(12 * iconScale),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.25),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Icon(
                                  Icons.waving_hand_rounded,
                                  color: Colors.white,
                                  size: 28 * iconScale,
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
                                      "Semangat untuk hari yang produktif!",
                                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                        color: Colors.white.withOpacity(0.9),
                                        fontWeight: FontWeight.w500,
                                        fontSize: (Theme.of(context).textTheme.bodyMedium?.fontSize ?? 14) * fontScale,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 24 * paddingScale),
                          
                          // Motivational Revenue Summary
                          Container(
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
                                        "Pendapatan Hari Ini",
                                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                          color: Colors.white.withOpacity(0.9),
                                          fontWeight: FontWeight.w500,
                                          fontSize: (Theme.of(context).textTheme.bodyMedium?.fontSize ?? 14) * fontScale,
                                        ),
                                      ),
                                      SizedBox(height: 8 * paddingScale),
                                      Text(
                                        "Rp ${_formatCurrency(todayRevenue)}",
                                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w800,
                                          fontSize: (Theme.of(context).textTheme.headlineMedium?.fontSize ?? 28) * fontScale,
                                        ),
                                      ),
                                      SizedBox(height: 8 * paddingScale),
                                      // Mini Growth Indicator
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
                          ),
                        ],
                      ),
                    );
                  },
                ),
                
                SizedBox(height: 32 * ResponsiveHelper.getPaddingScale(context)),

                // Menu Bisnis / Kelola Usaha Kamu - 2x2 Grid
                Builder(
                  builder: (context) {
                    final fontScale = ResponsiveHelper.getFontScale(context);
                    final paddingScale = ResponsiveHelper.getPaddingScale(context);
                    
                    return Column(
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
                        GridView.count(
                          crossAxisCount: 2,
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          crossAxisSpacing: 16 * paddingScale,
                          mainAxisSpacing: 16 * paddingScale,
                          childAspectRatio: 1.1,
                          children: [
                            HomeFeature(
                              icon: Icons.inventory_2_rounded,
                              label: "Stok",
                              color: const Color(0xFF3B82F6),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (context) => const ProdukPage()),
                                );
                              },
                            ),
                            HomeFeature(
                              icon: Icons.people_rounded,
                              label: "Pelanggan",
                              color: const Color(0xFFEF4444),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (context) => const PelangganPage()),
                                );
                              },
                            ),
                            HomeFeature(
                              icon: Icons.payment_rounded,
                              label: "Pembayaran",
                              color: const Color(0xFF10B981),
                              onTap: () => _showComingSoon(context, 'Pembayaran'),
                            ),
                            HomeFeature(
                              icon: Icons.local_offer_rounded,
                              label: "Promo",
                              color: const Color(0xFFF59E0B),
                              onTap: () => _showComingSoon(context, 'Promo'),
                            ),
                          ],
                        ),
                      ],
                    );
                  },
                ),

                SizedBox(height: 32 * ResponsiveHelper.getPaddingScale(context)),

                // Dynamic Content Section - Produk Populer
                Builder(
                  builder: (context) {
                    final fontScale = ResponsiveHelper.getFontScale(context);
                    final paddingScale = ResponsiveHelper.getPaddingScale(context);
                    
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "Produk Populer",
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                color: const Color(0xFF1F2937),
                                fontWeight: FontWeight.w700,
                                fontSize: (Theme.of(context).textTheme.titleLarge?.fontSize ?? 22) * fontScale,
                              ),
                            ),
                            TextButton(
                              onPressed: () {
                                HapticFeedback.lightImpact();
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (context) => const ProdukPage()),
                                );
                              },
                              child: Text(
                                "Lihat Semua",
                                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                  color: const Color(0xFF6366F1),
                                  fontWeight: FontWeight.w600,
                                  fontSize: (Theme.of(context).textTheme.titleSmall?.fontSize ?? 14) * fontScale,
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 16 * paddingScale),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              _buildPopularProductCard(
                                context,
                                "Nasi Goreng Spesial",
                                "Rp 15.000",
                                "42 terjual",
                                Icons.restaurant_rounded,
                                const Color(0xFF10B981),
                              ),
                              SizedBox(width: 16 * paddingScale),
                              _buildPopularProductCard(
                                context,
                                "Es Teh Manis",
                                "Rp 5.000",
                                "38 terjual",
                                Icons.local_drink_rounded,
                                const Color(0xFF3B82F6),
                              ),
                              SizedBox(width: 16 * paddingScale),
                              _buildPopularProductCard(
                                context,
                                "Mie Ayam",
                                "Rp 12.000",
                                "35 terjual",
                                Icons.ramen_dining_rounded,
                                const Color(0xFFF59E0B),
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  },
                ),

                SizedBox(height: 32 * ResponsiveHelper.getPaddingScale(context)),

                // Weekly Target Tracker (Optional Add-on)
                Builder(
                  builder: (context) {
                    final fontScale = ResponsiveHelper.getFontScale(context);
                    final paddingScale = ResponsiveHelper.getPaddingScale(context);
                    
                    final weeklyTarget = 10000000; // 10M target
                    final currentProgress = 6250000; // 6.25M current
                    final progressPercent = (currentProgress / weeklyTarget * 100).clamp(0.0, 100.0);
                    
                    return Container(
                      padding: EdgeInsets.all(24 * paddingScale),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            const Color(0xFF8B5CF6).withOpacity(0.1),
                            const Color(0xFFEC4899).withOpacity(0.1),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: const Color(0xFF8B5CF6).withOpacity(0.2),
                          width: 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF8B5CF6).withOpacity(0.1),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: EdgeInsets.all(10 * paddingScale),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF8B5CF6).withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  Icons.track_changes_rounded,
                                  color: const Color(0xFF8B5CF6),
                                  size: 24 * ResponsiveHelper.getIconScale(context),
                                ),
                              ),
                              SizedBox(width: 12 * paddingScale),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      "Target Mingguan",
                                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                        color: const Color(0xFF1F2937),
                                        fontWeight: FontWeight.w700,
                                        fontSize: (Theme.of(context).textTheme.titleMedium?.fontSize ?? 16) * fontScale,
                                      ),
                                    ),
                                    SizedBox(height: 4 * paddingScale),
                                    Text(
                                      "${progressPercent.toStringAsFixed(0)}% tercapai",
                                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                        color: const Color(0xFF6B7280),
                                        fontWeight: FontWeight.w500,
                                        fontSize: (Theme.of(context).textTheme.bodySmall?.fontSize ?? 12) * fontScale,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 20 * paddingScale),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: LinearProgressIndicator(
                              value: progressPercent / 100,
                              minHeight: 12,
                              backgroundColor: Colors.grey[200],
                              valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF8B5CF6)),
                            ),
                          ),
                          SizedBox(height: 12 * paddingScale),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                "Rp ${_formatCurrency(currentProgress)}",
                                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                  color: const Color(0xFF8B5CF6),
                                  fontWeight: FontWeight.w700,
                                  fontSize: (Theme.of(context).textTheme.titleSmall?.fontSize ?? 14) * fontScale,
                                ),
                              ),
                              Text(
                                "Rp ${_formatCurrency(weeklyTarget)}",
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: const Color(0xFF6B7280),
                                  fontWeight: FontWeight.w500,
                                  fontSize: (Theme.of(context).textTheme.bodySmall?.fontSize ?? 12) * fontScale,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
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

