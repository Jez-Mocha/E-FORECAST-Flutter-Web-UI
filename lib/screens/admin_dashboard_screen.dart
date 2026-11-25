import 'package:flutter/material.dart';

import '../models/electricity_provider.dart';

import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../theme/app_tokens.dart';
import '../theme/landing_colors.dart';
import '../widgets/dashboard_sidebar.dart';
import '../landing/landing_widgets.dart'
    show LandingCard, LandingContainer, ThemeToggleButton;
import 'home_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() =>
      _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  bool _isLoading = true;
  String? _loadError;
  bool _showHouseholdAccounts = false;
  bool _showRegisteredHouseholds = false;
  bool _showForecastMonitoring = false;
  bool _showConsumptionRecords = false;
  bool _showElectricityRates = false;
  

  List<Map<String, dynamic>> _users = [];
  List<Map<String, dynamic>> _households = [];
  List<Map<String, dynamic>> _forecasts = [];
  List<Map<String, dynamic>> _consumption = [];
  List<Map<String, dynamic>> _rates = [];

  String? _selectedProvider;
  final _rateController = TextEditingController();
  final _effectiveDateController = TextEditingController();
  final _sourceUrlController = TextEditingController();
  final _remarksController = TextEditingController();

  bool _isSavingRate = false;

  @override
  void initState() {
    super.initState();
    _loadAdminData();
  }

  @override
  void dispose() {
    _rateController.dispose();
    _effectiveDateController.dispose();
    _sourceUrlController.dispose();
    _remarksController.dispose();
    super.dispose();
  }

  Future<void> _loadAdminData() async {
    setState(() {
      _isLoading = true;
      _loadError = null;
    });

    try {
      final results = await Future.wait([
        ApiService.getAdminUsers(),
        ApiService.getAdminHouseholds(),
        ApiService.getAdminForecasts(),
        ApiService.getAdminConsumption(),
        ApiService.getAdminRates(),
      ]);

      if (!mounted) return;

      setState(() {
        _users = results[0];
        _households = results[1];
        _forecasts = results[2];
        _consumption = results[3];
        _isLoading = false;
        _rates = results[4];
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _loadError = e.toString().replaceFirst('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  void _logout() {
    ApiService.logout();
    ThemeController.resetToLight();

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) => const HomeScreen(),
      ),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < 640;

    return Theme(
      data: AppTheme.lightTheme,
      child: Scaffold(
        backgroundColor: LandingColors.backgroundSoft,
        body: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Column(
                children: [
                  _buildTopBar(),
                  Expanded(
                    child: SingleChildScrollView(
                      child: LandingContainer(
                        child: Padding(
                          padding: EdgeInsets.symmetric(
                            vertical: compact ? 24 : 32,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildHeader(),
                              const SizedBox(height: 28),

                              if (_isLoading)
                                const Center(
                                  child: Padding(
                                    padding: EdgeInsets.all(40),
                                    child: CircularProgressIndicator(),
                                  ),
                                )
                              else if (_loadError != null)
                                _buildError()
                              else ...[
                                _buildOverview(),
                                const SizedBox(height: 28),
                                _buildSection(
                                  'Household Accounts',
                                  'Registered household user accounts',
                                  _users
                                      .where((u) =>
                                          u['role'] == 'HOUSEHOLD_USER')
                                      .length,
                                  Icons.people_outline_rounded,
                                  onTap: () {
                                    setState(() {
                                      _showHouseholdAccounts = !_showHouseholdAccounts;
                                    });
                                  },
                                ),

                                if (_showHouseholdAccounts) ...[
                                  const SizedBox(height: 12),
                                  _buildHouseholdAccountsTable(),
                                ],

                                const SizedBox(height: 16),
                                _buildSection(
                                  'Registered Households',
                                  'Households managed by registered users',
                                  _households.length,
                                  Icons.home_work_outlined,
                                  onTap: () {
                                    setState(() {
                                      _showRegisteredHouseholds =
                                          !_showRegisteredHouseholds;
                                    });
                                  },
                                ),

                                if (_showRegisteredHouseholds) ...[
                                  const SizedBox(height: 12),
                                  _buildRegisteredHouseholdsTable(),
                                ],

                                const SizedBox(height: 16),
                                _buildSection(
                                  'Forecast Monitoring',
                                  'Generated electricity forecasts',
                                  _forecasts.length,
                                  Icons.analytics_outlined,
                                  onTap: () {
                                    setState(() {
                                      _showForecastMonitoring =
                                          !_showForecastMonitoring;
                                    });
                                  },
                                ),

                                if (_showForecastMonitoring) ...[
                                  const SizedBox(height: 12),
                                  _buildForecastMonitoringTable(),
                                ],

                                const SizedBox(height: 16),
                                _buildSection(
                                  'Consumption Records',
                                  'View household electricity consumption records',
                                  _consumption.length,
                                  Icons.electric_meter_outlined,
                                  onTap: () {
                                    setState(() {
                                      _showConsumptionRecords =
                                          !_showConsumptionRecords;
                                    });

                                    debugPrint('Expanded: $_showConsumptionRecords',);
                                    },
                                ),
                                if (_showConsumptionRecords) ...[
                                  const SizedBox(height: 12),
                                  _buildConsumptionRecordsTable(),
                                ],

                                const SizedBox(height: 16),
                                _buildSection(
                                  'Electricity Rates',
                                  'Manage provider-specific electricity rates',
                                  _rates.length,
                                  Icons.electric_bolt_outlined,
                                  onTap: () {
                                    setState(() {
                                      _showElectricityRates = !_showElectricityRates;
                                    });
                                  },

                                ),

                                if (_showElectricityRates) ...[
                                  const SizedBox(height: 12),
                                  _buildAddRateForm(),
                                  const SizedBox(height: 20),
                                  _buildElectricityRatesTable(),
                                ],
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
          ],
        ),
      ),
    );
  }


  Future<void> _selectEffectiveDate() async {
    final today = DateTime.now();

    final selectedDate = await showDatePicker(
      context: context,
      initialDate: today,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      helpText: 'Select rate effective date',
    );

    if (selectedDate != null && mounted) {
      setState(() {
        _effectiveDateController.text =
            selectedDate.toIso8601String().split('T').first;
      });
    }
  }

  Future<void> _saveAdminRate() async {
    final provider = _selectedProvider;
    final rate = double.tryParse(_rateController.text.trim());
    final effectiveDate = _effectiveDateController.text.trim();

    if (provider == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select an electricity provider.')),
      );
      return;
    }

    if (rate == null || rate <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a valid rate greater than zero.')),
      );
      return;
    }

    if (effectiveDate.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select an effective date.')),
      );
      return;
    }

    setState(() => _isSavingRate = true);

    try {
      await ApiService.addAdminRate(
        provider: provider,
        ratePerKwh: rate,
        effectiveDate: effectiveDate,
        sourceUrl: _sourceUrlController.text.trim().isEmpty
            ? null
            : _sourceUrlController.text.trim(),
        remarks: _remarksController.text.trim().isEmpty
            ? null
            : _remarksController.text.trim(),
      );

      final updatedRates = await ApiService.getAdminRates();

      if (!mounted) return;

      setState(() {
        _rates = updatedRates;
        _selectedProvider = null;
        _rateController.clear();
        _effectiveDateController.clear();
        _sourceUrlController.clear();
        _remarksController.clear();
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Electricity rate added successfully.'),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Failed to add electricity rate: ${e.toString()}',
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isSavingRate = false);
      }
    }
  }
  Widget _buildAddRateForm() {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade300),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Add New Electricity Rate',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Text(
              'Enter the provider rate and its effective date.',
              style: TextStyle(color: Colors.grey.shade600),
            ),
            const SizedBox(height: 20),
            DropdownButtonFormField<String>(
  initialValue: _selectedProvider,
  isExpanded: true,
  decoration: const InputDecoration(
    labelText: 'Electricity Provider',
    border: OutlineInputBorder(),
  ),
  items: mindanaoElectricityProviders.map((provider) {
    return DropdownMenuItem<String>(
      value: provider.code,
      child: Text(provider.label),
    );
  }).toList(),
  onChanged: _isSavingRate
      ? null
      : (value) {
          setState(() {
            _selectedProvider = value;
          });
        },
),
            const SizedBox(height: 14),
            TextField(
              controller: _rateController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Rate per kWh (₱)',
                hintText: 'e.g. 12.50',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _effectiveDateController,
              readOnly: true,
              onTap: _selectEffectiveDate,
              decoration: const InputDecoration(
                labelText: 'Effective Date',
                hintText: 'Select effective date',
                suffixIcon: Icon(Icons.calendar_today),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _sourceUrlController,
              keyboardType: TextInputType.url,
              decoration: const InputDecoration(
                labelText: 'Source URL (Optional)',
                hintText: 'https://example.com',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _remarksController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Remarks (Optional)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isSavingRate ? null : _saveAdminRate,
                icon: _isSavingRate
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.save_outlined),
                label: Text(
                  _isSavingRate ? 'Saving...' : 'Save Electricity Rate',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  Widget _buildElectricityRatesTable() {
    if (_rates.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Text('No electricity rate records found.'),
      );
    }

    return Column(
      children: _rates.map((rate) {
        final provider =
            rate['provider']?.toString() ?? 'Legacy / Unassigned';
        final amount =
            double.tryParse(rate['rate_per_kwh']?.toString() ?? '') ?? 0;
        final effectiveDate =
            rate['effective_date']?.toString() ?? 'N/A';
        final remarks = rate['remarks']?.toString() ?? '';

        return Card(
          margin: const EdgeInsets.only(bottom: 10),
          child: ListTile(
            leading: const Icon(Icons.electric_bolt_outlined),
            title: Text(provider),
            subtitle: Text(
              'Effective: $effectiveDate'
              '${remarks.isNotEmpty ? '\n$remarks' : ''}',
            ),
            trailing: Text(
              '₱${amount.toStringAsFixed(2)}/kWh',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildTopBar() {
    return Container(
      height: DashboardSidebar.headerHeight,
      decoration: BoxDecoration(
        color: LandingColors.background,
        border: Border(
          bottom: BorderSide(color: LandingColors.border),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              const ThemeToggleButton(),
              const SizedBox(width: 12),
              TextButton.icon(
                onPressed: _logout,
                icon: const Icon(Icons.logout_rounded, size: 18),
                label: const Text('Logout'),
                style: TextButton.styleFrom(
                  foregroundColor: LandingColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Admin Dashboard',
          style: TextStyle(
            color: LandingColors.textPrimary,
            fontSize: AppText.pageTitle,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Monitor E-FORECAST users, households, and system records.',
          style: TextStyle(
            color: LandingColors.textSecondary,
            fontSize: 14,
            height: 1.5,
          ),
        ),
      ],
    );
  }

  Widget _buildOverview() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'System Overview',
          style: TextStyle(
            color: LandingColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 16),
        LayoutBuilder(
          builder: (context, constraints) {
            const spacing = 16.0;
            final columns = constraints.maxWidth >= 900
                ? 4
                : constraints.maxWidth >= 520
                    ? 2
                    : 1;

            final width =
                (constraints.maxWidth - spacing * (columns - 1)) /
                    columns;

            final items = [
              _OverviewItem(
                title: 'Total Users',
                value: _users.length,
                icon: Icons.people_outline_rounded,
              ),
              _OverviewItem(
                title: 'Households',
                value: _households.length,
                icon: Icons.home_work_outlined,
              ),
              _OverviewItem(
                title: 'Forecasts',
                value: _forecasts.length,
                icon: Icons.analytics_outlined,
              ),
              _OverviewItem(
                title: 'Consumption Records',
                value: _consumption.length,
                icon: Icons.electric_meter_outlined,
              ),
            ];

            return Wrap(
              spacing: spacing,
              runSpacing: spacing,
              children: [
                for (final item in items)
                  SizedBox(
                    width: width,
                    child: _OverviewCard(item: item),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildSection(
    String title,
    String description,
    int count,
    IconData icon, {
    VoidCallback? onTap,
  }) {
    return LandingCard(
      padding: const EdgeInsets.all(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: LandingColors.periwinkleTint,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: LandingColors.primary,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: LandingColors.textPrimary,
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: TextStyle(
                      color: LandingColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              count.toString(),
              style: TextStyle(
                color: LandingColors.primary,
                fontSize: 22,
                fontWeight: FontWeight.w700,
              ),
            ),
            if (onTap != null) ...[
              const SizedBox(width: 8),
              Icon(
                Icons.keyboard_arrow_down_rounded,
                color: LandingColors.textSecondary,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildHouseholdAccountsTable() {
    final accounts = _users
        .where((u) => u['role'] == 'HOUSEHOLD_USER')
        .toList();
        
    return LandingCard(
      padding: const EdgeInsets.all(20),
      child: accounts.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    Icon(
                      Icons.people_outline_rounded,
                      size: 32,
                      color: LandingColors.textSecondary,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'No household accounts registered yet.',
                      style: TextStyle(
                        color: LandingColors.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
          )
          : SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                horizontalMargin: 20,
                columnSpacing: 32,
                headingRowHeight: 52,
                dataRowMinHeight: 56,
                dataRowMaxHeight: 64,
                headingRowColor: WidgetStatePropertyAll(
                  LandingColors.periwinkleTint,
                ),
                headingTextStyle: TextStyle(
                  color: LandingColors.primary,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
                dataTextStyle: TextStyle(
                  color: LandingColors.textPrimary,
                  fontSize: 13,
                ),
                columns: const [
                  DataColumn(label: Text('User ID')),
                  DataColumn(label: Text('Username')),
                  DataColumn(label: Text('Email')),
                  DataColumn(label: Text('Date Registered')),
                ],
                rows: accounts.map((user) {
                  return DataRow(
                    cells: [
                      DataCell(Text(
                        user['user_id']?.toString() ?? '-',
                      )),
                      DataCell(Text(
                        user['username']?.toString() ?? '-',
                      )),
                      DataCell(Text(
                        user['email']?.toString() ?? '-',
                      )),
                      DataCell(Text(
                        user['created_at']?.toString() ?? '-',
                      )),
                    ],
                  );
                }).toList(),
             ),
            ),
        );
  }

  Widget _buildRegisteredHouseholdsTable() {
  return LandingCard(
    padding: const EdgeInsets.all(20),
    child: _households.isEmpty
        ? Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Icon(
                    Icons.home_work_outlined,
                    size: 32,
                    color: LandingColors.textSecondary,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'No registered households yet.',
                    style: TextStyle(
                      color: LandingColors.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          )
        : SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              horizontalMargin: 20,
              columnSpacing: 32,
              headingRowHeight: 52,
              dataRowMinHeight: 56,
              dataRowMaxHeight: 64,
              headingRowColor: WidgetStatePropertyAll(
                LandingColors.periwinkleTint,
              ),
              headingTextStyle: TextStyle(
                color: LandingColors.primary,
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
  dataTextStyle: TextStyle(
    color: LandingColors.textPrimary,
    fontSize: 13,
  ),
              columns: const [
                DataColumn(label: Text('Household ID')),
                DataColumn(label: Text('Household Name')),
                DataColumn(label: Text('Address')),
                DataColumn(label: Text('Owner')),
                DataColumn(label: Text('Email')),
              ],
              rows: _households.map((household) {
                return DataRow(
                  cells: [
                    DataCell(Text(
                      household['household_id']?.toString() ?? '-',
                    )),
                    DataCell(Text(
                      household['household_name']?.toString() ?? '-',
                    )),
                    DataCell(Text(
                      household['address']?.toString() ?? '-',
                    )),
                    DataCell(Text(
                      household['owner']?.toString() ?? '-',
                    )),
                    DataCell(Text(
                      household['email']?.toString() ?? '-',
                    )),
                  ],
                );
              }).toList(),
            ),
          ),
  );
}

  Widget _buildForecastMonitoringTable() {
  return LandingCard(
    padding: const EdgeInsets.all(20),
    child: _forecasts.isEmpty
        ? Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Icon(
                    Icons.analytics_outlined,
                    size: 32,
                    color: LandingColors.textSecondary,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'No forecast records available yet.',
                    style: TextStyle(
                      color: LandingColors.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          )
        : SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              columns: const [
                DataColumn(label: Text('Forecast ID')),
                DataColumn(label: Text('Household')),
                DataColumn(label: Text('Predicted kWh')),
                DataColumn(label: Text('Estimated Bill')),
                DataColumn(label: Text('Forecast Date')),
                DataColumn(label: Text('Date Created')),
              ],
              rows: _forecasts.map((forecast) {
                return DataRow(
                  cells: [
                    DataCell(Text(
                      forecast['forecast_id']?.toString() ?? '-',
                    )),
                    DataCell(Text(
                      forecast['household']?.toString() ?? '-',
                    )),
                    DataCell(Text(
                      forecast['predicted_kwh']?.toString() ?? '-',
                    )),
                    DataCell(Text(
                      forecast['estimated_bill']?.toString() ?? '-',
                    )),
                    DataCell(Text(
                      forecast['forecast_date']?.toString() ?? '-',
                    )),
                    DataCell(Text(
                      forecast['created_at']?.toString() ?? '-',
                    )),
                  ],
                );
              }).toList(),
            ),
          ),
  );
}

  Widget _buildConsumptionRecordsTable() {
  return LandingCard(
    padding: const EdgeInsets.all(20),
    child: _consumption.isEmpty
        ? Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Icon(
                    Icons.electric_meter_outlined,
                    size: 32,
                    color: LandingColors.textSecondary,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'No consumption records available yet.',
                    style: TextStyle(
                      color: LandingColors.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          )
        : SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              columns: const [
                DataColumn(label: Text('Consumption ID')),
                DataColumn(label: Text('Household')),
                DataColumn(label: Text('Date')),
                DataColumn(label: Text('kWh')),
                DataColumn(label: Text('Previous Reading')),
                DataColumn(label: Text('Current Reading')),
              ],
              rows: _consumption.map((record) {
                return DataRow(
                  cells: [
                    DataCell(Text(
                      record['consumption_id']?.toString() ?? '-',
                    )),
                    DataCell(Text(
                      record['household']?.toString() ?? '-',
                    )),
                    DataCell(Text(
                      record['date']?.toString() ?? '-',
                    )),
                    DataCell(Text(
                      record['kwh']?.toString() ?? '-',
                    )),
                    DataCell(Text(
                      record['meter_previous']?.toString() ?? '-',
                    )),
                    DataCell(Text(
                      record['meter_current']?.toString() ?? '-',
                    )),
                  ],
                );
              }).toList(),
            ),
          ),
  );
}

  Widget _buildError() {
    return LandingCard(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const Icon(
            Icons.error_outline,
            color: Colors.red,
            size: 32,
          ),
          const SizedBox(height: 12),
          Text(
            'Unable to load admin dashboard',
            style: TextStyle(
              color: LandingColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _loadError!,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: LandingColors.textSecondary,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _loadAdminData,
            child: const Text('Try Again'),
          ),
        ],
      ),
    );
  }
}

class _OverviewItem {
  final String title;
  final int value;
  final IconData icon;

  const _OverviewItem({
    required this.title,
    required this.value,
    required this.icon,
  });
}

class _OverviewCard extends StatelessWidget {
  final _OverviewItem item;

  const _OverviewCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return LandingCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            item.icon,
            color: LandingColors.primary,
            size: 24,
          ),
          const SizedBox(height: 16),
          Text(
            item.value.toString(),
            style: TextStyle(
              color: LandingColors.textPrimary,
              fontSize: 28,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            item.title,
            style: TextStyle(
              color: LandingColors.textSecondary,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}











