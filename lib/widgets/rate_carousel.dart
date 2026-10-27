import 'dart:async';

import 'package:flutter/material.dart';

import '../models/electricity_rate.dart';
import '../theme/landing_colors.dart';

/// Three electricity-company cards stacked like a carousel.
///
/// STEP 2.4: the cards now swap places with a smooth animation.
/// Position 0 = front (large), 1 = right (behind), 2 = left (behind).
/// Every 4 seconds the LEFT card moves to the front, the front card moves
/// to the right, and the right card moves to the left.
///
/// No rate here is invented. If [ElectricityRate.ratePerKwh] is null, the
/// card shows "Rate unavailable".
class RateCarousel extends StatefulWidget {
  final List<ElectricityRate> rates;

  /// Which provider starts in front. Default 1 = the middle one.
  final int frontIndex;

  const RateCarousel({
    super.key,
    this.rates = electricityRates,
    this.frontIndex = 1,
  }) : assert(frontIndex >= 0 && frontIndex < 3);

  @override
  State<RateCarousel> createState() => _RateCarouselState();
}

class _RateCarouselState extends State<RateCarousel>
    with SingleTickerProviderStateMixin {
  static const double _stackHeight = 250;
  static const Duration _moveDuration = Duration(milliseconds: 700);
  static const Duration _autoInterval = Duration(seconds: 4);

  late final AnimationController _controller;
  late final CurvedAnimation _curve;
  Timer? _timer;

  // The provider that was in front when the move started, and the one that
  // is (or will be) in front when it ends. When nothing is moving, both are
  // the same.
  late int _from;
  late int _to;

  @override
  void initState() {
    super.initState();
    assert(widget.rates.length == 3, 'RateCarousel needs exactly 3 rates.');
    _from = widget.frontIndex;
    _to = widget.frontIndex;

    _controller = AnimationController(vsync: this, duration: _moveDuration);
    _curve = CurvedAnimation(parent: _controller, curve: Curves.easeInOutCubic);

    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _curve.dispose();
    _controller.dispose();
    super.dispose();
  }

  // ── Timer ─────────────────────────────────────────────────────────────────

  void _startTimer() {
    _timer?.cancel();
    // Automatic move: the left card comes to the front.
    _timer = Timer.periodic(_autoInterval, (_) => _goTo((_to - 1) % 3));
  }

  // ── Moving cards ──────────────────────────────────────────────────────────

  /// Brings the provider at [target] to the front.
  /// Ignored while a move is already running, to keep the motion calm.
  void _goTo(int target) {
    if (!mounted) return;
    if (target == _to) return;
    if (_controller.isAnimating) return;

    setState(() {
      _from = _to;
      _to = target;
    });
    _controller.forward(from: 0);
  }

  /// Called by the arrows and by tapping a card. Also restarts the timer so
  /// the carousel does not jump right after the user clicked.
  void _goToManually(int target) {
    if (_controller.isAnimating) return;
    _goTo(target);
    _startTimer();
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;

            return SizedBox(
              width: width,
              height: _stackHeight,
              child: AnimatedBuilder(
                animation: _curve,
                builder: (context, _) {
                  final t = _curve.value;

                  // Work out where each card is right now by blending from
                  // its old slot to its new slot.
                  final cards = <_PlacedCard>[
                    for (var i = 0; i < widget.rates.length; i++)
                      _PlacedCard(
                        index: i,
                        rate: widget.rates[i],
                        slot: _Slot.lerp(
                          _Slot.forPosition((i - _from) % 3, width),
                          _Slot.forPosition((i - _to) % 3, width),
                          t,
                        ),
                      ),
                  ];

                  // Paint order: lowest depth first, so the front card is
                  // always drawn last (on top), even in the middle of a move.
                  cards.sort((a, b) => a.slot.depth.compareTo(b.slot.depth));

                  return Stack(
                    clipBehavior: Clip.none,
                    children: [
                      for (final c in cards)
                        Positioned(
                          key: ValueKey(c.rate.provider),
                          left: c.slot.left,
                          top: c.slot.top,
                          width: c.slot.width,
                          height: c.slot.height,
                          child: MouseRegion(
                            cursor: c.index == _to
                                ? SystemMouseCursors.basic
                                : SystemMouseCursors.click,
                            child: GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onTap: () => _goToManually(c.index),
                              child: _RateCard(
                                rate: c.rate,
                                focus: c.slot.focus,
                              ),
                            ),
                          ),
                        ),
                    ],
                  );
                },
              ),
            );
          },
        ),
        const SizedBox(height: 6),
        _Controls(
          selected: _to,
          onLeft: () => _goToManually((_to - 1) % 3),
          onRight: () => _goToManually((_to + 1) % 3),
        ),
        const SizedBox(height: 6),
        Text(
          'Rates are for comparison only. Your actual rate depends on your '
          'provider, location and billing details.',
          style: TextStyle(
            color: LandingColors.textSecondary,
            fontSize: 11,
            height: 1.45,
          ),
        ),
      ],
    );
  }
}

/// A card together with the place it currently sits.
class _PlacedCard {
  final int index;
  final ElectricityRate rate;
  final _Slot slot;

  const _PlacedCard({
    required this.index,
    required this.rate,
    required this.slot,
  });
}

/// Where and how big one card is. Everything about a position lives here,
/// so the animation can simply blend from one slot to another.
class _Slot {
  final double left;
  final double top;
  final double width;
  final double height;

  /// 1.0 = fully in front (all details visible), 0.0 = behind (name only).
  final double focus;

  /// Paint order. A higher number is drawn on top.
  final double depth;

  const _Slot({
    required this.left,
    required this.top,
    required this.width,
    required this.height,
    required this.focus,
    required this.depth,
  });

  /// [position]: 0 = front, 1 = right, 2 = left. [areaWidth] is the width of
  /// the whole stack (the usable sidebar width).
  factory _Slot.forPosition(int position, double areaWidth) {
    final frontWidth = areaWidth * 0.82;
    final sideWidth = areaWidth * 0.66;

    switch (position) {
      case 0: // Front: larger, lower, centered.
        return _Slot(
          left: (areaWidth - frontWidth) / 2,
          top: 54,
          width: frontWidth,
          height: 196,
          focus: 1,
          depth: 1,
        );
      case 1: // Right: smaller, higher, pushed to the right edge.
        return _Slot(
          left: areaWidth - sideWidth,
          top: 0,
          width: sideWidth,
          height: 150,
          focus: 0,
          depth: 0.1,
        );
      default: // Left: smaller, higher, pushed to the left edge.
        return _Slot(
          left: 0,
          top: 0,
          width: sideWidth,
          height: 150,
          focus: 0,
          depth: 0,
        );
    }
  }

  /// Blends two slots. [t] goes from 0 (all [a]) to 1 (all [b]).
  static _Slot lerp(_Slot a, _Slot b, double t) {
    double mix(double x, double y) => x + (y - x) * t;
    return _Slot(
      left: mix(a.left, b.left),
      top: mix(a.top, b.top),
      width: mix(a.width, b.width),
      height: mix(a.height, b.height),
      focus: mix(a.focus, b.focus),
      depth: mix(a.depth, b.depth),
    );
  }
}

/// One provider card. [focus] (0 to 1) decides how "in front" it looks, and
/// every visual detail blends smoothly with it.
class _RateCard extends StatelessWidget {
  final ElectricityRate rate;
  final double focus;

  const _RateCard({required this.rate, required this.focus});

  @override
  Widget build(BuildContext context) {
    // Details fade in only during the second half of the move to the front.
    final detailOpacity = ((focus - 0.4) / 0.6).clamp(0.0, 1.0).toDouble();

    return Container(
      decoration: BoxDecoration(
        color: Color.lerp(
          LandingColors.periwinkleTint,
          LandingColors.backgroundSoft,
          focus,
        ),
        borderRadius: BorderRadius.circular(LandingRadius.card),
        border: Border.all(
          color:
              Color.lerp(
                LandingColors.border,
                LandingColors.primary.withValues(alpha: 0.45),
                focus,
              ) ??
              LandingColors.border,
        ),
        boxShadow: BoxShadow.lerpList(null, LandingColors.softShadow, focus),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(LandingRadius.card),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Provider name is always visible, even on the side cards.
              Text(
                rate.provider,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Color.lerp(
                    LandingColors.textSecondary,
                    LandingColors.textPrimary,
                    focus,
                  ),
                  fontSize: 14 + 4 * focus,
                  fontWeight: FontWeight.w700,
                ),
              ),
              // The details live in a fixed-height, clipped area. That way a
              // card that is shrinking never causes an overflow error.
              Expanded(
                child: ClipRect(
                  child: OverflowBox(
                    alignment: Alignment.topLeft,
                    minHeight: 140,
                    maxHeight: 140,
                    child: Opacity(
                      opacity: detailOpacity,
                      child: _CardDetails(rate: rate),
                    ),
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

/// Area, rate, effective date and source.
/// Area, rate, effective date and source.
class _CardDetails extends StatelessWidget {
  final ElectricityRate rate;

  const _CardDetails({required this.rate});

  @override
  Widget build(BuildContext context) {
    final effective = rate.effectiveLabel != null
        ? 'Effective ${rate.effectiveLabel}'
        : rate.effectiveText;
    final source = rate.sourceLabel != null
        ? 'Source: ${rate.sourceLabel}'
        : rate.sourceText;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 2),
        Text(
          rate.area,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(color: LandingColors.textSecondary, fontSize: 13),
        ),
        const SizedBox(height: 12),
        if (rate.hasRate)
          Text(
            rate.rateText,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: LandingColors.primary,
              fontSize: 26,
              fontWeight: FontWeight.w700,
            ),
          )
        else
          Row(
            children: [
              Icon(
                Icons.info_outline_rounded,
                size: 17,
                color: LandingColors.textSecondary,
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  rate.rateText,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: LandingColors.textSecondary,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        const Spacer(),
        Text(
          effective,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(color: LandingColors.textSecondary, fontSize: 12),
        ),
        const SizedBox(height: 3),
        Text(
          source,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(color: LandingColors.textSecondary, fontSize: 12),
        ),
      ],
    );
  }
}

/// Previous / next arrows with three small dots between them.
/// The left arrow brings the left card forward; the right arrow brings the
/// right card forward.
class _Controls extends StatelessWidget {
  final int selected;
  final VoidCallback onLeft;
  final VoidCallback onRight;

  const _Controls({
    required this.selected,
    required this.onLeft,
    required this.onRight,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          onPressed: onLeft,
          tooltip: 'Bring left card forward',
          icon: const Icon(Icons.chevron_left_rounded),
          iconSize: 22,
          color: LandingColors.textSecondary,
          visualDensity: VisualDensity.compact,
        ),
        const SizedBox(width: 6),
        for (var i = 0; i < 3; i++)
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            margin: const EdgeInsets.symmetric(horizontal: 3),
            width: i == selected ? 16 : 6,
            height: 6,
            decoration: BoxDecoration(
              color: i == selected
                  ? LandingColors.primary
                  : LandingColors.border,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
        const SizedBox(width: 6),
        IconButton(
          onPressed: onRight,
          tooltip: 'Bring right card forward',
          icon: const Icon(Icons.chevron_right_rounded),
          iconSize: 22,
          color: LandingColors.textSecondary,
          visualDensity: VisualDensity.compact,
        ),
      ],
    );
  }
}
