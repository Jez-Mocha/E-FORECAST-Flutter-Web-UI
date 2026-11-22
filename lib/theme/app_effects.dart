import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';

import 'landing_colors.dart';

/// Reusable visual effects for the redesign.
///
/// - Raised look (neumorphism): cards that sit softly above the page.
/// - Pressed look: a slightly darker fill with a thin border, for inputs.
///
/// All colors come from [LandingColors], so they follow light and dark mode.
class AppEffects {
  AppEffects._();

  /// Soft raised shadow for cards (a blue-tinted shadow plus a soft highlight).
  static List<BoxShadow> get raised => [
    BoxShadow(
      color: LandingColors.shadowDark,
      blurRadius: 24,
      offset: const Offset(6, 10),
    ),
    BoxShadow(
      color: LandingColors.shadowLight,
      blurRadius: 18,
      offset: const Offset(-6, -6),
    ),
  ];

  /// Smaller raised shadow for buttons, chips and small tiles.
  static List<BoxShadow> get raisedSmall => LandingColors.softShadow;

  /// A raised card look.
  static BoxDecoration raisedDecoration({
    double radius = LandingRadius.card,
    Color? color,
    bool small = false,
  }) {
    return BoxDecoration(
      color: color ?? LandingColors.surface,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: LandingColors.border),
      boxShadow: small ? raisedSmall : raised,
    );
  }

  /// A pressed-in look (no shadow, darker fill).
  static BoxDecoration insetDecoration({
    double radius = LandingRadius.control,
  }) {
    return BoxDecoration(
      color: LandingColors.backgroundSoft,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: LandingColors.border),
    );
  }
}

/// A translucent "glass" panel with a light blur. Flat (no shadow).
///
/// Use it for the sidebar and top bars. For cards use [GlassCard].
class GlassPanel extends StatelessWidget {
  final Widget child;

  /// Rounded corners. Square by default (good for a sidebar or top bar).
  final BorderRadius borderRadius;

  /// Optional border. For a sidebar use only a right line, for example.
  final BoxBorder? border;

  /// How blurry the background behind the panel is. Keep this small.
  final double blur;

  const GlassPanel({
    super.key,
    required this.child,
    this.borderRadius = BorderRadius.zero,
    this.border,
    this.blur = 12,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: borderRadius,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: Container(
          decoration: BoxDecoration(
            color: LandingColors.glassFill,
            borderRadius: borderRadius,
            border: border,
          ),
          child: child,
        ),
      ),
    );
  }
}

/// A rounded frosted-glass card with a soft raised shadow.
///
/// [blur] is the background blur. Use 0 for no blur, which is cheaper and
/// the right choice for small cards that appear many times on one screen.
/// [tint] replaces the glass color, for example a pastel metric card.
class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;
  final double blur;
  final Color? tint;
  final bool shadow;

  const GlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.radius = LandingRadius.card,
    this.blur = 10,
    this.tint,
    this.shadow = true,
  });

  @override
  Widget build(BuildContext context) {
    final corners = BorderRadius.circular(radius);

    Widget content = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: tint ?? LandingColors.glassFill,
        borderRadius: corners,
        border: Border.all(color: LandingColors.glassBorder),
      ),
      child: child,
    );

    if (blur > 0) {
      content = ClipRRect(
        borderRadius: corners,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
          child: content,
        ),
      );
    }

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: corners,
        boxShadow: shadow ? AppEffects.raised : null,
      ),
      child: content,
    );
  }
}

/// Page background: a soft blue gradient with two faint ambient glows.
/// Wrap the content of a screen with it (used from Stage 2 on).
class AppBackground extends StatelessWidget {
  final Widget child;

  const AppBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(gradient: LandingColors.pageGradient),
      child: Stack(
        children: [
          Positioned(
            top: -180,
            left: -140,
            child: _Glow(color: LandingColors.glowBlue, size: 560),
          ),
          Positioned(
            bottom: -200,
            right: -160,
            child: _Glow(color: LandingColors.glowGreen, size: 600),
          ),
          Positioned.fill(child: child),
        ],
      ),
    );
  }
}

class _Glow extends StatelessWidget {
  final Color color;
  final double size;

  const _Glow({required this.color, required this.size});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(colors: [color, color.withValues(alpha: 0)]),
        ),
      ),
    );
  }
}
