import 'package:flutter/material.dart';
import 'profile_header.dart';
import 'banner_carousel.dart';
import 'business_menu.dart';
import 'news_section.dart';
import '../../controllers/home_controller.dart';
import '../../utils/responsive_helper.dart';
import '../../utils/home_utils.dart' as home_utils;

class HomeContent extends StatelessWidget {
  final HomeController controller;
  final ScrollController scrollController;
  final Animation<double> fadeAnimation;
  final Animation<Offset> slideAnimation;

  const HomeContent({
    super.key,
    required this.controller,
    required this.scrollController,
    required this.fadeAnimation,
    required this.slideAnimation,
  });

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: fadeAnimation,
      child: SlideTransition(
        position: slideAnimation,
        child: SingleChildScrollView(
          controller: scrollController,
          padding: EdgeInsets.all(20 * ResponsiveHelper.getPaddingScale(context)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ProfileHeader(
                currentUser: controller.currentUser,
                databaseService: controller.databaseService,
              ),
              SizedBox(height: 32 * ResponsiveHelper.getPaddingScale(context)),
              BannerCarousel(bannerImages: controller.bannerImages),
              SizedBox(height: 32 * ResponsiveHelper.getPaddingScale(context)),
              BusinessMenu(
                onShowComingSoon: home_utils.showComingSoonDialog,
              ),
              SizedBox(height: 32 * ResponsiveHelper.getPaddingScale(context)),
              const NewsSection(),
              SizedBox(height: 20 * ResponsiveHelper.getPaddingScale(context)),
            ],
          ),
        ),
      ),
    );
  }
}
