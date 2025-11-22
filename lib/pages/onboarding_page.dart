import 'package:flutter/material.dart';
import '../services/onboarding_controller.dart';
import '../widgets/onboarding/skip_button.dart';
import '../widgets/onboarding/onboarding_slide_content.dart';
import '../widgets/onboarding/page_indicators.dart';
import '../widgets/onboarding/onboarding_button.dart';

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({
    super.key,
    required this.onFinished,
  });

  final VoidCallback onFinished;

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  late OnboardingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = OnboardingController();
    _controller.addListener(_handleControllerChange);
  }

  @override
  void dispose() {
    _controller.removeListener(_handleControllerChange);
    _controller.dispose();
    super.dispose();
  }

  void _handleControllerChange() {
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _handleComplete() async {
    await _controller.completeOnboarding();
    if (mounted) {
      widget.onFinished();
    }
  }

  void _handleNext() {
    if (_controller.isLastPage) {
      _handleComplete();
    } else {
      _controller.nextPage();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            SkipButton(onPressed: _handleComplete),
            Expanded(
              child: PageView.builder(
                controller: _controller.pageController,
                itemCount: _controller.slides.length,
                onPageChanged: _controller.setCurrentPage,
                itemBuilder: (context, index) {
                  return OnboardingSlideContent(
                    slide: _controller.slides[index],
                  );
                },
              ),
            ),
            const SizedBox(height: 20),
            PageIndicators(
              totalPages: _controller.slides.length,
              currentPage: _controller.currentPage,
            ),
            const SizedBox(height: 24),
            OnboardingButton(
              text: _controller.isLastPage ? 'Mulai Sekarang' : 'Lanjut',
              onPressed: _handleNext,
              isLoading: _controller.isSaving,
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

