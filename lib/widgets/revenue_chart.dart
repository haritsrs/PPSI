import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../models/transaction_model.dart';
import 'package:intl/intl.dart';

class RevenueChart extends StatefulWidget {
  final List<Transaction> transactions;

  const RevenueChart({
    super.key,
    required this.transactions,
  });

  @override
  State<RevenueChart> createState() => _RevenueChartState();
}

class _RevenueChartState extends State<RevenueChart> {
  int? _hoveredIndex;
  Offset? _hoverPosition;

  Map<String, double> _getDailyRevenue() {
    final Map<String, double> dailyRevenue = {};
    for (var transaction in widget.transactions) {
      final dateKey = DateFormat('yyyy-MM-dd').format(transaction.date);
      dailyRevenue[dateKey] = (dailyRevenue[dateKey] ?? 0.0) + transaction.total;
    }
    return dailyRevenue;
  }

  Map<String, int> _getDailyTransactionCount() {
    final Map<String, int> dailyCount = {};
    for (var transaction in widget.transactions) {
      final dateKey = DateFormat('yyyy-MM-dd').format(transaction.date);
      dailyCount[dateKey] = (dailyCount[dateKey] ?? 0) + 1;
    }
    return dailyCount;
  }

  List<double> _calculateChartData() {
    if (widget.transactions.isEmpty) return [];
    final dailyRevenue = _getDailyRevenue();
    final sortedDates = dailyRevenue.keys.toList()..sort();
    return sortedDates.map((date) => dailyRevenue[date]!).toList();
  }

  List<String> _getSortedDates() {
    final dailyRevenue = _getDailyRevenue();
    return dailyRevenue.keys.toList()..sort();
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
    final sortedDates = _getSortedDates();
    final dailyCount = _getDailyTransactionCount();
    
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
            child: LayoutBuilder(
              builder: (context, constraints) {
                return MouseRegion(
                  onHover: (event) {
                    final stepX = constraints.maxWidth / (chartData.length - 1);
                    final index = (event.localPosition.dx / stepX).round().clamp(0, chartData.length - 1);
                    setState(() {
                      _hoveredIndex = index;
                      _hoverPosition = event.localPosition;
                    });
                  },
                  onExit: (_) {
                    setState(() {
                      _hoveredIndex = null;
                      _hoverPosition = null;
                    });
                  },
                  child: GestureDetector(
                    onTapDown: (details) {
                      final stepX = constraints.maxWidth / (chartData.length - 1);
                      final index = (details.localPosition.dx / stepX).round().clamp(0, chartData.length - 1);
                      setState(() {
                        _hoveredIndex = index;
                        _hoverPosition = details.localPosition;
                      });
                    },
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        CustomPaint(
                          size: Size(constraints.maxWidth, 200),
                          painter: ChartPainter(chartData, maxValue, _hoveredIndex),
                        ),
                        if (_hoveredIndex != null && _hoverPosition != null)
                          Positioned(
                            left: (_hoverPosition!.dx - 60).clamp(0, constraints.maxWidth - 120),
                            top: math.max(0, _hoverPosition!.dy - 70),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.grey[900],
                                borderRadius: BorderRadius.circular(8),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.2),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    'Rp ${chartData[_hoveredIndex!].toStringAsFixed(0).replaceAllMapped(RegExp(r'(\\d{1,3})(?=(\\d{3})+(?!\\d))'), (m) => '${m[1]}.')}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    DateFormat('dd MMM yyyy', 'id_ID').format(DateTime.parse(sortedDates[_hoveredIndex!])),
                                    style: TextStyle(
                                      color: Colors.grey[400],
                                      fontSize: 10,
                                    ),
                                  ),
                                  Text(
                                    '${dailyCount[sortedDates[_hoveredIndex!]] ?? 0} transaksi',
                                    style: TextStyle(
                                      color: Colors.grey[400],
                                      fontSize: 10,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              },
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
  final int? hoveredIndex;

  ChartPainter(this.data, this.maxValue, this.hoveredIndex);

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

    final hoveredPaint = Paint()
      ..color = const Color(0xFFF97316)
      ..style = PaintingStyle.fill;

    for (int i = 0; i < data.length; i++) {
      final x = i * stepX;
      final y = size.height - (data[i] / maxValue) * size.height;
      final isHovered = i == hoveredIndex;
      canvas.drawCircle(
        Offset(x, y),
        isHovered ? 6 : 4,
        isHovered ? hoveredPaint : pointPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant ChartPainter oldDelegate) {
    return oldDelegate.hoveredIndex != hoveredIndex || oldDelegate.data != data;
  }
}

