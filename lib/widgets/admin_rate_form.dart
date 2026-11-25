import 'package:flutter/material.dart';

import '../models/electricity_provider.dart';
import '../services/api_service.dart';
import '../theme/app_tokens.dart';
import '../theme/landing_colors.dart';
import 'app_message.dart';

class AdminRateForm extends StatefulWidget {
  const AdminRateForm({
    super.key,
    required this.onSaved,
    required this.onApiError,
  });

  final VoidCallback onSaved;
  final ValueChanged<ApiException> onApiError;

  @override
  State<AdminRateForm> createState() => _AdminRateFormState();
}

class _AdminRateFormState extends State<AdminRateForm> {
  final _form = GlobalKey<FormState>();
  final _rate = TextEditingController();
  final _date = TextEditingController();
  final _source = TextEditingController();
  final _remarks = TextEditingController();
  String? _provider;
  DateTime? _effectiveDate;
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _rate.dispose();
    _date.dispose();
    _source.dispose();
    _remarks.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _effectiveDate ?? DateTime.now(),
      firstDate: DateTime(1),
      lastDate: DateTime(9999, 12, 31),
      helpText: 'Select the provider’s effective date',
    );
    if (!mounted || picked == null) return;
    setState(() {
      _effectiveDate = picked;
      _date.text = MaterialLocalizations.of(context).formatShortDate(picked);
    });
  }

  Future<void> _save() async {
    if (_saving || !(_form.currentState?.validate() ?? false)) return;
    setState(() {
      _saving = true;
      _error = null;
    });

    try {
      await ApiService.addAdminRate(
        provider: _provider!,
        ratePerKwh: double.parse(_rate.text.trim()),
        effectiveDate: _effectiveDate!,
        sourceUrl: _source.text,
        remarks: _remarks.text,
      );
      if (!mounted) return;
      setState(() {
        _form.currentState?.reset();
        _provider = null;
        _effectiveDate = null;
        _rate.clear();
        _date.clear();
        _source.clear();
        _remarks.clear();
        _saving = false;
      });
      widget.onSaved();
      showTemporaryMessage(context, 'Electricity rate saved.');
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = error.message;
      });
      widget.onApiError(error);
    }
  }

  String? _validateRate(String? input) {
    final text = input?.trim() ?? '';
    final value = double.tryParse(text);
    if (!RegExp(r'^\d*\.?\d{0,4}$').hasMatch(text) ||
        value == null ||
        value < 0.0001 ||
        value > 999999.9999) {
      return 'Enter a positive rate with up to four decimal places (max ₱999,999.9999).';
    }
    return null;
  }

  String? _validateSource(String? input) {
    final text = input?.trim() ?? '';
    if (text.isEmpty) return null;
    final url = Uri.tryParse(text);
    if (text.length > 1000 ||
        url == null ||
        (url.scheme != 'http' && url.scheme != 'https') ||
        url.host.isEmpty) {
      return 'Enter an HTTP or HTTPS source URL of up to 1,000 characters.';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _form,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Add Provider Rate',
            style: TextStyle(
              color: LandingColors.textPrimary,
              fontSize: AppText.sectionTitle,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          LayoutBuilder(
            builder: (context, constraints) {
              final width = constraints.maxWidth >= 720
                  ? (constraints.maxWidth - AppSpacing.md * 2) / 3
                  : constraints.maxWidth;
              return Wrap(
                spacing: AppSpacing.md,
                runSpacing: AppSpacing.md,
                children: [
                  SizedBox(
                    width: width,
                    child: DropdownButtonFormField<String>(
                      initialValue: _provider,
                      decoration: const InputDecoration(
                        labelText: 'Electricity Provider',
                      ),
                      isExpanded: true,
                      menuMaxHeight: 320,
                      items: [
                        for (final provider in mindanaoElectricityProviders)
                          DropdownMenuItem(
                            value: provider.code,
                            child: Text(
                              provider.label,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                      ],
                      onChanged: _saving ? null : (value) => _provider = value,
                      validator: (value) =>
                          value == null ? 'Choose a provider.' : null,
                    ),
                  ),
                  SizedBox(
                    width: width,
                    child: TextFormField(
                      controller: _rate,
                      readOnly: _saving,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'Rate per kWh (₱)',
                        errorMaxLines: 2,
                      ),
                      validator: _validateRate,
                    ),
                  ),
                  SizedBox(
                    width: width,
                    child: TextFormField(
                      controller: _date,
                      readOnly: true,
                      onTap: _saving ? null : _pickDate,
                      decoration: const InputDecoration(
                        labelText: 'Effective Date',
                        suffixIcon: Icon(Icons.calendar_month_outlined),
                      ),
                      validator: (_) => _effectiveDate == null
                          ? 'Choose the effective date.'
                          : null,
                    ),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: AppSpacing.md),
          TextFormField(
            controller: _source,
            readOnly: _saving,
            keyboardType: TextInputType.url,
            decoration: const InputDecoration(
              labelText: 'Official Source URL (optional)',
            ),
            validator: _validateSource,
          ),
          const SizedBox(height: AppSpacing.md),
          TextFormField(
            controller: _remarks,
            readOnly: _saving,
            decoration: const InputDecoration(labelText: 'Remarks (optional)'),
            validator: (value) => (value ?? '').trim().runes.length > 2000
                ? 'Use up to 2,000 characters.'
                : null,
          ),
          if (_error case final error?) ...[
            const SizedBox(height: AppSpacing.md),
            Semantics(
              liveRegion: true,
              child: Text(
                error,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.lg),
          ElevatedButton(
            onPressed: _saving ? null : _save,
            child: Text(_saving ? 'Saving…' : 'Save Rate'),
          ),
        ],
      ),
    );
  }
}
