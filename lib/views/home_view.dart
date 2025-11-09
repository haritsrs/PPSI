import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../pages/kasir_page.dart';
import '../pages/laporan_page.dart';
import '../pages/produk_page.dart';
import '../pages/scanner_page.dart';
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
    setState(() {
      _selectedIndex = index;
    });
    
    HapticFeedback.lightImpact();
    
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
        showComingSoonDialog(context, 'Scan Barcode');
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: CustomAppBar(databaseService: _databaseService),
      body: FadeTransition(
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
      ),
      bottomNavigationBar: CustomBottomNavBar(
        selectedIndex: _selectedIndex,
        onItemTapped: _onItemTapped,
        onScanTapped: _onScanTapped,
      ),
    );
  }
}

