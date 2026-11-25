import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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

/// Record Consumption.
/// Sends meter readings or the billed kWh for a month to the backend.
/// The backend calculates kWh for meter readings using the saved baseline.
/// On success the screen closes and returns `true`.
class RecordConsumptionScreen extends StatefulWidget {
  final Household household;

  const RecordConsumptionScreen({super.key, required this.household});

  @override
  State<RecordConsumptionScreen> createState() =>
      _RecordConsumptionScreenState();
}

enum _RecordMode { meter, direct }

class _RecordConsumptionScreenState extends State<RecordConsumptionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _currentFieldKey = GlobalKey<FormFieldState<String>>();

  final _dateCtrl = TextEditingController();
  final _previousDateCtrl = TextEditingController();
  final _previousCtrl = TextEditingController();
  final _currentCtrl = TextEditingController();
  final _monthCtrl = TextEditingController();
  final _directKwhCtrl = TextEditingController();

  // The date the user picked. Starts as today.
  late DateTime _selectedDate;
  late DateTime _billingMonth;
  DateTime? _previousDate;
  _RecordMode _mode = _RecordMode.meter;
  bool get _isMeter => _mode == _RecordMode.meter;

  // True while the reading is being sent (shows "Saving…").
  bool _isSaving = false;
  bool _validateEdits = false;

  // True while the last saved reading is being loaded.
  bool _isLoadingPrevious = true;

  MeterReading? _lastReading;
  String? _historyError;

  // A message from the last failed save. Shown on the form until the next try.
  String? _submitError;

  @override
  void initState() {
    super.initState();
    _selectedDate = _dateOnly(DateTime.now());
    _dateCtrl.text = _displayDate(_selectedDate);
    _billingMonth = DateTime(_selectedDate.year, _selectedDate.month);
    _monthCtrl.text = _displayMonth(_billingMonth);
    _loadPreviousReading();
  }

  @override
  void dispose() {
    _dateCtrl.dispose();
    _previousDateCtrl.dispose();
    _previousCtrl.dispose();
    _currentCtrl.dispose();
    _monthCtrl.dispose();
    _directKwhCtrl.dispose();
    super.dispose();
  }

  // ── Actions ───────────────────────────────────────────────────────────────

  /// Loads the baseline before allowing submission in Meter Reading mode.
  Future<void> _loadPreviousReading() async {
    final householdId = widget.household.id;

    // A household without a server ID has no saved readings to look up.
    if (householdId == null) {
      setState(() => _isLoadingPrevious = false);
      return;
    }

    setState(() {
      _isLoadingPrevious = true;
      _historyError = null;
    });
    try {
      final last = await ApiService.getLatestMeterReading(householdId);

      if (!mounted) return;

      setState(() {
        _isLoadingPrevious = false;

        _lastReading = last;
        if (last != null) {
          _previousCtrl.text = last.value.toStringAsFixed(2);
          _previousDate = last.date;
          _previousDateCtrl.text = _displayDate(last.date);
        }
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoadingPrevious = false;
        _historyError = e.message;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoadingPrevious = false;
        _historyError = 'Could not load your last meter reading.';
      });
    }
  }

  /// Opens the calendar and saves the chosen date.
  /// The calendar uses the app's current theme (light or dark).
  Future<void> _pickDate() async {
    final today = _dateOnly(DateTime.now());

    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate.isAfter(today) ? today : _selectedDate,
      firstDate: DateTime(2020),
      lastDate: today,
      helpText: 'Select reading date',
    );

    if (picked == null || !mounted) return;

    setState(() {
      _selectedDate = _dateOnly(picked);
      _dateCtrl.text = _displayDate(_selectedDate);
    });
  }

  Future<void> _pickPreviousDate() async {
    final latestAllowed = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day - 1,
    );
    final previous = _previousDate;
    final picked = await showDatePicker(
      context: context,
      initialDate: previous != null && !previous.isAfter(latestAllowed)
          ? previous
          : latestAllowed,
      firstDate: DateTime(1900),
      lastDate: latestAllowed,
      helpText: 'Select previous reading date',
    );
    if (picked == null || !mounted) return;
    setState(() {
      _previousDate = _dateOnly(picked);
      _previousDateCtrl.text = _displayDate(_previousDate!);
    });
  }

  Future<void> _pickBillingMonth() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _billingMonth,
      firstDate: DateTime(1900),
      lastDate: _dateOnly(DateTime.now()),
      helpText: 'Select a date in the billing month',
    );
    if (picked == null || !mounted) return;
    setState(() {
      _billingMonth = DateTime(picked.year, picked.month);
      _monthCtrl.text = _displayMonth(_billingMonth);
    });
  }

  /// When the previous reading changes, re-check the current reading (it must
  /// be higher), but only if the user has already typed something there.
  void _onPreviousChanged(String _) {
    if (_currentCtrl.text.trim().isNotEmpty) {
      _currentFieldKey.currentState?.validate();
    }
  }

  /// Checks the form, sends the reading to the backend and handles the result.
  Future<void> _submit() async {
    // Stops double taps and a second Enter key press while saving.
    if (_isSaving || (_isMeter && _meterHistoryPending)) return;
    if (!_validateEdits) setState(() => _validateEdits = true);
    if (!(_formKey.currentState?.validate() ?? false)) return;

    // Sample or unsaved households have no server ID.
    final householdId = widget.household.id;
    if (householdId == null) {
      setState(() {
        _submitError =
            'This household is not saved on the server yet, so readings '
            'cannot be recorded for it.';
      });
      return;
    }

    setState(() {
      _isSaving = true;
      _submitError = null;
    });

    try {
      final double? kwh;
      if (_isMeter) {
        final result = await ApiService.recordConsumption(
          householdId: householdId,
          consumptionDate: _selectedDate,
          previousReadingDate: _previousDate!,
          meterPrevious: double.parse(_previousCtrl.text.trim()),
          meterCurrent: double.parse(_currentCtrl.text.trim()),
        );
        final savedKwh = result['kwh'];
        kwh = savedKwh is num
            ? savedKwh.toDouble()
            : double.tryParse('$savedKwh');
      } else {
        final result = await ApiService.recordMonthlyConsumption(
          householdId: householdId,
          billingMonth: _billingMonth,
          consumptionKwh: double.parse(_directKwhCtrl.text.trim()),
        );
        kwh = result.kwh;
      }

      if (!mounted) return;

      // Confirm the save with the shared centered popup, then go back.
      // The form stays disabled while the popup is open.
      await showSuccessPopup(
        context,
        message: 'Consumption recorded successfully.',
        kwh: kwh,
      );

      if (!mounted) return;

      // Go back to the household dashboard.
      Navigator.of(context).pop(true);
    } on ApiException catch (e) {
      // Friendly backend message. The user stays on the form to fix it.
      // This includes an expired or missing login (401).
      if (!mounted) return;
      setState(() {
        _isSaving = false;
        _submitError = e.message;
      });
      if (_isMeter &&
          (e.code == 'METER_SEQUENCE_MISMATCH' ||
              e.code == 'DUPLICATE_CONSUMPTION_RECORD' ||
              e.code == 'INVALID_READING_DATE')) {
        await _loadPreviousReading();
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isSaving = false;
        _submitError = 'Something went wrong. Please try again.';
      });
    }
  }

  /// Leaves the screen without saving.
  void _cancel() => Navigator.of(context).pop();

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
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
                          label: widget.household.name,
                          onPressed: _cancel,
                        ),
                        const SizedBox(height: 8),
                        _buildHeader(),
                        const SizedBox(height: 24),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(child: _buildFormCard()),
                            const SizedBox(width: 24),
                            SizedBox(width: 320, child: _buildSidePanel()),
                          ],
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

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Record Consumption',
          style: TextStyle(
            color: LandingColors.textPrimary,
            fontSize: AppText.pageTitle,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.4,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          _isMeter
              ? 'Enter the readings from your electricity meter for '
                    '${widget.household.name}.'
              : 'Enter the monthly kWh from the bill for '
                    '${widget.household.name}.',
          style: TextStyle(
            color: LandingColors.textSecondary,
            fontSize: AppText.body + 1,
            height: 1.5,
          ),
        ),
      ],
    );
  }

  // ── Form card ─────────────────────────────────────────────────────────────

  /// Helper text under the previous reading field. It tells the user what
  /// happened with the automatic fill-in.
  String get _previousHelper {
    if (_isLoadingPrevious) return 'Loading your last saved reading…';
    if (_lastReading != null) return 'From your last saved reading';
    return 'Enter the reading you want to start from';
  }

  bool get _meterHistoryPending => _isLoadingPrevious || _historyError != null;

  Widget _buildFormCard() {
    return GlassCard(
      blur: 0,
      padding: const EdgeInsets.fromLTRB(28, 26, 28, 28),
      child: Form(
        key: _formKey,
        // Prefilling saved values must not show errors before the user submits.
        autovalidateMode: _validateEdits
            ? AutovalidateMode.onUserInteraction
            : AutovalidateMode.disabled,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: IgnorePointer(
                ignoring: _isSaving,
                child: AppPillTabs(
                  labels: const ['Meter Reading', 'Direct kWh'],
                  selected: _mode.index,
                  onChanged: (index) => setState(() {
                    _mode = _RecordMode.values[index];
                    _validateEdits = false;
                    _submitError = null;
                  }),
                ),
              ),
            ),
            const SizedBox(height: 22),
            if (_isMeter) ..._meterFields() else ..._directFields(),
            if (_submitError != null) ...[
              const SizedBox(height: 16),
              _ErrorBanner(message: _submitError!),
            ],
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton(
                  onPressed: _isSaving ? null : _cancel,
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(0, 52),
                    padding: const EdgeInsets.symmetric(horizontal: 28),
                  ),
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  onPressed: _isSaving || (_isMeter && _meterHistoryPending)
                      ? null
                      : _submit,
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(0, 52),
                    padding: const EdgeInsets.symmetric(horizontal: 28),
                    textStyle: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  icon: _isSaving
                      ? SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: LandingColors.onPrimary,
                          ),
                        )
                      : const Icon(Icons.check_rounded, size: 20),
                  label: Text(_isSaving ? 'Saving…' : 'Record Consumption'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _meterFields() => [
    const _StepHeader(
      number: 1,
      title: 'Reading dates',
      subtitle: 'Choose the day you read the meter.',
    ),
    const SizedBox(height: 14),
    _readingFields(
      _dateField(
        controller: _dateCtrl,
        label: 'Consumption date',
        onTap: _pickDate,
        validator: (_) {
          final lastDate = _lastReading?.date;
          if (lastDate != null && !_selectedDate.isAfter(lastDate)) {
            return 'Choose a date after ${_displayDate(lastDate)}';
          }
          return null;
        },
      ),
      _dateField(
        controller: _previousDateCtrl,
        label: 'Previous reading date',
        onTap: _meterHistoryPending || _lastReading != null
            ? null
            : _pickPreviousDate,
        validator: (_) {
          if (_lastReading != null) return null;
          final previous = _previousDate;
          if (previous == null) return 'Choose the previous reading date';
          if (!previous.isBefore(_selectedDate)) {
            return 'Must be before the consumption date';
          }
          return null;
        },
      ),
    ),
    if (_historyError case final error?) ...[
      const SizedBox(height: 14),
      _ErrorBanner(message: error),
      Align(
        alignment: Alignment.centerLeft,
        child: TextButton(
          onPressed: _loadPreviousReading,
          child: const Text('Retry meter history'),
        ),
      ),
    ],
    ..._sectionDivider(),
    const _StepHeader(
      number: 2,
      title: 'Meter readings',
      subtitle:
          'Type the numbers shown on your meter. The current reading '
          'must be higher than the previous one.',
    ),
    const SizedBox(height: 14),
    _readingFields(
      _meterField(
        controller: _previousCtrl,
        label: 'Previous meter reading',
        hint: 'e.g. 211.00',
        helper: _previousHelper,
        icon: Icons.speed_outlined,
        validator: _validatePrevious,
        onChanged: _onPreviousChanged,
        readOnly: _meterHistoryPending || _lastReading != null,
      ),
      _meterField(
        fieldKey: _currentFieldKey,
        controller: _currentCtrl,
        label: 'Current meter reading',
        hint: 'e.g. 223.50',
        helper: 'The reading on your meter now',
        icon: Icons.bolt_rounded,
        validator: _validateCurrent,
        last: true,
      ),
    ),
    const SizedBox(height: 22),
    _buildUsagePreview(),
  ];

  List<Widget> _directFields() => [
    const _StepHeader(
      number: 1,
      title: 'Billing month',
      subtitle: 'Choose the month shown on your electricity bill.',
    ),
    const SizedBox(height: 14),
    Align(
      alignment: Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 320),
        child: _dateField(
          controller: _monthCtrl,
          label: 'Billing month',
          onTap: _pickBillingMonth,
        ),
      ),
    ),
    ..._sectionDivider(),
    const _StepHeader(
      number: 2,
      title: 'Billed consumption',
      subtitle: 'Enter the total kWh for the billing month.',
    ),
    const SizedBox(height: 14),
    _meterField(
      controller: _directKwhCtrl,
      label: 'Consumption in kWh',
      hint: 'e.g. 125.50',
      helper: 'Total consumption shown on your bill',
      icon: Icons.bolt_rounded,
      validator: _validateDirectKwh,
      last: true,
    ),
  ];

  List<Widget> _sectionDivider() => [
    const SizedBox(height: 26),
    Divider(color: LandingColors.border, height: 1),
    const SizedBox(height: 22),
  ];

  Widget _readingFields(Widget first, Widget second) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 480) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [first, const SizedBox(height: 14), second],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: first),
            const SizedBox(width: 16),
            Expanded(child: second),
          ],
        );
      },
    );
  }

  Widget _dateField({
    required TextEditingController controller,
    required String label,
    required VoidCallback? onTap,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      readOnly: true,
      canRequestFocus: onTap != null && !_isSaving,
      onTap: _isSaving ? null : onTap,
      validator: validator,
      style: TextStyle(
        color: LandingColors.textPrimary,
        fontSize: AppText.body,
      ),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(
          Icons.event_outlined,
          size: 18,
          color: LandingColors.textSecondary,
        ),
        suffixIcon: onTap == null
            ? null
            : Icon(
                Icons.calendar_month_outlined,
                size: 18,
                color: LandingColors.primary,
              ),
      ),
    );
  }

  /// Shows the kWh that the two readings add up to, as the user types.
  /// The backend still does the real calculation when the reading is saved.
  Widget _buildUsagePreview() {
    return ListenableBuilder(
      listenable: Listenable.merge([_previousCtrl, _currentCtrl]),
      builder: (context, _) {
        final previous = double.tryParse(_previousCtrl.text.trim());
        final current = double.tryParse(_currentCtrl.text.trim());
        final usage =
            (previous != null && current != null && current > previous)
            ? current - previous
            : null;
        final ready = usage != null;

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          decoration: BoxDecoration(
            color: ready
                ? LandingColors.primary.withValues(alpha: 0.08)
                : LandingColors.backgroundSoft,
            borderRadius: BorderRadius.circular(LandingRadius.control),
            border: Border.all(
              color: ready
                  ? LandingColors.primary.withValues(alpha: 0.30)
                  : LandingColors.border,
            ),
          ),
          child: Row(
            children: [
              Icon(
                Icons.calculate_outlined,
                size: 22,
                color: ready
                    ? LandingColors.primary
                    : LandingColors.textSecondary,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  ready
                      ? 'Electricity used for this reading'
                      : 'Enter both readings to see the kWh used '
                            '(current minus previous).',
                  style: TextStyle(
                    color: ready
                        ? LandingColors.textPrimary
                        : LandingColors.textSecondary,
                    fontSize: AppText.body,
                    fontWeight: ready ? FontWeight.w600 : FontWeight.w400,
                    height: 1.4,
                  ),
                ),
              ),
              if (usage != null) ...[
                const SizedBox(width: 12),
                Text(
                  '${usage.toStringAsFixed(2)} kWh',
                  style: TextStyle(
                    color: LandingColors.primary,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.2,
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  /// A meter reading field: numbers only, up to 2 decimal places.
  Widget _meterField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required String helper,
    required IconData icon,
    required String? Function(String?) validator,
    GlobalKey<FormFieldState<String>>? fieldKey,
    ValueChanged<String>? onChanged,
    bool readOnly = false,
    bool last = false,
  }) {
    return TextFormField(
      key: fieldKey,
      controller: controller,
      validator: validator,
      onChanged: onChanged,
      enabled: !_isSaving,
      readOnly: readOnly,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
      ],
      textInputAction: last ? TextInputAction.done : TextInputAction.next,
      onFieldSubmitted: last ? (_) => _submit() : null,
      style: TextStyle(
        color: LandingColors.textPrimary,
        fontSize: 16,
        fontWeight: FontWeight.w600,
      ),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        helperText: helper,
        helperMaxLines: 2,
        errorMaxLines: 2,
        suffixText: 'kWh',
        prefixIcon: Icon(icon, size: 18, color: LandingColors.textSecondary),
      ),
    );
  }

  // ── Side panel ────────────────────────────────────────────────────────────

  Widget _buildSidePanel() {
    final meter = widget.household.meterNumber?.trim();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        GlassCard(
          blur: 0,
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              const AppIconBadge(icon: Icons.home_rounded, size: 44),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Recording for',
                      style: TextStyle(
                        color: LandingColors.textSecondary,
                        fontSize: AppText.caption,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      widget.household.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: LandingColors.textPrimary,
                        fontSize: AppText.cardTitle + 1,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (meter != null && meter.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        'Meter $meter',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: LandingColors.textSecondary,
                          fontSize: AppText.caption + 0.5,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        GlassCard(
          blur: 0,
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _isMeter
                    ? 'Tips for accurate readings'
                    : 'Tips for bill entries',
                style: TextStyle(
                  color: LandingColors.textPrimary,
                  fontSize: AppText.cardTitle,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12),
              if (_isMeter) ...const [
                _Tip(text: 'Use the number shown on your electricity meter.'),
                _Tip(
                  text: 'The previous value and date come from your last saved reading.',
                ),
                _Tip(
                  text: 'The current reading must be higher than the previous.',
                ),
              ] else ...const [
                _Tip(text: 'Use the billed kWh total for the selected month.'),
                _Tip(text: 'Only one Direct kWh entry can be saved per month.'),
              ],
              const _Tip(text: 'You can use up to 2 decimal places.'),
            ],
          ),
        ),
      ],
    );
  }

  // ── Validation ────────────────────────────────────────────────────────────

  String? _validatePrevious(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return 'Enter the previous meter reading';

    final number = double.tryParse(text);
    if (number == null) return 'Enter a valid number, e.g. 211.00';
    if (number < 0) return 'Reading cannot be negative';
    if (!number.isFinite || number > 9_999_999_999.99) {
      return 'Reading exceeds the supported range';
    }
    return null;
  }

  String? _validateCurrent(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return 'Enter the current meter reading';

    final current = double.tryParse(text);
    if (current == null) return 'Enter a valid number, e.g. 223.50';
    if (current < 0) return 'Reading cannot be negative';
    if (!current.isFinite || current > 9_999_999_999.99) {
      return 'Reading exceeds the supported range';
    }

    // The current reading must be higher than the previous one.
    final previous = double.tryParse(_previousCtrl.text.trim());
    if (previous != null && current <= previous) {
      return 'Must be higher than the previous reading '
          '(${previous.toStringAsFixed(2)})';
    }
    if (previous != null &&
        previous.isFinite &&
        ((current - previous) * 100).round() > 9_999_999_999) {
      return 'Consumption exceeds the supported range';
    }
    return null;
  }

  String? _validateDirectKwh(String? value) {
    final kwh = double.tryParse(value?.trim() ?? '');
    if (kwh == null || !kwh.isFinite || kwh < 0.01) {
      return 'Enter a consumption total of at least 0.01 kWh';
    }
    if (kwh > 99_999_999.99) return 'Consumption exceeds the supported range';
    return null;
  }

  // ── Date helpers ──────────────────────────────────────────────────────────

  /// Removes the time part so only the day is kept.
  DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  static const _months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];

  /// Friendly format for the screen, e.g. "Nov 1, 2026".
  String _displayDate(DateTime d) =>
      '${_months[d.month - 1]} ${d.day}, ${d.year}';

  String _displayMonth(DateTime d) => '${_months[d.month - 1]} ${d.year}';
}

// ── Small building blocks ───────────────────────────────────────────────────

/// A numbered heading for one part of the form.
class _StepHeader extends StatelessWidget {
  final int number;
  final String title;
  final String subtitle;

  const _StepHeader({
    required this.number,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 28,
          height: 28,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: LandingColors.primary.withValues(alpha: 0.12),
          ),
          child: Text(
            '$number',
            style: TextStyle(
              color: LandingColors.primary,
              fontSize: 13,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: LandingColors.textPrimary,
                  fontSize: AppText.cardTitle + 1,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(
                  color: LandingColors.textSecondary,
                  fontSize: 13,
                  height: 1.45,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// One line in the tips list.
class _Tip extends StatelessWidget {
  final String text;

  const _Tip({required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 1),
            child: Icon(
              Icons.check_circle_outline_rounded,
              size: 16,
              color: LandingColors.primary,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: LandingColors.textSecondary,
                fontSize: 13,
                height: 1.45,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// A message shown on the form when saving fails.
class _ErrorBanner extends StatelessWidget {
  final String message;

  const _ErrorBanner({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: LandingColors.danger.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(LandingRadius.control),
        border: Border.all(color: LandingColors.danger.withValues(alpha: 0.35)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.error_outline_rounded,
            size: 18,
            color: LandingColors.danger,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: LandingColors.textPrimary,
                fontSize: 13.5,
                height: 1.45,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
