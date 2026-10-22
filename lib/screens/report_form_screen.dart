import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../theme/landing_colors.dart';
import '../widgets/app_button.dart';
import '../widgets/app_text_field.dart';
import '../landing/landing_widgets.dart' show LandingCard, LandingContainer;

class ReportFormScreen extends StatefulWidget {
  const ReportFormScreen({super.key});

  @override
  State<ReportFormScreen> createState() => _ReportFormScreenState();
}

class _ReportFormScreenState extends State<ReportFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();

  String _reportType = 'Electricity Consumption / Meter Reading';
  String _priority = 'Normal';
  String _status = 'idle';

  final List<String> _reportTypes = [
    'Electricity Consumption / Meter Reading',
    'Incorrect Forecast / Estimated Bill',
    'App Problem / Feedback',
  ];

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _submitReport() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _status = 'loading');

    // Simulated request. No backend or database is connected.
    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;

    // Demo only: enter [error] in the title to test the Error state.
    if (_titleController.text.toLowerCase().contains('[error]')) {
      setState(() => _status = 'error');
      return;
    }

    setState(() => _status = 'success');
  }

  void _resetForm() {
    _formKey.currentState?.reset();
    _titleController.clear();
    _descriptionController.clear();

    setState(() {
      _reportType = _reportTypes.first;
      _priority = 'Normal';
      _status = 'idle';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: AppTheme.lightTheme,
      child: Scaffold(
        backgroundColor: LandingColors.backgroundSoft,
        appBar: AppBar(
          title: const Text('Submit a Report'),
          backgroundColor: LandingColors.background,
          foregroundColor: LandingColors.textPrimary,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
          child: LandingContainer(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 680),
                child: LandingCard(
                  padding: const EdgeInsets.all(24),
                  child: _buildContent(),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (_status == 'empty') {
      return _buildEmptyState();
    }

    if (_status == 'success') {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.check_circle_outline_rounded,
            color: Colors.green,
            size: 48,
          ),
          const SizedBox(height: 16),
          const Text(
            'Report Submitted Successfully!',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'Your report was processed in this demo. '
            'It has not been saved to a server or database.',
          ),
          const SizedBox(height: 24),
          AppButton(
            label: 'Submit Another Report',
            icon: Icons.add_rounded,
            onPressed: _resetForm,
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Back to Dashboard'),
          ),
        ],
      );
    }

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Report an Issue',
            style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Tell us about a meter-reading issue, an incorrect '
            'forecast or bill, or a problem with the app.',
            style: TextStyle(color: LandingColors.textSecondary, height: 1.5),
          ),
          const SizedBox(height: 24),

          const Text(
            'Report Category',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            initialValue: _reportType,
            isExpanded: true,
            decoration: const InputDecoration(border: OutlineInputBorder()),
            items: _reportTypes.map((type) {
              return DropdownMenuItem(
                value: type,
                child: Text(type, overflow: TextOverflow.ellipsis),
              );
            }).toList(),
            onChanged: _status == 'loading'
                ? null
                : (value) {
                    if (value != null) {
                      setState(() => _reportType = value);
                    }
                  },
          ),

          const SizedBox(height: 20),
          AppTextField(
            label: 'Report Title',
            hint: 'Briefly describe the issue',
            controller: _titleController,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Please enter a report title.';
              }
              if (value.trim().length < 5) {
                return 'Title must contain at least 5 characters.';
              }
              return null;
            },
          ),

          const SizedBox(height: 20),
          AppTextField(
            label: 'Description',
            hint: 'Explain what happened and include relevant details',
            controller: _descriptionController,
            maxLines: 5,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Please describe the issue.';
              }
              if (value.trim().length < 10) {
                return 'Description must contain at least 10 characters.';
              }
              return null;
            },
          ),

          const SizedBox(height: 20),
          const Text('Priority', style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            initialValue: _priority,
            decoration: const InputDecoration(border: OutlineInputBorder()),
            items: const [
              DropdownMenuItem(value: 'Low', child: Text('Low')),
              DropdownMenuItem(value: 'Normal', child: Text('Normal')),
              DropdownMenuItem(value: 'High', child: Text('High')),
            ],
            onChanged: _status == 'loading'
                ? null
                : (value) {
                    if (value != null) {
                      setState(() => _priority = value);
                    }
                  },
          ),

          const SizedBox(height: 24),

          if (_status == 'error')
            const Padding(
              padding: EdgeInsets.only(bottom: 16),
              child: Text(
                'Something went wrong. Correct the report title '
                'or try submitting again.',
                style: TextStyle(color: Colors.red),
              ),
            ),

          AppButton(
            label: 'Submit Report',
            icon: Icons.send_rounded,
            isLoading: _status == 'loading',
            onPressed: _submitReport,
          ),

          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: _status == 'loading'
                  ? null
                  : () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
          ),

          const SizedBox(height: 12),
          TextButton.icon(
            onPressed: _status == 'loading'
                ? null
                : () {
                    setState(() => _status = 'empty');
                  },
            icon: const Icon(Icons.inbox_outlined),
            label: const Text('View Reports'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(Icons.inbox_outlined, size: 48, color: Colors.grey),
        const SizedBox(height: 16),
        const Text(
          'No Reports Yet',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        const Text(
          'No submitted reports are available in this demo. '
          'Create a report to get started.',
        ),
        const SizedBox(height: 24),
        AppButton(
          label: 'Create a Report',
          icon: Icons.add_rounded,
          onPressed: _resetForm,
        ),
        const SizedBox(height: 12),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Back to Dashboard'),
        ),
      ],
    );
  }
}
