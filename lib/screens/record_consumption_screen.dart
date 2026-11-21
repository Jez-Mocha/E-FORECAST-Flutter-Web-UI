import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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
/// Lets the user enter a date plus the previous and current meter readings
/// for one household, then sends them to the backend. The backend works out
/// the kWh used. When the screen opens, the previous reading is filled in
/// from the household's last saved reading (the user can still edit it).
/// On success the screen closes and returns `true`.
class RecordConsumptionScreen extends StatefulWidget {
  final Household household;

  const RecordConsumptionScreen({super.key, required this.household});

  @override
  State<RecordConsumptionScreen> createState() =>
      _RecordConsumptionScreenState();
}

class _RecordConsumptionScreenState extends State<RecordConsumptionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _currentFieldKey = GlobalKey<FormFieldState<String>>();

  final _dateCtrl = TextEditingController();
  final _previousCtrl = TextEditingController();
  final _currentCtrl = TextEditingController();

  // The date the user picked. Starts as today.
  late DateTime _selectedDate;

  // True while the reading is being sent (shows "Saving…").
  bool _isSaving = false;

  // True while the last saved reading is being loaded.
  bool _isLoadingPrevious = true;

  // True if the previous reading was filled in from a saved reading.
  bool _prefilled = false;

  // True if the household was checked and has no saved readings yet.
  bool _noSavedReadings = false;

  // A message from the last failed save. Shown on the form until the next try.
  String? _submitError;

  @override
  void initState() {
    super.initState();
    _selectedDate = _dateOnly(DateTime.now());
    _dateCtrl.text = _displayDate(_selectedDate);
    _loadPreviousReading();
  }

  @override
  void dispose() {
    _dateCtrl.dispose();
    _previousCtrl.dispose();
    _currentCtrl.dispose();
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

        // Do not overwrite anything the user already typed or started saving.
        if (_previousCtrl.text.trim().isEmpty && !_isSaving) {
          _previousCtrl.text = last.toStringAsFixed(2);
          _prefilled = true;
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
    if (_isSaving) return;
    if (!(_formKey.currentState?.validate() ?? false)) return;

    // Households added only inside the app have no server id yet.
    final householdId = widget.household.id;
    if (householdId == null) {
      setState(() {
        _submitError =
            'This household is not saved on the server yet, so readings '
            'cannot be recorded for it.';
      });
      return;
    }

    final previous = double.parse(_previousCtrl.text.trim());
    final current = double.parse(_currentCtrl.text.trim());

    setState(() {
      _isSaving = true;
      _submitError = null;
    });

    try {
      final result = await ApiService.recordConsumption(
        householdId: householdId,
        consumptionDate: _selectedDate,
        meterPrevious: previous,
        meterCurrent: current,
      );

      if (!mounted) return;

      // The backend returns the kWh it calculated.
      final kwhValue = result['kwh'];
      final kwh = kwhValue is num
          ? kwhValue.toDouble()
          : double.tryParse('$kwhValue');

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
          'Enter the readings from your electricity meter for '
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
    if (_prefilled) {
      return 'Filled in from your last saved reading. You can change it.';
    }
    if (_noSavedReadings) {
      return 'No saved readings yet. Enter the reading you want to start from.';
    }
    return 'The last reading you recorded';
  }

  Widget _buildFormCard() {
    return GlassCard(
      blur: 0,
      padding: const EdgeInsets.fromLTRB(28, 26, 28, 28),
      child: Form(
        key: _formKey,
        // Errors appear after the user has interacted with a field.
        autovalidateMode: AutovalidateMode.onUserInteraction,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const _StepHeader(
              number: 1,
              title: 'Reading date',
              subtitle: 'Choose the day you read the meter.',
            ),
            const SizedBox(height: 14),
            Align(
              alignment: Alignment.centerLeft,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 320),
                child: MouseRegion(
                  cursor: _isSaving
                      ? SystemMouseCursors.basic
                      : SystemMouseCursors.click,
                  child: TextFormField(
                    controller: _dateCtrl,
                    readOnly: true,
                    onTap: _isSaving ? null : _pickDate,
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? 'Choose the date of the reading'
                        : null,
                    style: TextStyle(
                      color: LandingColors.textPrimary,
                      fontSize: AppText.body,
                    ),
                    decoration: InputDecoration(
                      labelText: 'Consumption date',
                      prefixIcon: Icon(
                        Icons.event_outlined,
                        size: 18,
                        color: LandingColors.textSecondary,
                      ),
                      suffixIcon: Icon(
                        Icons.calendar_month_outlined,
                        size: 18,
                        color: LandingColors.primary,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 26),
            Divider(color: LandingColors.border, height: 1),
            const SizedBox(height: 22),
            const _StepHeader(
              number: 2,
              title: 'Meter readings',
              subtitle:
                  'Type the numbers shown on your meter. The current reading '
                  'must be higher than the previous one.',
            ),
            const SizedBox(height: 14),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _meterField(
                    controller: _previousCtrl,
                    label: 'Previous meter reading',
                    hint: 'e.g. 211.00',
                    helper: _previousHelper,
                    icon: Icons.speed_outlined,
                    validator: _validatePrevious,
                    onChanged: _onPreviousChanged,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _meterField(
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
              ],
            ),
            const SizedBox(height: 22),
            _buildUsagePreview(),
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
                  onPressed: _isSaving ? null : _submit,
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
    bool last = false,
  }) {
    return TextFormField(
      key: fieldKey,
      controller: controller,
      validator: validator,
      onChanged: onChanged,
      enabled: !_isSaving,
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
                'Tips for accurate readings',
                style: TextStyle(
                  color: LandingColors.textPrimary,
                  fontSize: AppText.cardTitle,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12),
              const _Tip(
                text: 'Use the number shown on your electricity meter.',
              ),
              const _Tip(
                text:
                    'The previous reading is your last saved one. Change it '
                    'if it is not correct.',
              ),
              const _Tip(
                text: 'The current reading must be higher than the previous.',
              ),
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
    return null;
  }

  String? _validateCurrent(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return 'Enter the current meter reading';

    final current = double.tryParse(text);
    if (current == null) return 'Enter a valid number, e.g. 223.50';
    if (current < 0) return 'Reading cannot be negative';

    // The current reading must be higher than the previous one.
    final previous = double.tryParse(_previousCtrl.text.trim());
    if (previous != null && current <= previous) {
      return 'Must be higher than the previous reading '
          '(${previous.toStringAsFixed(2)})';
    }
    return null;
  }

  // ── Date helpers ──────────────────────────────────────────────────────────

  /// Removes the time part so only the day is kept.
  DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  /// Friendly format for the screen, e.g. "Nov 1, 2026".
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
    return '${months[d.month - 1]} ${d.day}, ${d.year}';
  }
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
