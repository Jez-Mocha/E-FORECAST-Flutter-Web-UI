import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../landing/landing_widgets.dart'
    show
        LandingCard,
        LandingContainer,
        LandingLogo,
        LandingPrimaryButton,
        LandingSecondaryButton,
        ThemeToggleButton;
import '../models/household.dart';
import '../theme/app_theme.dart';
import '../theme/landing_colors.dart';

/// SCR-04: Add Household.
/// Collects the details of one household and returns a [Household] to the
/// screen that opened it (via Navigator.pop). Nothing is sent to a server.
class AddHouseholdScreen extends StatefulWidget {
  const AddHouseholdScreen({super.key});

  @override
  State<AddHouseholdScreen> createState() => _AddHouseholdScreenState();
}

class _AddHouseholdScreenState extends State<AddHouseholdScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nameCtrl = TextEditingController();
  final _streetCtrl = TextEditingController();
  final _cityCtrl = TextEditingController();
  final _occupantsCtrl = TextEditingController();
  final _providerCtrl = TextEditingController();
  final _rateCtrl = TextEditingController();
  final _billingDayCtrl = TextEditingController();

  @override
  void dispose() {
    _nameCtrl.dispose();
    _streetCtrl.dispose();
    _cityCtrl.dispose();
    _occupantsCtrl.dispose();
    _providerCtrl.dispose();
    _rateCtrl.dispose();
    _billingDayCtrl.dispose();
    super.dispose();
  }

  // ── Actions ───────────────────────────────────────────────────────────────

  /// Checks every field. If all are valid, returns the new household.
  void _save() {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    Navigator.of(context).pop(
      Household(
        name: _nameCtrl.text.trim(),
        street: _streetCtrl.text.trim(),
        city: _cityCtrl.text.trim(),
        occupants: int.parse(_occupantsCtrl.text.trim()),
        provider: _providerCtrl.text.trim(),
        ratePerKwh: double.parse(_rateCtrl.text.trim()),
        billingCycleDay: int.parse(_billingDayCtrl.text.trim()),
      ),
    );
  }

  /// Leaves without saving (the dashboard receives nothing).
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
            _AddHouseholdTopBar(compact: compact),
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
                        _buildBackLink(),
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
                          'Households are kept for this session only. '
                          'Permanent storage will be added later.',
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

  Widget _buildBackLink() {
    return Align(
      alignment: Alignment.centerLeft,
      child: TextButton.icon(
        onPressed: _cancel,
        icon: const Icon(Icons.arrow_back_rounded, size: 16),
        label: const Text('My Households'),
        style: TextButton.styleFrom(
          foregroundColor: LandingColors.textSecondary,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
          textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Add Household',
          style: TextStyle(
            color: LandingColors.textPrimary,
            fontSize: 28,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Enter the details of the household you want to track.',
          style: TextStyle(
            color: LandingColors.textSecondary,
            fontSize: 14,
            height: 1.5,
          ),
        ),
      ],
    );
  }

  Widget _buildForm() {
    return Form(
      key: _formKey,
      // Errors appear after the user has interacted with a field.
      autovalidateMode: AutovalidateMode.onUserInteraction,
      child: LayoutBuilder(
        builder: (context, constraints) {
          // Pairs of fields sit side by side when there is room.
          final twoCol = constraints.maxWidth >= 480;

          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _field(
                controller: _nameCtrl,
                label: 'Household Name',
                hint: 'e.g. Family Home',
                icon: Icons.home_outlined,
                capitalization: TextCapitalization.words,
                validator: _validateName,
              ),
              const SizedBox(height: 16),
              _fieldRow(
                twoCol,
                _field(
                  controller: _streetCtrl,
                  label: 'Street / Barangay',
                  icon: Icons.signpost_outlined,
                  capitalization: TextCapitalization.words,
                  validator: (v) => _validateRequired(v, 'Street / Barangay'),
                ),
                _field(
                  controller: _cityCtrl,
                  label: 'City / Municipality',
                  icon: Icons.location_city_outlined,
                  capitalization: TextCapitalization.words,
                  validator: (v) => _validateRequired(v, 'City / Municipality'),
                ),
              ),
              const SizedBox(height: 16),
              _fieldRow(
                twoCol,
                _field(
                  controller: _occupantsCtrl,
                  label: 'Number of Occupants',
                  icon: Icons.people_outline_rounded,
                  keyboardType: TextInputType.number,
                  formatters: [FilteringTextInputFormatter.digitsOnly],
                  validator: (v) => _validateWholeNumber(
                    v,
                    label: 'Number of occupants',
                    min: 1,
                    max: 50,
                  ),
                ),
                _field(
                  controller: _providerCtrl,
                  label: 'Electricity Provider',
                  icon: Icons.bolt_rounded,
                  capitalization: TextCapitalization.words,
                  validator: (v) =>
                      _validateRequired(v, 'Electricity provider'),
                ),
              ),
              const SizedBox(height: 16),
              _fieldRow(
                twoCol,
                _field(
                  controller: _rateCtrl,
                  label: 'Rate per kWh (₱)',
                  hint: 'e.g. 12.50',
                  helper: 'Price per kWh on your bill',
                  icon: Icons.payments_outlined,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  formatters: [
                    FilteringTextInputFormatter.allow(
                      RegExp(r'^\d*\.?\d{0,4}'),
                    ),
                  ],
                  validator: _validateRate,
                ),
                _field(
                  controller: _billingDayCtrl,
                  label: 'Billing Cycle Day',
                  hint: '1 to 31',
                  helper: 'Day of the month (1–31)',
                  icon: Icons.event_outlined,
                  keyboardType: TextInputType.number,
                  formatters: [FilteringTextInputFormatter.digitsOnly],
                  last: true,
                  validator: (v) => _validateWholeNumber(
                    v,
                    label: 'Billing cycle day',
                    min: 1,
                    max: 31,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              if (twoCol)
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    LandingSecondaryButton(label: 'Cancel', onPressed: _cancel),
                    const SizedBox(width: 12),
                    LandingPrimaryButton(
                      label: 'Save Household',
                      onPressed: _save,
                    ),
                  ],
                )
              else ...[
                LandingPrimaryButton(label: 'Save Household', onPressed: _save),
                const SizedBox(height: 12),
                LandingSecondaryButton(label: 'Cancel', onPressed: _cancel),
              ],
            ],
          );
        },
      ),
    );
  }

  /// Two fields side by side, or stacked when the card is narrow.
  Widget _fieldRow(bool twoCol, Widget a, Widget b) {
    if (!twoCol) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [a, const SizedBox(height: 16), b],
      );
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: a),
        const SizedBox(width: 16),
        Expanded(child: b),
      ],
    );
  }

  /// One text field in the shared E-FORECAST input style.
  Widget _field({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required String? Function(String?) validator,
    String? hint,
    String? helper,
    TextInputType keyboardType = TextInputType.text,
    List<TextInputFormatter>? formatters,
    TextCapitalization capitalization = TextCapitalization.none,
    bool last = false,
  }) {
    return TextFormField(
      controller: controller,
      validator: validator,
      keyboardType: keyboardType,
      inputFormatters: formatters,
      textCapitalization: capitalization,
      textInputAction: last ? TextInputAction.done : TextInputAction.next,
      onFieldSubmitted: last ? (_) => _save() : null,
      style: TextStyle(color: LandingColors.textPrimary, fontSize: 14),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        helperText: helper,
        helperMaxLines: 2,
        prefixIcon: Icon(icon, size: 18, color: LandingColors.textSecondary),
      ),
    );
  }
}

// ── Validation ──────────────────────────────────────────────────────────────

String? _validateRequired(String? value, String label) {
  if (value == null || value.trim().isEmpty) return '$label is required';
  return null;
}

String? _validateName(String? value) {
  final required = _validateRequired(value, 'Household name');
  if (required != null) return required;
  if (value!.trim().length > 60) return 'Use 60 characters or fewer';
  return null;
}

/// A whole number between [min] and [max] (both included).
String? _validateWholeNumber(
  String? value, {
  required String label,
  required int min,
  required int max,
}) {
  final text = value?.trim() ?? '';
  if (text.isEmpty) return '$label is required';
  final number = int.tryParse(text);
  if (number == null) return 'Enter a whole number';
  if (number < 1 || number < min || number > max) {
    return 'Enter a number from $min to $max';
  }
  return null;
}

/// A number greater than 0, such as 12.5 (decimals allowed).
String? _validateRate(String? value) {
  final text = value?.trim() ?? '';
  if (text.isEmpty) return 'Rate per kWh is required';
  final rate = double.tryParse(text);
  if (rate == null) return 'Enter a valid number, e.g. 12.50';
  if (rate <= 0) return 'Rate must be greater than 0';
  return null;
}

/// Top bar: logo and theme toggle (same look as the dashboard top bar).
class _AddHouseholdTopBar extends StatelessWidget {
  final bool compact;

  const _AddHouseholdTopBar({required this.compact});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: LandingColors.background,
        border: Border(bottom: BorderSide(color: LandingColors.border)),
      ),
      child: SafeArea(
        bottom: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1200),
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: compact ? 16 : 24,
                vertical: 8,
              ),
              child: const Row(
                children: [
                  Expanded(
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: LandingLogo(),
                      ),
                    ),
                  ),
                  ThemeToggleButton(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
