import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
  final PageController _pageController = PageController();
  final List<_OnboardingSlide> _slides = const [
    _OnboardingSlide(
      title: 'Kelola Produk Lebih Cepat',
      description: 'Pantau stok, tambahkan produk baru, dan atur katalog hanya dengan beberapa sentuhan.',
      icon: Icons.inventory_2_rounded,
      background: Color(0xFF6366F1),
    ),
    _OnboardingSlide(
      title: 'Catat Transaksi Otomatis',
      description: 'Setiap transaksi tersimpan rapi lengkap dengan metode pembayaran dan histori pelanggan.',
      icon: Icons.point_of_sale_rounded,
      background: Color(0xFF0EA5E9),
    ),
    _OnboardingSlide(
      title: 'Analisis Bisnis Realtime',
      description: 'Gunakan laporan interaktif untuk memahami performa toko dan keputusan yang tepat.',
      icon: Icons.analytics_rounded,
      background: Color(0xFF10B981),
    ),
  ];

  int _currentPage = 0;
  bool _isSaving = false;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _completeOnboarding() async {
    if (_isSaving) return;
    setState(() {
      _isSaving = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('has_seen_onboarding', true);
    } finally {
      if (mounted) {
        widget.onFinished();
      }
    }
  }

  void _next() {
    if (_currentPage == _slides.length - 1) {
      _completeOnboarding();
    } else {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: _completeOnboarding,
                child: const Text('Lewati'),
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _slides.length,
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index;
                  });
                },
                itemBuilder: (context, index) {
                  final slide = _slides[index];
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
                },
              ),
            ),
            const SizedBox(height: 20),
            _buildPageIndicators(),
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _next,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    backgroundColor: const Color(0xFF6366F1),
                    foregroundColor: Colors.white,
                  ),
                  child: Text(
                    _currentPage == _slides.length - 1 ? 'Mulai Sekarang' : 'Lanjut',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildPageIndicators() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(
        _slides.length,
        (index) {
          final isActive = index == _currentPage;
          return AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            margin: const EdgeInsets.symmetric(horizontal: 6),
            width: isActive ? 32 : 10,
            height: 10,
            decoration: BoxDecoration(
              color: isActive ? const Color(0xFF6366F1) : const Color(0xFFE2E8F0),
              borderRadius: BorderRadius.circular(999),
            ),
          );
        },
      ),
    );
  }
}

class _OnboardingSlide {
  const _OnboardingSlide({
    required this.title,
    required this.description,
    required this.icon,
    required this.background,
  });

  final String title;
  final String description;
  final IconData icon;
  final Color background;
}

