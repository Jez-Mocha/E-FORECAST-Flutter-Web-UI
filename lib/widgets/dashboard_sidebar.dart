import 'package:flutter/material.dart';

import '../landing/landing_widgets.dart' show LandingLogo;
import '../theme/app_effects.dart';
import '../theme/app_tokens.dart';
import '../theme/landing_colors.dart';
import 'app_components.dart';
import 'rate_carousel.dart';

/// Left sidebar of the desktop dashboard: a tall frosted-glass panel.
///
/// Top: the E-FORECAST logo.
/// Middle: navigation links, then the "Electricity Rates" section with the
/// animated [RateCarousel].
class DashboardSidebar extends StatelessWidget {
  /// Width of the sidebar on desktop (shared value from app_tokens.dart).
  static const double width = AppLayout.sidebarWidth;

  /// Height of the logo area (shared value from app_tokens.dart).
  static const double headerHeight = AppLayout.topBarHeight;

  /// Opens the existing Add Household screen.
  final VoidCallback? onAddHousehold;

  const DashboardSidebar({super.key, this.onAddHousehold});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 0, 16),
      child: SizedBox(
        width: width,
        child: GlassCard(
          radius: 24,
          padding: EdgeInsets.zero,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Logo area ──────────────────────────────────────────────
              Container(
                height: headerHeight,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                alignment: Alignment.centerLeft,
                child: const LandingLogo(),
              ),

              // ── Navigation + Electricity Rates ─────────────────────────
              // Scrolls only if the browser window is very short.
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(14, 0, 14, 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const _GroupLabel('MENU'),
                      const AppNavItem(
                        icon: Icons.home_work_outlined,
                        label: 'My Households',
                        selected: true,
                      ),
                      const SizedBox(height: 4),
                      AppNavItem(
                        icon: Icons.add_rounded,
                        label: 'Add Household',
                        onTap: onAddHousehold,
                      ),
                      const _GroupLabel('ELECTRICITY RATES'),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 6),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _RatesHeading(),
                            SizedBox(height: 16),
                            RateCarousel(),
                          ],
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
    );
  }
}

/// Small uppercase label above a group of links.
class _GroupLabel extends StatelessWidget {
  final String text;

  const _GroupLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 20, 14, 8),
      child: Text(
        text,
        style: TextStyle(
          color: LandingColors.textSecondary,
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 1,
        ),
      ),
    );
  }
}

/// "Electricity Rates" title with a short description.
class _RatesHeading extends StatelessWidget {
  const _RatesHeading();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.bolt_rounded, size: 18, color: LandingColors.primary),
            const SizedBox(width: 6),
            Text(
              'Electricity Rates',
              style: TextStyle(
                color: LandingColors.textPrimary,
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          'Residential rates per kWh from nearby electricity companies.',
          style: TextStyle(
            color: LandingColors.textSecondary,
            fontSize: 12,
            height: 1.45,
          ),
        ),
      ],
    );
  }
}
