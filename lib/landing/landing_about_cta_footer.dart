import 'package:flutter/material.dart';

import '../theme/landing_colors.dart';
import 'landing_widgets.dart';

// ─── ABOUT ───────────────────────────────────────────────────────────────

const List<String> _aboutPoints = [
  'Household-focused monitoring',
  'Organized electricity consumption records',
  'Easy-to-understand usage trends',
  'Machine learning-based forecasting',
  'Estimated electricity bills',
];

class LandingAboutSection extends StatelessWidget {
  const LandingAboutSection({super.key});

  @override
  Widget build(BuildContext context) {
    return LandingSection(
      color: LandingColors.backgroundSoft,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isDesktop = constraints.maxWidth >= 900;
          const copy = _AboutCopy();
          const list = _AboutList();
          if (isDesktop) {
            return Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(flex: 11, child: copy),
                const SizedBox(width: 56),
                Expanded(flex: 9, child: list),
              ],
            );
          }
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [copy, const SizedBox(height: 32), list],
          );
        },
      ),
    );
  }
}

class _AboutCopy extends StatelessWidget {
  const _AboutCopy();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        LandingSectionHeader(
          tag: 'About E-FORECAST',
          title: 'Smarter Insights for Household Electricity',
          subtitle: 'E-FORECAST combines household electricity monitoring with machine learning-based forecasting to help users better understand their consumption and explore potential future electricity costs.',
          centered: false,
        ),
        SizedBox(height: 20),
        Text(
          'A college Information Technology system development project.',
          style: TextStyle(
            color: LandingColors.textSecondary,
            fontSize: 14,
            fontStyle: FontStyle.italic,
          ),
        ),
      ],
    );
  }
}

class _AboutList extends StatelessWidget {
  const _AboutList();

  @override
  Widget build(BuildContext context) {
    return LandingCard(
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var i = 0; i < _aboutPoints.length; i++) ...[
            if (i > 0) const SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 26,
                  height: 26,
                  decoration: BoxDecoration(
                    color: LandingColors.periwinkleTint,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.check_rounded,
                    size: 16,
                    color: LandingColors.primary,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      _aboutPoints[i],
                      style: TextStyle(
                        color: LandingColors.textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        height: 1.4,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

// ─── CTA ─────────────────────────────────────────────────────────────────

class LandingCtaSection extends StatelessWidget {
  const LandingCtaSection({super.key});

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < 640;
    return LandingSection(
      maxWidth: 1000,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 24 : 56,
          vertical: compact ? 40 : 64,
        ),
        decoration: BoxDecoration(
          gradient: LandingColors.ctaGradient,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: LandingColors.border),
          boxShadow: LandingColors.softShadow,
        ),
        child: Column(
          children: [
            Text(
              'Take the Next Step Toward Understanding Your Energy.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: LandingColors.textPrimary,
                fontSize: compact ? 26 : 36,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.8,
                height: 1.2,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              'Explore household electricity monitoring and forecasting with E-FORECAST.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: LandingColors.textSecondary,
                fontSize: 16,
                height: 1.6,
              ),
            ),
            const SizedBox(height: 28),
            LandingPrimaryButton(
              label: 'Get Started',
              onPressed: () => openLogin(context, tab: 1),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── FOOTER ──────────────────────────────────────────────────────────────

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
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 48),
      decoration: BoxDecoration(
        color: LandingColors.background,
        border: Border(top: BorderSide(color: LandingColors.border)),
      ),
      child: LandingContainer(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isDesktop = constraints.maxWidth >= 720;
            const brand = _FooterBrand();
            final links = Wrap(
              spacing: 4,
              runSpacing: 4,
              children: [
                _footerLink('Home', onHomeTap),
                _footerLink('Features', onFeaturesTap),
                _footerLink('How It Works', onHowItWorksTap),
                _footerLink('About', onAboutTap),
                _footerLink('Login', () => openLogin(context, tab: 0)),
              ],
            );

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (isDesktop)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: brand),
                      const SizedBox(width: 32),
                      Flexible(child: links),
                    ],
                  )
                else ...[
                  brand,
                  const SizedBox(height: 20),
                  links,
                ],
                const SizedBox(height: 28),
                Divider(color: LandingColors.border, height: 1),
                const SizedBox(height: 20),
                Text(
                  '© ${DateTime.now().year} E-FORECAST. All rights reserved.',
                  style: TextStyle(
                    color: LandingColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _footerLink(String label, VoidCallback onTap) {
    return TextButton(
      onPressed: onTap,
      style: TextButton.styleFrom(
        foregroundColor: LandingColors.textSecondary,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      child: Text(
        label,
        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
      ),
    );
  }
}

class _FooterBrand extends StatelessWidget {
  const _FooterBrand();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const LandingLogo(),
        const SizedBox(height: 14),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 380),
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
  }
}
