import 'package:flutter/material.dart';

import '../landing/landing_widgets.dart'
    show LandingCard, LandingPrimaryButton, SampleDataChip;
import '../models/household.dart';
import '../services/api_service.dart';
import '../theme/app_effects.dart';
import '../theme/app_theme.dart';
import '../theme/app_tokens.dart';
import '../theme/landing_colors.dart';
import '../widgets/app_components.dart';
import '../widgets/app_message.dart';
import '../widgets/dashboard_sidebar.dart';
import '../widgets/household_card.dart';
import '../widgets/welcome_greeting.dart';
import 'add_household_screen.dart';
import 'home_screen.dart';
import 'household_dashboard_screen.dart';
import 'profile_settings_screen.dart';

/// SCR-03: Main Dashboard.
/// Lists the households registered to the signed-in user.
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final List<Household> _households = [];
  bool _isLoadingHouseholds = true;

  Future<void> _loadHouseholds() async {
    try {
      final data = await ApiService.getHouseholds();

      final households = data.map((json) {
        return Household.fromJson(json);
      }).toList();

      if (!mounted) return;

      setState(() {
        _households
          ..clear()
          ..addAll(households);
        _isLoadingHouseholds = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoadingHouseholds = false;
      });

      showTemporaryMessage(
        context,
        'Could not load households. Please try again.',
      );
    }
  }

  @override
  void initState() {
    super.initState();
    _loadHouseholds();
  }

  // ── Actions ───────────────────────────────────────────────────────────────

  /// Opens SCR-04 and waits. If the user saved, adds the household to the list.
  Future<void> _addHousehold() async {
    final created = await Navigator.of(context).push<Household>(
      MaterialPageRoute(builder: (_) => const AddHouseholdScreen()),
    );
    if (!mounted || created == null) return;

    setState(() => _households.insert(0, created));
    showTemporaryMessage(
      context,
      'Added "${created.name}" and saved it to your account.',
    );
  }

  /// Opens SCR-05 for the household that was selected.
  void _viewHousehold(Household household) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => HouseholdDashboardScreen(
          household: household,
          onBillingUpdated: (updated) {
            if (!mounted) return;
            final index = _households.indexWhere((h) => h.id == updated.id);
            if (index != -1) setState(() => _households[index] = updated);
          },
        ),
      ),
    );
  }

  /// Opens the Profile & Settings screen.
  void _openProfile() {
    Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => const ProfileSettingsScreen()));
  }

  /// Clears the login token, returns to the landing page and clears the
  /// screen history.
  void _logout() {
    ApiService.logout();
    ThemeController.resetToLight();
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const HomeScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: AppTheme.lightTheme,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: AppBackground(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Left: glass sidebar with navigation and Electricity Rates.
              DashboardSidebar(onAddHousehold: _addHousehold),

              // Right: top bar, then the scrolling page content.
              Expanded(
                child: Column(
                  children: [
                    _DashboardTopBar(
                      onProfile: _openProfile,
                      onLogout: _logout,
                    ),
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
                                const WelcomeGreeting(),
                                const SizedBox(height: 20),

                                if (!_isLoadingHouseholds) ...[
                                  _MetricsRow(
                                    households: _households,
                                    onAddHousehold: _addHousehold,
                                  ),
                                  const SizedBox(height: 28),
                                ],

                                _SectionHeader(
                                  count: _isLoadingHouseholds
                                      ? null
                                      : _households.length,
                                ),
                                const SizedBox(height: 16),

                                if (_isLoadingHouseholds)
                                  const Center(
                                    child: Padding(
                                      padding: EdgeInsets.all(32),
                                      child: CircularProgressIndicator(),
                                    ),
                                  )
                                else
                                  _HouseholdSection(
                                    households: _households,
                                    onAddHousehold: _addHousehold,
                                    onViewHousehold: _viewHousehold,
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
            ],
          ),
        ),
      ),
    );
  }
}

/// Top bar: page title on the left; Profile / Settings and Logout on the
/// right. (The theme toggle stays only in Profile & Settings.)
class _DashboardTopBar extends StatelessWidget {
  final VoidCallback onProfile;
  final VoidCallback onLogout;

  const _DashboardTopBar({required this.onProfile, required this.onLogout});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 12),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: AppLayout.contentMaxWidth,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'My Households',
                        style: TextStyle(
                          color: LandingColors.textPrimary,
                          fontSize: AppText.pageTitle,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.4,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Manage the households registered to your account.',
                        style: TextStyle(
                          color: LandingColors.textSecondary,
                          fontSize: 14,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                _pill(
                  Icons.person_outline_rounded,
                  'Profile / Settings',
                  onProfile,
                ),
                const SizedBox(width: 10),
                _pill(Icons.logout_rounded, 'Logout', onLogout),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _pill(IconData icon, String label, VoidCallback onTap) {
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 18),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        foregroundColor: LandingColors.textPrimary,
        backgroundColor: LandingColors.glassFill,
        side: BorderSide(color: LandingColors.glassBorder),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        shape: const StadiumBorder(),
        textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
      ),
    );
  }
}

/// Three colorful cards. Every number comes from the households that are
/// already loaded. There is no consumption data on this screen, so there
/// are no usage numbers or sparklines here.
class _MetricsRow extends StatelessWidget {
  final List<Household> households;
  final VoidCallback onAddHousehold;

  const _MetricsRow({required this.households, required this.onAddHousehold});

  @override
  Widget build(BuildContext context) {
    final total = households.length;
    final withMeter = households
        .where((h) => (h.meterNumber ?? '').trim().isNotEmpty)
        .length;
    final tone = LandingColors.textSecondary;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: AppMetricCard(
            icon: Icons.home_work_rounded,
            accent: AppAccent.blue,
            label: 'Households',
            value: '$total',
            trend: 'Registered to your account',
            trendColor: tone,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: AppMetricCard(
            icon: Icons.speed_rounded,
            accent: AppAccent.green,
            label: 'Meter numbers',
            value: '$withMeter / $total',
            trend: 'Households with a meter number',
            trendColor: tone,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: AppMetricCard(
            icon: Icons.add_rounded,
            accent: AppAccent.orange,
            label: 'Quick action',
            value: 'Add Household',
            trend: 'Register another household',
            trendColor: tone,
            trailing: Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: LandingColors.surface,
              ),
              child: Icon(
                Icons.arrow_forward_rounded,
                size: 16,
                color: LandingColors.orange,
              ),
            ),
            onTap: onAddHousehold,
          ),
        ),
      ],
    );
  }
}

/// "Your Households" title with a small count badge.
class _SectionHeader extends StatelessWidget {
  /// Null while the households are still loading.
  final int? count;

  const _SectionHeader({required this.count});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          'Your Households',
          style: TextStyle(
            color: LandingColors.textPrimary,
            fontSize: AppText.sectionTitle,
            fontWeight: FontWeight.w700,
          ),
        ),
        if (count != null) ...[
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
            decoration: BoxDecoration(
              color: LandingColors.blueTint,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              '$count',
              style: TextStyle(
                color: LandingColors.primary,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

/// Decides what to show: the empty state, or the notice + household grid.
class _HouseholdSection extends StatelessWidget {
  final List<Household> households;
  final VoidCallback onAddHousehold;
  final void Function(Household household) onViewHousehold;

  const _HouseholdSection({
    required this.households,
    required this.onAddHousehold,
    required this.onViewHousehold,
  });

  @override
  Widget build(BuildContext context) {
    if (households.isEmpty) {
      return _EmptyHouseholds(onAddHousehold: onAddHousehold);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Only mention sample data when some is actually on screen.
        if (households.any((h) => h.isSample)) ...[
          const _SampleDataNotice(),
          const SizedBox(height: 20),
        ],
        _HouseholdGrid(
          households: households,
          onViewHousehold: onViewHousehold,
        ),
      ],
    );
  }
}

/// Friendly message shown when the user has no households.
class _EmptyHouseholds extends StatelessWidget {
  final VoidCallback onAddHousehold;

  const _EmptyHouseholds({required this.onAddHousehold});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: LandingCard(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const AppIconBadge(
              icon: Icons.home_work_outlined,
              accent: AppAccent.blue,
              size: 64,
            ),
            const SizedBox(height: 20),
            Text(
              'No households yet',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: LandingColors.textPrimary,
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Text(
                'Households you add will appear here, so you can '
                'manage each one from this page.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: LandingColors.textSecondary,
                  fontSize: 14,
                  height: 1.5,
                ),
              ),
            ),
            const SizedBox(height: 24),
            LandingPrimaryButton(
              label: 'Add Household',
              large: false,
              onPressed: onAddHousehold,
            ),
          ],
        ),
      ),
    );
  }
}

/// A notice that explains which households are demo data.
class _SampleDataNotice extends StatelessWidget {
  const _SampleDataNotice();

  @override
  Widget build(BuildContext context) {
    return LandingCard(
      color: LandingColors.periwinkleTint,
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SampleDataChip(label: 'Sample data'),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Households named "Sample Household" are demo examples for '
              'previewing the layout. Households you add are saved to your '
              'account.',
              style: TextStyle(
                color: LandingColors.textSecondary,
                fontSize: 13,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Lays the household cards out in 1, 2 or 3 columns depending on width.
class _HouseholdGrid extends StatelessWidget {
  final List<Household> households;
  final void Function(Household household) onViewHousehold;

  const _HouseholdGrid({
    required this.households,
    required this.onViewHousehold,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const spacing = 16.0;
        final width = constraints.maxWidth;

        final columns = width >= 900 ? 3 : (width >= 600 ? 2 : 1);

        // floorToDouble avoids tiny rounding errors that could push a card
        // onto the next row.
        final cardWidth = ((width - spacing * (columns - 1)) / columns)
            .floorToDouble();

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: [
            for (final h in households)
              SizedBox(
                width: cardWidth,
                child: HouseholdCard(
                  name: h.name,
                  address: h.address,
                  numberOfAppliances: h.numberOfAppliances,
                  provider: h.provider,
                  onView: () => onViewHousehold(h),
                ),
              ),
          ],
        );
      },
    );
  }
}
