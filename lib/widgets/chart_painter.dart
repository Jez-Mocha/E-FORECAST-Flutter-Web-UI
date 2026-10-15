import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../models/energy_models.dart';
import '../theme/app_colors.dart';

class SmoothChartPainter extends CustomPainter {
  final List<EnergyDataPoint> data;
  SmoothChartPainter({required this.data});

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;
    final maxVal = data.map((d) => math.max(d.actual, d.predicted)).reduce(math.max) * 1.25;

    final gridPaint = Paint()
      ..color = AppColors.borderSubtle
      ..strokeWidth = 1;

    for (int i = 1; i <= 2; i++) {
      final y = size.height * (i / 3);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    final pts = <Offset>[];
    final predPts = <Offset>[];
    for (int i = 0; i < data.length; i++) {
      final x = (i / (data.length - 1)) * size.width;
      pts.add(Offset(x, size.height - (data[i].actual / maxVal) * size.height));
      predPts.add(Offset(x, size.height - (data[i].predicted / maxVal) * size.height));
    }

    final fillPath = Path()..moveTo(pts.first.dx, size.height);
    for (final pt in pts) {
      fillPath.lineTo(pt.dx, pt.dy);
    }
    fillPath.lineTo(pts.last.dx, size.height);
    fillPath.close();

    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [AppColors.cyan.withValues(alpha: 0.2), AppColors.cyan.withValues(alpha: 0.0)],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawPath(fillPath, fillPaint);

    final predPaint = Paint()
      ..color = AppColors.purple.withValues(alpha: 0.6)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    final predPath = Path()..moveTo(predPts.first.dx, predPts.first.dy);
    for (int i = 1; i < predPts.length; i++) {
      predPath.lineTo(predPts[i].dx, predPts[i].dy);
    }
    canvas.drawPath(predPath, predPaint);

    final linePaint = Paint()
      ..color = AppColors.cyan
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke;
    final linePath = Path()..moveTo(pts.first.dx, pts.first.dy);
    for (int i = 1; i < pts.length; i++) {
      linePath.lineTo(pts[i].dx, pts[i].dy);
    }
    canvas.drawPath(linePath, linePaint);

    final dotBg = Paint()..color = AppColors.card;
    final dotPaint = Paint()..color = AppColors.cyan;
    for (final p in pts) {
      canvas.drawCircle(p, 3.5, dotBg);
      canvas.drawCircle(p, 2.5, dotPaint);
    }
  }

  @override
  bool shouldRepaint(covariant SmoothChartPainter oldDelegate) => oldDelegate.data != data;
}
