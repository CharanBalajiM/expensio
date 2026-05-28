import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../blocs/expense/expense_bloc.dart';
import '../models/expense_model.dart';
import '../services/database_service.dart';

class AnalyticsScreen extends StatelessWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Analytics')),
      body: BlocBuilder<ExpenseBloc, ExpenseState>(
        builder: (context, state) {
          if (state.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final expenses = state.expenses;
          if (expenses.isEmpty) {
            return const Center(
              child: Text(
                'No transactions to analyze.',
                style: TextStyle(color: Colors.grey),
              ),
            );
          }

          // Calculate weekly breakdown of expenses (last 7 days)
          final Map<int, double> last7Days = {};
          final now = DateTime.now();
          for (int i = 0; i < 7; i++) {
            final day = now.subtract(Duration(days: i));
            final total = expenses
                .where(
                  (e) =>
                      e.date.day == day.day &&
                      e.date.month == day.month &&
                      e.date.year == day.year,
                )
                .fold(0.0, (sum, e) => sum + e.amount);
            last7Days[i] = total;
          }

          final chartData = List.generate(
            7,
            (index) => last7Days[6 - index] ?? 0.0,
          );

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 16),
                const Text(
                  'Spending Trend (Last 7 Days)',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),

                // Trend line chart container
                Container(
                  height: 220,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF141416),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: Colors.white.withOpacity(0.03)),
                  ),
                  child: CustomPaint(
                    painter: LineChartPainter(chartData),
                    child: Container(),
                  ),
                ),
                const SizedBox(height: 24),

                const Text(
                  'Category Breakdown',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),

                Expanded(
                  child: ListView(children: _buildCategoryList(expenses)),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  List<Widget> _buildCategoryList(List<Expense> expenses) {
    final Map<String, double> categorySums = {};
    for (final exp in expenses) {
      categorySums[exp.categoryId] =
          (categorySums[exp.categoryId] ?? 0.0) + exp.amount;
    }

    final double total = categorySums.values.fold(0.0, (sum, val) => sum + val);

    final sortedCategories = categorySums.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return sortedCategories.map((entry) {
      final category = DatabaseService.categoryBox.get(entry.key);
      final double percentage = total > 0 ? (entry.value / total) * 100 : 0.0;
      final iconData = category != null
          ? IconData(
              int.parse(category.iconCodePoint),
              fontFamily: 'MaterialIcons',
            )
          : Icons.receipt;

      return Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF141416),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: const Color(0xFF09090B),
              child: Icon(iconData, color: Colors.white),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    category?.name ?? 'Unknown',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: percentage / 100,
                      backgroundColor: Colors.white.withOpacity(0.05),
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        Color(0xFF00E676),
                      ),
                      minHeight: 6,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '-${NumberFormat.currency(symbol: '₹').format(entry.value)}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  '${percentage.toStringAsFixed(1)}%',
                  style: const TextStyle(color: Colors.grey, fontSize: 11),
                ),
              ],
            ),
          ],
        ),
      );
    }).toList();
  }
}

class LineChartPainter extends CustomPainter {
  final List<double> dataPoints;
  LineChartPainter(this.dataPoints);

  @override
  void paint(Canvas canvas, Size size) {
    if (dataPoints.isEmpty) return;

    final maxVal = dataPoints.reduce(max);
    final minVal = dataPoints.reduce(min);
    final double range = maxVal - minVal == 0 ? 1 : maxVal - minVal;

    final double widthInterval = size.width / (dataPoints.length - 1);

    final path = Path();
    final fillPath = Path();

    // Map points to coordinates
    final points = <Offset>[];
    for (int i = 0; i < dataPoints.length; i++) {
      final double x = i * widthInterval;
      final double y =
          size.height -
          ((dataPoints[i] - minVal) / range) * (size.height - 40) -
          20;
      points.add(Offset(x, y));
    }

    path.moveTo(points[0].dx, points[0].dy);
    fillPath.moveTo(points[0].dx, size.height);
    fillPath.lineTo(points[0].dx, points[0].dy);

    for (int i = 0; i < points.length - 1; i++) {
      final p1 = points[i];
      final p2 = points[i + 1];
      final controlPoint1 = Offset(p1.dx + widthInterval / 2, p1.dy);
      final controlPoint2 = Offset(p2.dx - widthInterval / 2, p2.dy);

      path.cubicTo(
        controlPoint1.dx,
        controlPoint1.dy,
        controlPoint2.dx,
        controlPoint2.dy,
        p2.dx,
        p2.dy,
      );
      fillPath.cubicTo(
        controlPoint1.dx,
        controlPoint1.dy,
        controlPoint2.dx,
        controlPoint2.dy,
        p2.dx,
        p2.dy,
      );
    }

    fillPath.lineTo(size.width, size.height);
    fillPath.close();

    // Paint Background Fill Gradient
    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          const Color(0xFF00E676).withOpacity(0.15),
          const Color(0xFF00E676).withOpacity(0.0),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawPath(fillPath, fillPaint);

    // Paint Trend Line
    final linePaint = Paint()
      ..color = const Color(0xFF00E676)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(path, linePaint);

    // Draw Glow points
    final pointPaint = Paint()..color = const Color(0xFF00E676);
    final shadowPaint = Paint()..color = Colors.white.withOpacity(0.2);

    for (final p in points) {
      canvas.drawCircle(p, 6, shadowPaint);
      canvas.drawCircle(p, 3, pointPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
