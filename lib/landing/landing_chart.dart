import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/landing_colors.dart';

/// One labelled value on the illustrative landing-page chart.
class LandingChartPoint {
  final String label;
  final double value;
  const LandingChartPoint(this.label, this.value);
}

/// Actual (solid) vs forecast (dashed) line chart drawn with [CustomPainter].
/// Points before [forecastStart] are "actual"; the rest are "forecast".
/// No chart package is required.
class LandingLineChart extends StatelessWidget {
  final List<LandingChartPoint> points;
  final int forecastStart;
  final double height;
  final String semanticLabel;

  const LandingLineChart({
    super.key,
    required this.points,
    required this.forecastStart,
    this.height = 160,
    this.semanticLabel = 'Illustrative chart of actual and forecast consumption',
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: semanticLabel,
      image: true,
      child: SizedBox(
        height: height,
        width: double.infinity,
        child: CustomPaint(
          painter: _LandingChartPainter(points: points, forecastStart: forecastStart),
        ),
      ),
    );
  }
}

class _LandingChartPainter extends CustomPainter {
  final List<LandingChartPoint> points;
  final int forecastStart;

  _LandingChartPainter({required this.points, required this.forecastStart});

  static const double _labelHeight = 26;
  static const double _topPad = 12;
  static const double _sidePad = 20;

  @override
  void paint(Canvas canvas, Size size) {
    if (points.length < 2 || size.width <= 0 || size.height <= _labelHeight + _topPad) {
      return;
    }

    final chartHeight = size.height - _labelHeight - _topPad;
    final baseY = _topPad + chartHeight;

    final values = points.map((p) => p.value);
    final minV = values.reduce(math.min);
    final maxV = values.reduce(math.max);
    final range = math.max(maxV - minV, 1.0);
    final lo = minV - range * 0.35;
    final hi = maxV + range * 0.15;

    final stepX = (size.width - 2 * _sidePad) / (points.length - 1);
    final offsets = <Offset>[
      for (var i = 0; i < points.length; i++)
        Offset(
          _sidePad + stepX * i,
          _topPad + chartHeight * (1 - (points[i].value - lo) / (hi - lo)),
        ),
    ];

    // Grid
    final gridPaint = Paint()
      ..color = LandingColors.border
      ..strokeWidth = 1;
    for (var i = 0; i <= 3; i++) {
      final y = _topPad + chartHeight * i / 3;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    // Split into actual / forecast segments (forecast starts at last actual point).
    final split = forecastStart.clamp(1, points.length).toInt();
    final actualPts = offsets.sublist(0, split);
    final forecastPts = split < offsets.length
        ? offsets.sublist(split - 1)
        : <Offset>[];

    // Area under the actual line.
    final actualPath = _smoothPath(actualPts);
    if (actualPts.length >= 2) {
      final area = Path.from(actualPath)
        ..lineTo(actualPts.last.dx, baseY)
        ..lineTo(actualPts.first.dx, baseY)
        ..close();
      final areaPaint = Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            LandingColors.primary.withValues(alpha: 0.18),
            LandingColors.primary.withValues(alpha: 0.0),
          ],
        ).createShader(Rect.fromLTWH(0, _topPad, size.width, chartHeight));
      canvas.drawPath(area, areaPaint);
    }

    // Forecast (dashed).
    if (forecastPts.length >= 2) {
      final forecastPaint = Paint()
        ..color = LandingColors.secondary
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..strokeCap = StrokeCap.round;
      canvas.drawPath(_dashed(_smoothPath(forecastPts), 7, 6), forecastPaint);
    }

    // Actual (solid).
    if (actualPts.length >= 2) {
      final actualPaint = Paint()
        ..color = LandingColors.primary
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round;
      canvas.drawPath(actualPath, actualPaint);
    }

    // Dots.
    final whiteFill = Paint()..color = Colors.white;
    for (var i = 0; i < offsets.length; i++) {
      final isForecast = i >= split;
      final ring = Paint()
        ..color = isForecast ? LandingColors.secondary : LandingColors.primary
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5;
      canvas.drawCircle(offsets[i], 4.5, whiteFill);
      canvas.drawCircle(offsets[i], 4.5, ring);
    }

    // X labels.
    for (var i = 0; i < points.length; i++) {
      final tp = TextPainter(
        text: TextSpan(
          text: points[i].label,
          style: TextStyle(
            color: LandingColors.textSecondary,
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(offsets[i].dx - tp.width / 2, size.height - _labelHeight + 8));
    }
  }

  /// Catmull-Rom style smoothing converted to cubic Béziers.
  Path _smoothPath(List<Offset> pts) {
    final path = Path();
    if (pts.isEmpty) return path;
    path.moveTo(pts.first.dx, pts.first.dy);
    for (var i = 0; i < pts.length - 1; i++) {
      final p0 = i > 0 ? pts[i - 1] : pts[i];
      final p1 = pts[i];
      final p2 = pts[i + 1];
      final p3 = i + 2 < pts.length ? pts[i + 2] : pts[i + 1];
      final c1 = p1 + (p2 - p0) / 6;
      final c2 = p2 - (p3 - p1) / 6;
      path.cubicTo(c1.dx, c1.dy, c2.dx, c2.dy, p2.dx, p2.dy);
    }
    return path;
  }

  Path _dashed(Path source, double dash, double gap) {
    final out = Path();
    for (final metric in source.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        final end = math.min(distance + dash, metric.length);
        out.addPath(metric.extractPath(distance, end), Offset.zero);
        distance += dash + gap;
      }
    }
    return out;
  }

  @override
  bool shouldRepaint(covariant _LandingChartPainter old) =>
      old.points != points || old.forecastStart != forecastStart;
}
