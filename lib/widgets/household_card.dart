import 'package:flutter/material.dart';

import '../landing/landing_widgets.dart' show LandingCard;
import '../theme/landing_colors.dart';

/// A reusable card that shows one household's basic information.
/// It only displays what it is given. It has no data of its own.
/// If [onView] is given, a "View Household" button is shown.
class HouseholdCard extends StatelessWidget {
  final String name;
  final String address;
  final int occupants;
  final String provider;
  final VoidCallback? onView;

  const HouseholdCard({
    super.key,
    required this.name,
    required this.address,
    required this.occupants,
    required this.provider,
    this.onView,
  });

  @override
  Widget build(BuildContext context) {
    return LandingCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _HouseholdIcon(),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: LandingColors.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Icon(
                            Icons.location_on_outlined,
                            size: 14,
                            color: LandingColors.textSecondary,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            address,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: LandingColors.textSecondary,
                              fontSize: 13,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Divider(color: LandingColors.border, height: 1),
          const SizedBox(height: 16),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _InfoPill(
                icon: Icons.people_outline_rounded,
                label: occupants == 1 ? '1 occupant' : '$occupants occupants',
              ),
              _InfoPill(icon: Icons.bolt_rounded, label: provider),
            ],
          ),
          if (onView != null) ...[
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: onView,
                icon: const Icon(Icons.arrow_forward_rounded, size: 16),
                label: const Text('View Household'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: LandingColors.primary,
                  side: BorderSide(color: LandingColors.border),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(LandingRadius.control),
                  ),
                  textStyle: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// The small rounded square with a house icon.
class _HouseholdIcon extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: LandingColors.periwinkleTint,
        borderRadius: BorderRadius.circular(LandingRadius.control),
      ),
      child: Icon(Icons.home_rounded, color: LandingColors.primary, size: 24),
    );
  }
}

/// A small tinted label with an icon (used for occupants and provider).
class _InfoPill extends StatelessWidget {
  final IconData icon;
  final String label;

  const _InfoPill({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: LandingColors.backgroundSoft,
        borderRadius: BorderRadius.circular(LandingRadius.control),
        border: Border.all(color: LandingColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: LandingColors.primary),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: LandingColors.textPrimary,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
