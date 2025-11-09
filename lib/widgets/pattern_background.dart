import 'package:flutter/material.dart';

/// A subtle background pattern widget that can be used as a decoration
class PatternBackground extends StatelessWidget {
  final Widget child;
  final PatternType patternType;
  final Color? patternColor;
  final double opacity;

  const PatternBackground({
    super.key,
    required this.child,
    this.patternType = PatternType.dots,
    this.patternColor,
    this.opacity = 0.03,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        CustomPaint(
          painter: PatternPainter(
            patternType: patternType,
            color: patternColor ?? Colors.grey.shade400,
            opacity: opacity,
          ),
          size: Size.infinite,
        ),
        child,
      ],
    );
  }
}

enum PatternType {
  dots,
  diagonalStripes,
  grid,
}

class PatternPainter extends CustomPainter {
  final PatternType patternType;
  final Color color;
  final double opacity;

  PatternPainter({
    required this.patternType,
    required this.color,
    required this.opacity,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withOpacity(opacity)
      ..style = PaintingStyle.fill;

    switch (patternType) {
      case PatternType.dots:
        _drawDots(canvas, size, paint);
        break;
      case PatternType.diagonalStripes:
        _drawDiagonalStripes(canvas, size, paint);
        break;
      case PatternType.grid:
        _drawGrid(canvas, size, paint);
        break;
    }
  }

  void _drawDots(Canvas canvas, Size size, Paint paint) {
    const spacing = 40.0;
    const radius = 2.0;

    for (double x = 0; x < size.width; x += spacing) {
      for (double y = 0; y < size.height; y += spacing) {
        canvas.drawCircle(
          Offset(x, y),
          radius,
          paint,
        );
      }
    }
  }

  void _drawDiagonalStripes(Canvas canvas, Size size, Paint paint) {
    const stripeWidth = 60.0;
    final path = Path();

    for (double i = -size.height; i < size.width + size.height; i += stripeWidth * 2) {
      path.moveTo(i, 0);
      path.lineTo(i + stripeWidth, 0);
      path.lineTo(i + stripeWidth - size.height, size.height);
      path.lineTo(i - size.height, size.height);
      path.close();
    }

    canvas.drawPath(path, paint);
  }

  void _drawGrid(Canvas canvas, Size size, Paint paint) {
    const spacing = 40.0;
    paint.style = PaintingStyle.stroke;
    paint.strokeWidth = 0.5;

    // Vertical lines
    for (double x = 0; x < size.width; x += spacing) {
      canvas.drawLine(
        Offset(x, 0),
        Offset(x, size.height),
        paint,
      );
    }

    // Horizontal lines
    for (double y = 0; y < size.height; y += spacing) {
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

