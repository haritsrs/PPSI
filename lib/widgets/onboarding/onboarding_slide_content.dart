import 'package:flutter/material.dart';
import '../../models/onboarding_slide.dart';

class OnboardingSlideContent extends StatelessWidget {
  final OnboardingSlide slide;

  const OnboardingSlideContent({
    super.key,
    required this.slide,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeOutCubic,
            width: 140,
            height: 140,
            decoration: BoxDecoration(
              color: slide.background.withOpacity(0.12),
              borderRadius: BorderRadius.circular(32),
            ),
            child: Icon(
              slide.icon,
              size: 72,
              color: slide.background,
            ),
          ),
          const SizedBox(height: 40),
          Text(
            slide.title,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF1F2937),
                ),
          ),
          const SizedBox(height: 16),
          Text(
            slide.description,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Colors.grey[600],
                ),
          ),
        ],
      ),
    );
  }
}


