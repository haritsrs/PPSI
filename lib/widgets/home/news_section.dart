import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import '../../utils/responsive_helper.dart';

class NewsSection extends StatefulWidget {
  const NewsSection({super.key});

  @override
  State<NewsSection> createState() => _NewsSectionState();
}

class _NewsSectionState extends State<NewsSection> {
  Timer? _timer;
  final DateTime _postDate = DateTime.now();

  // News item data
  final Map<String, dynamic> _newsItem = {
    'title': 'Selamat Datang di KiosDarma!',
    'description': 'Aplikasi KiosDarma telah dirilis! Kelola bisnis Anda dengan lebih mudah dan efisien melalui fitur-fitur lengkap yang tersedia.',
    'fullContent': 'Aplikasi KiosDarma adalah solusi lengkap untuk mengelola bisnis Anda. Dengan fitur kasir, manajemen produk, dan laporan yang komprehensif, Anda dapat mengoptimalkan operasional bisnis dengan lebih baik. Nikmati pengalaman yang mudah digunakan dan efisien. Mulai kelola bisnis Anda hari ini dan rasakan kemudahan yang ditawarkan oleh KiosDarma!',
    'icon': Icons.waving_hand_rounded,
    'color': const Color(0xFF6366F1),
  };

  @override
  void initState() {
    super.initState();
    // Update every hour to refresh the time display
    _timer = Timer.periodic(const Duration(hours: 1), (timer) {
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
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

  void _showNewsDetail(BuildContext context) {
    final fontScale = ResponsiveHelper.getFontScale(context);
    final paddingScale = ResponsiveHelper.getPaddingScale(context);
    final iconScale = ResponsiveHelper.getIconScale(context);

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
                      color: (_newsItem['color'] as Color).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      _newsItem['icon'] as IconData,
                      color: _newsItem['color'] as Color,
                      size: 28 * iconScale,
                    ),
                  ),
                  SizedBox(width: 16 * paddingScale),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _newsItem['title'] as String,
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
                              _formatDate(_postDate),
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
                  _newsItem['fullContent'] as String,
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

  @override
  Widget build(BuildContext context) {
    final fontScale = ResponsiveHelper.getFontScale(context);
    final paddingScale = ResponsiveHelper.getPaddingScale(context);
    final iconScale = ResponsiveHelper.getIconScale(context);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
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
        SizedBox(height: 16 * paddingScale),
        GestureDetector(
          onTap: () {
            HapticFeedback.lightImpact();
            _showNewsDetail(context);
          },
          child: Container(
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
                color: (_newsItem['color'] as Color).withOpacity(0.1),
                width: 1,
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: EdgeInsets.all(12 * paddingScale),
                  decoration: BoxDecoration(
                    color: (_newsItem['color'] as Color).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    _newsItem['icon'] as IconData,
                    color: _newsItem['color'] as Color,
                    size: 24 * iconScale,
                  ),
                ),
                SizedBox(width: 12 * paddingScale),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _newsItem['title'] as String,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: const Color(0xFF1F2937),
                          fontWeight: FontWeight.w600,
                          fontSize: (Theme.of(context).textTheme.titleMedium?.fontSize ?? 16) * fontScale,
                        ),
                      ),
                      SizedBox(height: 4 * paddingScale),
                      Text(
                        _newsItem['description'] as String,
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
                            _formatDate(_postDate),
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
          ),
        ),
      ],
    );
  }
}

