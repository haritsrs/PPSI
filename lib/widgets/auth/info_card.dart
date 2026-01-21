import 'package:flutter/material.dart';

class InfoCard extends StatelessWidget {
  final String message;
  final IconData icon;
  final Color backgroundColor;
  final Color borderColor;
  final Color iconColor;
  final Color textColor;

  const InfoCard({
    super.key,
    required this.message,
    this.icon = Icons.info_rounded,
    this.backgroundColor = const Color(0xFFFEF3C7),
    this.borderColor = const Color(0xFFFCD34D),
    this.iconColor = const Color(0xFFF59E0B),
    this.textColor = const Color(0xFF92400E),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: borderColor,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: iconColor,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: textColor,
                    fontWeight: FontWeight.w500,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}


