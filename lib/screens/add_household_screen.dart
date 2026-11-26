import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../landing/landing_widgets.dart'
    show
        LandingCard,
        LandingContainer,
        LandingPrimaryButton,
        LandingSecondaryButton;
import '../models/electricity_provider.dart';
import '../models/household.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../theme/app_tokens.dart';
import '../theme/landing_colors.dart';
import '../widgets/app_back_link.dart';
import '../widgets/app_message.dart';
import '../widgets/app_top_bar.dart';

/// SCR-04: Add Household.
/// Collects the details of one household and saves it on the server.
/// Only after the server confirms (and returns a household ID) does it
/// return a [Household] to the screen that opened it (via Navigator.pop).
/// If saving fails, the user stays on the form and nothing is returned.
class AddHouseholdScreen extends StatefulWidget {
  const AddHouseholdScreen({super.key, this.editBillingFor});

  final Household? editBillingFor;

  @override
  State<AddHouseholdScreen> createState() => _AddHouseholdScreenState();
}

class _AddHouseholdScreenState extends State<AddHouseholdScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nameCtrl = TextEditingController();
  final _meterCtrl = TextEditingController();
  final _streetCtrl = TextEditingController();
  final _cityCtrl = TextEditingController();
  final _occupantsCtrl = TextEditingController();
  late final _billingDayCtrl = TextEditingController(
    text: widget.editBillingFor?.billingCycleDay?.toString(),
  );
  late String? _providerCode = _existingProvider;

  bool get _isEditing => widget.editBillingFor != null;

  String? get _existingProvider {
    final provider = widget.editBillingFor?.provider;
    return provider == null || provider.isEmpty ? null : provider;
  }

  String get _saveLabel => _isSaving
      ? 'Saving…'
      : _isEditing
      ? 'Save Billing Settings'
      : 'Save Household';

  // True while the household is being saved on the server.
  bool _isSaving = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _meterCtrl.dispose();
    _streetCtrl.dispose();
    _cityCtrl.dispose();
    _occupantsCtrl.dispose();
    _billingDayCtrl.dispose();
    super.dispose();
  }

  // ── Actions ───────────────────────────────────────────────────────────────

  /// Checks every field, saves the household on the server, and only then
  /// returns the new household (with its server ID) to the dashboard.
  Future<void> _save() async {
    // Stops double taps and a second Enter key press while saving.
    if (_isSaving) return;
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _isSaving = true);

    try {
      final billingDay = int.parse(_billingDayCtrl.text.trim());
      final household = await (_isEditing
          ? ApiService.updateHouseholdBilling(
              householdId: widget.editBillingFor!.id!,
              electricityProvider: _providerCode!,
              billingCycleDay: billingDay,
            )
          : ApiService.createHousehold(
              householdName: _nameCtrl.text.trim(),
              address: '${_streetCtrl.text.trim()}, ${_cityCtrl.text.trim()}',
              meterNumber: _meterCtrl.text.trim(),
              occupants: int.parse(_occupantsCtrl.text.trim()),
              electricityProvider: _providerCode!,
              billingCycleDay: billingDay,
            ));
      if (!mounted) return;
      Navigator.of(context).pop(household);
    } on ApiException catch (e) {
      // Friendly message. The user stays on the form to fix it.
      if (!mounted) return;
      setState(() => _isSaving = false);
      showTemporaryMessage(context, e.message);
    } catch (_) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      showTemporaryMessage(context, 'Something went wrong. Please try again.');
    }
  }

  /// Leaves without saving (the dashboard receives nothing).
  void _cancel() {
    if (!_isSaving) Navigator.of(context).pop();
  }

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
                          label: _isEditing
                              ? 'Household Details'
                              : 'My Households',
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
                        if (!_isEditing) const SizedBox(height: 16),
                        if (!_isEditing)
                          Text(
                            'Open the household after saving to see its current '
                            'electricity rate.',
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
          _isEditing ? 'Edit Billing Settings' : 'Add Household',
          style: TextStyle(
            color: LandingColors.textPrimary,
            fontSize: AppText.pageTitle,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          _isEditing
              ? 'Use the provider and billing cycle day from your electricity bill.'
              : 'Enter the details of the household you want to track.',
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
              if (_isEditing)
                _fieldRow(twoCol, _providerField(), _billingDayField())
              else ...[
                _field(
                  controller: _nameCtrl,
                  label: 'Household Name',
                  hint: 'e.g. Family Home',
                  icon: Icons.home_outlined,
                  capitalization: TextCapitalization.words,
                  validator: _validateName,
                ),
                const SizedBox(height: 16),
                _field(
                  controller: _meterCtrl,
                  label: 'Meter Number',
                  hint: 'e.g. MTR-000010',
                  helper: 'The number printed on your electric meter',
                  icon: Icons.speed_outlined,
                  capitalization: TextCapitalization.characters,
                  validator: _validateMeterNumber,
                ),
                const SizedBox(height: 16),
                _fieldRow(
                  twoCol,
                  _field(
                    controller: _streetCtrl,
                    label: 'Street / Barangay',
                    icon: Icons.signpost_outlined,
                    capitalization: TextCapitalization.words,
                    validator: (v) =>
                        _validateAddressPart(v, 'Street / Barangay'),
                  ),
                  _field(
                    controller: _cityCtrl,
                    label: 'City / Municipality',
                    icon: Icons.location_city_outlined,
                    capitalization: TextCapitalization.words,
                    validator: (v) =>
                        _validateAddressPart(v, 'City / Municipality'),
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
                  _providerField(),
                ),
                const SizedBox(height: 16),
                _fieldRow(
                  twoCol,
                  InputDecorator(
                    decoration: InputDecoration(
                      labelText: 'Rate per kWh (₱)',
                      helperText: 'Managed by the administrator',
                      helperMaxLines: 2,
                      prefixIcon: Icon(
                        Icons.payments_outlined,
                        size: 18,
                        color: LandingColors.textSecondary,
                      ),
                    ),
                    child: const Text('Available after saving'),
                  ),
                  _billingDayField(),
                ),
              ],
              const SizedBox(height: 24),
              if (twoCol)
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    LandingSecondaryButton(
                      label: 'Cancel',
                      onPressed: _isSaving ? null : _cancel,
                    ),
                    const SizedBox(width: 12),
                    LandingPrimaryButton(
                      label: _saveLabel,
                      onPressed: _isSaving ? null : _save,
                    ),
                  ],
                )
              else ...[
                LandingPrimaryButton(
                  label: _saveLabel,
                  onPressed: _isSaving ? null : _save,
                ),
                const SizedBox(height: 12),
                LandingSecondaryButton(
                  label: 'Cancel',
                  onPressed: _isSaving ? null : _cancel,
                ),
              ],
            ],
          );
        },
      ),
    );
  }

  Widget _providerField() {
    final existingProvider = _existingProvider;
    return DropdownButtonFormField<String>(
      initialValue: _providerCode,
      isExpanded: true,
      menuMaxHeight: 320,
      style: TextStyle(color: LandingColors.textPrimary, fontSize: 14),
      decoration: InputDecoration(
        labelText: 'Electricity Provider',
        prefixIcon: Icon(
          Icons.bolt_rounded,
          size: 18,
          color: LandingColors.textSecondary,
        ),
      ),
      items: [
        if (existingProvider != null &&
            !mindanaoElectricityProviders.any(
              (p) => p.code == existingProvider,
            ))
          DropdownMenuItem(
            value: existingProvider,
            child: Text(existingProvider, overflow: TextOverflow.ellipsis),
          ),
        for (final provider in mindanaoElectricityProviders)
          DropdownMenuItem(
            value: provider.code,
            child: Text(provider.label, overflow: TextOverflow.ellipsis),
          ),
      ],
      onChanged: _isSaving ? null : (value) => _providerCode = value,
      validator: (value) => _validateRequired(value, 'Electricity provider'),
    );
  }

  Widget _billingDayField() => _field(
    controller: _billingDayCtrl,
    label: 'Billing Cycle Day',
    hint: '1 to 31',
    helper: 'Day of the month (1–31)',
    icon: Icons.event_outlined,
    keyboardType: TextInputType.number,
    formatters: [FilteringTextInputFormatter.digitsOnly],
    last: true,
    validator: (value) => _validateWholeNumber(
      value,
      label: 'Billing cycle day',
      min: 1,
      max: 31,
    ),
  );

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
      enabled: !_isSaving,
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

/// The server accepts 2 to 100 characters. We keep the existing 60 limit.
String? _validateName(String? value) {
  final required = _validateRequired(value, 'Household name');
  if (required != null) return required;
  final length = value!.trim().length;
  if (length < 2) return 'Use at least 2 characters';
  if (length > 60) return 'Use 60 characters or fewer';
  return null;
}

/// The server accepts 1 to 30 characters, and each meter number can only
/// belong to one household.
String? _validateMeterNumber(String? value) {
  final required = _validateRequired(value, 'Meter number');
  if (required != null) return required;
  if (value!.trim().length > 30) return 'Use 30 characters or fewer';
  return null;
}

/// Street and city are joined into one address (the server allows 255).
String? _validateAddressPart(String? value, String label) {
  final required = _validateRequired(value, label);
  if (required != null) return required;
  if (value!.trim().length > 120) return 'Use 120 characters or fewer';
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
