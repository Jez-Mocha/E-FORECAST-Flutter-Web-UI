import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../models/household.dart';
import '../services/api_service.dart';
import '../theme/app_effects.dart';
import '../theme/app_tokens.dart';
import '../theme/landing_colors.dart';
import '../widgets/app_back_link.dart';
import '../widgets/app_top_bar.dart';

class HistoricalConsumptionScreen extends StatefulWidget {
  final Household household;

  const HistoricalConsumptionScreen({super.key, required this.household});

  @override
  State<HistoricalConsumptionScreen> createState() =>
      _HistoricalConsumptionScreenState();
}

class _HistoricalEntry {
  final DateTime month;
  final TextEditingController controller;

  _HistoricalEntry(this.month, {String value = ''})
    : controller = TextEditingController(text: value);

  void dispose() => controller.dispose();
}

class _HistoricalConsumptionScreenState
    extends State<HistoricalConsumptionScreen> {
  final _formKey = GlobalKey<FormState>();

  late DateTime _latestMonth;
  late List<_HistoricalEntry> _entries;

  Uint8List? _imageBytes;
  String? _imageName;
  String? _scanMessage;
  String? _errorMessage;

  bool _isScanning = false;
  bool _isSaving = false;
  bool _isManualMode = false;
  bool _hasScanned = false;

  static const _monthNames = [
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

  @override
  void initState() {
    super.initState();

    final now = DateTime.now();
    _latestMonth = DateTime(now.year, now.month);
    _entries = _createEntries(_latestMonth);
  }

  @override
  void dispose() {
    for (final entry in _entries) {
      entry.dispose();
    }
    super.dispose();
  }

  List<_HistoricalEntry> _createEntries(DateTime latestMonth) {
    return List.generate(6, (index) {
      final month = DateTime(latestMonth.year, latestMonth.month - 5 + index);
      return _HistoricalEntry(month);
    });
  }

  void _changeLatestMonth(DateTime? value) {
    if (value == null) return;

    final oldValues = {
      for (final entry in _entries)
        '${entry.month.year}-${entry.month.month}': entry.controller.text,
    };

    for (final entry in _entries) {
      entry.dispose();
    }

    final generated = _createEntries(value);

    for (final entry in generated) {
      final key = '${entry.month.year}-${entry.month.month}';
      entry.controller.text = oldValues[key] ?? '';
    }

    setState(() {
      _latestMonth = value;
      _entries = generated;
      _errorMessage = null;
    });
  }

  String _monthLabel(DateTime month) =>
      '${_monthNames[month.month - 1]} ${month.year}';

  Future<void> _chooseBillImage() async {
    if (_isScanning || _isSaving) return;

    try {
      final file = await FilePicker.pickFile(type: FileType.image);

      if (file == null) return;

      final fileName = file.name.trim();
      final dotIndex = fileName.lastIndexOf('.');
      final extension =
          (file.extension?.trim().isNotEmpty == true
                  ? file.extension!.trim()
                  : dotIndex >= 0
                  ? fileName.substring(dotIndex + 1)
                  : '')
              .replaceFirst(RegExp(r'^\.'), '')
              .toLowerCase();

      if (!['jpg', 'jpeg', 'png', 'webp'].contains(extension)) {
        _showMessage('Please select a JPG, PNG, or WEBP image.');
        return;
      }

      final bytes = await file.readAsBytes();

      if (bytes.length > 10 * 1024 * 1024) {
        _showMessage('The image must not exceed 10 MB.');
        return;
      }

      setState(() {
        _imageBytes = bytes;
        _imageName = file.name;
        _scanMessage = null;
        _errorMessage = null;
      });
    } catch (_) {
      _showMessage('Could not select the bill image. Please try again.');
    }
  }

  Future<void> _scanBill() async {
    if (_imageBytes == null || _imageName == null) {
      _showMessage('Please select a bill image first.');
      return;
    }

    setState(() {
      _isScanning = true;
      _scanMessage = null;
      _errorMessage = null;
    });

    try {
      final result = await ApiService.scanElectricityBill(
        imageBytes: _imageBytes!,
        filename: _imageName!,
        latestMonth: _latestMonth,
      );

      if (!mounted) return;

      final records = result['records'];

      int matched = 0;

      if (records is List) {
        for (final item in records) {
          if (item is! Map) continue;

          final date = DateTime.tryParse(
            item['billing_month']?.toString() ?? '',
          );
          final value = item['consumption_kwh'];

          if (date == null || value == null) continue;

          final entry = _entries.where(
            (e) => e.month.year == date.year && e.month.month == date.month,
          );

          if (entry.isNotEmpty) {
            entry.first.controller.text = value.toString();
            matched++;
          }
        }
      }

      setState(() {
        _hasScanned = true;
        _scanMessage = matched > 0
            ? 'Found $matched monthly value(s). Review the scanned values below and edit any incorrect entries.'
            : 'The bill was scanned, but exact monthly kWh values could not be reliably identified. Use Edit below to enter the correct values.';
        _isScanning = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _isScanning = false;
        _errorMessage = e.message;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isScanning = false;
        _errorMessage = 'Could not scan the bill. Please try again.';
      });
    }
  }

  Future<void> _saveAll() async {
    if (_isSaving || _isScanning) return;

    if (widget.household.id == null || widget.household.isSample) {
      _showMessage('Historical records require a registered household.');
      return;
    }

    for (final entry in _entries) {
      final number = double.tryParse(entry.controller.text.trim());

      if (number == null ||
          !number.isFinite ||
          number < 0.01 ||
          number > 99999999.99) {
        _showMessage(
          '${_monthLabel(entry.month)} needs a valid consumption value.',
        );
        return;
      }
    }

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    try {
      final records = _entries.map((entry) {
        return {
          'billing_month': entry.month,
          'consumption_kwh': double.parse(entry.controller.text.trim()),
        };
      }).toList();

      await ApiService.recordMonthlyConsumptionBatch(
        householdId: widget.household.id!,
        records: records,
      );

      if (!mounted) return;

      _showMessage('Historical consumption saved successfully.');
      Navigator.of(context).pop(true);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _isSaving = false;
        _errorMessage = e.message;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isSaving = false;
        _errorMessage = 'Could not save the historical records.';
      });
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
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
                          label: 'Household Dashboard',
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          'Historical Consumption',
                          style: TextStyle(
                            color: LandingColors.textPrimary,
                            fontSize: AppText.pageTitle,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Add your previous monthly electricity consumption '
                          'to help improve your forecast.',
                          style: TextStyle(
                            color: LandingColors.textSecondary,
                            fontSize: AppText.body,
                          ),
                        ),
                        const SizedBox(height: 22),
                        _buildOptionSelector(),
                        const SizedBox(height: 20),
                        if (_isManualMode)
                          _buildManualEntryCard()
                        else ...[
                          _buildUploadCard(),
                          if (_hasScanned) ...[
                            const SizedBox(height: 20),
                            _buildScanReviewCard(),
                          ],
                        ],
                        if (_errorMessage != null) ...[
                          const SizedBox(height: 16),
                          _messageBox(
                            _errorMessage!,
                            Colors.red,
                            Icons.error_outline,
                          ),
                        ],
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

  Widget _buildOptionSelector() {
    return _sectionCard(
      title: 'Add Historical Consumption',
      subtitle: 'Choose how you want to provide your previous electricity consumption.',
      icon: Icons.history_rounded,
      child: Wrap(
        spacing: 10,
        runSpacing: 10,
        children: [
          ChoiceChip(
            avatar: const Icon(Icons.upload_file_rounded, size: 18),
            label: const Text('Upload Bill Photos'),
            selected: !_isManualMode,
            onSelected: _isScanning || _isSaving
                ? null
                : (selected) {
                    if (selected) {
                      setState(() => _isManualMode = false);
                    }
                  },
          ),
          ChoiceChip(
            avatar: const Icon(Icons.edit_note_rounded, size: 18),
            label: const Text('Manual Input'),
            selected: _isManualMode,
            onSelected: _isScanning || _isSaving
                ? null
                : (selected) {
                    if (selected) {
                      setState(() => _isManualMode = true);
                    }
                  },
          ),
        ],
      ),
    );
  }

  Widget _buildLatestMonthDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Select Latest Billing Month',
          style: TextStyle(
            color: LandingColors.textPrimary,
            fontWeight: FontWeight.w600,
            fontSize: AppText.body,
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<DateTime>(
          initialValue: _latestMonth,
          decoration: const InputDecoration(
            labelText: 'Latest billing month',
            border: OutlineInputBorder(),
            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          ),
          items: List.generate(24, (index) {
            final now = DateTime.now();
            final month = DateTime(now.year, now.month - index);

            return DropdownMenuItem(
              value: month,
              child: Text(_monthLabel(month)),
            );
          }),
          onChanged: _isSaving || _isScanning ? null : _changeLatestMonth,
        ),
      ],
    );
  }

  Widget _buildUploadCard() {
    return _sectionCard(
      title: 'Upload Electricity Bill',
      subtitle:
          'Choose a clear picture of your electricity bill. '
          'The system will try to read its monthly consumption values.',
      icon: Icons.receipt_long_rounded,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildLatestMonthDropdown(),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: _isScanning || _isSaving || _imageBytes != null
                ? null
                : _chooseBillImage,
            icon: const Icon(Icons.upload_file_rounded),
            label: Text(
              _imageName == null
                  ? 'Choose Bill Picture'
                  : 'Bill Picture Selected',
            ),
          ),
          if (_imageBytes != null) ...[
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: LandingColors.blueTint,
                borderRadius: BorderRadius.circular(AppRadius.card),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _imageName ?? 'Selected bill',
                    style: TextStyle(
                      color: LandingColors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 10),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.memory(
                      _imageBytes!,
                      height: 230,
                      width: double.infinity,
                      fit: BoxFit.contain,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: _isScanning || _isSaving ? null : _scanBill,
              icon: _isScanning
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.document_scanner_outlined),
              label: Text(_isScanning ? 'Scanning Bill...' : 'Scan Bill'),
            ),
          ],
          if (_scanMessage != null) ...[
            const SizedBox(height: 14),
            _messageBox(_scanMessage!, Colors.blue, Icons.info_outline),
          ],
        ],
      ),
    );
  }

  Widget _buildScanReviewCard() {
    return _sectionCard(
      title: 'Scanned Monthly Consumption',
      subtitle:
          'Review the values extracted from your bill. Use Edit to correct '
          'a value or enter one that was not detected.',
      icon: Icons.fact_check_outlined,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ..._entries.map(_buildMonthReviewRow),
          const SizedBox(height: 8),
          FilledButton.icon(
            onPressed: _isSaving || _isScanning ? null : _saveAll,
            icon: _isSaving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.save_rounded),
            label: Text(_isSaving ? 'Saving...' : 'Save All'),
          ),
          const SizedBox(height: 8),
          Text(
            'Check all six monthly values before saving. '
            'Months already saved for this household cannot be duplicated.',
            style: TextStyle(
              color: LandingColors.textSecondary,
              fontSize: AppText.caption,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildManualEntryCard() {
    return _sectionCard(
      title: 'Manual Monthly Consumption',
      subtitle:
          'Select the latest billing month. The previous five months '
          'will be generated automatically. Enter the kWh for each month.',
      icon: Icons.edit_calendar_outlined,
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildLatestMonthDropdown(),
            const SizedBox(height: 18),
            ..._entries.map(_buildMonthInputRow),
            const SizedBox(height: 8),
            FilledButton.icon(
              onPressed: _isSaving || _isScanning ? null : _saveAll,
              icon: _isSaving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.save_rounded),
              label: Text(_isSaving ? 'Saving...' : 'Save All'),
            ),
            const SizedBox(height: 8),
            Text(
              'All six monthly records will be saved together. '
              'Months already saved for this household cannot be duplicated.',
              style: TextStyle(
                color: LandingColors.textSecondary,
                fontSize: AppText.caption,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMonthInputRow(_HistoricalEntry entry) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextFormField(
        controller: entry.controller,
        enabled: !_isSaving && !_isScanning,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        decoration: InputDecoration(
          labelText: 'Consumption for ${_monthLabel(entry.month)}',
          suffixText: 'kWh',
          border: const OutlineInputBorder(),
          prefixIcon: const Icon(Icons.bolt_rounded),
        ),
        validator: (value) {
          final number = double.tryParse(value?.trim() ?? '');

          if (number == null || !number.isFinite) {
            return 'Enter a valid consumption value.';
          }
          if (number < 0.01) {
            return 'Value must be at least 0.01 kWh.';
          }
          if (number > 99999999.99) {
            return 'The value is too large.';
          }
          return null;
        },
      ),
    );
  }

  Widget _buildMonthReviewRow(_HistoricalEntry entry) {
    final value = entry.controller.text.trim();
    final hasValue = value.isNotEmpty;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: LandingColors.blueTint.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: LandingColors.border),
      ),
      child: Row(
        children: [
          Icon(Icons.bolt_rounded, color: LandingColors.primary, size: 23),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _monthLabel(entry.month),
                  style: TextStyle(
                    color: LandingColors.textPrimary,
                    fontWeight: FontWeight.w700,
                    fontSize: AppText.body,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  hasValue ? '$value kWh' : 'Not detected',
                  style: TextStyle(
                    color: hasValue
                        ? LandingColors.textPrimary
                        : LandingColors.textSecondary,
                    fontSize: AppText.body,
                    fontWeight: hasValue ? FontWeight.w600 : FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
          OutlinedButton.icon(
            onPressed: _isSaving || _isScanning
                ? null
                : () => _editMonthValue(entry),
            icon: const Icon(Icons.edit_outlined, size: 17),
            label: const Text('Edit'),
          ),
        ],
      ),
    );
  }

  Future<void> _editMonthValue(_HistoricalEntry entry) async {
    final controller = TextEditingController(text: entry.controller.text);

    String? validationError;

    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, updateDialog) {
            return AlertDialog(
              title: Text('Edit ${_monthLabel(entry.month)}'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Enter the correct monthly consumption value.'),
                  const SizedBox(height: 16),
                  TextField(
                    controller: controller,
                    autofocus: true,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: InputDecoration(
                      labelText: 'Consumption',
                      suffixText: 'kWh',
                      border: const OutlineInputBorder(),
                      errorText: validationError,
                    ),
                    onChanged: (_) {
                      if (validationError != null) {
                        updateDialog(() => validationError = null);
                      }
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(false),
                  child: const Text('Cancel'),
                ),
                FilledButton.icon(
                  onPressed: () {
                    final number = double.tryParse(controller.text.trim());

                    if (number == null || !number.isFinite) {
                      updateDialog(
                        () => validationError = 'Enter a valid number.',
                      );
                      return;
                    }

                    if (number < 0.01) {
                      updateDialog(
                        () => validationError =
                            'Value must be at least 0.01 kWh.',
                      );
                      return;
                    }

                    if (number > 99999999.99) {
                      updateDialog(
                        () => validationError = 'The value is too large.',
                      );
                      return;
                    }

                    Navigator.of(dialogContext).pop(true);
                  },
                  icon: const Icon(Icons.check_rounded),
                  label: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );

    if (saved == true && mounted) {
      setState(() {
        entry.controller.text = controller.text.trim();
        _errorMessage = null;
      });
    }

    controller.dispose();
  }

  Widget _sectionCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: LandingColors.surface,
        borderRadius: BorderRadius.circular(LandingRadius.card),
        border: Border.all(color: LandingColors.border),
        boxShadow: AppEffects.raised,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: LandingColors.primary, size: 24),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: LandingColors.textPrimary,
                    fontSize: AppText.cardTitle,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: TextStyle(
              color: LandingColors.textSecondary,
              fontSize: AppText.body,
            ),
          ),
          const SizedBox(height: 18),
          child,
        ],
      ),
    );
  }

  Widget _messageBox(String message, Color color, IconData icon) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        border: Border.all(color: color.withValues(alpha: 0.35)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: LandingColors.textPrimary,
                fontSize: AppText.body,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
