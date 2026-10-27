import 'package:flutter/material.dart';

import '../landing/landing_widgets.dart'
    show LandingCard, LandingContainer, LandingPrimaryButton;
import '../theme/app_theme.dart';
import '../theme/landing_colors.dart';
import 'report_form_screen.dart';

/// Separate "My Reports" screen, opened from the sidebar.
///
/// Report history is not connected to a backend yet, so this screen only
/// shows an empty state. It does not show or invent any reports.
/// The "Submit a Report" button reuses the existing [ReportFormScreen].
class ReportsScreen extends StatelessWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: AppTheme.lightTheme,
      child: Scaffold(
        backgroundColor: LandingColors.backgroundSoft,
        appBar: AppBar(
          title: const Text('My Reports'),
          backgroundColor: LandingColors.background,
          foregroundColor: LandingColors.textPrimary,
        ),
        body: SingleChildScrollView(
          child: LandingContainer(
            maxWidth: 720,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 40),
              child: SizedBox(
                width: double.infinity,
                child: LandingCard(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 48,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          color: LandingColors.periwinkleTint,
                          borderRadius: BorderRadius.circular(
                            LandingRadius.card,
                          ),
                        ),
                        child: Icon(
                          Icons.assignment_outlined,
                          color: LandingColors.primary,
                          size: 32,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'No reports to show yet',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: LandingColors.textPrimary,
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 440),
                        child: Text(
                          'Report history is not connected yet, so nothing '
                          'is listed here. Once the backend is ready, the '
                          'reports you submit will appear on this page.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: LandingColors.textSecondary,
                            fontSize: 14,
                            height: 1.5,
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      LandingPrimaryButton(
                        label: 'Submit a Report',
                        large: false,
                        onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const ReportFormScreen(),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
