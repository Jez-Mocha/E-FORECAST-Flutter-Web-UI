import 'package:flutter/material.dart';

import '../landing/landing_widgets.dart'
    show LandingSecondaryButton, SampleDataChip;
import '../models/billing_data.dart';
import '../models/household.dart';
import '../services/api_service.dart';
import '../theme/app_effects.dart';
import '../theme/app_tokens.dart';
import '../theme/landing_colors.dart';
import '../widgets/app_back_link.dart';
import '../widgets/app_components.dart';
import '../widgets/app_message.dart';
import '../widgets/app_top_bar.dart';
import 'add_household_screen.dart';
import 'forecast_bill_screen.dart';
import 'record_consumption_screen.dart';
import 'usage_history_screen.dart';
import 'usage_monitoring_screen.dart';

/// SCR-05: Selected Household Dashboard.
/// Shows the details of the household it receives. Record Consumption, Usage
/// History, Usage Monitoring and Forecast & Bill open their own screens.
class HouseholdDashboardScreen extends StatefulWidget {
  final Household household;
  final ValueChanged<Household>? onBillingUpdated;

  const HouseholdDashboardScreen({
    super.key,
    required this.household,
    this.onBillingUpdated,
  });

  @override
  State<HouseholdDashboardScreen> createState() =>
      _HouseholdDashboardScreenState();
}

class _HouseholdDashboardScreenState extends State<HouseholdDashboardScreen> {
  late Household household = widget.household;

  Future<void> _editBilling() async {
    final updated = await Navigator.of(context).push<Household>(
      MaterialPageRoute(
        builder: (_) => AddHouseholdScreen(editBillingFor: household),
      ),
    );
    if (!mounted || updated == null) return;
    setState(() => household = updated);
    widget.onBillingUpdated?.call(updated);
    showTemporaryMessage(context, 'Billing settings saved.');
  }

  void _openRecordConsumption(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => RecordConsumptionScreen(household: household),
      ),
    );
  }

  void _openUsageHistory(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => UsageHistoryScreen(household: household),
      ),
    );
  }

  void _openForecastBill(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ForecastBillScreen(household: household),
      ),
    );
  }

  void _openUsageMonitoring(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => UsageMonitoringScreen(household: household),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final note = _noteFor(household);

    // Inherit the app's selected theme instead of forcing light mode.
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: AppBackground(
        child: Column(
          children: [
            const AppTopBar(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(
                      maxWidth: AppLayout.contentMaxWidth,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AppBackLink(
                          label: 'My Households',
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                        const SizedBox(height: 8),
                        _HouseholdHeader(household: household),
                        if (note != null) ...[
                          const SizedBox(height: 14),
                          _InfoNote(text: note),
                        ],
                        if (household.id != null && !household.isSample) ...[
                          const SizedBox(height: 12),
                          LandingSecondaryButton(
                            label: 'Edit Billing Settings',
                            onPressed: _editBilling,
                          ),
                        ],
                        const SizedBox(height: 32),
                        Text(
                          'Household tools',
                          style: TextStyle(
                            color: LandingColors.textPrimary,
                            fontSize: AppText.sectionTitle,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.2,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Record your latest readings, then review usage and bills.',
                          style: TextStyle(
                            color: LandingColors.textSecondary,
                            fontSize: AppText.body,
                          ),
                        ),
                        const SizedBox(height: 16),
                        _ToolGrid(
                          onRecord: () => _openRecordConsumption(context),
                          onHistory: () => _openUsageHistory(context),
                          onMonitoring: () => _openUsageMonitoring(context),
                          onForecast: () => _openForecastBill(context),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Display helpers ─────────────────────────────────────────────────────────

/// Formats a rate without unnecessary trailing zeros.
/// Examples: 12.5000 -> 12.5, 12.0000 -> 12, 12.3456 -> 12.3456.
String _formatRate(double rate) {
  final text = rate.toStringAsFixed(4).replaceFirst(RegExp(r'\.?0+$'), '');
  return '₱$text';
}

/// The short note under the header, or null when there is nothing to say.
String? _noteFor(Household h) {
  if (h.isSample) {
    return 'This is a sample household. Its values are placeholders.';
  }
  if (h.provider.trim().isEmpty || h.billingCycleDay == null) {
    return 'Add your provider and billing cycle day to see bill estimates.';
  }
  if (h.occupants <= 0) {
    return 'Some household details are not available for this household.';
  }
  return null;
}

// ── Header: identity + household details in one card ────────────────────────

class _HouseholdHeader extends StatelessWidget {
  final Household household;

  const _HouseholdHeader({required this.household});

  @override
  Widget build(BuildContext context) {
    final meter = household.meterNumber?.trim();
    final occupants = household.occupants;
    final billingDay = household.billingCycleDay;

    return GlassCard(
      blur: 0,
      padding: const EdgeInsets.fromLTRB(28, 26, 28, 26),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const AppIconBadge(icon: Icons.home_rounded, size: 60),
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      household.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: LandingColors.textPrimary,
                        fontSize: 30,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                        height: 1.15,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(
                          Icons.location_on_outlined,
                          size: 16,
                          color: LandingColors.textSecondary,
                        ),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            household.address,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: LandingColors.textSecondary,
                              fontSize: AppText.body,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  if (meter != null && meter.isNotEmpty)
                    _MeterChip(meter: meter),
                  if (household.isSample)
                    const SampleDataChip(label: 'Sample data'),
                ],
              ),
            ],
          ),
          const SizedBox(height: 22),
          Divider(color: LandingColors.border, height: 1),
          const SizedBox(height: 18),
          Text(
            'HOUSEHOLD DETAILS',
            style: TextStyle(
              color: LandingColors.textSecondary,
              fontSize: AppText.caption,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _DetailTile(
                  icon: Icons.people_outline_rounded,
                  label: 'Occupants',
                  value: occupants <= 0 ? null : '$occupants',
                  unit: occupants == 1 ? 'occupant' : 'occupants',
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: _DetailTile(
                  icon: Icons.bolt_rounded,
                  label: 'Electricity provider',
                  value: household.provider.trim().isEmpty
                      ? null
                      : household.provider.trim(),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: _HouseholdRateTile(
                  key: ValueKey((household.id, household.provider)),
                  household: household,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: _DetailTile(
                  icon: Icons.event_outlined,
                  label: 'Billing cycle',
                  value: billingDay == null ? null : 'Day $billingDay',
                  unit: 'of the month',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MeterChip extends StatelessWidget {
  final String meter;

  const _MeterChip({required this.meter});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: LandingColors.primary.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: LandingColors.primary.withValues(alpha: 0.25),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.speed_rounded, size: 15, color: LandingColors.primary),
          const SizedBox(width: 6),
          Text(
            'Meter $meter',
            style: TextStyle(
              color: LandingColors.primary,
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _HouseholdRateTile extends StatefulWidget {
  const _HouseholdRateTile({super.key, required this.household});

  final Household household;

  @override
  State<_HouseholdRateTile> createState() => _HouseholdRateTileState();
}

class _HouseholdRateTileState extends State<_HouseholdRateTile> {
  late final Future<ProviderRate>? _rate;

  @override
  void initState() {
    super.initState();
    final household = widget.household;
    final id = household.id;
    _rate = id != null && !household.isSample && household.provider.isNotEmpty
        ? ApiService.getCurrentElectricityRate(id)
        : null;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<ProviderRate>(
      future: _rate,
      builder: (context, snapshot) {
        final rate = snapshot.data;
        final error = snapshot.error;
        final tile = _DetailTile(
          icon: Icons.payments_outlined,
          label: 'Rate per kWh',
          value: rate == null ? null : _formatRate(rate.ratePerKwh),
          unit: 'per kWh',
          missingLabel: switch (snapshot.connectionState) {
            ConnectionState.waiting => 'Loading…',
            _
                when error is ApiException &&
                    error.code != 'RATE_NOT_FOUND' &&
                    error.code != 'PROVIDER_NOT_CONFIGURED' =>
              'Could not load rate',
            _ => 'Rate unavailable',
          },
        );
        if (rate == null) return tile;
        final date = MaterialLocalizations.of(context)
            .formatMediumDate(rate.effectiveDate);
        return Tooltip(message: 'Effective $date', child: tile);
      },
    );
  }
}

/// One household detail: small icon and label on top, a prominent value below.
/// A null [value] shows a muted "Not set".
class _DetailTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? value;
  final String? unit;
  final String missingLabel;

  const _DetailTile({
    required this.icon,
    required this.label,
    required this.value,
    this.unit,
    this.missingLabel = 'Not set',
  });

  @override
  Widget build(BuildContext context) {
    final missing = value == null;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      decoration: AppEffects.insetDecoration(radius: AppRadius.card),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: LandingColors.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: LandingColors.textSecondary,
                    fontSize: AppText.caption,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (missing)
            Text(
              missingLabel,
              style: TextStyle(
                color: LandingColors.textSecondary,
                fontSize: 17,
                fontWeight: FontWeight.w600,
                height: 1.2,
              ),
            )
          else
            Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: value,
                    style: TextStyle(
                      color: LandingColors.textPrimary,
                      fontSize: 19,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.2,
                    ),
                  ),
                  if (unit != null)
                    TextSpan(
                      text: '  $unit',
                      style: TextStyle(
                        color: LandingColors.textSecondary,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                ],
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(height: 1.25),
            ),
        ],
      ),
    );
  }
}

/// A slim one-line note. Replaces the old "Preview" banner.
class _InfoNote extends StatelessWidget {
  final String text;

  const _InfoNote({required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        children: [
          Icon(
            Icons.info_outline_rounded,
            size: 16,
            color: LandingColors.textSecondary,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: LandingColors.textSecondary,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Household tools ─────────────────────────────────────────────────────────

/// Record Consumption as a full-width primary card, then the three other
/// tools in an equal row below it.
class _ToolGrid extends StatelessWidget {
  final VoidCallback onRecord;
  final VoidCallback onHistory;
  final VoidCallback onMonitoring;
  final VoidCallback onForecast;

  const _ToolGrid({
    required this.onRecord,
    required this.onHistory,
    required this.onMonitoring,
    required this.onForecast,
  });

  @override
  Widget build(BuildContext context) {
    const gap = 16.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _PrimaryToolCard(
          icon: Icons.edit_note_rounded,
          title: 'Record Consumption',
          description:
              'Enter your previous and current meter readings to keep your '
              'usage, forecast and bill up to date.',
          actionLabel: 'Record readings',
          onTap: onRecord,
        ),
        const SizedBox(height: gap),
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: _ToolCard(
                  icon: Icons.history_rounded,
                  accent: AppAccent.purple,
                  title: 'Usage History',
                  description:
                      'Browse past readings and how much you used each period.',
                  onTap: onHistory,
                ),
              ),
              const SizedBox(width: gap),
              Expanded(
                child: _ToolCard(
                  icon: Icons.show_chart_rounded,
                  accent: AppAccent.green,
                  title: 'Usage Monitoring',
                  description:
                      'Follow your electricity usage trends over time.',
                  onTap: onMonitoring,
                ),
              ),
              const SizedBox(width: gap),
              Expanded(
                child: _ToolCard(
                  icon: Icons.auto_graph_rounded,
                  accent: AppAccent.orange,
                  title: 'Forecast & Bill',
                  description: 'See projected usage and an estimated bill for this cycle.',
                  onTap: onForecast,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// The primary action: a full-width blue card with a clear call to action.
class _PrimaryToolCard extends StatefulWidget {
  final IconData icon;
  final String title;
  final String description;
  final String actionLabel;
  final VoidCallback onTap;

  const _PrimaryToolCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.actionLabel,
    required this.onTap,
  });

  @override
  State<_PrimaryToolCard> createState() => _PrimaryToolCardState();
}

class _PrimaryToolCardState extends State<_PrimaryToolCard> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(LandingRadius.card);
    final onPrimary = LandingColors.onPrimary;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        curve: Curves.easeOut,
        transform: Matrix4.translationValues(0, _hover ? -3 : 0, 0),
        decoration: BoxDecoration(
          gradient: LandingColors.primaryGradient,
          borderRadius: radius,
          boxShadow: [
            BoxShadow(
              color: LandingColors.primary.withValues(alpha: 0.22),
              blurRadius: 24,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: radius,
            onTap: widget.onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 26),
              child: Row(
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: onPrimary.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: onPrimary.withValues(alpha: 0.28),
                      ),
                    ),
                    child: Icon(widget.icon, color: onPrimary, size: 34),
                  ),
                  const SizedBox(width: 22),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.title,
                          style: TextStyle(
                            color: onPrimary,
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.3,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          widget.description,
                          style: TextStyle(
                            color: onPrimary.withValues(alpha: 0.9),
                            fontSize: 14.5,
                            height: 1.45,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 24),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 13,
                    ),
                    decoration: BoxDecoration(
                      color: onPrimary,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          widget.actionLabel,
                          style: TextStyle(
                            color: LandingColors.primary,
                            fontSize: 14.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(
                          Icons.arrow_forward_rounded,
                          size: 18,
                          color: LandingColors.primary,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// A tappable card for one secondary tool. The whole card is the tap target.
class _ToolCard extends StatefulWidget {
  final IconData icon;
  final AppAccent accent;
  final String title;
  final String description;
  final VoidCallback onTap;

  const _ToolCard({
    required this.icon,
    required this.accent,
    required this.title,
    required this.description,
    required this.onTap,
  });

  @override
  State<_ToolCard> createState() => _ToolCardState();
}

class _ToolCardState extends State<_ToolCard> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final color = widget.accent.color;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        curve: Curves.easeOut,
        transform: Matrix4.translationValues(0, _hover ? -3 : 0, 0),
        child: GlassCard(
          blur: 0,
          padding: EdgeInsets.zero,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(LandingRadius.card),
              onTap: widget.onTap,
              child: Padding(
                padding: const EdgeInsets.all(22),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: widget.accent.tint,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: color.withValues(alpha: 0.22),
                            ),
                          ),
                          child: Icon(widget.icon, color: color, size: 26),
                        ),
                        const Spacer(),
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 160),
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: _hover
                                ? color
                                : color.withValues(alpha: 0.10),
                          ),
                          child: Icon(
                            Icons.arrow_forward_rounded,
                            size: 17,
                            color: _hover ? Colors.white : color,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      widget.title,
                      style: TextStyle(
                        color: LandingColors.textPrimary,
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      widget.description,
                      style: TextStyle(
                        color: LandingColors.textSecondary,
                        fontSize: 13.5,
                        height: 1.45,
                      ),
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
