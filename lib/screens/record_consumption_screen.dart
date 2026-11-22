import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../landing/landing_widgets.dart'
    show
        LandingCard,
        LandingContainer,
        LandingPrimaryButton,
        LandingSecondaryButton;
import '../models/household.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../theme/app_tokens.dart';
import '../theme/landing_colors.dart';
import '../widgets/app_back_link.dart';
import '../widgets/app_message.dart';
import '../widgets/app_top_bar.dart';
/// Record Consumption.
/// Allows the household to record electricity consumption using either:
/// 1. Meter Reading - enters previous and current meter readings.
/// 2. Direct kWh Entry - enters actual monthly consumption from the bill.
/// The backend stores the submitted consumption records.
/// On success, the screen closes and returns `true`.
class RecordConsumptionScreen extends StatefulWidget {
  final Household household;

  const RecordConsumptionScreen({super.key, required this.household});

  @override
  State<RecordConsumptionScreen> createState() =>
      _RecordConsumptionScreenState();
}

class _RecordConsumptionScreenState extends State<RecordConsumptionScreen> {
  final _formKey = GlobalKey<FormState>();

  final _dateCtrl = TextEditingController();
  final _previousDateCtrl = TextEditingController();
  final _previousCtrl = TextEditingController();
  final _currentCtrl = TextEditingController();

  final _billingMonthCtrl = TextEditingController();
  final _monthlyKwhCtrl = TextEditingController();

  // false = Meter Reading, true = Direct kWh Entry
  bool _useDirectKwhEntry = false;

  // Selected billing month for direct kWh entry
  late DateTime _selectedBillingMonth;

  // The date the user picked. Starts as today.
  late DateTime _selectedDate;

  // Date of the previous meter reading.
  DateTime? _previousReadingDate;

  // True if the previous reading date came from a saved reading.
  bool _previousDatePrefilled = false;

  // True while the reading is being sent (shows "Saving…").
  bool _isSaving = false;

  // True while the last saved reading is being loaded.
  bool _isLoadingPrevious = true;

  // True if the previous reading was filled in from a saved reading.
  bool _prefilled = false;

  // True if the household was checked and has no saved readings yet.
  bool _noSavedReadings = false;

  @override
  void initState() {
    super.initState();

    _selectedDate = _dateOnly(DateTime.now());

    _selectedBillingMonth = DateTime(
      DateTime.now().year,
      DateTime.now().month,
      1,
    );

    _billingMonthCtrl.text = _displayMonth(_selectedBillingMonth);
    _dateCtrl.text = _displayDate(_selectedDate);
    _loadPreviousReading();
  }

  @override
  void dispose() {
    _dateCtrl.dispose();
    _previousDateCtrl.dispose();
    _previousCtrl.dispose();
    _currentCtrl.dispose();
    _billingMonthCtrl.dispose();
    _monthlyKwhCtrl.dispose();
    super.dispose();
  }

  // ── Actions ───────────────────────────────────────────────────────────────

  /// Looks up the household's last saved reading and fills in the previous
  /// reading field. The field always stays editable. If anything goes wrong
  /// the user can simply type the value.
  Future<void> _loadPreviousReading() async {
    final householdId = widget.household.id;

    // A household without a server ID has no saved readings to look up.
    if (householdId == null) {
      setState(() => _isLoadingPrevious = false);
      return;
    }

    try {
      final last = await ApiService.getLastMeterReading(householdId);

      if (!mounted) return;

      setState(() {
        _isLoadingPrevious = false;

        if (last == null) {
          _noSavedReadings = true;
          return;
        }

        if (_previousCtrl.text.trim().isEmpty && !_isSaving) {
          final reading = last['meter_reading'];

          if (reading is num) {
            _previousCtrl.text = reading.toStringAsFixed(2);
            _prefilled = true;
          }
        }

        if (_previousReadingDate == null) {
          final savedDate = DateTime.tryParse(
            '${last['reading_date'] ?? ''}',
          );

          if (savedDate != null) {
            _previousReadingDate = _dateOnly(savedDate);
            _previousDateCtrl.text =
                _displayDate(_previousReadingDate!);
            _previousDatePrefilled = true;
          }
        }
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _isLoadingPrevious = false);

      showTemporaryMessage(
        context,
        e.isSessionExpired
            ? e.message
            : 'Could not load your last meter reading. '
                  'You can type it in yourself.',
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoadingPrevious = false);

      showTemporaryMessage(
        context,
        'Could not load your last meter reading. You can type it in yourself.',
      );
    }
  }

  /// Opens the calendar and saves the chosen date.
  Future<void> _pickDate() async {
    final today = _dateOnly(DateTime.now());

    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate.isAfter(today) ? today : _selectedDate,
      firstDate: DateTime(2020),
      lastDate: today,
      helpText: 'Select reading date',
      // Keep the calendar in the E-FORECAST light theme.
      builder: (context, child) =>
          Theme(data: AppTheme.lightTheme, child: child!),
    );

    if (picked == null || !mounted) return;

    setState(() {
      _selectedDate = _dateOnly(picked);
      _dateCtrl.text = _displayDate(_selectedDate);
    });
  }


Future<void> _pickPreviousReadingDate() async {
  final today = _dateOnly(DateTime.now());

  final latestAllowedDate = _selectedDate.isAfter(today)
      ? today
      : _selectedDate;

  final initialDate = _previousReadingDate != null &&
          !_previousReadingDate!.isAfter(latestAllowedDate)
      ? _previousReadingDate!
      : latestAllowedDate;

  final picked = await showDatePicker(
    context: context,
    initialDate: initialDate,
    firstDate: DateTime(2020),
    lastDate: latestAllowedDate,
    helpText: 'Select previous reading date',
    builder: (context, child) =>
        Theme(data: AppTheme.lightTheme, child: child!),
  );

  if (picked == null || !mounted) return;

  setState(() {
    _previousReadingDate = _dateOnly(picked);
    _previousDateCtrl.text = _displayDate(_previousReadingDate!);
    _previousDatePrefilled = false;
  });
}


  Future<void> _pickBillingMonth() async {
    final today = DateTime.now();

    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedBillingMonth,
      firstDate: DateTime(2020),
      lastDate: DateTime(today.year, today.month, today.day),
      helpText: 'Select billing month',
      initialDatePickerMode: DatePickerMode.year,
      builder: (context, child) =>
          Theme(data: AppTheme.lightTheme, child: child!),
    );

    if (picked == null || !mounted) return;

    setState(() {
      _selectedBillingMonth = DateTime(picked.year, picked.month, 1);
      _billingMonthCtrl.text = _displayMonth(_selectedBillingMonth);
    });
  }
  
  /// Checks the form, saves the selected entry mode and handles the result.
  Future<void> _submit() async {
    if (_isSaving) return;
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final householdId = widget.household.id;

    if (householdId == null) {
      showTemporaryMessage(
        context,
        'This household is not saved on the server yet, so '
        'consumption cannot be recorded for it.',
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      if (_useDirectKwhEntry) {
        // Save actual monthly kWh from the electricity bill.
        final monthlyKwh = double.parse(_monthlyKwhCtrl.text.trim());

        await ApiService.recordMonthlyConsumption(
          householdId: householdId,
          billingMonth: _selectedBillingMonth,
          consumptionKwh: monthlyKwh,
        );

        if (!mounted) return;

        showTemporaryMessage(
          context,
          'Monthly consumption recorded successfully.',
        );
      } else {
        // Save previous and current meter readings.
        final previous = double.parse(_previousCtrl.text.trim());
        final current = double.parse(_currentCtrl.text.trim());

        final result = await ApiService.recordConsumption(
          householdId: householdId,
          consumptionDate: _selectedDate,
          previousReadingDate: _previousReadingDate,
          meterPrevious: previous,
          meterCurrent: current,
        );

        if (!mounted) return;

        final kwhValue = result['kwh'];
        final kwh = kwhValue is num
            ? kwhValue.toDouble()
            : double.tryParse('$kwhValue');

        showTemporaryMessage(
          context,
          kwh == null
              ? 'Consumption recorded successfully.'
              : 'Consumption recorded: ${kwh.toStringAsFixed(2)} kWh used.',
        );
      }

      if (!mounted) return;

      Navigator.of(context).pop(true);
    } on ApiException catch (e) {
      if (!mounted) return;

      setState(() => _isSaving = false);
      showTemporaryMessage(context, e.message);
    } catch (_) {
      if (!mounted) return;

      setState(() => _isSaving = false);
      showTemporaryMessage(
        context,
        'Something went wrong. Please try again.',
      );
    }
  }


  /// Leaves the screen without saving.
  void _cancel() => Navigator.of(context).pop();

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < 600;

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
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                child: LandingContainer(
                  maxWidth: 720,
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: compact ? 20 : 40),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AppBackLink(
                          label: widget.household.name,
                          onPressed: _cancel,
                        ),
                        const SizedBox(height: 12),
                        _buildHeader(),
                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          child: LandingCard(
                            padding: EdgeInsets.all(compact ? 20 : 28),
                            child: _buildForm(),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _useDirectKwhEntry
                              ? 'Enter the actual monthly kWh shown on your electricity bill.'
                              : 'The kWh used is calculated for you from the two meter readings.',
                          style: TextStyle(
                            color: LandingColors.textSecondary,
                            fontSize: 12,
                            height: 1.5,
                          ),
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
            fontWeight: FontWeight.w700,
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          _useDirectKwhEntry
              ? 'Enter the actual monthly electricity consumption for '
                  '${widget.household.name}.'
              : 'Enter the previous and current meter readings for '
                  '${widget.household.name}.',
          style: TextStyle(
            color: LandingColors.textSecondary,
            fontSize: 14,
            height: 1.5,
          ),
        ),
      ],
    );
  }

  /// Helper text under the previous reading field. It tells the user what
  /// happened with the automatic fill-in.
  String get _previousHelper {
    if (_isLoadingPrevious) return 'Loading your last saved reading…';
    if (_prefilled) {
      return 'Filled in from your last saved reading. You can edit it.';
    }
    if (_noSavedReadings) {
      return 'No saved readings yet. Enter your meter reading as the '
          'starting point.';
    }
    return 'The last reading you recorded';
  }

  Widget _buildEntryModeSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Choose Entry Method',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 10),
        SegmentedButton<bool>(
          segments: const [
            ButtonSegment<bool>(
              value: false,
              label: Text('Meter Reading'),
              icon: Icon(Icons.speed_outlined),
            ),
            ButtonSegment<bool>(
              value: true,
              label: Text('Direct kWh'),
              icon: Icon(Icons.bolt_outlined),
            ),
          ],
          selected: {_useDirectKwhEntry},
          onSelectionChanged: _isSaving
              ? null
              : (selection) {
                  setState(() {
                    _useDirectKwhEntry = selection.first;
                  });
              },
          ),
       ],
    );
  }

  
  Widget _buildForm() {
    return Form(
      key: _formKey,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final wide = constraints.maxWidth >= 480;

          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildEntryModeSelector(),
              const SizedBox(height: 20),

              if (!_useDirectKwhEntry) ...[
                // METER READING MODE
                TextFormField(
                  controller: _dateCtrl,
                  readOnly: true,
                  enabled: !_isSaving,
                  onTap: _isSaving ? null : _pickDate,
                  validator: (v) =>
                      (v == null || v.trim().isEmpty)
                          ? 'Consumption date is required'
                          : null,
                  style: const TextStyle(
                    fontSize: 14,
                  ),
                  decoration: InputDecoration(
                    labelText: 'Consumption Date',
                    helperText: 'Select the date of your meter reading',
                    prefixIcon: Icon(
                      Icons.calendar_today_outlined,
                      size: 18,
                      color: LandingColors.textSecondary,
                    ),
                    suffixIcon: Icon(
                      Icons.arrow_drop_down,
                      color: LandingColors.textSecondary,
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                TextFormField(
                  controller: _previousDateCtrl,
                  readOnly: true,
                  enabled: !_isSaving,
                  onTap: _isSaving ? null : _pickPreviousReadingDate,
                  validator: (value) {
                    if (_previousReadingDate == null) {
                      return 'Previous reading date is required';
                    }

                    if (!_previousReadingDate!.isBefore(_selectedDate)) {
                      return 'Previous reading date must be before consumption date';
                    }

                    return null;
                  },
                  style: const TextStyle(fontSize: 14),
                  decoration: InputDecoration(
                    labelText: 'Previous Reading Date',
                    helperText: _previousDatePrefilled
                        ? 'Automatically filled from your last saved reading.'
                        : 'Select the date of your previous meter reading.',
                    helperMaxLines: 2,
                    prefixIcon: Icon(
                      Icons.calendar_today_outlined,
                      size: 18,
                      color: LandingColors.textSecondary,
                    ),
                    suffixIcon: Icon(
                      Icons.arrow_drop_down,
                      color: LandingColors.textSecondary,
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                _meterField(
                  controller: _previousCtrl,
                  label: 'Previous Meter Reading',
                  hint: 'e.g. 211.00',
                  helper: _previousHelper,
                  icon: Icons.speed_outlined,
                  validator: _validatePrevious,
                ),
                const SizedBox(height: 16),

                _meterField(
                  controller: _currentCtrl,
                  label: 'Current Meter Reading',
                  hint: 'e.g. 223.50',
                  helper: 'The reading on your meter now',
                  icon: Icons.bolt_rounded,
                  validator: _validateCurrent,
                  last: true,
                ),
              ] else ...[
                // DIRECT KWH ENTRY MODE
                TextFormField(
                  controller: _billingMonthCtrl,
                  readOnly: true,
                  enabled: !_isSaving,
                  onTap: _isSaving ? null : _pickBillingMonth,
                  validator: (v) =>
                      (v == null || v.trim().isEmpty)
                          ? 'Billing month is required'
                          : null,
                  style: const TextStyle(
                    fontSize: 14,
                  ),
                  decoration: InputDecoration(
                    labelText: 'Billing Month',
                    helperText:
                        'Select the month shown on your electricity bill',
                    helperMaxLines: 2,
                    prefixIcon: Icon(
                      Icons.calendar_month_outlined,
                      size: 18,
                      color: LandingColors.textSecondary,
                    ),
                    suffixIcon: Icon(
                      Icons.arrow_drop_down,
                      color: LandingColors.textSecondary,
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                _meterField(
                  controller: _monthlyKwhCtrl,
                  label: 'Monthly Consumption',
                  hint: 'e.g. 150.00',
                  helper: 'Enter the actual kWh consumption from your bill',
                  icon: Icons.bolt_rounded,
                  validator: _validateMonthlyKwh,
                  last: true,
                ),
              ],

              const SizedBox(height: 24),

              if (wide)
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    LandingSecondaryButton(
                      label: 'Cancel',
                      onPressed: _isSaving ? () {} : _cancel,
                    ),
                    const SizedBox(width: 12),
                    LandingPrimaryButton(
                      label: _isSaving ? 'Saving...' : 'Record Consumption',
                      onPressed: _isSaving ? () {} : _submit,
                    ),
                  ],
                )
              else ...[
                LandingPrimaryButton(
                  label: _isSaving ? 'Saving...' : 'Record Consumption',
                  onPressed: _isSaving ? () {} : _submit,
                ),
                const SizedBox(height: 12),
                LandingSecondaryButton(
                  label: 'Cancel',
                  onPressed: _isSaving ? () {} : _cancel,
                ),
              ],
            ],
          );
        },
      ),
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
    bool last = false,
  }) {
    return TextFormField(
      controller: controller,
      validator: validator,
      enabled: !_isSaving,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
      ],
      textInputAction: last ? TextInputAction.done : TextInputAction.next,
      onFieldSubmitted: last ? (_) => _submit() : null,
      style: TextStyle(color: LandingColors.textPrimary, fontSize: 14),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        helperText: helper,
        helperMaxLines: 2,
        suffixText: 'kWh',
        prefixIcon: Icon(icon, size: 18, color: LandingColors.textSecondary),
      ),
    );
  }

  // ── Validation ────────────────────────────────────────────────────────────

  String? _validatePrevious(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return 'Previous meter reading is required';

    final number = double.tryParse(text);
    if (number == null) return 'Enter a valid number, e.g. 211.00';
    if (number < 0) return 'Reading cannot be negative';
    return null;
  }

  String? _validateCurrent(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return 'Current meter reading is required';

    final current = double.tryParse(text);
    if (current == null) return 'Enter a valid number, e.g. 223.50';
    if (current < 0) return 'Reading cannot be negative';

    // The current reading must be higher than the previous one.
    final previous = double.tryParse(_previousCtrl.text.trim());
    if (previous != null && current <= previous) {
      return 'Must be greater than the previous reading';
    }
    return null;
  }

  String? _validateMonthlyKwh(String? value) {
    final text = value?.trim() ?? '';

    if (text.isEmpty) {
      return 'Monthly consumption is required';
    }

    final number = double.tryParse(text);

    if (number == null) {
      return 'Enter a valid consumption value';
    }

    if (number <= 0) {
      return 'Consumption must be greater than zero';
    }

    return null;
  }

  // ── Date helpers ──────────────────────────────────────────────────────────

  /// Removes the time part so only the day is kept.
  DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  // Displays the billing month, e.g. "November 2026".
  String _displayMonth(DateTime date) {
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

    return '${months[date.month - 1]} ${date.year}';
  }

  /// Friendly format for the screen, e.g. "01 Nov 2026".
  String _displayDate(DateTime d) {
    const months = [
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
    final day = d.day.toString().padLeft(2, '0');
    return '$day ${months[d.month - 1]} ${d.year}';
  }
}
