import 'package:flutter/material.dart';

import '../landing/landing_widgets.dart'
    show LandingSecondaryButton, LandingStatTile, ThemeToggleButton;
import '../models/auth_session.dart';
import '../models/billing_data.dart';
import '../services/api_service.dart';
import '../theme/app_effects.dart';
import '../theme/app_theme.dart';
import '../theme/app_tokens.dart';
import '../theme/landing_colors.dart';
import '../widgets/admin_rate_form.dart';
import '../widgets/app_components.dart';
import '../widgets/app_top_bar.dart';
import 'home_screen.dart';

typedef _Row = Map<String, dynamic>;
typedef _Collection<T> = ({List<T>? items, String? error});

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  late Future<_Collection<_Row>> _users;
  late Future<_Collection<_Row>> _households;
  late Future<_Collection<_Row>> _consumption;
  late Future<_Collection<_Row>> _forecasts;
  late Future<_Collection<ProviderRate>> _rates;
  bool _accessDenied = false;

  bool get _canAccess =>
      !_accessDenied && ApiService.session?.role == AccountRole.admin;

  @override
  void initState() {
    super.initState();
    if (_canAccess) {
      _users = _load(ApiService.getAdminUsers);
      _households = _load(ApiService.getAdminHouseholds);
      _consumption = _load(ApiService.getAdminConsumption);
      _forecasts = _load(ApiService.getAdminForecasts);
      _rates = _load(ApiService.getAdminRates);
    }
  }

  Future<_Collection<T>> _load<T>(Future<List<T>> Function() request) async {
    try {
      return (items: await request(), error: null);
    } on ApiException catch (error) {
      _handleAccessError(error);
      return (items: null, error: error.message);
    } catch (_) {
      return (items: null, error: 'Could not load records. Please try again.');
    }
  }

  void _handleAccessError(ApiException error) {
    if (mounted && (error.statusCode == 401 || error.statusCode == 403)) {
      setState(() => _accessDenied = true);
    }
  }

  void _reloadRates() {
    setState(() {
      _rates = _load(ApiService.getAdminRates);
    });
  }

  void _signOut() {
    ApiService.logout();
    ThemeController.resetToLight();
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const HomeScreen()),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: AppTheme.lightTheme,
      child: Scaffold(
        body: AppBackground(
          child: Column(
            children: [
              const AppTopBar(),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(AppLayout.pagePadding),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(
                        maxWidth: AppLayout.contentMaxWidth,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _buildHeader(),
                          const SizedBox(height: AppSpacing.xl),
                          if (_canAccess) ...[
                            _buildOverview(),
                            const SizedBox(height: AppSpacing.xl),
                            ..._buildSections(),
                          ] else
                            GlassCard(
                              child: _status(
                                'Administrator access required. Sign in with an administrator account.',
                                error: true,
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
      ),
    );
  }

  Widget _buildHeader() {
    return GlassCard(
      child: Wrap(
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: AppSpacing.lg,
        runSpacing: AppSpacing.lg,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const AppIconBadge(
                icon: Icons.admin_panel_settings_outlined,
                size: 44,
              ),
              const SizedBox(width: AppSpacing.md),
              Flexible(
                child: Text(
                  'Admin Dashboard',
                  style: TextStyle(
                    color: LandingColors.textPrimary,
                    fontSize: AppText.pageTitle,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const ThemeToggleButton(),
              const SizedBox(width: AppSpacing.sm),
              LandingSecondaryButton(label: 'Sign Out', onPressed: _signOut),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOverview() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle('Overview'),
        const SizedBox(height: AppSpacing.md),
        LayoutBuilder(
          builder: (context, constraints) {
            final columns = constraints.maxWidth >= 900
                ? 4
                : constraints.maxWidth >= 450
                ? 2
                : 1;
            final width =
                (constraints.maxWidth - AppSpacing.md * (columns - 1)) /
                columns;
            return Wrap(
              spacing: AppSpacing.md,
              runSpacing: AppSpacing.md,
              children: [
                SizedBox(width: width, child: _count('Users', _users)),
                SizedBox(
                  width: width,
                  child: _count('Households', _households),
                ),
                SizedBox(
                  width: width,
                  child: _count('Meter readings', _consumption),
                ),
                SizedBox(width: width, child: _count('Forecasts', _forecasts)),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _count(String label, Future<_Collection<_Row>> future) =>
      FutureBuilder<_Collection<_Row>>(
        future: future,
        builder: (context, snapshot) {
          final loading = snapshot.connectionState == ConnectionState.waiting;
          final rows = snapshot.data?.items;
          return LandingStatTile(
            label: label,
            value: loading ? '…' : rows?.length.toString() ?? '—',
            caption: loading
                ? 'Loading'
                : rows == null
                ? 'Unavailable'
                : 'Total records',
          );
        },
      );

  List<Widget> _buildSections() {
    final dates = MaterialLocalizations.of(context);
    return [
      _section(
        title: 'User Management',
        icon: Icons.people_outline_rounded,
        child: _records(
          future: _users,
          empty: 'No users found.',
          retry: () => setState(() {
            _users = _load(ApiService.getAdminUsers);
          }),
          columns: const ['User ID', 'Username', 'Email', 'Role', 'Registered'],
          row: (data) => [
            _text(data['user_id']),
            _text(data['username']),
            _text(data['email']),
            _text(data['role']),
            _date(dates, data['created_at']),
          ],
        ),
      ),
      _section(
        title: 'Household Monitoring',
        icon: Icons.home_work_outlined,
        child: _records(
          future: _households,
          empty: 'No households found.',
          retry: () => setState(() {
            _households = _load(ApiService.getAdminHouseholds);
          }),
          columns: const [
            'Household ID',
            'Household',
            'Address',
            'Owner',
            'Email',
            'Meter readings',
            'Total kWh',
          ],
          row: (data) => [
            _text(data['household_id']),
            _text(data['household_name']),
            _text(data['address']),
            _text(data['owner']),
            _text(data['email']),
            _text(data['consumption_records']),
            _number(data['total_kwh']),
          ],
        ),
      ),
      _section(
        title: 'Consumption Records',
        icon: Icons.speed_outlined,
        child: _records(
          future: _consumption,
          empty: 'No meter readings found.',
          retry: () => setState(() {
            _consumption = _load(ApiService.getAdminConsumption);
          }),
          columns: const [
            'Record ID',
            'Household',
            'Reading Date',
            'kWh',
            'Previous Meter',
            'Current Meter',
          ],
          row: (data) => [
            _text(data['consumption_id']),
            _text(data['household']),
            _date(dates, data['date']),
            _number(data['kwh']),
            _number(data['meter_previous']),
            _number(data['meter_current']),
          ],
        ),
      ),
      _section(
        title: 'Forecast Records',
        icon: Icons.insights_outlined,
        child: _records(
          future: _forecasts,
          empty: 'No forecasts found.',
          retry: () => setState(() {
            _forecasts = _load(ApiService.getAdminForecasts);
          }),
          columns: const [
            'Forecast ID',
            'Household',
            'Type',
            'Period',
            'Predicted kWh',
            'Estimated Bill',
            'Created',
          ],
          row: (data) {
            final type = data['forecast_type'];
            return [
              _text(data['forecast_id']),
              _text(data['household']),
              switch (type) {
                'monthly' => 'Monthly',
                'daily' => 'Legacy daily',
                _ => _text(type),
              },
              _date(dates, data['forecast_date'], month: type == 'monthly'),
              _number(data['predicted_kwh']),
              _number(data['estimated_bill'], prefix: '₱'),
              _date(dates, data['created_at']),
            ];
          },
        ),
      ),
      _section(
        title: 'Electricity Rates',
        icon: Icons.bolt_outlined,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AdminRateForm(
              onSaved: _reloadRates,
              onApiError: _handleAccessError,
            ),
            const SizedBox(height: AppSpacing.xl),
            _sectionTitle('Rate History'),
            const SizedBox(height: AppSpacing.md),
            _records(
              future: _rates,
              empty: 'No rate records found.',
              retry: _reloadRates,
              columns: const [
                'Provider',
                '₱/kWh',
                'Effective Date',
                'Source URL',
                'Remarks',
                'Added',
              ],
              row: (rate) => [
                rate.provider ?? 'Legacy / Unassigned',
                rate.ratePerKwh.toStringAsFixed(4),
                dates.formatShortDate(rate.effectiveDate),
                _text(rate.sourceUrl),
                _text(rate.remarks),
                _date(dates, rate.createdAt),
              ],
            ),
          ],
        ),
      ),
    ];
  }

  Widget _section({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: GlassCard(
        padding: EdgeInsets.zero,
        child: ExpansionTile(
          key: ValueKey(title),
          maintainState: true,
          shape: const Border(),
          collapsedShape: const Border(),
          tilePadding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          childrenPadding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            0,
            AppSpacing.lg,
            AppSpacing.lg,
          ),
          leading: AppIconBadge(icon: icon, size: 34),
          title: Text(
            title,
            style: TextStyle(
              color: LandingColors.textPrimary,
              fontSize: AppText.cardTitle,
              fontWeight: FontWeight.w700,
            ),
          ),
          children: [child],
        ),
      ),
    );
  }

  Widget _records<T>({
    required Future<_Collection<T>> future,
    required String empty,
    required VoidCallback retry,
    required List<String> columns,
    required List<String> Function(T) row,
  }) {
    return FutureBuilder<_Collection<T>>(
      future: future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const LinearProgressIndicator(
            semanticsLabel: 'Loading records',
          );
        }
        final data = snapshot.data;
        if (data?.error case final error?) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _status(error, error: true),
              TextButton(onPressed: retry, child: const Text('Retry')),
            ],
          );
        }
        final items = data?.items;
        if (items == null || items.isEmpty) return _status(empty);
        return _AdminTable(columns: columns, rows: items.map(row).toList());
      },
    );
  }

  Widget _sectionTitle(String title) => Text(
    title,
    style: TextStyle(
      color: LandingColors.textPrimary,
      fontSize: AppText.sectionTitle,
      fontWeight: FontWeight.w700,
    ),
  );

  Widget _status(String message, {bool error = false}) => Semantics(
    liveRegion: true,
    child: Text(
      message,
      style: TextStyle(
        color: error
            ? Theme.of(context).colorScheme.error
            : LandingColors.textSecondary,
        fontSize: AppText.body,
      ),
    ),
  );
}

class _AdminTable extends StatefulWidget {
  const _AdminTable({required this.columns, required this.rows});

  final List<String> columns;
  final List<List<String>> rows;

  @override
  State<_AdminTable> createState() => _AdminTableState();
}

class _AdminTableState extends State<_AdminTable> {
  final _scroll = ScrollController(keepScrollOffset: false);

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) => Scrollbar(
      controller: _scroll,
      thumbVisibility: true,
      child: SingleChildScrollView(
        controller: _scroll,
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.only(bottom: AppSpacing.sm),
        child: ConstrainedBox(
          constraints: BoxConstraints(minWidth: constraints.maxWidth),
          child: SelectionArea(
            child: DataTable(
              headingRowColor: WidgetStatePropertyAll(
                LandingColors.backgroundSoft,
              ),
              columnSpacing: AppSpacing.xl,
              columns: widget.columns
                  .map((title) => DataColumn(label: Text(title)))
                  .toList(),
              rows: [
                for (final row in widget.rows)
                  DataRow(
                    cells: [
                      for (final value in row)
                        DataCell(
                          ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 240),
                            child: Tooltip(
                              message: value,
                              excludeFromSemantics: true,
                              child: Text(
                                value,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

String _text(Object? value) {
  final text = value?.toString().trim();
  return text == null || text.isEmpty ? '—' : text;
}

String _number(Object? value, {String prefix = ''}) =>
    value is num ? '$prefix${value.toStringAsFixed(2)}' : '—';

String _date(MaterialLocalizations dates, Object? value, {bool month = false}) {
  final date = value is DateTime ? value : DateTime.tryParse('${value ?? ''}');
  if (date == null) return '—';
  final local = date.toLocal();
  return month ? dates.formatMonthYear(local) : dates.formatShortDate(local);
}
