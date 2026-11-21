import 'dart:async';

import 'package:flutter/material.dart';

import '../theme/app_effects.dart';
import '../theme/landing_colors.dart';
import 'landing_widgets.dart';

class LandingHero extends StatelessWidget {
  final VoidCallback onExploreFeatures;

  const LandingHero({super.key, required this.onExploreFeatures});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LandingColors.pageGradient,
      ),
      child: Stack(
        clipBehavior: Clip.hardEdge,
        children: [
          Positioned(
            top: -120,
            right: -100,
            child: _GlowBlob(
              color: LandingColors.pinkTint,
              size: 420,
            ),
          ),
          Positioned(
            top: 140,
            left: -160,
            child: _GlowBlob(
              color: LandingColors.periwinkleTint,
              size: 420,
            ),
          ),
          LandingContainer(
            child: Padding(
              padding: const EdgeInsets.only(top: 48, bottom: 72),
              child: LayoutBuilder(
                builder: (context, c) {
                  final wide = c.maxWidth >= 960;
                  final headlineSize = wide
                      ? 56.0
                      : c.maxWidth < 560
                          ? 36.0
                          : 46.0;

                  final copy = _HeroCopy(
                    wide: wide,
                    headlineSize: headlineSize,
                    onExploreFeatures: onExploreFeatures,
                  );

                  if (wide) {
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(flex: 11, child: copy),
                        const SizedBox(width: 56),
                        const Expanded(
                          flex: 10,
                          child: _EnergyIllustration(),
                        ),
                      ],
                    );
                  }

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      copy,
                      const SizedBox(height: 56),
                      const _EnergyIllustration(),
                    ],
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GlowBlob extends StatelessWidget {
  final Color color;
  final double size;

  const _GlowBlob({
    required this.color,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [
              color,
              color.withValues(alpha: 0),
            ],
          ),
        ),
      ),
    );
  }
}
class _HeroCopy extends StatelessWidget {
  final bool wide;
  final double headlineSize;
  final VoidCallback onExploreFeatures;

  const _HeroCopy({
    required this.wide,
    required this.headlineSize,
    required this.onExploreFeatures,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
          decoration: BoxDecoration(
            color: LandingColors.primary.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: LandingColors.primary.withValues(alpha: 0.25),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.bolt_rounded, size: 16, color: LandingColors.primary),
              const SizedBox(width: 6),
              Text(
                'AI-Powered Energy Forecasting',
                style: TextStyle(
                  color: LandingColors.primary,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Text.rich(
          TextSpan(
            style: TextStyle(
              color: LandingColors.textPrimary,
              fontSize: headlineSize,
              fontWeight: FontWeight.w800,
              height: 1.1,
              letterSpacing: -1.2,
            ),
            children: [
              const TextSpan(text: 'Know Your Energy.\n'),
              TextSpan(
                text: 'Predict Your Future.',
                style: TextStyle(color: LandingColors.primary),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Text(
            'Understand your household electricity consumption, monitor usage '
            'trends, and forecast future energy needs with E-FORECAST.',
            style: TextStyle(
              color: LandingColors.textSecondary,
              fontSize: 17,
              height: 1.65,
            ),
          ),
        ),
        const SizedBox(height: 32),
        Wrap(
          spacing: 14,
          runSpacing: 12,
          children: [
            LandingPrimaryButton(
              label: 'Get Started',
              onPressed: () => openLogin(context, tab: 1),
            ),
            LandingSecondaryButton(
              label: 'Explore Features',
              onPressed: onExploreFeatures,
            ),
          ],
        ),
        const SizedBox(height: 32),
        const Wrap(
          spacing: 24,
          runSpacing: 10,
          children: [
            _HeroPoint('Consumption Monitoring'),
            _HeroPoint('XGBoost Forecasting'),
            _HeroPoint('Estimated Electricity Bills'),
          ],
        ),
      ],
    );
  }
}

class _HeroPoint extends StatelessWidget {
  final String label;
  const _HeroPoint(this.label);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.check_circle_rounded,
          size: 18,
          color: LandingColors.secondary,
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(
            color: LandingColors.textPrimary,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

// â”€â”€ Helpers â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

Widget _skeleton(double w, double h) => Container(
  width: w,
  height: h,
  decoration: BoxDecoration(
    color: LandingColors.textSecondary.withValues(alpha: 0.16),
    borderRadius: BorderRadius.circular(6),
  ),
);

/// Eased 0..1 progress of [t] between [a] and [b].
double _seg(
  double t,
  double a,
  double b, [
  Curve curve = Curves.easeOutCubic,
]) => curve.transform(((t - a) / (b - a)).clamp(0.0, 1.0));

String _fmt(int v) =>
    v >= 1000 ? '${v ~/ 1000},${(v % 1000).toString().padLeft(3, '0')}' : '$v';

/// Scale + fade pop-in between [a] and [b] of the entry progress [t].
class _Pop extends StatelessWidget {
  final double t;
  final double a;
  final double b;
  final Alignment alignment;
  final Widget child;

  const _Pop({
    required this.t,
    required this.a,
    required this.b,
    required this.child,
    this.alignment = Alignment.center,
  });

  @override
  Widget build(BuildContext context) {
    final o = _seg(t, a, b);
    final s = _seg(t, a, b, Curves.easeOutBack);
    return Opacity(
      opacity: o,
      child: Transform.scale(
        scale: 0.7 + 0.3 * s,
        alignment: alignment,
        child: child,
      ),
    );
  }
}

// â”€â”€ Animated illustration (demo data only) â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class _EnergyIllustration extends StatefulWidget {
  const _EnergyIllustration();

  @override
  State<_EnergyIllustration> createState() => _EnergyIllustrationState();
}

class _EnergyIllustrationState extends State<_EnergyIllustration>
    with SingleTickerProviderStateMixin {
  static const Duration _interval = Duration(milliseconds: 2600);
  static const int _count = 4;

  late final AnimationController _slide;
  Timer? _timer;
  int _index = 0;
  int? _prev;
  int _dir = 1;
  bool _paused = false;

  @override
  void initState() {
    super.initState();
    _slide = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _slide.addStatusListener((s) {
      if (s == AnimationStatus.completed && mounted) {
        setState(() => _prev = null);
      }
    });
    _start();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _slide.dispose();
    super.dispose();
  }

  void _start() {
    _timer?.cancel();
    _timer = Timer.periodic(_interval, (_) {
      if (!mounted || _paused || _slide.isAnimating) return;
      _go((_index + 1) % _count, 1);
    });
  }

  void _go(int target, int dir) {
    if (target == _index) return;
    setState(() {
      _prev = _index;
      _index = target;
      _dir = dir;
    });
    _slide.forward(from: 0);
  }

  void _select(int i) {
    _go(i, i > _index ? 1 : -1);
    _start();
  }

  Widget _entry(Widget Function(double t) build) =>
      TweenAnimationBuilder<double>(
        tween: Tween<double>(begin: 0, end: 1),
        duration: const Duration(milliseconds: 1100),
        builder: (context, t, _) => build(t),
      );

  Widget _panel(int i) {
    switch (i) {
      case 0:
        return _entry(
          (t) => _PanelFrame(
            icon: Icons.show_chart_rounded,
            title: 'Consumption Monitoring',
            color: LandingColors.primary,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _Pop(
                  t: t,
                  a: 0.0,
                  b: 0.4,
                  alignment: Alignment.centerLeft,
                  child: _ValueCard(
                    label: 'Current usage',
                    value: '${(245 * _seg(t, 0.1, 0.8)).round()} kWh',
                    color: LandingColors.primary,
                    caption: 'Demo value',
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(child: _BarsChart(t: t)),
              ],
            ),
          ),
        );
      case 1:
        return _entry(
          (t) => _PanelFrame(
            icon: Icons.auto_graph_rounded,
            title: 'XGBoost Forecasting',
            color: LandingColors.purple,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _Pop(
                  t: t,
                  a: 0.0,
                  b: 0.4,
                  alignment: Alignment.centerLeft,
                  child: _ValueCard(
                    label: 'Predicted consumption',
                    value: '${(280 * _seg(t, 0.1, 0.8)).round()} kWh',
                    color: LandingColors.purple,
                    caption: 'Demo value',
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: LandingColors.surface.withValues(alpha: 0.7),
                        border: Border.all(color: LandingColors.border),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: CustomPaint(
                        size: Size.infinite,
                        painter: _CurvePainter(
                          history: LandingColors.primary,
                          forecast: LandingColors.purple,
                          grid: LandingColors.border,
                          surface: LandingColors.surface,
                          progress: _seg(t, 0.1, 0.9, Curves.easeInOut),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      case 2:
        return _entry(
          (t) => _PanelFrame(
            icon: Icons.receipt_long_rounded,
            title: 'Estimated Electricity Bill',
            color: LandingColors.orange,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _Pop(
                  t: t,
                  a: 0.0,
                  b: 0.4,
                  alignment: Alignment.centerLeft,
                  child: _ValueCard(
                    label: 'Estimated monthly bill',
                    value: 'â‚±${_fmt((3450 * _seg(t, 0.1, 0.8)).round())}',
                    color: LandingColors.orange,
                    caption: 'Demo value',
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(child: _ReceiptLines(t: t)),
              ],
            ),
          ),
        );
      default:
        return _entry(
          (t) => _PanelFrame(
            icon: Icons.history_rounded,
            title: 'Recording & History',
            color: LandingColors.primary,
            child: Row(
              children: [
                _Pop(
                  t: t,
                  a: 0.0,
                  b: 0.4,
                  child: Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: LandingColors.surface,
                      border: Border.all(
                        color: LandingColors.primary.withValues(alpha: 0.3),
                        width: 5,
                      ),
                    ),
                    child: Icon(
                      Icons.speed_rounded,
                      color: LandingColors.primary,
                      size: 28,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _Pop(
                        t: t,
                        a: 0.1,
                        b: 0.5,
                        child: _ReadingRow(
                          label: 'Previous reading',
                          value: '1,205 kWh',
                          color: LandingColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _Pop(
                        t: t,
                        a: 0.25,
                        b: 0.65,
                        child: _ReadingRow(
                          label: 'Current reading',
                          value: '1,450 kWh',
                          color: LandingColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _Pop(
                        t: t,
                        a: 0.4,
                        b: 0.8,
                        child: _ReadingRow(
                          label: 'Consumption',
                          value: '245 kWh',
                          color: LandingColors.primary,
                          highlight: true,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
    }
  }

  Widget _slot(int i, Offset offset) => KeyedSubtree(
    key: ValueKey<int>(i),
    child: FractionalTranslation(
      translation: offset,
      child: SizedBox.expand(child: _panel(i)),
    ),
  );

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => _paused = true,
      onExit: (_) => _paused = false,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 540),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                GlassCard(
                  radius: 28,
                  blur: 0,
                  padding: const EdgeInsets.all(22),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          _Badge(Icons.bolt_rounded, LandingColors.primary, 40),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _skeleton(120, 10),
                              const SizedBox(height: 7),
                              _skeleton(76, 8),
                            ],
                          ),
                          const Spacer(),
                          _legend('History', LandingColors.primary),
                          const SizedBox(width: 12),
                          _legend('Forecast', LandingColors.purple),
                        ],
                      ),
                      const SizedBox(height: 18),
                      Container(
                        height: 200,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(18),
                          color: LandingColors.blueTint.withValues(alpha: 0.55),
                          border: Border.all(color: LandingColors.border),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(18),
                          child: AnimatedBuilder(
                            animation: _slide,
                            builder: (context, _) {
                              final t = Curves.easeInOutCubic.transform(
                                _slide.value,
                              );
                              return Stack(
                                fit: StackFit.expand,
                                children: [
                                  if (_prev != null)
                                    _slot(_prev!, Offset(-_dir * t, 0)),
                                  _slot(
                                    _index,
                                    _prev == null
                                        ? Offset.zero
                                        : Offset(_dir * (1 - t), 0),
                                  ),
                                ],
                              );
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final compact = constraints.maxWidth < 440;

                          final tiles = [
                            _tile(0, Icons.bar_chart_rounded, 'Monitoring', LandingColors.primary),
                            _tile(1, Icons.auto_graph_rounded, 'Forecast', LandingColors.purple),
                            _tile(2, Icons.receipt_long_rounded, 'Bill', LandingColors.orange),
                            _tile(3, Icons.history_rounded, 'History', LandingColors.primary),
                          ];

                          if (compact) {
                            return Column(
                              children: [
                                Row(
                                  children: [
                                    Expanded(child: tiles[0]),
                                    const SizedBox(width: 10),
                                    Expanded(child: tiles[1]),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                Row(
                                  children: [
                                    Expanded(child: tiles[2]),
                                    const SizedBox(width: 10),
                                    Expanded(child: tiles[3]),
                                  ],
                                ),
                              ],
                            );
                          }

                          return Row(
                            children: [
                              for (var i = 0; i < tiles.length; i++) ...[
                                if (i > 0) const SizedBox(width: 10),
                                Expanded(child: tiles[i]),
                              ],
                            ],
                          );
                        },
                      ),
                    ],
                  ),
                ),
                Positioned(
                  top: -18,
                  right: 20,
                  child: Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [
                          LandingColors.orange,
                          Color.lerp(LandingColors.orange, Colors.white, 0.3)!,
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: LandingColors.orange.withValues(alpha: 0.35),
                          blurRadius: 18,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.bolt_rounded,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                ),
                Positioned(
                  bottom: -16,
                  left: 24,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      color: LandingColors.surface,
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: LandingColors.border),
                      boxShadow: LandingColors.softShadow,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.info_outline_rounded,
                          size: 14,
                          color: LandingColors.textSecondary,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Illustrative demo data',
                          style: TextStyle(
                            color: LandingColors.textSecondary,
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _legend(String label, Color color) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(
        width: 8,
        height: 8,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      ),
      const SizedBox(width: 6),
      Text(
        label,
        style: TextStyle(
          color: LandingColors.textSecondary,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    ],
  );

  Widget _tile(int i, IconData icon, String label, Color color) {
    final active = _index == i;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () => _select(i),
        child: AnimatedScale(
          scale: active ? 1.03 : 1,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: active ? 0.14 : 0.06),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: color.withValues(alpha: active ? 0.55 : 0.18),
                width: active ? 1.5 : 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _Badge(icon, color, 32),
                const SizedBox(height: 10),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: LandingColors.textPrimary,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                _skeleton(44, 7),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// â”€â”€ Panel building blocks â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class _PanelFrame extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color color;
  final Widget child;

  const _PanelFrame({
    required this.icon,
    required this.title,
    required this.color,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _Badge(icon, color, 30),
              const SizedBox(width: 10),
              Flexible(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: LandingColors.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  'Demo data',
                  style: TextStyle(
                    color: color,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Expanded(child: child),
        ],
      ),
    );
  }
}

class _ValueCard extends StatelessWidget {
  final String label;
  final String value;
  final String caption;
  final Color color;

  const _ValueCard({
    required this.label,
    required this.value,
    required this.caption,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: MediaQuery.sizeOf(context).width < 430 ? 116 : 158,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: LandingColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: LandingColors.textSecondary,
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: TextStyle(
                color: color,
                fontSize: 32,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            caption,
            style: TextStyle(color: LandingColors.textSecondary, fontSize: 11),
          ),
        ],
      ),
    );
  }
}

class _BarsChart extends StatelessWidget {
  final double t;
  const _BarsChart({required this.t});

  static const _heights = [.35, .5, .42, .62, .48, .7, .58, .9];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
      decoration: BoxDecoration(
        color: LandingColors.surface.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: LandingColors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          for (var i = 0; i < _heights.length; i++)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 3),
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: FractionallySizedBox(
                    heightFactor:
                        (_heights[i] * _seg(t, 0.15 + i * 0.05, 0.6 + i * 0.05))
                            .clamp(0.02, 1.0),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(6),
                        color: LandingColors.primary.withValues(
                          alpha: i == _heights.length - 1 ? 1 : 0.35,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _ReceiptLines extends StatelessWidget {
  final double t;
  const _ReceiptLines({required this.t});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: LandingColors.surface.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: LandingColors.border),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          for (var i = 0; i < 3; i++) ...[
            _Pop(
              t: t,
              a: 0.15 + i * 0.12,
              b: 0.55 + i * 0.12,
              child: Row(
                children: [
                  _skeleton(i == 1 ? 80 : 64, 7),
                  const Spacer(),
                  _skeleton(34, 7),
                ],
              ),
            ),
            const SizedBox(height: 10),
          ],
          Divider(color: LandingColors.border, height: 1),
          const SizedBox(height: 10),
          _Pop(
            t: t,
            a: 0.55,
            b: 0.95,
            alignment: Alignment.centerRight,
            child: Row(
              children: [
                _skeleton(44, 8),
                const Spacer(),
                Container(
                  width: 62,
                  height: 12,
                  decoration: BoxDecoration(
                    color: LandingColors.orange.withValues(alpha: 0.85),
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ReadingRow extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final bool highlight;

  const _ReadingRow({
    required this.label,
    required this.value,
    required this.color,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: highlight
            ? LandingColors.primary.withValues(alpha: 0.10)
            : LandingColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: highlight
              ? LandingColors.primary.withValues(alpha: 0.35)
              : LandingColors.border,
        ),
      ),
      child: Row(
        children: [
          Text(
            label,
            style: TextStyle(
              color: LandingColors.textSecondary,
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 13,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final IconData icon;
  final Color color;
  final double size;
  const _Badge(this.icon, this.color, this.size);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(size * 0.3),
        gradient: LinearGradient(
          colors: [
            color.withValues(alpha: 0.24),
            color.withValues(alpha: 0.08),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Icon(icon, color: color, size: size * 0.5),
    );
  }
}

class _CurvePainter extends CustomPainter {
  final Color history;
  final Color forecast;
  final Color grid;
  final Color surface;
  final double progress;

  const _CurvePainter({
    required this.history,
    required this.forecast,
    required this.grid,
    required this.surface,
    required this.progress,
  });

  static const _hist = [
    Offset(0, .66),
    Offset(.1, .50),
    Offset(.2, .60),
    Offset(.3, .42),
    Offset(.4, .52),
    Offset(.5, .36),
    Offset(.58, .44),
  ];
  static const _fore = [
    Offset(.58, .44),
    Offset(.7, .32),
    Offset(.8, .40),
    Offset(.9, .24),
    Offset(1, .30),
  ];

  Path _smooth(List<Offset> pts, Size s) {
    final p = pts.map((o) => Offset(o.dx * s.width, o.dy * s.height)).toList();
    final path = Path()..moveTo(p.first.dx, p.first.dy);
    for (var i = 0; i < p.length - 1; i++) {
      final mid = Offset(
        (p[i].dx + p[i + 1].dx) / 2,
        (p[i].dy + p[i + 1].dy) / 2,
      );
      path.quadraticBezierTo(p[i].dx, p[i].dy, mid.dx, mid.dy);
    }
    path.lineTo(p.last.dx, p.last.dy);
    return path;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final gridPaint = Paint()
      ..color = grid
      ..strokeWidth = 1;
    for (final f in [0.25, 0.5, 0.75]) {
      canvas.drawLine(Offset(0, h * f), Offset(w, h * f), gridPaint);
    }

    // Sweep the curve in from the left.
    canvas.save();
    canvas.clipRect(Rect.fromLTWH(0, 0, w * progress, h));

    canvas.drawRect(
      Rect.fromLTWH(w * .58, 0, w * .42, h),
      Paint()..color = forecast.withValues(alpha: 0.06),
    );

    final histPath = _smooth(_hist, size);
    final area = Path.from(histPath)
      ..lineTo(w * .58, h)
      ..lineTo(0, h)
      ..close();
    canvas.drawPath(
      area,
      Paint()
        ..shader = LinearGradient(
          colors: [
            history.withValues(alpha: 0.28),
            history.withValues(alpha: 0),
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ).createShader(Rect.fromLTWH(0, 0, w, h)),
    );
    canvas.drawPath(
      histPath,
      Paint()
        ..color = history
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.5
        ..strokeCap = StrokeCap.round,
    );

    final forePaint = Paint()
      ..color = forecast
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.round;
    for (final m in _smooth(_fore, size).computeMetrics()) {
      var d = 0.0;
      while (d < m.length) {
        canvas.drawPath(m.extractPath(d, d + 8), forePaint);
        d += 14;
      }
    }

    final join = Offset(w * .58, h * .44);
    canvas.drawCircle(join, 7, Paint()..color = surface);
    canvas.drawCircle(
      join,
      7,
      Paint()
        ..color = history
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3,
    );

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _CurvePainter old) =>
      old.history != history ||
      old.forecast != forecast ||
      old.grid != grid ||
      old.surface != surface ||
      old.progress != progress;
}
