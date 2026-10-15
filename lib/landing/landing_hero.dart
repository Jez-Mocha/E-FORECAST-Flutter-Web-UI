import 'dart:async';

import 'package:flutter/material.dart';

import '../theme/landing_colors.dart';
import 'landing_widgets.dart';

class LandingHero extends StatelessWidget {
  final VoidCallback onExploreFeatures;

  const LandingHero({super.key, required this.onExploreFeatures});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(gradient: LandingColors.pageGradient),
      child: Stack(
        clipBehavior: Clip.hardEdge,
        children: [
          Positioned(
            top: -120,
            right: -100,
            child: _GlowBlob(color: LandingColors.pinkTint, size: 420),
          ),
          Positioned(
            top: 140,
            left: -160,
            child: _GlowBlob(color: LandingColors.periwinkleTint, size: 420),
          ),
          LandingContainer(
            child: Padding(
              padding: EdgeInsets.symmetric(
                vertical: MediaQuery.sizeOf(context).width < 640 ? 40 : 88,
              ),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final isDesktop = constraints.maxWidth >= 960;
                  final copy = _HeroCopy(
                    onExploreFeatures: onExploreFeatures,
                    large: isDesktop,
                    small: constraints.maxWidth < 560,
                  );
                  if (isDesktop) {
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(flex: 11, child: copy),
                        const SizedBox(width: 56),
                        const Expanded(flex: 10, child: HeroDashboardPreview()),
                      ],
                    );
                  }
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      copy,
                      const SizedBox(height: 48),
                      const HeroDashboardPreview(),
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
  const _GlowBlob({required this.color, required this.size});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(colors: [color, color.withValues(alpha: 0)]),
        ),
      ),
    );
  }
}

class _HeroCopy extends StatelessWidget {
  final VoidCallback onExploreFeatures;
  final bool large;
  final bool small;

  const _HeroCopy({
    required this.onExploreFeatures,
    required this.large,
    required this.small,
  });

  @override
  Widget build(BuildContext context) {
    final headlineSize = large ? 56.0 : (small ? 36.0 : 46.0);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
          decoration: BoxDecoration(
            color: LandingColors.background,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: LandingColors.border),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.auto_awesome_rounded,
                color: LandingColors.primary,
                size: 15,
              ),
              SizedBox(width: 8),
              Flexible(
                child: Text(
                  'AI-Powered Energy Forecasting',
                  style: TextStyle(
                    color: LandingColors.primary,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Text.rich(
          TextSpan(
            children: [
              TextSpan(text: 'Know Your Energy.\n'),
              TextSpan(
                text: 'Predict Your Future.',
                style: TextStyle(color: LandingColors.primary),
              ),
            ],
          ),
          style: TextStyle(
            color: LandingColors.textPrimary,
            fontSize: headlineSize,
            fontWeight: FontWeight.w800,
            letterSpacing: -1.6,
            height: 1.1,
          ),
        ),
        const SizedBox(height: 22),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Text(
            'Understand your household electricity consumption, monitor usage trends, '
            'and forecast future energy needs with E-FORECAST.',
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
          spacing: 20,
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
  final String text;
  const _HeroPoint(this.text);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.check_circle_rounded,
          color: LandingColors.secondary,
          size: 18,
        ),
        const SizedBox(width: 8),
        Text(
          text,
          style: TextStyle(
            color: LandingColors.textSecondary,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

/// Household energy dashboard preview shown in the hero. All numbers are
/// illustrative, not real measurements or a real model output.
class HeroDashboardPreview extends StatefulWidget {
  const HeroDashboardPreview({super.key});

  @override
  State<HeroDashboardPreview> createState() => _HeroDashboardPreviewState();
}

class _HeroDashboardPreviewState extends State<HeroDashboardPreview> {
  static const Duration _interval = Duration(seconds: 3); // time per card
  static const Duration _moveTime = Duration(milliseconds: 450);
  static const double _step = 14; // how far each card behind peeks out

  Timer? _timer;
  Timer? _flyTimer;
  int _activeIndex = 0;
  bool _flying = false;

  static const List<_FeatureInfo> _features = [
    _FeatureInfo(
      title: 'Consumption History',
      subtitle: 'Review your meter readings',
      label: 'Latest Meter Reading',
      value: '1,250 kWh',
      description: 'Review recorded readings and usage history.',
      icon: Icons.history,
    ),
    _FeatureInfo(
      title: 'Usage Monitoring',
      subtitle: 'Understand your energy consumption',
      label: 'Current Usage',
      value: '150 kWh',
      description: 'Monitor your household electricity usage.',
      icon: Icons.bolt,
    ),
    _FeatureInfo(
      title: 'XGBoost Forecasting',
      subtitle: 'Predict your future energy needs',
      label: 'Predicted Consumption',
      value: '180 kWh',
      description: 'View forecasts based on previous readings.',
      icon: Icons.auto_graph,
    ),
    _FeatureInfo(
      title: 'Estimated Electricity Bill',
      subtitle: 'Plan your electricity expenses',
      label: 'Estimated Monthly Bill',
      value: '₱1,450',
      description: 'See an estimate of your upcoming electricity bill.',
      icon: Icons.receipt_long,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(_interval, (_) => _shuffle());
  }

  @override
  void dispose() {
    _timer?.cancel();
    _flyTimer?.cancel();
    super.dispose();
  }

  /// Step 1: the front card slides out. Step 2: it goes to the back.
  void _shuffle() {
    if (!mounted) return;
    setState(() => _flying = true);
    _flyTimer?.cancel();
    _flyTimer = Timer(const Duration(milliseconds: 400), () {
      if (!mounted) return;
      setState(() {
        _flying = false;
        _activeIndex = (_activeIndex + 1) % _features.length;
      });
    });
  }

  void _selectFeature(int index) {
    _flyTimer?.cancel();
    setState(() {
      _flying = false;
      _activeIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 600;
        final n = _features.length;
        final peek = _step * (n - 1);
        final cardHeight = isMobile ? 430.0 : 450.0;
        final cardWidth = constraints.maxWidth - peek;

        // Back-most card first, so the front card is painted last (on top).
        final order = List<int>.generate(n, (i) => i)
          ..sort(
            (a, b) =>
                ((b - _activeIndex) % n).compareTo((a - _activeIndex) % n),
          );

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: double.infinity,
              height: cardHeight + peek,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  for (final i in order)
                    _buildCard(
                      index: i,
                      pos: (i - _activeIndex) % n,
                      width: cardWidth,
                      height: cardHeight,
                      isMobile: isMobile,
                    ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(n, (index) {
                final isActive = index == _activeIndex;
                return GestureDetector(
                  onTap: () => _selectFeature(index),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: isActive ? 28 : 9,
                    height: 9,
                    decoration: BoxDecoration(
                      color: isActive
                          ? LandingColors.primary
                          : LandingColors.secondary.withValues(alpha: 0.65),
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                );
              }),
            ),
          ],
        );
      },
    );
  }

  Widget _buildCard({
    required int index,
    required int pos, // 0 = front, 1..3 = further back
    required double width,
    required double height,
    required bool isMobile,
  }) {
    final isFront = pos == 0;
    final flyingOut = isFront && _flying;

    final left = flyingOut ? -40.0 : _step * pos;
    final top = flyingOut ? 0.0 : _step * pos;
    final turns = flyingOut ? -0.03 : 0.0;
    final opacity = flyingOut ? 0.0 : 1.0;

    final borderColor = isFront
        ? LandingColors.secondary
        : LandingColors.secondary.withValues(alpha: 0.55 - (pos - 1) * 0.15);

    return AnimatedPositioned(
      key: ValueKey(index),
      duration: _moveTime,
      curve: Curves.easeInOutCubic,
      left: left,
      top: top,
      width: width,
      height: height,
      child: IgnorePointer(
        ignoring: !isFront,
        child: AnimatedOpacity(
          duration: _moveTime,
          opacity: opacity,
          child: AnimatedRotation(
            duration: _moveTime,
            curve: Curves.easeInOutCubic,
            turns: turns,
            child: _featureCard(
              info: _features[index],
              index: index,
              isFront: isFront,
              borderColor: borderColor,
              isMobile: isMobile,
            ),
          ),
        ),
      ),
    );
  }

  Widget _featureCard({
    required _FeatureInfo info,
    required int index,
    required bool isFront,
    required Color borderColor,
    required bool isMobile,
  }) {
    const heights = [
      18.0,
      27.0,
      22.0,
      38.0,
      31.0,
      46.0,
      35.0,
      52.0,
      42.0,
      57.0,
      48.0,
      60.0,
    ];

    return AnimatedContainer(
      duration: _moveTime,
      padding: EdgeInsets.all(isMobile ? 20 : 28),
      decoration: BoxDecoration(
        color: LandingColors.background, // NOW DYNAMIC (Dark mode ready!)
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: borderColor, width: 2),
        boxShadow: isFront
            ? [
                BoxShadow(
                  color: LandingColors.primary.withValues(alpha: 0.10),
                  blurRadius: 35,
                  offset: const Offset(0, 15),
                ),
              ]
            : const [],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: LandingColors.secondary.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Icon(info.icon, color: LandingColors.primary, size: 27),
              ),
              const Spacer(),
              const SampleDataChip(),
            ],
          ),
          const SizedBox(height: 24),
          Text(
            info.title,
            style: TextStyle(
              color: LandingColors.textPrimary,
              fontSize: isMobile ? 21 : 24,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            info.subtitle,
            style: TextStyle(color: LandingColors.textSecondary, fontSize: 14),
          ),
          const SizedBox(height: 28),
          Text(
            info.label,
            style: TextStyle(color: LandingColors.textSecondary, fontSize: 13),
          ),
          const SizedBox(height: 8),
          Text(
            info.value,
            style: TextStyle(
              color: LandingColors.primary,
              fontSize: isMobile ? 30 : 36,
              fontWeight: FontWeight.w800,
            ),
          ),
          const Spacer(),
          Container(
            height: 70,
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: LandingColors.secondary.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List.generate(12, (i) {
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 3),
                    child: Container(
                      height: heights[(i + index * 2) % heights.length],
                      decoration: BoxDecoration(
                        color: i % 3 == 0
                            ? LandingColors.primary
                            : LandingColors.secondary.withValues(alpha: 0.55),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            info.description,
            style: TextStyle(color: LandingColors.textSecondary, fontSize: 13),
          ),
        ],
      ),
    );
  }
}

class _FeatureInfo {
  final String title;
  final String subtitle;
  final String label;
  final String value;
  final String description;
  final IconData icon;

  const _FeatureInfo({
    required this.title,
    required this.subtitle,
    required this.label,
    required this.value,
    required this.description,
    required this.icon,
  });
}
