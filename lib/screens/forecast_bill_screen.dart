
import 'package:flutter/material.dart';

import '../landing/landing_widgets.dart'
    show
        LandingCard,
        LandingContainer,
        LandingPrimaryButton,
        LandingSecondaryButton,
        LandingStatTile;
import '../models/forecast_result.dart';
import '../models/household.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../theme/app_tokens.dart';
import '../theme/landing_colors.dart';
import '../widgets/app_back_link.dart';
import '../widgets/app_top_bar.dart';
import 'record_consumption_screen.dart';

/// Forecast & Bill.
///
/// Shows the current bill estimate, projected month-end bill,
/// and the existing XGBoost next-month forecast.
class ForecastBillScreen extends StatefulWidget {
  final Household household;

  const ForecastBillScreen({super.key, required this.household});

  @override
  State<ForecastBillScreen> createState() => _ForecastBillScreenState();
}

class _ForecastBillScreenState extends State<ForecastBillScreen> {
  // ── XGBoost forecast state ───────────────────────────────────────────────

  ForecastResult? _result;

  bool _isLoading = false;
  bool _notEnoughData = false;
  String? _errorMessage;

  // ── Current bill and projected bill state ────────────────────────────────

  bool _billLoading = true;
  String? _billError;
  bool _hasBillRecords = false;

  double _currentUsageKwh = 0;
  double _projectedUsageKwh = 0;
  double _currentBill = 0;
  double _projectedBill = 0;

  double _electricityRate = 0;
  String? _rateProvider;
  DateTime? _rateEffectiveDate;

  DateTime? _periodStart;
  DateTime? _nextPeriodStart;

  int _elapsedDays = 0;
  int _totalCycleDays = 0;

  @override
  void initState() {
    super.initState();
    _loadBillEstimates();
  }

  // ── Billing cycle calculations ──────────────────────────────────────────

  /// Returns the billing-cycle date for a particular month.
  ///
  /// If the selected day does not exist in that month, the last
  /// calendar day of the month is used.
  ///
  /// Example: cycle day 31 in February becomes February 28 or 29.
  DateTime _cycleDateForMonth(DateTime month, int cycleDay) {
    final daysInMonth = DateTime(month.year, month.month + 1, 0).day;

    final day = cycleDay < 1
        ? 1
        : cycleDay > daysInMonth
            ? daysInMonth
            : cycleDay;

    return DateTime(month.year, month.month, day);
  }

  /// Finds the current billing period's start and next start date.
  ///
  /// The current period starts on the most recent billing-cycle day
  /// that has already occurred.
  List<DateTime> _getBillingPeriod(DateTime today, int cycleDay) {
    final thisMonthStart = _cycleDateForMonth(today, cycleDay);

    final start = today.isBefore(thisMonthStart)
        ? _cycleDateForMonth(
            DateTime(today.year, today.month - 1, 1),
            cycleDay,
          )
        : thisMonthStart;

    final nextStart = _cycleDateForMonth(
      DateTime(start.year, start.month + 1, 1),
      cycleDay,
    );

    return [start, nextStart];
  }

  /// Loads daily meter readings for the current billing period.
  ///
  /// Direct monthly kWh entries are intentionally not included here.
  Future<void> _loadBillEstimates() async {
    final householdId = widget.household.id;
    final cycleDay = widget.household.billingCycleDay;

    if (householdId == null) return;

    setState(() {
      _billLoading = true;
      _billError = null;
      _hasBillRecords = false;
    });

    try {
      final rateData =
          await ApiService.getCurrentElectricityRate(householdId);

      final rateValue = rateData['rate_per_kwh'];
      final rate = rateValue is num
          ? rateValue.toDouble()
          : double.tryParse(rateValue.toString());

      if (rate == null || rate <= 0) {
        throw const ApiException(
          'The server returned an invalid electricity rate.',
        );
      }

      final provider = rateData['provider']?.toString();
      final effectiveDate = DateTime.tryParse(
        rateData['effective_date']?.toString() ?? '',
      );

      if (!mounted) return;

      setState(() {
        _electricityRate = rate;
        _rateProvider = provider;
        _rateEffectiveDate = effectiveDate;
      });  



      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);

      final period = _getBillingPeriod(today, cycleDay);
      final start = period[0];
      final nextStart = period[1];

      final records = await ApiService.getConsumptionHistory(
        householdId,
        startDate: start,
        endDate: today,
      );

      if (!mounted) return;

      // Only include records inside the current billing period.
      final currentRecords = records.where((record) {
        return !record.date.isBefore(start) &&
            !record.date.isAfter(today);
      }).toList();

      double totalKwh = 0;

      for (final record in currentRecords) {
        final previousDate = record.previousReadingDate;

        // Keep the full usage for older records without a saved
        // previous reading date.
        if (previousDate == null) {
          totalKwh += record.kwh;
          continue;
        }

        // Calculate the number of days between meter readings.
        final intervalDays = record.date.difference(previousDate).inDays;

        if (intervalDays <= 0) continue;

        // Find the portion of the reading interval inside
        // the current billing period.
        final overlapStart = previousDate.add(const Duration(days: 1)).isAfter(start)
            ? previousDate.add(const Duration(days: 1))
            : start;

        final overlapEnd = record.date.isBefore(today) ? record.date : today;

        if (overlapStart.isAfter(overlapEnd)) continue;

        final overlapDays = overlapEnd.difference(overlapStart).inDays + 1;

        // Estimate consumption proportionally across the interval.
        final proratedKwh = record.kwh * overlapDays / intervalDays;

        totalKwh += proratedKwh;
      }

      final elapsedDays = today.difference(start).inDays + 1;
      final totalCycleDays = nextStart.difference(start).inDays;

      if (currentRecords.isEmpty || elapsedDays <= 0 || totalCycleDays <= 0) {
        setState(() {
          _billLoading = false;
          _hasBillRecords = false;
          _periodStart = start;
          _nextPeriodStart = nextStart;
          _elapsedDays = elapsedDays;
          _totalCycleDays = totalCycleDays;
        });
        return;
      }

      // Current estimate: actual recorded consumption multiplied by rate.
      final currentBill = totalKwh * rate;

      // Projected usage: average daily consumption multiplied by
      // the total number of days in the billing cycle.
      final averageDailyKwh = totalKwh / elapsedDays;
      final projectedKwh = averageDailyKwh * totalCycleDays;
      final projectedBill = projectedKwh * rate;

      setState(() {
        _billLoading = false;
        _hasBillRecords = true;

        _currentUsageKwh = totalKwh;
        _projectedUsageKwh = projectedKwh;
        _currentBill = currentBill;
        _projectedBill = projectedBill;

        _periodStart = start;
        _nextPeriodStart = nextStart;

        _elapsedDays = elapsedDays;
        _totalCycleDays = totalCycleDays;
      });
    } on ApiException catch (e) {
      if (!mounted) return;

      setState(() {
        _billLoading = false;
        _billError = e.message;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _billLoading = false;
        _billError = 'Could not load your current billing information.';
      });
    }
  }

  // ── XGBoost forecast ──────────────────────────────────────────────────────

  /// Asks the backend for the existing next-month forecast.
  Future<void> _generate() async {
    final id = widget.household.id;

    if (id == null || _isLoading) return;

    setState(() {
      _isLoading = true;
      _notEnoughData = false;
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

        if (e.code == 'INSUFFICIENT_HISTORICAL_DATA') {
          _notEnoughData = true;
        } else {
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

  /// Opens Record Consumption.
  /// Refreshes the bill estimates when the user returns.
  Future<void> _openRecordConsumption() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => RecordConsumptionScreen(
          household: widget.household,
        ),
      ),
    );

    if (mounted) {
      _loadBillEstimates();
    }
  }

  void _goBack() => Navigator.of(context).pop();

  // ── Formatting helpers ───────────────────────────────────────────────────

  String _formatForecastMonth(String value) {
    final parts = value.split('-');

    if (parts.length != 2) return value;

    final year = int.tryParse(parts[0]);
    final month = int.tryParse(parts[1]);

    if (year == null || month == null || month < 1 || month > 12) {
      return value;
    }

    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];

    return '${months[month - 1]} $year';
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '';

    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];

    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
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

                        // New current billing estimates.
                        _buildBillEstimateSection(),

                        const SizedBox(height: AppSpacing.xl),

                        // Existing XGBoost forecast.
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
          'View your current bill estimate, projected billing cost, '
          'and next month\'s electricity forecast for '
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

  // ── Current bill and projected bill UI ───────────────────────────────────

  Widget _buildBillEstimateSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Current Billing Estimates',
          style: TextStyle(
            color: LandingColors.textPrimary,
            fontSize: AppText.sectionTitle,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          'Based on your daily meter-reading records and household '
          'electricity rate.',
          style: TextStyle(
            color: LandingColors.textSecondary,
            fontSize: AppText.body,
            height: 1.5,
          ),
        ),
        const SizedBox(height: AppSpacing.lg),

        if (_billLoading)
          const LandingCard(
            padding: EdgeInsets.all(28),
            child: Center(
              child: CircularProgressIndicator(),
            ),
          )
        else if (_billError != null)
          LandingCard(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                Icon(
                  Icons.error_outline_rounded,
                  size: 32,
                  color: LandingColors.primary,
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  _billError!,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: LandingColors.textSecondary,
                    fontSize: AppText.body,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                LandingSecondaryButton(
                  label: 'Refresh Estimates',
                  onPressed: _loadBillEstimates,
                ),
              ],
            ),
          )
        else if (!_hasBillRecords)
          LandingCard(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                Icon(
                  Icons.electric_meter_outlined,
                  size: 34,
                  color: LandingColors.primary,
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  'No meter readings for this billing period yet',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: LandingColors.textPrimary,
                    fontSize: AppText.cardTitle,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'Record your current meter reading to calculate '
                  'your current bill estimate and projected month-end bill.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: LandingColors.textSecondary,
                    fontSize: AppText.body,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                LandingPrimaryButton(
                  label: 'Record Consumption',
                  large: false,
                  onPressed: _openRecordConsumption,
                ),
              ],
            ),
          )
        else
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: LandingStatTile(
                      label: 'Current Bill Estimate',
                      value: _money(_currentBill),
                      caption:
                          '${_currentUsageKwh.toStringAsFixed(2)} kWh recorded',
                      highlight: true,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.lg),
                  Expanded(
                    child: LandingStatTile(
                      label: 'Projected Month-End Bill',
                      value: _money(_projectedBill),
                      caption:
                          '${_projectedUsageKwh.toStringAsFixed(2)} kWh projected',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              LandingCard(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Billing Period',
                      style: TextStyle(
                        color: LandingColors.textPrimary,
                        fontWeight: FontWeight.w700,
                        fontSize: AppText.body,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      '${_formatDate(_periodStart)} – '
                      '${_formatDate(_nextPeriodStart!.subtract(
                        const Duration(days: 1),
                      ))}',
                      style: TextStyle(
                        color: LandingColors.textSecondary,
                        fontSize: AppText.body,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      'Elapsed days: $_elapsedDays of $_totalCycleDays days',
                      style: TextStyle(
                        color: LandingColors.textSecondary,
                        fontSize: AppText.caption,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      'Electricity rate: ${_money(_electricityRate)} per kWh',
                      style: TextStyle(
                        color: LandingColors.textSecondary,
                        fontSize: AppText.caption,
                      ),
                    ),
                    Text(
                      '${_rateProvider ?? 'Provider unavailable'}'
                      '${_rateEffectiveDate != null ? ' • Effective ${_rateEffectiveDate!.toIso8601String().split('T').first}' : ''}',
                      style: TextStyle(
                        color: LandingColors.textSecondary,
                        fontSize: AppText.caption,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'The projected bill assumes your average daily electricity '
                'consumption continues for the rest of this billing period. '
                'Your actual bill may be different.',
                style: TextStyle(
                  color: LandingColors.textSecondary,
                  fontSize: AppText.caption,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              LandingSecondaryButton(
                label: 'Refresh Estimates',
                onPressed: _loadBillEstimates,
              ),
            ],
          ),
      ],
    );
  }

  // ── Existing XGBoost forecast UI ─────────────────────────────────────────

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

    if (_notEnoughData) {
      return _buildStateCard(
        icon: Icons.insights_outlined,
        title: 'Not enough readings yet',
        message:
            'A forecast needs at least 6 consecutive months of saved '
            'consumption records. Record your missing monthly consumption '
            'data, then come back and generate your forecast.',
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
        title: 'Could not generate forecast',
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
            'Generate a prediction for next month\'s electricity '
            'consumption and estimated bill using your saved monthly records.',
        action: LandingPrimaryButton(
          label: 'Generate Forecast',
          onPressed: _generate,
        ),
      );
    }

    return _buildResult(result);
  }

  Widget _buildResult(ForecastResult result) {
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
                caption: 'For ${_formatForecastMonth(result.forecastMonth)}',
              ),
            ),
            const SizedBox(width: AppSpacing.lg),
            Expanded(
              child: LandingStatTile(
                label: 'Estimated Bill',
                value: _money(result.estimatedBill),
                caption:
                    'Estimated cost for '
                    '${_formatForecastMonth(result.forecastMonth)}',
                highlight: true,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        Text(
          'This is an estimate made by the forecasting model. Your real '
          'use and bill may be different.',
          style: TextStyle(
            color: LandingColors.textSecondary,
            fontSize: AppText.caption,
            height: 1.5,
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        LandingSecondaryButton(
          label: 'Generate Again',
          onPressed: _generate,
        ),
      ],
    );
  }

  // ── Shared state card ────────────────────────────────────────────────────

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
        padding: const EdgeInsets.symmetric(
          horizontal: 28,
          vertical: 48,
        ),
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
              Icon(
                icon,
                size: 36,
                color: LandingColors.primary,
              ),
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

/// Formats an amount as pesos with commas.
String _money(double amount) {
  final parts = amount.toStringAsFixed(2).split('.');
  final whole = parts[0].replaceAllMapped(
    RegExp(r'\B(?=(\d{3})+(?!\d))'),
    (match) => ',',
  );

  return '₱$whole.${parts[1]}';
}
