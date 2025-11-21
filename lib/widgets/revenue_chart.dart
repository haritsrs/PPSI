import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../models/transaction_model.dart';
import 'package:intl/intl.dart';

class RevenueChart extends StatelessWidget {
  final List<Transaction> transactions;

  const RevenueChart({
    super.key,
    required this.transactions,
  });

  List<double> _calculateChartData() {
    if (transactions.isEmpty) return [];
    
    final Map<String, double> dailyRevenue = {};
    for (var transaction in transactions) {
      final dateKey = DateFormat('yyyy-MM-dd').format(transaction.date);
      dailyRevenue[dateKey] = (dailyRevenue[dateKey] ?? 0.0) + transaction.total;
    }
    
    final sortedDates = dailyRevenue.keys.toList()..sort();
    return sortedDates.map((date) => dailyRevenue[date]!).toList();
  }

  @override
  Widget build(BuildContext context) {
    final chartData = _calculateChartData();
    
    if (chartData.isEmpty) {
      return Center(
        child: Text(
          'Tidak ada data untuk ditampilkan',
          style: TextStyle(color: Colors.grey[600]),
        ),
      );
    }
    
    final double maxValue = chartData.reduce(math.max);
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Grafik Penghasilan",
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: const Color(0xFF1F2937),
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 200,
            child: CustomPaint(
              size: const Size(double.infinity, 200),
              painter: ChartPainter(chartData, maxValue),
            ),
          ),
        ],
      ),
    );
  }
}

class ChartPainter extends CustomPainter {
  final List<double> data;
  final double maxValue;

  ChartPainter(this.data, this.maxValue);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    final path = Path();
    final stepX = size.width / (data.length - 1);

    for (int i = 0; i < data.length; i++) {
      final x = i * stepX;
      final y = size.height - (data[i] / maxValue) * size.height;

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    paint.style = PaintingStyle.stroke;
    paint.strokeWidth = 3;
    canvas.drawPath(path, paint);

    // Draw data points
    final pointPaint = Paint()
      ..color = const Color(0xFF6366F1)
      ..style = PaintingStyle.fill;

    for (int i = 0; i < data.length; i++) {
      final x = i * stepX;
      final y = size.height - (data[i] / maxValue) * size.height;
      canvas.drawCircle(Offset(x, y), 4, pointPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

