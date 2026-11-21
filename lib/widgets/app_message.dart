import 'dart:async';

import 'package:flutter/material.dart';

import '../theme/landing_colors.dart';

/// Shows a short message in the E-FORECAST style (a floating SnackBar).
/// Shared by the dashboard screens.
void showTemporaryMessage(BuildContext context, String message) {
  final messenger = ScaffoldMessenger.of(context);
  messenger.clearSnackBars();
  messenger.showSnackBar(
    SnackBar(
      backgroundColor: LandingColors.background,
      behavior: SnackBarBehavior.floating,
      margin: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(LandingRadius.control),
        side: BorderSide(color: LandingColors.border),
      ),
      content: Row(
        children: [
          Icon(
            Icons.info_outline_rounded,
            color: LandingColors.primary,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: LandingColors.textPrimary,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
      duration: const Duration(seconds: 3),
    ),
  );
}

/// Shows a small centered success popup with a soft fade and scale.
/// It closes by itself after about 2 seconds, or sooner when the user taps
/// Done or outside the popup. The returned Future completes when it closes.
///
/// [kwh] is optional. When given, the amount is shown under the message.
Future<void> showSuccessPopup(
  BuildContext context, {
  required String message,
  double? kwh,
}) {
  return showGeneralDialog<void>(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Close',
    barrierColor: Colors.black.withValues(alpha: 0.35),
    transitionDuration: const Duration(milliseconds: 220),
    pageBuilder: (context, animation, secondaryAnimation) =>
        _SuccessDialog(message: message, kwh: kwh),
    transitionBuilder: (context, animation, secondaryAnimation, child) {
      final curved = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeIn,
      );
      return FadeTransition(
        opacity: curved,
        child: ScaleTransition(
          scale: Tween<double>(begin: 0.92, end: 1).animate(curved),
          child: child,
        ),
      );
    },
  );
}

/// The popup itself. Closes itself after a short time.
class _SuccessDialog extends StatefulWidget {
  final String message;
  final double? kwh;

  const _SuccessDialog({required this.message, this.kwh});

  @override
  State<_SuccessDialog> createState() => _SuccessDialogState();
}

class _SuccessDialogState extends State<_SuccessDialog> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer(const Duration(milliseconds: 2200), _close);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _close() {
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final green = LandingColors.secondary;
    final kwh = widget.kwh;

    return Center(
      child: Material(
        color: Colors.transparent,
        child: Container(
          width: 340,
          padding: const EdgeInsets.fromLTRB(28, 28, 28, 24),
          decoration: BoxDecoration(
            color: LandingColors.surface,
            borderRadius: BorderRadius.circular(LandingRadius.card),
            border: Border.all(color: LandingColors.border),
            boxShadow: [
              BoxShadow(
                color: LandingColors.shadowDark,
                blurRadius: 28,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: green.withValues(alpha: 0.14),
                ),
                child: Icon(Icons.check_rounded, size: 34, color: green),
              ),
              const SizedBox(height: 18),
              Text(
                widget.message,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: LandingColors.textPrimary,
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  height: 1.3,
                ),
              ),
              if (kwh != null) ...[
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: LandingColors.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(LandingRadius.control),
                    border: Border.all(
                      color: LandingColors.primary.withValues(alpha: 0.25),
                    ),
                  ),
                  child: Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: kwh.toStringAsFixed(2),
                          style: TextStyle(
                            color: LandingColors.primary,
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.2,
                          ),
                        ),
                        TextSpan(
                          text: '  kWh used',
                          style: TextStyle(
                            color: LandingColors.textSecondary,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 18),
              TextButton(onPressed: _close, child: const Text('Done')),
            ],
          ),
        ),
      ),
    );
  }
}
