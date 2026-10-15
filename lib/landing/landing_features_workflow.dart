import 'package:flutter/material.dart';

import '../models/energy_models.dart';
import '../theme/landing_colors.dart';
import 'landing_widgets.dart';

int _columnsFor(double width, {int wide = 4}) {
  if (width >= 1000) return wide;
  if (width >= 600) return 2;
  return 1;
}

// ─── FEATURES ────────────────────────────────────────────────────────────

class _Feature {
  final IconData icon;
  final String title;
  final String description;
  final Color iconColor;
  final Color tint;

  const _Feature({
    required this.icon,
    required this.title,
    required this.description,
    required this.iconColor,
    required this.tint,
  });
}

List<_Feature> get _features => [
  _Feature(
    icon: Icons.edit_note_rounded,
    title: 'Record Consumption',
    description: 'Record previous and current electricity meter readings and calculate your household\'s electricity consumption.',
    iconColor: LandingColors.primary,
    tint: LandingColors.periwinkleTint,
  ),
  _Feature(
    icon: Icons.show_chart_rounded,
    title: 'Usage Monitoring',
    description: 'Track household electricity usage, review historical records, and understand consumption trends through clear visualizations.',
    iconColor: LandingColors.secondary,
    tint: LandingColors.lavenderTint,
  ),
  _Feature(
    icon: Icons.auto_graph_rounded,
    title: 'XGBoost Forecasting',
    description: 'Use an XGBoost-based machine learning model to forecast future household electricity consumption.',
    iconColor: LandingColors.pinkText,
    tint: LandingColors.pinkTint,
  ),
  _Feature(
    icon: Icons.receipt_long_rounded,
    title: 'Estimated Electricity Bill',
    description: 'View an estimated electricity bill based on forecast consumption and the system\'s configured billing logic.',
    iconColor: LandingColors.primary,
    tint: LandingColors.periwinkleTint,
  ),
];

class LandingFeaturesSection extends StatelessWidget {
  const LandingFeaturesSection({super.key});

  @override
  Widget build(BuildContext context) {
    return LandingSection(
      child: Column(
        children: [
          const LandingSectionHeader(
            tag: 'Features',
            title: 'Everything You Need to Understand Your Energy',
            subtitle: 'Monitor household electricity consumption, explore usage history, and discover insights about future energy needs.',
          ),
          const SizedBox(height: 48),
          LayoutBuilder(
            builder: (context, constraints) {
              return LandingGrid(
                columns: _columnsFor(constraints.maxWidth),
                children: [for (final f in _features) _FeatureCard(feature: f)],
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
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final f = widget.feature;
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        transform: Matrix4.translationValues(0, _hovered ? -4 : 0, 0),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: LandingColors.background,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: _hovered
                ? LandingColors.secondary.withValues(alpha: 0.5)
                : LandingColors.border,
          ),
          boxShadow: _hovered ? LandingColors.softShadow : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: f.tint,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(f.icon, color: f.iconColor, size: 24),
            ),
            const SizedBox(height: 20),
            Text(
              f.title,
              style: TextStyle(
                color: LandingColors.textPrimary,
                fontSize: 17,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.2,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              f.description,
              style: TextStyle(
                color: LandingColors.textSecondary,
                fontSize: 14,
                height: 1.6,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── HOW IT WORKS ────────────────────────────────────────────────────────

// Reuses the existing StepItem model from models/energy_models.dart.
const List<StepItem> _steps = [
  StepItem(
    step: '01',
    title: 'Record',
    description:
        'Users enter their previous and current electricity meter readings.',
    icon: Icons.edit_note_rounded,
  ),
  StepItem(
    step: '02',
    title: 'Calculate',
    description: 'The system determines the recorded consumption from the difference between the meter readings.',
    icon: Icons.calculate_rounded,
  ),
  StepItem(
    step: '03',
    title: 'Forecast',
    description: 'The XGBoost machine learning model forecasts future electricity consumption using the data available to the system.',
    icon: Icons.auto_graph_rounded,
  ),
  StepItem(
    step: '04',
    title: 'Estimate',
    description:
        'Users view forecast consumption and an estimated electricity bill.',
    icon: Icons.receipt_long_rounded,
  ),
];

class LandingHowItWorksSection extends StatelessWidget {
  const LandingHowItWorksSection({super.key});

  @override
  Widget build(BuildContext context) {
    return LandingSection(
      color: LandingColors.backgroundSoft,
      child: Column(
        children: [
          const LandingSectionHeader(
            tag: 'Process',
            title: 'How E-FORECAST Works',
            subtitle: 'From meter readings to meaningful energy insights.',
          ),
          const SizedBox(height: 48),
          LayoutBuilder(
            builder: (context, constraints) {
              return LandingGrid(
                columns: _columnsFor(constraints.maxWidth),
                children: [for (final s in _steps) _StepCard(step: s)],
              );
            },
          ),
          const SizedBox(height: 32),
          const _IllustrativeExample(),
        ],
      ),
    );
  }
}

class _StepCard extends StatelessWidget {
  final StepItem step;
  const _StepCard({required this.step});

  @override
  Widget build(BuildContext context) {
    return LandingCard(
      shadow: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  gradient: LandingColors.primaryGradient,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  step.step,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const Spacer(),
              Icon(step.icon, color: LandingColors.secondary, size: 22),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            step.title,
            style: TextStyle(
              color: LandingColors.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            step.description,
            style: TextStyle(
              color: LandingColors.textSecondary,
              fontSize: 14,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }
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
            '1,400 kWh current − 1,250 kWh previous = 150 kWh',
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
