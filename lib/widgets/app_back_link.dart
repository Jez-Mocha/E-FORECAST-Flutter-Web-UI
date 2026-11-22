import 'package:flutter/material.dart';

import '../theme/landing_colors.dart';

/// A "← label" control shown at the top of a page to go back.
/// Used by Add Household, Household Dashboard, Record Consumption, Usage
/// History, Usage Monitoring, Forecast & Bill and Profile Settings.
///
/// It is a compact pill with a bordered outline, a small arrow badge and the
/// label. On hover or keyboard focus it picks up the blue accent. All colors
/// come from [LandingColors], so it follows light and dark mode.
class AppBackLink extends StatefulWidget {
  final String label;
  final VoidCallback onPressed;

  const AppBackLink({super.key, required this.label, required this.onPressed});

  @override
  State<AppBackLink> createState() => _AppBackLinkState();
}

class _AppBackLinkState extends State<AppBackLink> {
  bool _hover = false;
  bool _focus = false;

  @override
  Widget build(BuildContext context) {
    final active = _hover || _focus;
    final radius = BorderRadius.circular(999);

    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Semantics(
          button: true,
          label: 'Back to ${widget.label}',
          excludeSemantics: true,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: widget.onPressed,
              borderRadius: radius,
              mouseCursor: SystemMouseCursors.click,
              // Hover and focus are drawn by the pill itself below.
              splashColor: LandingColors.primary.withValues(alpha: 0.08),
              highlightColor: Colors.transparent,
              hoverColor: Colors.transparent,
              focusColor: Colors.transparent,
              onHover: (value) => setState(() => _hover = value),
              onFocusChange: (value) => setState(() => _focus = value),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 140),
                curve: Curves.easeOut,
                padding: const EdgeInsets.fromLTRB(6, 6, 16, 6),
                decoration: BoxDecoration(
                  color: active
                      ? LandingColors.blueTint
                      : LandingColors.glassFill,
                  borderRadius: radius,
                  border: Border.all(
                    color: active
                        ? LandingColors.primary.withValues(alpha: 0.45)
                        : LandingColors.border,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 140),
                      curve: Curves.easeOut,
                      width: 28,
                      height: 28,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: active
                            ? LandingColors.primary
                            : LandingColors.primary.withValues(alpha: 0.12),
                      ),
                      child: AnimatedSlide(
                        duration: const Duration(milliseconds: 140),
                        curve: Curves.easeOut,
                        offset: Offset(_hover ? -0.08 : 0, 0),
                        child: Icon(
                          Icons.arrow_back_rounded,
                          size: 16,
                          color: active
                              ? LandingColors.onPrimary
                              : LandingColors.primary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    AnimatedDefaultTextStyle(
                      duration: const Duration(milliseconds: 140),
                      style: TextStyle(
                        color: active
                            ? LandingColors.primary
                            : LandingColors.textPrimary,
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600,
                        height: 1.2,
                      ),
                      child: Text(widget.label),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
