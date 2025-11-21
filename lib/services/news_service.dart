import 'package:flutter/material.dart';

/// Service for managing news data
class NewsService {
  /// Get default welcome news item
  static Map<String, dynamic> getDefaultNews() {
    return {
      'title': 'Selamat Datang di KiosDarma!',
      'description':
          'Aplikasi KiosDarma telah dirilis! Kelola bisnis Anda dengan lebih mudah dan efisien melalui fitur-fitur lengkap yang tersedia.',
      'fullContent':
          'Aplikasi KiosDarma adalah solusi lengkap untuk mengelola bisnis Anda. Dengan fitur kasir, manajemen produk, dan laporan yang komprehensif, Anda dapat mengoptimalkan operasional bisnis dengan lebih baik. Nikmati pengalaman yang mudah digunakan dan efisien. Mulai kelola bisnis Anda hari ini dan rasakan kemudahan yang ditawarkan oleh KiosDarma!',
      'date': DateTime.now(),
      'icon': Icons.waving_hand_rounded,
      'color': const Color(0xFF6366F1),
    };
  }
}

