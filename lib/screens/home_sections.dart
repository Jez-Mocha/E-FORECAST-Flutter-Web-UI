import 'package:flutter/material.dart';
import '../models/energy_models.dart';
import '../theme/app_colors.dart';
import '../widgets/feature_card.dart';
import '../widgets/interactive_chart.dart';
import '../widgets/live_estimator.dart';
import '../widgets/step_card.dart';
import 'login_screen.dart';

// ─── HERO ─────────────────────────────────────────────────────────────────
class HeroSection extends StatelessWidget {
  final VoidCallback onCalculateTap;
  const HeroSection({super.key, required this.onCalculateTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [AppColors.backgroundLight, AppColors.background],
        ),
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 72),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isDesktop = constraints.maxWidth >= 900;
                if (isDesktop) {
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(flex: 55, child: _buildHeroCopy(context)),
                      const SizedBox(width: 56),
                      const Expanded(flex: 45, child: InteractiveEnergyDashboard()),
                    ],
                  );
                }
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeroCopy(context),
                    const SizedBox(height: 48),
                    const InteractiveEnergyDashboard(),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeroCopy(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildBadge(),
        const SizedBox(height: 26),
        _buildHeadline(),
        const SizedBox(height: 20),
        _buildSubtitle(),
        const SizedBox(height: 36),
        _buildCTARow(context),
        const SizedBox(height: 32),
        _buildHeroStats(),
      ],
    );
  }

  Widget _buildBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.bolt_rounded, color: AppColors.cyan, size: 14),
          SizedBox(width: 6),
          Text('XGBoost-Powered Household Forecasting',
              style: TextStyle(color: AppColors.cyan, fontSize: 12, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildHeadline() {
    return const Text(
      'Predict Your\nElectricity Bill\nBefore It Arrives',
      style: TextStyle(fontSize: 46, fontWeight: FontWeight.w800,
          letterSpacing: -1.2, height: 1.15, color: AppColors.textPrimary),
    );
  }

  Widget _buildSubtitle() {
    return const Text(
      'E-FORECAST uses XGBoost ML trained on Philippine household data to forecast your monthly electricity consumption — giving you cost control before the meter reads.',
      style: TextStyle(color: AppColors.textSecondary, fontSize: 16, height: 1.65),
    );
  }


  Widget _buildCTARow(BuildContext context) {
    return Wrap(
      spacing: 14,
      runSpacing: 12,
      children: [
        ElevatedButton.icon(
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const LoginScreen(initialTab: 1)),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            elevation: 0,
          ),
          icon: const Icon(Icons.rocket_launch_rounded, size: 17),
          label: const Text('Start Forecasting', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
        ),
        OutlinedButton.icon(
          onPressed: onCalculateTap,
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.textPrimary,
            side: const BorderSide(color: AppColors.border),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          icon: const Icon(Icons.calculate_outlined, size: 17),
          label: const Text('See Estimator', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
        ),
      ],
    );
  }

  Widget _buildHeroStats() {
    return const Wrap(
      spacing: 28,
      runSpacing: 12,
      children: [
        _HeroStat(label: '98.4%', sublabel: 'Model Accuracy'),
        _HeroStat(label: '12%', sublabel: 'Avg. Bill Savings'),
        _HeroStat(label: '< 1 sec', sublabel: 'Forecast Speed'),
      ],
    );
  }
}

class _HeroStat extends StatelessWidget {
  final String label;
  final String sublabel;
  const _HeroStat({required this.label, required this.sublabel});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 22,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          sublabel,
          style: const TextStyle(
            color: AppColors.textMuted,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

// ─── STATS BANNER ─────────────────────────────────────────────────────────
class StatsBanner extends StatelessWidget {
  const StatsBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: AppColors.card,
        border: Border.symmetric(
          horizontal: BorderSide(color: AppColors.borderSubtle),
        ),
      ),
      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth < 680) {
                return const Wrap(
                  alignment: WrapAlignment.spaceAround,
                  spacing: 24,
                  runSpacing: 20,
                  children: [
                    _StatBlock('98.4%', 'Forecast Accuracy'),
                    _StatBlock('₱1,250+', 'Avg. Monthly Savings'),
                    _StatBlock('< 100ms', 'Inference Latency'),
                    _StatBlock('10k+', 'Meter Cycles Logged'),
                  ],
                );
              }
              return const Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _StatBlock('98.4%', 'Forecast Accuracy'),
                  _StatDivider(),
                  _StatBlock('₱1,250+', 'Avg. Monthly Savings'),
                  _StatDivider(),
                  _StatBlock('< 100ms', 'Inference Latency'),
                  _StatDivider(),
                  _StatBlock('10k+', 'Meter Cycles Logged'),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

// ─── FEATURES SECTION ──────────────────────────────────────────────────────
class FeaturesSection extends StatelessWidget {
  const FeaturesSection({super.key});

  @override
  Widget build(BuildContext context) {
    final features = [
      const FeatureItem(
        title: 'Smart Meter Ingestion',
        description: 'Log and track monthly kWh meter readings with automatic billing cycle normalization and anomaly detection.',
        icon: Icons.speed_rounded,
        badge: 'INGESTION',
        accentColor: AppColors.cyan,
      ),
      const FeatureItem(
        title: 'XGBoost ML Pipeline',
        description: 'Gradient boosted trees model historical consumption trends, weather fluctuations, and appliance loads.',
        icon: Icons.auto_graph_rounded,
        badge: 'ALGORITHM',
        accentColor: AppColors.purple,
      ),
      const FeatureItem(
        title: 'Tariff & Bill Estimation',
        description: 'Accurate cost forecasting based on Philippine utility tiered rates (generation, transmission, lifeline subsidies).',
        icon: Icons.receipt_long_rounded,
        badge: 'ACCURACY',
        accentColor: AppColors.emerald,
      ),
      const FeatureItem(
        title: 'Peak Load Optimization',
        description: 'Proactive alerts and time-of-use recommendations to shift high-wattage appliance usage off peak hours.',
        icon: Icons.energy_savings_leaf_rounded,
        badge: 'OPTIMIZATION',
        accentColor: AppColors.amber,
      ),
    ];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 80),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: Column(
            children: [
              const _SectionHeader(
                tag: 'PLATFORM FEATURES',
                title: 'Intelligent Control Over Electricity Costs',
                subtitle: 'From raw meter readings to machine learning forecasts — all in one unified dashboard.',
              ),
              const SizedBox(height: 48),
              LayoutBuilder(
                builder: (context, constraints) {
                  final count = constraints.maxWidth >= 1024
                      ? 4
                      : constraints.maxWidth >= 600
                          ? 2
                          : 1;
                  return GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: count,
                      crossAxisSpacing: 20,
                      mainAxisSpacing: 20,
                      mainAxisExtent: 250,
                    ),
                    itemCount: features.length,
                    itemBuilder: (context, index) {
                      final item = features[index];
                      return FeatureCard(
                        icon: item.icon,
                        title: item.title,
                        description: item.description,
                        badge: item.badge,
                        accentColor: item.accentColor,
                      );
                    },
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── HOW IT WORKS SECTION ──────────────────────────────────────────────────
class HowItWorksSection extends StatelessWidget {
  const HowItWorksSection({super.key});

  @override
  Widget build(BuildContext context) {
    final steps = [
      const StepItem(
        step: '01',
        title: 'Input Meter Readings',
        description: 'Enter your monthly kWh usage or dial readings manually or sync from your electric utility statement.',
        icon: Icons.edit_note_rounded,
      ),
      const StepItem(
        step: '02',
        title: 'Cycle Normalization',
        description: 'E-FORECAST normalizes your billing days, accounts for seasonal weather trends, and detects unexpected usage spikes.',
        icon: Icons.analytics_rounded,
      ),
      const StepItem(
        step: '03',
        title: 'XGBoost ML Inference',
        description: 'Gradient boosted machine learning trees process household patterns and forecast next month’s consumption trajectory.',
        icon: Icons.psychology_rounded,
      ),
      const StepItem(
        step: '04',
        title: 'Prevent Bill Shocks',
        description: 'Receive estimated bill amounts before the meter is read, with personalized recommendations to save electricity.',
        icon: Icons.savings_rounded,
      ),
    ];

    return Container(
      width: double.infinity,
      color: AppColors.backgroundLight,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 80),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: Column(
            children: [
              const _SectionHeader(
                tag: 'WORKFLOW',
                title: 'How E-FORECAST Works',
                subtitle: 'A streamlined 4-step workflow to forecast and master your household electricity expenses.',
              ),
              const SizedBox(height: 48),
              LayoutBuilder(
                builder: (context, constraints) {
                  final count = constraints.maxWidth >= 1024
                      ? 4
                      : constraints.maxWidth >= 600
                          ? 2
                          : 1;
                  return GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: count,
                      crossAxisSpacing: 20,
                      mainAxisSpacing: 20,
                      mainAxisExtent: 240,
                    ),
                    itemCount: steps.length,
                    itemBuilder: (context, index) {
                      final item = steps[index];
                      return StepCard(
                        step: item.step,
                        title: item.title,
                        description: item.description,
                        icon: item.icon,
                      );
                    },
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}


// ─── ESTIMATOR SECTION ────────────────────────────────────────────────────
class EstimatorSection extends StatelessWidget {
  const EstimatorSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 80),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900),
          child: Column(
            children: [
              const _SectionHeader(
                tag: 'LIVE ESTIMATOR',
                title: 'Calculate Your Monthly Savings',
                subtitle: 'Adjust your current monthly electricity consumption to simulate how much E-FORECAST can help you save.',
              ),
              const SizedBox(height: 40),
              const LiveEstimator(),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── CTA SECTION ──────────────────────────────────────────────────────────
class CtaSection extends StatelessWidget {
  const CtaSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: AppColors.backgroundLight,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 72),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 48),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [AppColors.backgroundLight, AppColors.card],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.08),
                  blurRadius: 32,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.electric_bolt_rounded, color: AppColors.cyan, size: 28),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Ready to take charge of your power consumption?',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Join Philippine homeowners and businesses using XGBoost AI to forecast, monitor, and reduce monthly electric utility costs.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 15, height: 1.55),
                ),
                const SizedBox(height: 32),
                Wrap(
                  spacing: 16,
                  runSpacing: 12,
                  alignment: WrapAlignment.center,
                  children: [
                    ElevatedButton.icon(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const LoginScreen(initialTab: 1)),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        elevation: 0,
                      ),
                      icon: const Icon(Icons.person_add_rounded, size: 18),
                      label: const Text('Create Free Account', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                    ),
                    OutlinedButton.icon(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const LoginScreen(initialTab: 0)),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.textPrimary,
                        side: const BorderSide(color: AppColors.border),
                        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      icon: const Icon(Icons.login_rounded, size: 18),
                      label: const Text('Sign In', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}


// ─── SHARED PRIVATE HELPERS ───────────────────────────────────────────────
class _SectionHeader extends StatelessWidget {
  final String tag;
  final String title;
  final String subtitle;

  const _SectionHeader({
    required this.tag,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.cyan.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.cyan.withValues(alpha: 0.25)),
          ),
          child: Text(
            tag,
            style: const TextStyle(
              color: AppColors.cyan,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
            ),
          ),
        ),
        const SizedBox(height: 14),
        Text(
          title,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 30,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 10),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 620),
          child: Text(
            subtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 15,
              height: 1.55,
            ),
          ),
        ),
      ],
    );
  }
}

class _StatBlock extends StatelessWidget {
  final String value;
  final String label;
  const _StatBlock(this.value, this.label);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 26,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            color: AppColors.textMuted,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _StatDivider extends StatelessWidget {
  const _StatDivider();

  @override
  Widget build(BuildContext context) {
    return Container(width: 1, height: 36, color: AppColors.borderSubtle);
  }
}
