import 'package:flutter/material.dart';

import '../theme/app_effects.dart';
import '../theme/landing_colors.dart';
import 'landing_widgets.dart';

const List<String> _aboutPoints = [
  'Household-focused monitoring',
  'Organized electricity consumption records',
  'Easy-to-understand usage trends',
  'Machine learning-based forecasting',
  'Estimated electricity bills',
];

// ── About ────────────────────────────────────────────────────────────────

class LandingAboutSection extends StatelessWidget {
  const LandingAboutSection({super.key});

  @override
  Widget build(BuildContext context) {
    final copy = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const LandingSectionHeader(
          tag: 'About E-FORECAST',
          title: 'Smarter Insights for Household Electricity',
          subtitle: 'E-FORECAST combines household electricity monitoring with machine learning-based forecasting to help users better understand their consumption and explore potential future electricity costs.',
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            Icon(Icons.school_rounded, size: 18, color: LandingColors.purple),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                'A college Information Technology system development project.',
                style: TextStyle(
                  color: LandingColors.textSecondary,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ],
    );

    final list = GlassCard(
      blur: 0,
      padding: const EdgeInsets.all(28),
      child: Column(
        children: [
          for (var i = 0; i < _aboutPoints.length; i++) ...[
            if (i > 0) const SizedBox(height: 16),
            Row(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: LandingColors.primary.withValues(alpha: 0.12),
                  ),
                  child: Icon(
                    Icons.check_rounded,
                    size: 17,
                    color: LandingColors.primary,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    _aboutPoints[i],
                    style: TextStyle(
                      color: LandingColors.textPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );

    return LandingSection(
      color: Colors.transparent,
      child: LayoutBuilder(
        builder: (context, c) {
          if (c.maxWidth >= 900) {
            return Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(child: copy),
                const SizedBox(width: 56),
                Expanded(child: list),
              ],
            );
          }
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [copy, const SizedBox(height: 32), list],
          );
        },
      ),
    );
  }
}

// ── Call to action ───────────────────────────────────────────────────────

class LandingCtaSection extends StatelessWidget {
  const LandingCtaSection({super.key});

  @override
  Widget build(BuildContext context) {
    return LandingContainer(
      child: Padding(
        padding: const EdgeInsets.only(top: 24, bottom: 72),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 56),
            decoration: BoxDecoration(gradient: LandingColors.primaryGradient),
            child: Stack(
              children: [
                Positioned(top: -90, right: -60, child: _ring(260, 0.10)),
                Positioned(bottom: -120, left: -80, child: _ring(300, 0.08)),
                Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 680),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.bolt_rounded,
                          color: Colors.white,
                          size: 36,
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Take the Next Step Toward Understanding Your Energy.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 30,
                            fontWeight: FontWeight.w800,
                            height: 1.25,
                            letterSpacing: -0.4,
                          ),
                        ),
                        const SizedBox(height: 14),
                        Text(
                          'Explore household electricity monitoring and forecasting with E-FORECAST.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.9),
                            fontSize: 16,
                            height: 1.6,
                          ),
                        ),
                        const SizedBox(height: 28),
                        ElevatedButton(
                          onPressed: () => openLogin(context, tab: 1),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: LandingColors.primary,
                            elevation: 0,
                            minimumSize: const Size(0, 52),
                            padding: const EdgeInsets.symmetric(horizontal: 32),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                LandingRadius.control,
                              ),
                            ),
                            textStyle: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          child: const Text('Get Started'),
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

  static Widget _ring(double size, double alpha) => IgnorePointer(
    child: Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: Colors.white.withValues(alpha: alpha * 2),
          width: 2,
        ),
        color: Colors.white.withValues(alpha: alpha),
      ),
    ),
  );
}

// ── Footer ───────────────────────────────────────────────────────────────

class LandingFooter extends StatelessWidget {
  final VoidCallback onHomeTap;
  final VoidCallback onFeaturesTap;
  final VoidCallback onHowItWorksTap;
  final VoidCallback onAboutTap;

  const LandingFooter({
    super.key,
    required this.onHomeTap,
    required this.onFeaturesTap,
    required this.onHowItWorksTap,
    required this.onAboutTap,
  });

  @override
  Widget build(BuildContext context) {
    final brand = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const LandingLogo(),
        const SizedBox(height: 14),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 360),
          child: Text(
            'An XGBoost-based household electricity consumption and bill forecasting system.',
            style: TextStyle(
              color: LandingColors.textSecondary,
              fontSize: 14,
              height: 1.6,
            ),
          ),
        ),
      ],
    );

    final links = Wrap(
      spacing: 4,
      runSpacing: 4,
      children: [
        _link('Home', onHomeTap),
        _link('Features', onFeaturesTap),
        _link('How It Works', onHowItWorksTap),
        _link('About', onAboutTap),
        _link('Login', () => openLogin(context, tab: 0)),
      ],
    );

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: LandingColors.surface.withValues(alpha: 0.6),
        border: Border(top: BorderSide(color: LandingColors.border)),
      ),
      child: LandingContainer(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 36),
          child: Column(
            children: [
              LayoutBuilder(
                builder: (context, c) {
                  if (c.maxWidth >= 800) {
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Flexible(child: brand),
                        links,
                      ],
                    );
                  }
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [brand, const SizedBox(height: 20), links],
                  );
                },
              ),
              const SizedBox(height: 28),
              Divider(color: LandingColors.border, height: 1),
              const SizedBox(height: 20),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  '© ${DateTime.now().year} E-FORECAST. All rights reserved.',
                  style: TextStyle(
                    color: LandingColors.textSecondary,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static Widget _link(String label, VoidCallback onTap) => TextButton(
    onPressed: onTap,
    style: TextButton.styleFrom(
      foregroundColor: LandingColors.textSecondary,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    ),
    child: Text(
      label,
      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
    ),
  );
}
