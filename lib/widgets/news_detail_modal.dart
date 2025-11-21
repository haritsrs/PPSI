import 'package:flutter/material.dart';
import '../utils/responsive_helper.dart';
import '../utils/home_utils.dart';

/// Reusable news detail modal widget
class NewsDetailModal extends StatelessWidget {
  final Map<String, dynamic> news;

  const NewsDetailModal({
    super.key,
    required this.news,
  });

  static void show(BuildContext context, Map<String, dynamic> news) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => NewsDetailModal(news: news),
    );
  }

  @override
  Widget build(BuildContext context) {
    final fontScale = ResponsiveHelper.getFontScale(context);
    final paddingScale = ResponsiveHelper.getPaddingScale(context);
    final iconScale = ResponsiveHelper.getIconScale(context);

    return Container(
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
                              fontSize:
                                  (Theme.of(context).textTheme.titleLarge?.fontSize ?? 22) * fontScale,
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
                      fontSize:
                          (Theme.of(context).textTheme.bodyLarge?.fontSize ?? 16) * fontScale,
                    ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

