import 'package:flutter/material.dart';
import '../utils/responsive_helper.dart';
import '../pages/produk_page.dart';
import '../pages/pelanggan_page.dart';
import '../widgets/home_feature.dart';
import '../widgets/contact_us_modal.dart';

class BusinessMenu extends StatelessWidget {
  final Function(BuildContext, String) onShowComingSoon;

  const BusinessMenu({
    super.key,
    required this.onShowComingSoon,
  });

  @override
  Widget build(BuildContext context) {
    final fontScale = ResponsiveHelper.getFontScale(context);
    final paddingScale = ResponsiveHelper.getPaddingScale(context);
    
    final menuItems = [
      {
        'icon': Icons.contact_support_rounded,
        'label': 'Hubungi Kami',
        'color': const Color(0xFF3B82F6),
        'onTap': () {
          ContactUsModal.show(context);
        },
      },
      {
        'icon': Icons.language_rounded,
        'label': 'Website',
        'color': const Color(0xFF8B5CF6),
        'onTap': () => onShowComingSoon(context, 'Website'),
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
        'onTap': () => onShowComingSoon(context, 'Promo'),
      },
      {
        'icon': Icons.payment_rounded,
        'label': 'Pembayaran',
        'color': const Color(0xFF10B981),
        'onTap': () => onShowComingSoon(context, 'Pembayaran'),
      },
      {
        'icon': Icons.more_horiz_rounded,
        'label': 'More',
        'color': const Color(0xFF6B7280),
        'onTap': () => onShowComingSoon(context, 'More'),
      },
    ];
    
    final isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;

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
            "Kelola Usahamu",
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: const Color(0xFF1F2937),
              fontWeight: FontWeight.w700,
              fontSize: (Theme.of(context).textTheme.titleLarge?.fontSize ?? 22) * fontScale,
            ),
          ),
          SizedBox(height: 20 * paddingScale),
          if (isLandscape)
            LayoutBuilder(
              builder: (context, constraints) {
                final crossAxisCount = constraints.maxWidth > 600 ? 3 : 2;
                return GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: crossAxisCount,
                    mainAxisSpacing: 16 * paddingScale,
                    crossAxisSpacing: 16 * paddingScale,
                    childAspectRatio: 1.1,
                  ),
                  itemCount: menuItems.length,
                  itemBuilder: (context, index) {
                    final item = menuItems[index];
                    return HomeFeature(
                      icon: item['icon'] as IconData,
                      label: item['label'] as String,
                      color: item['color'] as Color,
                      onTap: item['onTap'] as VoidCallback,
                    );
                  },
                );
              },
            )
          else
            SizedBox(
              height: 120 * paddingScale,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: EdgeInsets.symmetric(horizontal: 12 * paddingScale),
                itemCount: menuItems.length,
                itemBuilder: (context, index) {
                  final item = menuItems[index];
                  return Container(
                    width: 100 * paddingScale,
                    margin: EdgeInsets.only(
                      right: index == menuItems.length - 1 ? 0 : 16 * paddingScale,
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
  }
}

