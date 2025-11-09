import 'package:flutter/material.dart';
import '../utils/responsive_helper.dart';

class NewsSection extends StatelessWidget {
  const NewsSection({super.key});

  @override
  Widget build(BuildContext context) {
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
  }
}

