import 'package:flutter/material.dart';

import '../theme/landing_colors.dart';

/// Slim welcome line for the top of the dashboard.
///
/// The greeting follows the local time of day. There is no user name yet
/// (no account data), so the greeting is generic.
class WelcomeGreeting extends StatelessWidget {
  const WelcomeGreeting({super.key});

  @override
  Widget build(BuildContext context) {
    final hour = DateTime.now().hour;

    final String greeting;
    final IconData icon;
    if (hour >= 5 && hour < 12) {
      greeting = 'Good morning!';
      icon = Icons.wb_sunny_outlined;
    } else if (hour >= 12 && hour < 18) {
      greeting = 'Good afternoon!';
      icon = Icons.light_mode_outlined;
    } else {
      greeting = 'Good evening!';
      icon = Icons.nights_stay_outlined;
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Icon(icon, size: 26, color: LandingColors.primary),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                greeting,
                style: TextStyle(
                  color: LandingColors.textPrimary,
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Keep an eye on your electricity usage today, so your next '
                'bill holds no surprises.',
                style: TextStyle(
                  color: LandingColors.textSecondary,
                  fontSize: 14,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
