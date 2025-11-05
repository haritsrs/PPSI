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
import 'utils/responsive_helper.dart';
import 'firebase_options.dart';

// Import future pages (for modularity)
// Example: import 'pages/overview_page.dart';
// We'll add these later as the app grows

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
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
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const KasirPage()),
        );
        break;
      case 3:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const LaporanPage()),
        );
        break;
    }
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
                // Welcome Section (Clickable to Account Page)
                Builder(
                  builder: (context) {
                    final iconScale = ResponsiveHelper.getIconScale(context);
                    final paddingScale = ResponsiveHelper.getPaddingScale(context);
                    final fontScale = ResponsiveHelper.getFontScale(context);
                    
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
                            colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF6366F1).withOpacity(0.3),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: EdgeInsets.all(12 * iconScale),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Icon(
                                    Icons.waving_hand,
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
                                        "Selamat datang kembali!",
                                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                          color: Colors.white70,
                                          fontWeight: FontWeight.w500,
                                          fontSize: (Theme.of(context).textTheme.bodyLarge?.fontSize ?? 16) * fontScale,
                                        ),
                                      ),
                                      SizedBox(height: 4 * paddingScale),
                                      Text(
                                        "Harits 👋",
                                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w600,
                                          fontSize: (Theme.of(context).textTheme.headlineSmall?.fontSize ?? 24) * fontScale,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Icon(
                                  Icons.chevron_right_rounded,
                                  color: Colors.white.withOpacity(0.7),
                                  size: 24 * iconScale,
                                ),
                              ],
                            ),
                            SizedBox(height: 20 * paddingScale),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      "Pendapatan Hari Ini",
                                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                        color: Colors.white70,
                                        fontWeight: FontWeight.w500,
                                        fontSize: (Theme.of(context).textTheme.bodyMedium?.fontSize ?? 14) * fontScale,
                                      ),
                                    ),
                                    SizedBox(height: 8 * paddingScale),
                                    Text(
                                      "Rp 1.250.000",
                                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w700,
                                        fontSize: (Theme.of(context).textTheme.headlineMedium?.fontSize ?? 28) * fontScale,
                                      ),
                                    ),
                                    SizedBox(height: 4 * paddingScale),
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.trending_up_rounded,
                                          color: Colors.green[300],
                                          size: 16 * iconScale,
                                        ),
                                        SizedBox(width: 4 * paddingScale),
                                        Text(
                                          "+12.5% dari kemarin",
                                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                            color: Colors.green[300],
                                            fontWeight: FontWeight.w500,
                                            fontSize: (Theme.of(context).textTheme.bodySmall?.fontSize ?? 12) * fontScale,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                Container(
                                  padding: EdgeInsets.all(16 * iconScale),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Icon(
                                    Icons.show_chart_rounded,
                                    color: Colors.white,
                                    size: 40 * iconScale,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
                
                SizedBox(height: 32 * ResponsiveHelper.getPaddingScale(context)),

                // Feature grid
                Builder(
                  builder: (context) {
                    final fontScale = ResponsiveHelper.getFontScale(context);
                    final paddingScale = ResponsiveHelper.getPaddingScale(context);
                    
                    return Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "Fitur Utama",
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                color: const Color(0xFF1F2937),
                                fontWeight: FontWeight.w600,
                                fontSize: (Theme.of(context).textTheme.titleLarge?.fontSize ?? 22) * fontScale,
                              ),
                            ),
                            TextButton(
                              onPressed: () {
                                HapticFeedback.lightImpact();
                                _showComingSoon(context, 'Semua Fitur');
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
                      ],
                    );
                  },
                ),

                GridView.count(
                  crossAxisCount: 4,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: 16 * ResponsiveHelper.getPaddingScale(context),
                  mainAxisSpacing: 16 * ResponsiveHelper.getPaddingScale(context),
                  childAspectRatio: 0.9,
                  children: [
                    HomeFeature(
                      icon: Icons.point_of_sale_rounded,
                      label: "Kasir",
                      color: const Color(0xFF10B981),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const KasirPage()),
                        );
                      },
                    ),
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
                      icon: Icons.analytics_rounded,
                      label: "Laporan",
                      color: const Color(0xFF8B5CF6),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const LaporanPage()),
                        );
                      },
                    ),
                    HomeFeature(
                      icon: Icons.qr_code_scanner_rounded,
                      label: "Scan",
                      color: const Color(0xFFF59E0B),
                      onTap: () => _showComingSoon(context, 'Scan Barcode'),
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
                      label: "Bayar",
                      color: const Color(0xFF06B6D4),
                      onTap: () => _showComingSoon(context, 'Pembayaran'),
                    ),
                    HomeFeature(
                      icon: Icons.cloud_off_rounded,
                      label: "Offline",
                      color: const Color(0xFF6B7280),
                      onTap: () => _showComingSoon(context, 'Mode Offline'),
                    ),
                    HomeFeature(
                      icon: Icons.settings_rounded,
                      label: "Setting",
                      color: const Color(0xFFEC4899),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const PengaturanPage()),
                        );
                      },
                    ),
                  ],
                ),

                SizedBox(height: 32 * ResponsiveHelper.getPaddingScale(context)),

                // Summary section
                Builder(
                  builder: (context) {
                    final fontScale = ResponsiveHelper.getFontScale(context);
                    final paddingScale = ResponsiveHelper.getPaddingScale(context);
                    
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Ringkasan Hari Ini",
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: const Color(0xFF1F2937),
                            fontWeight: FontWeight.w600,
                            fontSize: (Theme.of(context).textTheme.titleLarge?.fontSize ?? 22) * fontScale,
                          ),
                        ),
                        SizedBox(height: 16 * paddingScale),
                      ],
                    );
                  },
                ),

                Column(
                  children: [
                    SummaryCard(
                      title: "Transaksi Selesai",
                      value: "42",
                      subtitle: "Naik 8% dari kemarin",
                      icon: Icons.shopping_bag_rounded,
                      color: const Color(0xFF10B981),
                      trend: true,
                    ),
                    SizedBox(height: 16 * ResponsiveHelper.getPaddingScale(context)),
                    SummaryCard(
                      title: "Barang Hampir Habis",
                      value: "5 Produk",
                      subtitle: "Perlu restock segera",
                      icon: Icons.warning_amber_rounded,
                      color: const Color(0xFFF59E0B),
                      trend: false,
                    ),
                    SizedBox(height: 16 * ResponsiveHelper.getPaddingScale(context)),
                    SummaryCard(
                      title: "Total Pelanggan",
                      value: "120",
                      subtitle: "3 pelanggan baru hari ini",
                      icon: Icons.people_alt_rounded,
                      color: const Color(0xFF3B82F6),
                      trend: true,
                    ),
                  ],
                ),
                SizedBox(height: 20 * ResponsiveHelper.getPaddingScale(context)),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: Container(
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
