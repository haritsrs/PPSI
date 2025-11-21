import 'package:flutter/material.dart';

class PageIndicators extends StatelessWidget {
  final int totalPages;
  final int currentPage;
  final Color activeColor;
  final Color inactiveColor;

  const PageIndicators({
    super.key,
    required this.totalPages,
    required this.currentPage,
    this.activeColor = const Color(0xFF6366F1),
    this.inactiveColor = const Color(0xFFE2E8F0),
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(
        totalPages,
        (index) {
          final isActive = index == currentPage;
          return AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            margin: const EdgeInsets.symmetric(horizontal: 6),
            width: isActive ? 32 : 10,
            height: 10,
            decoration: BoxDecoration(
              color: isActive ? activeColor : inactiveColor,
              borderRadius: BorderRadius.circular(999),
            ),
          );
        },
      ),
    );
  }
}

