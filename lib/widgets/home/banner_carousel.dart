import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';
import '../../utils/responsive_helper.dart';

class BannerCarousel extends StatefulWidget {
  final List<String> bannerImages;

  const BannerCarousel({
    super.key,
    required this.bannerImages,
  });

  @override
  State<BannerCarousel> createState() => _BannerCarouselState();
}

class _BannerCarouselState extends State<BannerCarousel> {
  int _currentBannerIndex = 0;

  @override
  Widget build(BuildContext context) {
    final paddingScale = ResponsiveHelper.getPaddingScale(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final isHorizontal = ResponsiveHelper.isHorizontal(context);
    final homePadding = 20 * paddingScale; // Match home view padding
    final itemMargin = 4 * paddingScale; // Carousel item margin
    final availableWidth = screenWidth - (homePadding * 2);
    
    // Calculate height based on 2.7:1 aspect ratio (width:height)
    // viewportFraction = 0.9, so visible banner width = availableWidth * 0.9
    // Each item has margin, so image width = (availableWidth * 0.9) - (itemMargin * 2)
    // height = image width / 2.7
    final bannerImageWidth = (availableWidth * 0.9) - (itemMargin * 2);
    final bannerHeight = bannerImageWidth / 2.7;
    
    // In horizontal view, ensure full banner is shown (like vertical)
    // Use contain fit to show entire image without cropping
    final imageFit = isHorizontal ? BoxFit.contain : BoxFit.cover;
    
    if (widget.bannerImages.isEmpty) {
      // Show placeholder if no banners
      return Container(
        height: bannerHeight,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              const Color(0xFF6366F1).withOpacity(0.1),
              const Color(0xFF8B5CF6).withOpacity(0.1),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: const Color(0xFF6366F1).withOpacity(0.2),
            width: 2,
            style: BorderStyle.solid,
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.image_rounded,
                size: 48,
                color: const Color(0xFF6366F1).withOpacity(0.5),
              ),
              SizedBox(height: 8 * paddingScale),
              Text(
                'Tambahkan banner promosi di assets/banners/',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: const Color(0xFF6B7280),
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }
    
    return Column(
      children: [
        CarouselSlider.builder(
          itemCount: widget.bannerImages.length,
          itemBuilder: (context, index, realIndex) {
            return Container(
              margin: EdgeInsets.symmetric(horizontal: 4 * paddingScale),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: AspectRatio(
                  aspectRatio: 2.7,
                  child: Image.asset(
                    widget.bannerImages[index],
                    fit: imageFit,
                    width: double.infinity,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: Colors.grey[200],
                        child: const Center(
                          child: Icon(Icons.error_outline, color: Colors.grey),
                        ),
                      );
                    },
                  ),
                ),
              ),
            );
          },
          options: CarouselOptions(
            height: bannerHeight,
            autoPlay: true,
            autoPlayInterval: const Duration(seconds: 3),
            autoPlayAnimationDuration: const Duration(milliseconds: 800),
            autoPlayCurve: Curves.fastOutSlowIn,
            enlargeCenterPage: true,
            enlargeFactor: 0.2,
            viewportFraction: 0.9,
            onPageChanged: (index, reason) {
              setState(() {
                _currentBannerIndex = index;
              });
            },
          ),
        ),
        if (widget.bannerImages.length > 1) ...[
          SizedBox(height: 12 * paddingScale),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              widget.bannerImages.length,
              (index) => Container(
                width: 8,
                height: 8,
                margin: EdgeInsets.symmetric(horizontal: 4 * paddingScale),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _currentBannerIndex == index
                      ? const Color(0xFF6366F1)
                      : const Color(0xFF6366F1).withOpacity(0.3),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}


