import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../utils/responsive_helper.dart';
import '../utils/home_utils.dart';

/// Reusable news card widget
class NewsCard extends StatelessWidget {
  final Map<String, dynamic> news;
  final VoidCallback onTap;

  const NewsCard({
    super.key,
    required this.news,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final iconScale = ResponsiveHelper.getIconScale(context);
    final paddingScale = ResponsiveHelper.getPaddingScale(context);
    final fontScale = ResponsiveHelper.getFontScale(context);

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
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
                          fontSize:
                              (Theme.of(context).textTheme.titleMedium?.fontSize ?? 16) * fontScale,
                        ),
                  ),
                  SizedBox(height: 8 * paddingScale),
                  Text(
                    news['description'] as String,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: const Color(0xFF6B7280),
                          fontSize:
                              (Theme.of(context).textTheme.bodyMedium?.fontSize ?? 14) * fontScale,
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
                        formatRelativeDate(news['date'] as DateTime),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: const Color(0xFF9CA3AF),
                              fontSize:
                                  (Theme.of(context).textTheme.bodySmall?.fontSize ?? 12) * fontScale,
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
}


