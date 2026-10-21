import 'package:flutter/material.dart';

import '../screens/login_screen.dart';
import '../theme/landing_colors.dart';

/// Opens the existing [LoginScreen]. Tab 0 = Sign In, tab 1 = Register.
void openLogin(BuildContext context, {int tab = 0}) {
  Navigator.push(
    context,
    MaterialPageRoute(builder: (_) => LoginScreen(initialTab: tab)),
  );
}

/// Centers content and limits its width.
/// Side padding is 24 px, or 16 px on phones (under 600 px wide).
class LandingContainer extends StatelessWidget {
  final Widget child;
  final double maxWidth;

  const LandingContainer({
    super.key,
    required this.child,
    this.maxWidth = 1200,
  });

  @override
  Widget build(BuildContext context) {
    final phone = MediaQuery.sizeOf(context).width < 600;
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: phone ? 16 : 24),
          child: child,
        ),
      ),
    );
  }
}

/// Full-width section band with responsive vertical padding.
/// Phones (under 600 px): 36. 600 to 639 px: 48. 640 px and up: 72.
class LandingSection extends StatelessWidget {
  final Widget child;
  final Color? color;
  final double maxWidth;

  const LandingSection({
    super.key,
    required this.child,
    this.color,
    this.maxWidth = 1200,
  });

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final vertical = width < 600 ? 36.0 : (width < 640 ? 48.0 : 72.0);
    return Container(
      width: double.infinity,
      color: color ?? LandingColors.background,
      padding: EdgeInsets.symmetric(vertical: vertical),
      child: LandingContainer(maxWidth: maxWidth, child: child),
    );
  }
}

class LandingSectionHeader extends StatelessWidget {
  final String tag;
  final String title;
  final String subtitle;
  final bool centered;

  const LandingSectionHeader({
    super.key,
    required this.tag,
    required this.title,
    required this.subtitle,
    this.centered = false,
  });

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < 640;
    final align = centered
        ? CrossAxisAlignment.center
        : CrossAxisAlignment.start;
    final textAlign = centered ? TextAlign.center : TextAlign.start;

    return Column(
      crossAxisAlignment: align,
      children: [
        // Small plain label (no pill, no background).
        Text(
          tag.toUpperCase(),
          textAlign: textAlign,
          style: TextStyle(
            color: LandingColors.primary,
            fontSize: 12,
            fontWeight: FontWeight.w700,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          title,
          textAlign: textAlign,
          style: TextStyle(
            color: LandingColors.textPrimary,
            fontSize: compact ? 24 : 30,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.4,
            height: 1.25,
          ),
        ),
        const SizedBox(height: 10),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: Text(
            subtitle,
            textAlign: textAlign,
            style: TextStyle(
              color: LandingColors.textSecondary,
              fontSize: 16,
              height: 1.6,
            ),
          ),
        ),
      ],
    );
  }
}

/// White card with a thin border. Flat by default (no shadow).
class LandingCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color? color;
  final double radius;
  final bool shadow;

  const LandingCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(24),
    this.color,
    this.radius = LandingRadius.card,
    this.shadow = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: color ?? LandingColors.background,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: LandingColors.border),
        boxShadow: shadow ? LandingColors.softShadow : null,
      ),
      child: child,
    );
  }
}

/// Soft-pink pill that marks illustrative / placeholder content.
class SampleDataChip extends StatelessWidget {
  final String label;
  const SampleDataChip({super.key, this.label = 'Sample data'});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: LandingColors.pinkTint,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: LandingColors.pinkBorder),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: LandingColors.pinkText,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class LandingLogo extends StatelessWidget {
  const LandingLogo({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: LandingColors.primary,
            borderRadius: BorderRadius.circular(LandingRadius.control),
          ),
          child: const Icon(Icons.bolt_rounded, color: Colors.white, size: 20),
        ),
        const SizedBox(width: 10),
        Text(
          'E-FORECAST',
          style: TextStyle(
            color: LandingColors.textPrimary,
            fontSize: 16,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.6,
          ),
        ),
      ],
    );
  }
}

class LandingPrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  final bool large;

  const LandingPrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.large = true,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: LandingColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        padding: EdgeInsets.symmetric(
          horizontal: large ? 28 : 16,
          vertical: large ? 18 : 12,
        ),
        minimumSize: Size(0, large ? 52 : 40),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(LandingRadius.control),
        ),
        textStyle: TextStyle(
          fontSize: large ? 15 : 13,
          fontWeight: FontWeight.w700,
        ),
      ),
      child: Text(label),
    );
  }
}

class LandingSecondaryButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;

  const LandingSecondaryButton({
    super.key,
    required this.label,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: LandingColors.primary,
        backgroundColor: LandingColors.background,
        side: BorderSide(color: LandingColors.border),
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 18),
        minimumSize: const Size(0, 52),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(LandingRadius.control),
        ),
        textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
      ),
      child: Text(label),
    );
  }
}

/// A small label / big value / caption tile used by the hero and dashboard.
class LandingStatTile extends StatelessWidget {
  final String label;
  final String value;
  final String caption;
  final bool highlight;

  const LandingStatTile({
    super.key,
    required this.label,
    required this.value,
    required this.caption,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: highlight
            ? LandingColors.periwinkleTint
            : LandingColors.backgroundSoft,
        borderRadius: BorderRadius.circular(LandingRadius.card),
        border: Border.all(color: LandingColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              color: LandingColors.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              maxLines: 1,
              style: TextStyle(
                color: highlight
                    ? LandingColors.primary
                    : LandingColors.textPrimary,
                fontSize: 24,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.3,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            caption,
            style: TextStyle(color: LandingColors.textSecondary, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

/// Legend for the Actual / Forecast chart lines.
class ChartLegend extends StatelessWidget {
  const ChartLegend({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _LegendDot(
          color: LandingColors.primary,
          label: 'Actual',
          hollow: false,
        ),
        SizedBox(width: 14),
        _LegendDot(
          color: LandingColors.secondary,
          label: 'Forecast',
          hollow: true,
        ),
      ],
    );
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;
  final bool hollow;

  const _LegendDot({
    required this.color,
    required this.label,
    required this.hollow,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: hollow ? Colors.white : color,
            border: Border.all(color: color, width: 2),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            color: LandingColors.textSecondary,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

/// Lays [children] out in equal-width columns with equal-height rows.
/// Avoids fixed card heights so text never overflows on narrow screens.
///
/// If [spacing] is not given, the gap is 12 px on phones (under 600 px wide)
/// and 20 px otherwise. A value you pass is always used as-is.
class LandingGrid extends StatelessWidget {
  final int columns;
  final double? spacing;
  final List<Widget> children;

  const LandingGrid({
    super.key,
    required this.columns,
    required this.children,
    this.spacing,
  });

  @override
  Widget build(BuildContext context) {
    final gap =
        spacing ?? (MediaQuery.sizeOf(context).width < 600 ? 12.0 : 20.0);
    final rows = <Widget>[];
    for (var start = 0; start < children.length; start += columns) {
      final rowItems = <Widget>[];
      for (var j = 0; j < columns; j++) {
        if (j > 0) rowItems.add(SizedBox(width: gap));
        final index = start + j;
        rowItems.add(
          Expanded(
            child: index < children.length
                ? children[index]
                : const SizedBox.shrink(),
          ),
        );
      }
      if (rows.isNotEmpty) rows.add(SizedBox(height: gap));
      rows.add(
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: rowItems,
          ),
        ),
      );
    }
    return Column(children: rows);
  }
}

class ThemeToggleButton extends StatelessWidget {
  const ThemeToggleButton({super.key});

  @override
  Widget build(BuildContext context) {
    final dark = ThemeController.isDark;
    return IconButton(
      tooltip: dark ? 'Switch to light mode' : 'Switch to dark mode',
      onPressed: ThemeController.toggle,
      icon: Icon(
        dark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
        color: LandingColors.textPrimary,
        size: 22,
      ),
    );
  }
}
