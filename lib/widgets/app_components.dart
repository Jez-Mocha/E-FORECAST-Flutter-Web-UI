import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_effects.dart';
import '../theme/landing_colors.dart';

/// The four accent colors of the design: blue, green, purple, orange.
enum AppAccent { blue, green, purple, orange }

extension AppAccentStyle on AppAccent {
  /// Strong color for icons, lines and badges.
  Color get color => switch (this) {
    AppAccent.blue => LandingColors.primary,
    AppAccent.green => LandingColors.secondary,
    AppAccent.purple => LandingColors.purple,
    AppAccent.orange => LandingColors.orange,
  };

  /// Soft pastel color for card backgrounds.
  Color get tint => switch (this) {
    AppAccent.blue => LandingColors.blueTint,
    AppAccent.green => LandingColors.greenTint,
    AppAccent.purple => LandingColors.purpleTint,
    AppAccent.orange => LandingColors.orangeTint,
  };

  LinearGradient get gradient => LinearGradient(
    colors: [Color.lerp(color, Colors.white, 0.25)!, color],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}

/// A round gradient badge with a white icon.
class AppIconBadge extends StatelessWidget {
  final IconData icon;
  final AppAccent accent;
  final double size;

  const AppIconBadge({
    super.key,
    required this.icon,
    this.accent = AppAccent.blue,
    this.size = 44,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: accent.gradient,
        boxShadow: [
          BoxShadow(
            color: accent.color.withValues(alpha: 0.35),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Icon(icon, color: Colors.white, size: size * 0.5),
    );
  }
}

/// A small smooth line chart with a soft fill. Decoration only: it shows the
/// shape of the numbers you give it, with no axes or labels.
class AppSparkline extends StatelessWidget {
  final List<double> values;
  final Color color;
  final double width;
  final double height;

  const AppSparkline({
    super.key,
    required this.values,
    required this.color,
    this.width = 88,
    this.height = 34,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: CustomPaint(painter: _SparklinePainter(values, color)),
    );
  }
}

class _SparklinePainter extends CustomPainter {
  final List<double> values;
  final Color color;

  _SparklinePainter(this.values, this.color);

  @override
  void paint(Canvas canvas, Size size) {
    if (values.length < 2) return;

    final minV = values.reduce(math.min);
    final maxV = values.reduce(math.max);
    final range = (maxV - minV) == 0 ? 1.0 : (maxV - minV);
    final dx = size.width / (values.length - 1);

    Offset point(int i) => Offset(
      i * dx,
      size.height - ((values[i] - minV) / range) * (size.height - 4) - 2,
    );

    final path = Path()..moveTo(point(0).dx, point(0).dy);
    for (var i = 1; i < values.length; i++) {
      final p0 = point(i - 1);
      final p1 = point(i);
      final midX = (p0.dx + p1.dx) / 2;
      path.cubicTo(midX, p0.dy, midX, p1.dy, p1.dx, p1.dy);
    }

    final fill = Path.from(path)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();

    canvas.drawPath(
      fill,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [color.withValues(alpha: 0.25), color.withValues(alpha: 0)],
        ).createShader(Offset.zero & size),
    );
    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(covariant _SparklinePainter old) =>
      old.values != values || old.color != color;
}

/// A pastel card like the ones in the reference: round icon badge, small
/// label, big value, optional trend line and optional sparkline.
class AppMetricCard extends StatelessWidget {
  final IconData icon;
  final AppAccent accent;
  final String label;
  final String value;

  /// Small line under the value, for example "8% vs last hour".
  final String? trend;
  final IconData? trendIcon;
  final Color? trendColor;

  /// Numbers for the decorative sparkline. Leave null for no sparkline.
  final List<double>? sparkline;

  /// Optional widget at the right end, for example an arrow button.
  final Widget? trailing;

  final VoidCallback? onTap;

  const AppMetricCard({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    this.accent = AppAccent.blue,
    this.trend,
    this.trendIcon,
    this.trendColor,
    this.sparkline,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final trendTone = trendColor ?? LandingColors.secondary;

    final card = GlassCard(
      blur: 0,
      tint: accent.tint,
      padding: const EdgeInsets.all(18),
      child: Row(
        children: [
          AppIconBadge(icon: icon, accent: accent),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: LandingColors.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    value,
                    maxLines: 1,
                    style: TextStyle(
                      color: LandingColors.textPrimary,
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.3,
                    ),
                  ),
                ),
                if (trend != null) ...[
                  const SizedBox(height: 4),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (trendIcon != null) ...[
                        Icon(trendIcon, size: 14, color: trendTone),
                        const SizedBox(width: 2),
                      ],
                      Flexible(
                        child: Text(
                          trend!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: trendTone,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          if (sparkline != null) ...[
            const SizedBox(width: 8),
            AppSparkline(values: sparkline!, color: accent.color),
          ],
          if (trailing != null) ...[const SizedBox(width: 8), trailing!],
        ],
      ),
    );

    if (onTap == null) return card;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(onTap: onTap, child: card),
    );
  }
}

/// Small rounded tabs like "7D 30D 3M 1Y". Only shows the choice; your
/// screen decides what each tab does through [onChanged].
class AppPillTabs extends StatelessWidget {
  final List<String> labels;
  final int selected;
  final ValueChanged<int> onChanged;

  const AppPillTabs({
    super.key,
    required this.labels,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < labels.length; i++)
          Padding(
            padding: EdgeInsets.only(left: i == 0 ? 0 : 6),
            child: MouseRegion(
              cursor: SystemMouseCursors.click,
              child: GestureDetector(
                onTap: () => onChanged(i),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: i == selected
                        ? LandingColors.primary
                        : LandingColors.surface,
                    borderRadius: BorderRadius.circular(999),
                    border: i == selected
                        ? null
                        : Border.all(color: LandingColors.border),
                  ),
                  child: Text(
                    labels[i],
                    style: TextStyle(
                      color: i == selected
                          ? LandingColors.onPrimary
                          : LandingColors.textSecondary,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// One sidebar link. The selected one is a solid blue pill, like the
/// reference. It is only the look: [onTap] is your existing navigation.
class AppNavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback? onTap;

  const AppNavItem({
    super.key,
    required this.icon,
    required this.label,
    this.selected = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final fg = selected ? LandingColors.onPrimary : LandingColors.textSecondary;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(LandingRadius.control + 2),
        hoverColor: LandingColors.primary.withValues(alpha: 0.08),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            gradient: selected ? LandingColors.primaryGradient : null,
            borderRadius: BorderRadius.circular(LandingRadius.control + 2),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: LandingColors.primary.withValues(alpha: 0.35),
                      blurRadius: 14,
                      offset: const Offset(0, 6),
                    ),
                  ]
                : null,
          ),
          child: Row(
            children: [
              Icon(icon, size: 18, color: fg),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: fg,
                    fontSize: 14,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
