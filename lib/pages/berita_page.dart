import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async';
import '../services/auth_service.dart';
import '../utils/responsive_helper.dart';

class BeritaPage extends StatefulWidget {
  const BeritaPage({super.key});

  @override
  State<BeritaPage> createState() => _BeritaPageState();
}

class _BeritaPageState extends State<BeritaPage> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  User? _currentUser;
  Timer? _timer;

  // News item data
  final Map<String, dynamic> _newsItem = {
    'title': 'Selamat Datang di KiosDarma!',
    'description': 'Aplikasi KiosDarma telah dirilis! Kelola bisnis Anda dengan lebih mudah dan efisien melalui fitur-fitur lengkap yang tersedia.',
    'fullContent': 'Aplikasi KiosDarma adalah solusi lengkap untuk mengelola bisnis Anda. Dengan fitur kasir, manajemen produk, dan laporan yang komprehensif, Anda dapat mengoptimalkan operasional bisnis dengan lebih baik. Nikmati pengalaman yang mudah digunakan dan efisien. Mulai kelola bisnis Anda hari ini dan rasakan kemudahan yang ditawarkan oleh KiosDarma!',
    'date': DateTime.now(),
    'icon': Icons.waving_hand_rounded,
    'color': const Color(0xFF6366F1),
  };

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _initializeAnimations();
    // Update every minute to refresh the time display
    _timer = Timer.periodic(const Duration(minutes: 1), (timer) {
      if (mounted) {
        setState(() {});
      }
    });
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

  Future<void> _loadUserData() async {
    await AuthService.reloadUser();
    if (mounted) {
      setState(() {
        _currentUser = AuthService.currentUser;
      });
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _timer?.cancel();
    super.dispose();
  }

  String get _userDisplayName {
    if (_currentUser?.displayName != null && _currentUser!.displayName!.isNotEmpty) {
      return _currentUser!.displayName!;
    }
    if (_currentUser?.email != null) {
      return _currentUser!.email!.split('@')[0];
    }
    return 'Pengguna';
  }

  @override
  Widget build(BuildContext context) {
    final fontScale = ResponsiveHelper.getFontScale(context);
    final paddingScale = ResponsiveHelper.getPaddingScale(context);
    final iconScale = ResponsiveHelper.getIconScale(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle.light.copyWith(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
          statusBarBrightness: Brightness.dark,
        ),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          onPressed: () {
            HapticFeedback.lightImpact();
            Navigator.pop(context);
          },
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.newspaper_rounded,
                color: Colors.white,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              "Berita",
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w600,
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
            padding: EdgeInsets.all(20 * paddingScale),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Welcome Header with Release Date
                Container(
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
                        blurRadius: 15,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Icon(
                        Icons.waving_hand_rounded,
                        color: Colors.white,
                        size: 48 * iconScale,
                      ),
                      SizedBox(height: 12 * paddingScale),
                      Text(
                        "Selamat Datang, $_userDisplayName!",
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: (Theme.of(context).textTheme.titleLarge?.fontSize ?? 22) * fontScale,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                
                SizedBox(height: 24 * paddingScale),
                
                // News Items List
                Text(
                  "Berita & Update",
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: const Color(0xFF1F2937),
                    fontWeight: FontWeight.w700,
                    fontSize: (Theme.of(context).textTheme.titleLarge?.fontSize ?? 22) * fontScale,
                  ),
                ),
                
                SizedBox(height: 16 * paddingScale),
                
                _buildNewsCard(context, _newsItem, iconScale, paddingScale, fontScale),
                
                SizedBox(height: 20 * paddingScale),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inDays > 0) {
      return '${difference.inDays} hari yang lalu';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} jam yang lalu';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} menit yang lalu';
    } else {
      return 'Baru saja';
    }
  }

  Widget _buildNewsCard(
    BuildContext context,
    Map<String, dynamic> news,
    double iconScale,
    double paddingScale,
    double fontScale,
  ) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        _showNewsDetail(context, news, iconScale, paddingScale, fontScale);
      },
      child: Container(
        padding: EdgeInsets.all(20 * paddingScale),
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
                size: 28 * iconScale,
              ),
            ),
            SizedBox(width: 16 * paddingScale),
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
                  SizedBox(height: 8 * paddingScale),
                  Text(
                    news['description'] as String,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: const Color(0xFF6B7280),
                      fontSize: (Theme.of(context).textTheme.bodyMedium?.fontSize ?? 14) * fontScale,
                      height: 1.5,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 12 * paddingScale),
                  Row(
                    children: [
                      Icon(
                        Icons.access_time_rounded,
                        size: 14 * iconScale,
                        color: const Color(0xFF9CA3AF),
                      ),
                      SizedBox(width: 6 * paddingScale),
                      Text(
                        _formatDate(news['date'] as DateTime),
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
            Icon(
              Icons.chevron_right_rounded,
              color: Colors.grey[400],
              size: 24 * iconScale,
            ),
          ],
        ),
      ),
    );
  }

  void _showNewsDetail(
    BuildContext context,
    Map<String, dynamic> news,
    double iconScale,
    double paddingScale,
    double fontScale,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.8,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
        ),
        child: Column(
          children: [
            // Handle
            Container(
              margin: EdgeInsets.only(top: 12 * paddingScale),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            
            // Header
            Padding(
              padding: EdgeInsets.all(24 * paddingScale),
              child: Row(
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
                      size: 28 * iconScale,
                    ),
                  ),
                  SizedBox(width: 16 * paddingScale),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          news['title'] as String,
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: const Color(0xFF1F2937),
                            fontWeight: FontWeight.w700,
                            fontSize: (Theme.of(context).textTheme.titleLarge?.fontSize ?? 22) * fontScale,
                          ),
                        ),
                        SizedBox(height: 4 * paddingScale),
                        Row(
                          children: [
                            Icon(
                              Icons.access_time_rounded,
                              size: 14 * iconScale,
                              color: const Color(0xFF9CA3AF),
                            ),
                            SizedBox(width: 6 * paddingScale),
                            Text(
                              _formatDate(news['date'] as DateTime),
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
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            
            Divider(height: 1, color: Colors.grey[200]),
            
            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(24 * paddingScale),
                child: Text(
                  news['fullContent'] as String,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: const Color(0xFF1F2937),
                    height: 1.8,
                    fontSize: (Theme.of(context).textTheme.bodyLarge?.fontSize ?? 16) * fontScale,
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

