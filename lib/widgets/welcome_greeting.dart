import 'package:flutter/material.dart';

import '../theme/app_effects.dart';
import '../theme/landing_colors.dart';
import 'app_components.dart';

/// Welcome banner for the top of the dashboard.
///
/// The greeting follows the local time of day. There is no user name yet
/// (no account data), so the greeting is generic. The picture on the right
/// is made only from Flutter icons and gradients.
class WelcomeGreeting extends StatelessWidget {
  const WelcomeGreeting({super.key});

  @override
  Widget build(BuildContext context) {
    final hour = DateTime.now().hour;

    final String greeting;
    if (hour >= 5 && hour < 12) {
      greeting = 'Good morning!';
    } else if (hour >= 12 && hour < 18) {
      greeting = 'Good afternoon!';
    } else {
      greeting = 'Good evening!';
    }

    return Container(
      constraints: const BoxConstraints(minHeight: 168),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        gradient: LandingColors.ctaGradient,
        borderRadius: BorderRadius.circular(LandingRadius.card + 6),
        border: Border.all(color: LandingColors.glassBorder),
        boxShadow: AppEffects.raised,
      ),
      child: Row(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(32, 28, 16, 28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    greeting,
                    style: TextStyle(
                      color: LandingColors.textPrimary,
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.4,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Keep an eye on your electricity usage today, so your '
                    'next bill holds no surprises.',
                    style: TextStyle(
                      color: LandingColors.textSecondary,
                      fontSize: 14,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 18),
                  Container(
                    width: 44,
                    height: 4,
                    decoration: BoxDecoration(
                      gradient: LandingColors.energyGradient,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const _EnergyIllustration(),
        ],
      ),
    );
  }
}

/// A small energy-themed picture: a house in a glowing circle with a few
/// floating icon badges. Decoration only.
class _EnergyIllustration extends StatelessWidget {
  const _EnergyIllustration();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 300,
      height: 168,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 156,
            height: 156,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: LandingColors.glassBorder, width: 2),
            ),
          ),
          Container(
            width: 120,
            height: 120,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LandingColors.energyGradient,
              boxShadow: [
                BoxShadow(
                  color: LandingColors.primary.withValues(alpha: 0.35),
                  blurRadius: 24,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: const Icon(
              Icons.home_rounded,
              color: Colors.white,
              size: 60,
            ),
          ),
          const Positioned(
            top: 18,
            right: 52,
            child: AppIconBadge(
              icon: Icons.bolt_rounded,
              accent: AppAccent.orange,
              size: 40,
            ),
          ),
          const Positioned(
            bottom: 20,
            left: 56,
            child: AppIconBadge(
              icon: Icons.eco_rounded,
              accent: AppAccent.green,
              size: 38,
            ),
          ),
          const Positioned(
            bottom: 34,
            right: 34,
            child: AppIconBadge(
              icon: Icons.wb_sunny_rounded,
              accent: AppAccent.purple,
              size: 32,
            ),
          ),
        ],
      ),
    );
  }
}
