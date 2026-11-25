import 'package:flutter/material.dart';

import '../landing/landing_widgets.dart'
    show
        LandingCard,
        LandingContainer,
        LandingPrimaryButton,
        LandingSecondaryButton,
        LandingStatTile;
import '../models/billing_cycle.dart';
import '../models/billing_data.dart';
import '../models/forecast_result.dart';
import '../models/household.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../theme/app_tokens.dart';
import '../theme/landing_colors.dart';
import '../widgets/app_back_link.dart';
import '../widgets/app_top_bar.dart';
import 'record_consumption_screen.dart';

typedef _BillEstimate = ({
  BillingCycle cycle,
  BillingUsage usage,
  ProviderRate rate,
});
typedef _BillLoad = ({_BillEstimate? estimate, Object? error});

/// Forecast & Bill.
/// Shows billing-cycle estimates from meter readings and an independent
/// next-month forecast from the backend.
class ForecastBillScreen extends StatefulWidget {
  final Household household;

  const ForecastBillScreen({super.key, required this.household});

  @override
  State<ForecastBillScreen> createState() => _ForecastBillScreenState();
}

class _ForecastBillScreenState extends State<ForecastBillScreen> {
  Future<_BillLoad>? _bill;

  // The forecast from the backend. Null until one is generated.
  ForecastResult? _result;

  // True while the backend is working.
  bool _isLoading = false;

  String? _historyMessage;
  bool _forecastRateMissing = false;

  // A friendly message for any other error.
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _bill = _loadBill();
  }

  String? get _missingBillSettings {
    final household = widget.household;
    if (household.id == null) {
      return 'Save this household to see bill estimates.';
    }
    final day = household.billingCycleDay;
    if (day == null || day < 1 || day > 31) {
      return 'This household has no billing cycle day configured.';
    }
    if (household.provider.trim().isEmpty) {
      return 'This household has no electricity provider configured.';
    }
    return null;
  }

  Future<_BillLoad>? _loadBill() => _missingBillSettings == null
      ? _fetchBill(widget.household.id!, widget.household.billingCycleDay!)
      : null;

  Future<_BillLoad> _fetchBill(int id, int billingDay) async {
    try {
      final today = DateTime.now();
      final cycle = BillingCycle.current(today, billingDay);
      final rate = await ApiService.getCurrentElectricityRate(id);
      final readings = await ApiService.getConsumptionHistory(
        id,
        startDate: cycle.start,
        endDate: today,
      );
      return (
        estimate: (
          cycle: cycle,
          usage: cycle.measuredUsage(readings, today),
          rate: rate,
        ),
        error: null,
      );
    } catch (error) {
      return (estimate: null, error: error);
    }
  }

  /// Asks the backend for a forecast.
  Future<void> _generate() async {
    final id = widget.household.id;

    // Ignore extra taps while a forecast is already being generated.
    if (id == null || _isLoading) return;

    setState(() {
      _isLoading = true;
      _historyMessage = null;
      _forecastRateMissing = false;
      _errorMessage = null;
    });

    try {
      final result = await ApiService.generateForecast(householdId: id);

      if (!mounted) return;

      setState(() {
        _result = result;
        _isLoading = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;

      setState(() {
        _result = null;
        _isLoading = false;
        if (e.code == 'INSUFFICIENT_HISTORICAL_DATA' ||
            e.code == 'INVALID_MONTHLY_HISTORY') {
          _historyMessage = e.message;
        } else {
          _forecastRateMissing = _isMissingRate(e);
          _errorMessage = e.message;
        }
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _result = null;
        _isLoading = false;
        _errorMessage = 'Something went wrong. Please try again.';
      });
    }
  }

  /// Reloads estimates if the user saved a reading from this screen.
  Future<void> _openRecordConsumption() async {
    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => RecordConsumptionScreen(household: widget.household),
      ),
    );
    if (!mounted || saved != true) return;
    setState(() {
      _bill = _loadBill();
      _result = null;
      _historyMessage = null;
      _errorMessage = null;
    });
  }

  bool _isMissingRate(ApiException error) =>
      error.code == 'RATE_NOT_FOUND' ||
      error.code == 'RATE_UNAVAILABLE' ||
      error.code == 'PROVIDER_NOT_CONFIGURED';

  /// Back link: returns to the household dashboard.
  void _goBack() => Navigator.of(context).pop();

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    // Same pattern as the other screens: the theme-aware light theme.
    return Theme(
      data: AppTheme.lightTheme,
      child: Scaffold(
        backgroundColor: LandingColors.backgroundSoft,
        body: Column(
          children: [
            const AppTopBar(),
            Expanded(
              child: SingleChildScrollView(
                child: LandingContainer(
                  maxWidth: 960,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 40),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AppBackLink(
                          label: widget.household.name,
                          onPressed: _goBack,
                        ),
                        const SizedBox(height: AppSpacing.md),
                        _buildHeader(),
                        const SizedBox(height: AppSpacing.xl),
                        _sectionTitle('Billing Cycle Estimates'),
                        const SizedBox(height: AppSpacing.md),
                        _buildBillEstimates(),
                        const SizedBox(height: AppSpacing.xl),
                        _sectionTitle('Monthly XGBoost Forecast'),
                        const SizedBox(height: AppSpacing.md),
                        _buildBody(),
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

  /// Title and short description.
  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Forecast & Bill',
          style: TextStyle(
            color: LandingColors.textPrimary,
            fontSize: AppText.pageTitle,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'See bill estimates and next-month electricity use for '
          '${widget.household.name}.',
          style: TextStyle(
            color: LandingColors.textSecondary,
            fontSize: AppText.body,
            height: 1.5,
          ),
        ),
      ],
    );
  }

  Widget _sectionTitle(String text) => Text(
    text,
    style: TextStyle(
      color: LandingColors.textPrimary,
      fontSize: AppText.sectionTitle,
      fontWeight: FontWeight.w700,
    ),
  );

  Widget _buildBillEstimates() {
    final missingSettings = _missingBillSettings;
    if (missingSettings != null) {
      return _buildStateCard(
        icon: Icons.event_outlined,
        title: 'Billing settings unavailable',
        message: missingSettings,
      );
    }

    return FutureBuilder<_BillLoad>(
      future: _bill,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildStateCard(
            title: 'Loading bill estimates…',
            message: 'Checking the provider rate and meter history.',
            loading: true,
          );
        }
        final bill = snapshot.data?.estimate;
        if (bill != null) {
          return _buildBillResult(bill.cycle, bill.usage, bill.rate);
        }
        final error = snapshot.data?.error;
        final rateMissing = error is ApiException && _isMissingRate(error);
        return _buildStateCard(
          icon: Icons.info_outline_rounded,
          title: rateMissing
              ? 'Provider rate unavailable'
              : 'Could not load bill estimates',
          message: error is ApiException ? error.message : 'Please try again.',
          action: LandingSecondaryButton(
            label: 'Retry Bill Estimates',
            onPressed: () => setState(() {
              _bill = _loadBill();
            }),
          ),
        );
      },
    );
  }

  Widget _buildBillResult(
    BillingCycle cycle,
    BillingUsage usage,
    ProviderRate rate,
  ) {
    final projected = usage.projectedKwh(cycle);
    if (projected == null) {
      return _buildStateCard(
        icon: Icons.speed_outlined,
        title: 'No dated meter intervals for this cycle',
        message: usage.hasUndatedReadings
            ? 'Some readings have no usable previous date. Add a new meter reading to estimate this cycle.'
            : 'Record meter readings to estimate charges for this cycle.',
        action: LandingPrimaryButton(
          label: 'Record Consumption',
          large: false,
          onPressed: _openRecordConsumption,
        ),
      );
    }

    final dates = MaterialLocalizations.of(context);
    final period =
        '${dates.formatShortDate(cycle.start)} – ${dates.formatShortDate(cycle.end)}';
    return SizedBox(
      width: double.infinity,
      child: LandingCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _caption('Cycle: $period'),
            const SizedBox(height: AppSpacing.md),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: LandingStatTile(
                    label: 'Current Estimated Bill',
                    value: _money(usage.kwh * rate.ratePerKwh),
                    caption:
                        '${usage.kwh.toStringAsFixed(2)} kWh recorded this cycle',
                  ),
                ),
                const SizedBox(width: AppSpacing.lg),
                Expanded(
                  child: LandingStatTile(
                    label: 'Projected Cycle Bill',
                    value: _money(projected * rate.ratePerKwh),
                    caption:
                        '${projected.toStringAsFixed(2)} kWh projected over ${cycle.days} days',
                    highlight: true,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            _caption(
              'Energy charges at ${_rateMoney(rate.ratePerKwh)}/kWh '
              '(effective ${dates.formatShortDate(rate.effectiveDate)}). '
              'Projection uses ${usage.coveredDays} days of recorded meter intervals.',
            ),
            if (usage.hasUndatedReadings) ...[
              const SizedBox(height: AppSpacing.sm),
              _caption(
                'Readings without a usable previous date were excluded.',
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _caption(String text) => Text(
    text,
    style: TextStyle(
      color: LandingColors.textSecondary,
      fontSize: AppText.caption,
      height: 1.5,
    ),
  );

  /// Chooses what to show: no server ID, loading, not enough data, error,
  /// the result, or the first "Generate Forecast" prompt.
  Widget _buildBody() {
    if (widget.household.id == null) {
      return _buildStateCard(
        icon: Icons.cloud_off_outlined,
        title: 'Not saved on the server yet',
        message:
            'This household is not saved on the server yet, so a forecast '
            'cannot be generated.',
      );
    }

    if (_isLoading) {
      return _buildStateCard(
        title: 'Generating your forecast…',
        message: 'This will only take a moment.',
        loading: true,
      );
    }

    if (_historyMessage != null) {
      return _buildStateCard(
        icon: Icons.insights_outlined,
        title: 'Monthly consumption history needed',
        message:
            '$_historyMessage Use Direct kWh to enter billed monthly totals.',
        action: LandingPrimaryButton(
          label: 'Record Consumption',
          large: false,
          onPressed: _openRecordConsumption,
        ),
      );
    }

    if (_errorMessage != null) {
      return _buildStateCard(
        icon: Icons.error_outline_rounded,
        title: _forecastRateMissing
            ? 'Forecast rate unavailable'
            : 'Could not generate forecast',
        message: _errorMessage!,
        action: LandingPrimaryButton(
          label: 'Try Again',
          large: false,
          onPressed: _generate,
        ),
      );
    }

    final result = _result;

    if (result == null) {
      return _buildStateCard(
        icon: Icons.auto_graph_rounded,
        title: 'Ready to forecast',
        message:
            'Predict next-month use and its estimated bill from at least '
            'six consecutive monthly Direct kWh entries.',
        action: LandingPrimaryButton(
          label: 'Generate Forecast',
          onPressed: _generate,
        ),
      );
    }

    return _buildResult(result);
  }

  /// The two result tiles, a short note and the Generate Again button.
  Widget _buildResult(ForecastResult result) {
    final month = result.month;
    final dates = MaterialLocalizations.of(context);
    final rate = result.ratePerKwh;
    final effectiveDate = result.rateEffectiveDate;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: LandingStatTile(
                label: 'Predicted Consumption',
                value: '${result.predictedKwh.toStringAsFixed(2)} kWh',
                caption: month == null
                    ? 'Next month'
                    : dates.formatMonthYear(month),
              ),
            ),
            const SizedBox(width: AppSpacing.lg),
            Expanded(
              child: LandingStatTile(
                label: 'Forecast Estimated Bill',
                value: _money(result.estimatedBill),
                caption: rate == null
                    ? 'Cost of the predicted consumption'
                    : '${_rateMoney(rate)}/kWh${effectiveDate == null ? '' : ' · Effective ${dates.formatShortDate(effectiveDate)}'}',
                highlight: true,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        _caption(
          result.rateMessage ?? 'This is an estimate made by the forecasting model. Your real use and bill may differ.',
        ),
        const SizedBox(height: AppSpacing.xl),
        LandingSecondaryButton(label: 'Generate Again', onPressed: _generate),
      ],
    );
  }

  /// One card for the idle, loading, not-enough-data, error and
  /// no-server-ID states.
  Widget _buildStateCard({
    required String title,
    required String message,
    IconData? icon,
    bool loading = false,
    Widget? action,
  }) {
    return SizedBox(
      width: double.infinity,
      child: LandingCard(
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 48),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (loading)
              SizedBox(
                width: 32,
                height: 32,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  color: LandingColors.primary,
                ),
              )
            else if (icon != null)
              Icon(icon, size: 36, color: LandingColors.primary),
            const SizedBox(height: AppSpacing.lg),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: LandingColors.textPrimary,
                fontSize: AppText.cardTitle,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: Text(
                message,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: LandingColors.textSecondary,
                  fontSize: AppText.body,
                  height: 1.5,
                ),
              ),
            ),
            if (action != null) ...[
              const SizedBox(height: AppSpacing.xl),
              action,
            ],
          ],
        ),
      ),
    );
  }
}

/// Formats an amount as pesos with commas, e.g. 1234.5 -> "₱1,234.50".
String _money(double amount) {
  final parts = amount.toStringAsFixed(2).split('.');
  final whole = parts[0].replaceAllMapped(
    RegExp(r'\B(?=(\d{3})+(?!\d))'),
    (match) => ',',
  );
  return '₱$whole.${parts[1]}';
}

String _rateMoney(double rate) =>
    '₱${rate.toStringAsFixed(4).replaceFirst(RegExp(r'0+$'), '').replaceFirst(RegExp(r'\.$'), '')}';
