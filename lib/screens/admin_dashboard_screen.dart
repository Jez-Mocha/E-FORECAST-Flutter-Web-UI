import 'package:flutter/material.dart';

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
  

  List<Map<String, dynamic>> _users = [];
  List<Map<String, dynamic>> _households = [];
  List<Map<String, dynamic>> _forecasts = [];
  List<Map<String, dynamic>> _consumption = [];

  @override
  void initState() {
    super.initState();
    _loadAdminData();
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
      ]);

      if (!mounted) return;

      setState(() {
        _users = results[0];
        _households = results[1];
        _forecasts = results[2];
        _consumption = results[3];
        _isLoading = false;
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
            const DashboardSidebar(),
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
