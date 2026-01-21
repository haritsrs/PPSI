import 'package:flutter/material.dart';
import '../models/onboarding_slide.dart';
import '../services/onboarding_service.dart';

class OnboardingController extends ChangeNotifier {
  final PageController pageController = PageController();
  final List<OnboardingSlide> slides = const [
    OnboardingSlide(
      title: 'Kelola Produk Lebih Cepat',
      description:
          'Pantau stok, tambahkan produk baru, dan atur katalog hanya dengan beberapa sentuhan.',
      icon: Icons.inventory_2_rounded,
      background: Color(0xFF6366F1),
    ),
    OnboardingSlide(
      title: 'Catat Transaksi Otomatis',
      description:
          'Setiap transaksi tersimpan rapi lengkap dengan metode pembayaran dan histori pelanggan.',
      icon: Icons.point_of_sale_rounded,
      background: Color(0xFF0EA5E9),
    ),
    OnboardingSlide(
      title: 'Analisis Bisnis Realtime',
      description:
          'Gunakan laporan interaktif untuk memahami performa toko dan keputusan yang tepat.',
      icon: Icons.analytics_rounded,
      background: Color(0xFF10B981),
    ),
  ];

  int _currentPage = 0;
  bool _isSaving = false;

  int get currentPage => _currentPage;
  bool get isSaving => _isSaving;
  bool get isLastPage => _currentPage == slides.length - 1;

  void setCurrentPage(int page) {
    _currentPage = page;
    notifyListeners();
  }

  void nextPage() {
    if (_currentPage < slides.length - 1) {
      pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
      );
    }
  }

  Future<void> completeOnboarding() async {
    if (_isSaving) return;

    _isSaving = true;
    notifyListeners();

    try {
      await OnboardingService.completeOnboarding();
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    pageController.dispose();
    super.dispose();
  }
}


