import 'package:flutter/material.dart';

import '../theme/app_effects.dart';
import '../theme/landing_colors.dart';
import 'landing_widgets.dart';

class _Feature {
  final IconData icon;
  final String title;
  final String description;
  final Color color;
  const _Feature(this.icon, this.title, this.description, this.color);
}

List<_Feature> _features() => [
  _Feature(
    Icons.edit_note_rounded,
    'Record Consumption',
    'Record previous and current electricity meter readings and calculate your household\'s electricity consumption.',
    LandingColors.primary,
  ),
  _Feature(
    Icons.show_chart_rounded,
    'Usage Monitoring',
    'Track household electricity usage, review historical records, and understand consumption trends through clear visualizations.',
    LandingColors.primary,
  ),
  _Feature(
    Icons.auto_graph_rounded,
    'XGBoost Forecasting',
    'Use an XGBoost-based machine learning model to forecast future household electricity consumption.',
    LandingColors.purple,
  ),
  _Feature(
    Icons.receipt_long_rounded,
    'Estimated Electricity Bill',
    'View an estimated electricity bill based on forecast consumption and the system\'s configured billing logic.',
    LandingColors.orange,
  ),
];

class LandingFeaturesSection extends StatelessWidget {
  const LandingFeaturesSection({super.key});

  @override
  Widget build(BuildContext context) {
    final items = _features();
    return LandingSection(
      color: Colors.transparent,
      child: Column(
        children: [
          const LandingSectionHeader(
            centered: true,
            tag: 'Features',
            title: 'Everything You Need to Understand Your Energy',
            subtitle: 'Monitor household electricity consumption, explore usage history, and discover insights about future energy needs.',
          ),
          const SizedBox(height: 44),
          LayoutBuilder(
            builder: (context, c) {
              const gap = 20.0;
              final cols = c.maxWidth >= 760 ? 2 : 1;
              final itemW = (c.maxWidth - gap * (cols - 1)) / cols;
              return Wrap(
                spacing: gap,
                runSpacing: gap,
                children: [
                  for (final f in items)
                    SizedBox(
                      width: itemW,
                      child: _FeatureCard(feature: f),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _FeatureCard extends StatefulWidget {
  final _Feature feature;
  const _FeatureCard({required this.feature});

  @override
  State<_FeatureCard> createState() => _FeatureCardState();
}

class _FeatureCardState extends State<_FeatureCard> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final f = widget.feature;
    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        transform: Matrix4.translationValues(0, _hover ? -4 : 0, 0),
        child: GlassCard(
          blur: 0,
          padding: const EdgeInsets.all(26),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: LinearGradient(
                    colors: [
                      f.color.withValues(alpha: 0.26),
                      f.color.withValues(alpha: 0.08),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  border: Border.all(color: f.color.withValues(alpha: 0.28)),
                ),
                child: Icon(f.icon, color: f.color, size: 28),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      f.title,
                      style: TextStyle(
                        color: LandingColors.textPrimary,
                        fontSize: 19,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      f.description,
                      style: TextStyle(
                        color: LandingColors.textSecondary,
                        fontSize: 15,
                        height: 1.6,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── How it works ─────────────────────────────────────────────────────────

class _Step {
  final String number;
  final String title;
  final String description;
  final IconData icon;
  final Color color;
  const _Step(this.number, this.title, this.description, this.icon, this.color);
}

List<_Step> _steps() => [
  _Step(
    '01',
    'Record',
    'Users enter their previous and current electricity meter readings.',
    Icons.edit_note_rounded,
    LandingColors.primary,
  ),
  _Step(
    '02',
    'Calculate',
    'The system determines the recorded consumption from the difference between the meter readings.',
    Icons.calculate_rounded,
    LandingColors.primary,
  ),
  _Step(
    '03',
    'Forecast',
    'The XGBoost machine learning model forecasts future electricity consumption using the data available to the system.',
    Icons.auto_graph_rounded,
    LandingColors.purple,
  ),
  _Step(
    '04',
    'Estimate',
    'Users view forecast consumption and an estimated electricity bill.',
    Icons.receipt_long_rounded,
    LandingColors.orange,
  ),
];

class LandingHowItWorksSection extends StatelessWidget {
  const LandingHowItWorksSection({super.key});

  @override
  Widget build(BuildContext context) {
    final steps = _steps();
    return LandingSection(
      color: Colors.transparent,
      child: Column(
        children: [
          const LandingSectionHeader(
            centered: true,
            tag: 'How It Works',
            title: 'How E-FORECAST Works',
            subtitle: 'From meter readings to meaningful energy insights.',
          ),
          const SizedBox(height: 48),
          LayoutBuilder(
            builder: (context, c) {
              if (c.maxWidth >= 900) {
                final w = c.maxWidth;
                return Stack(
                  children: [
                    Positioned(
                      top: 27,
                      left: w / 8,
                      right: w / 8,
                      child: Container(
                        height: 2,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              LandingColors.primary.withValues(alpha: 0.5),
                              LandingColors.purple.withValues(alpha: 0.5),
                              LandingColors.orange.withValues(alpha: 0.5),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        for (final s in steps)
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                              ),
                              child: Column(
                                children: [
                                  _circle(s),
                                  const SizedBox(height: 16),
                                  _card(s, center: true),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                );
              }
              return Column(
                children: [
                  for (final s in steps)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _circle(s),
                          const SizedBox(width: 16),
                          Expanded(child: _card(s, center: false)),
                        ],
                      ),
                    ),
                ],
              );
            },
          ),
          const SizedBox(height: 32),
          const _IllustrativeExample(),
        ],
      ),
    );
  }

  static Widget _circle(_Step s) => Container(
    width: 56,
    height: 56,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      gradient: LinearGradient(
        colors: [s.color, Color.lerp(s.color, Colors.white, 0.3)!],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      border: Border.all(color: LandingColors.background, width: 4),
      boxShadow: [
        BoxShadow(
          color: s.color.withValues(alpha: 0.3),
          blurRadius: 14,
          offset: const Offset(0, 5),
        ),
      ],
    ),
    child: Icon(s.icon, color: Colors.white, size: 24),
  );

  static Widget _card(_Step s, {required bool center}) => GlassCard(
    blur: 0,
    padding: const EdgeInsets.all(20),
    child: SizedBox(
      width: double.infinity,
      child: Column(
        crossAxisAlignment: center
            ? CrossAxisAlignment.center
            : CrossAxisAlignment.start,
        children: [
          Text(
            'STEP ${s.number}',
            style: TextStyle(
              color: s.color,
              fontSize: 12,
              fontWeight: FontWeight.w800,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            s.title,
            style: TextStyle(
              color: LandingColors.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            s.description,
            textAlign: center ? TextAlign.center : TextAlign.start,
            style: TextStyle(
              color: LandingColors.textSecondary,
              fontSize: 14,
              height: 1.55,
            ),
          ),
        ],
      ),
    ),
  );
}

class _IllustrativeExample extends StatelessWidget {
  const _IllustrativeExample();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 18),
      decoration: BoxDecoration(
        color: LandingColors.background,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: LandingColors.border),
      ),
      child: Wrap(
        alignment: WrapAlignment.center,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 14,
        runSpacing: 10,
        children: [
          const SampleDataChip(label: 'Illustrative example'),
          Text(
            '1,400 kWh − 1,250 kWh = 150 kWh',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: LandingColors.textPrimary,
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
