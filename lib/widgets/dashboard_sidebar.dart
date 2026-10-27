import 'package:flutter/material.dart';

import '../landing/landing_widgets.dart' show LandingLogo;
import '../theme/landing_colors.dart';
import 'rate_carousel.dart';

/// Left sidebar of the desktop dashboard.
///
/// Top: the E-FORECAST logo.
/// Middle: the "Electricity Rates" section with the animated [RateCarousel].
/// Bottom: the "Submit a Report" and "View Reports" actions.
class DashboardSidebar extends StatelessWidget {
  /// Width of the sidebar on desktop.
  static const double width = 280;

  /// Height of the logo area. The top navigation in the main content area
  /// uses the same height so the lines meet across the screen.
  static const double headerHeight = 64;

  final VoidCallback onSubmitReport;
  final VoidCallback onViewReports;

  const DashboardSidebar({
    super.key,
    required this.onSubmitReport,
    required this.onViewReports,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      decoration: BoxDecoration(
        color: LandingColors.background,
        border: Border(right: BorderSide(color: LandingColors.border)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Logo area ────────────────────────────────────────────────────
          Container(
            height: headerHeight,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            alignment: Alignment.centerLeft,
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: LandingColors.border)),
            ),
            child: const LandingLogo(),
          ),

          // ── Electricity Rates ────────────────────────────────────────────
          // Scrolls only if the browser window is very short.
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _RatesHeading(),
                  SizedBox(height: 16),
                  RateCarousel(),
                ],
              ),
            ),
          ),

          // ── Report actions (anchored at the bottom) ──────────────────────
          _ReportActions(
            onSubmitReport: onSubmitReport,
            onViewReports: onViewReports,
          ),
        ],
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

/// "Submit a Report" and "View Reports", side by side.
class _ReportActions extends StatelessWidget {
  final VoidCallback onSubmitReport;
  final VoidCallback onViewReports;

  const _ReportActions({
    required this.onSubmitReport,
    required this.onViewReports,
  });

  @override
  Widget build(BuildContext context) {
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(LandingRadius.control),
    );
    const padding = EdgeInsets.symmetric(horizontal: 8, vertical: 12);
    const minSize = Size(0, 42);
    const textStyle = TextStyle(fontSize: 13, fontWeight: FontWeight.w600);

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: LandingColors.border)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Reports',
            style: TextStyle(
              color: LandingColors.textPrimary,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: onSubmitReport,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: LandingColors.primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: padding,
                    minimumSize: minSize,
                    shape: shape,
                    textStyle: textStyle,
                  ),
                  child: const FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text('Submit a Report', maxLines: 1),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton(
                  onPressed: onViewReports,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: LandingColors.primary,
                    side: BorderSide(color: LandingColors.border),
                    padding: padding,
                    minimumSize: minSize,
                    shape: shape,
                    textStyle: textStyle,
                  ),
                  child: const FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text('View Reports', maxLines: 1),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
