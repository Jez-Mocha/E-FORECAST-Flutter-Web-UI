import 'package:flutter/material.dart';

import '../landing/landing_widgets.dart'
    show
        LandingCard,
        LandingContainer,
        LandingLogo,
        LandingPrimaryButton,
        SampleDataChip,
        ThemeToggleButton;
import '../models/household.dart';
import '../theme/app_theme.dart';
import '../theme/landing_colors.dart';
import '../widgets/household_card.dart';
import 'add_household_screen.dart';
import 'home_screen.dart';
import 'household_dashboard_screen.dart';

/// SCR-03: Main Dashboard.
/// Lists the households registered to the signed-in user.
/// Households are kept in memory for this session (no backend yet).
/// SCR-11 does not exist yet, so Profile / Settings shows a temporary
/// SnackBar.
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  // Starts with the labeled SAMPLE households. Households added on SCR-04
  // are inserted at the top. To preview the empty state, temporarily start
  // with an empty list instead: final List<Household> _households = [];
  final List<Household> _households = List<Household>.of(_sampleHouseholds);

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
      'Added "${created.name}". It is kept for this session only; '
      'nothing is saved to a server yet.',
    );
  }

  /// Opens SCR-05 for the household that was selected.
  void _viewHousehold(Household household) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => HouseholdDashboardScreen(household: household),
      ),
    );
  }

  void _openProfile() {
    showTemporaryMessage(
      context,
      'Profile / Settings (SCR-11) is not built yet. Temporary message.',
    );
  }

  /// Returns to the landing page and clears the screen history.
  /// There is no real session yet, so nothing else is signed out.
  void _logout() {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const HomeScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < 640;

    // Same pattern as LoginScreen: wrap in the theme-aware light theme.
    return Theme(
      data: AppTheme.lightTheme,
      child: Scaffold(
        backgroundColor: LandingColors.backgroundSoft,
        body: Column(
          children: [
            _DashboardTopBar(onProfile: _openProfile, onLogout: _logout),
            Expanded(
              child: SingleChildScrollView(
                child: LandingContainer(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: compact ? 24 : 40),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _DashboardHeader(onAddHousehold: _addHousehold),
                        const SizedBox(height: 24),
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
    );
  }
}

/// Shows a short message in the E-FORECAST style (a floating SnackBar).
/// Shared by the dashboard screens.
void showTemporaryMessage(BuildContext context, String message) {
  final messenger = ScaffoldMessenger.of(context);
  messenger.clearSnackBars();
  messenger.showSnackBar(
    SnackBar(
      backgroundColor: LandingColors.background,
      behavior: SnackBarBehavior.floating,
      margin: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(LandingRadius.control),
        side: BorderSide(color: LandingColors.border),
      ),
      content: Row(
        children: [
          Icon(
            Icons.info_outline_rounded,
            color: LandingColors.primary,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: LandingColors.textPrimary,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
      duration: const Duration(seconds: 3),
    ),
  );
}

enum _AccountAction { profile, logout }

/// Top bar: logo on the left; theme toggle, Profile / Settings and Logout on
/// the right. On narrow screens the last two collapse into one menu.
class _DashboardTopBar extends StatelessWidget {
  final VoidCallback onProfile;
  final VoidCallback onLogout;

  const _DashboardTopBar({required this.onProfile, required this.onLogout});

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < 640;

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
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              child: Row(
                children: [
                  // The logo scales down instead of wrapping on tiny screens.
                  Expanded(
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: LandingLogo(),
                      ),
                    ),
                  ),
                  const ThemeToggleButton(),
                  if (compact)
                    _buildMenu()
                  else ...[
                    const SizedBox(width: 4),
                    TextButton.icon(
                      onPressed: onProfile,
                      icon: const Icon(Icons.person_outline_rounded, size: 18),
                      label: const Text('Profile / Settings'),
                      style: _linkStyle(),
                    ),
                    const SizedBox(width: 4),
                    TextButton.icon(
                      onPressed: onLogout,
                      icon: const Icon(Icons.logout_rounded, size: 18),
                      label: const Text('Logout'),
                      style: _linkStyle(),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  ButtonStyle _linkStyle() {
    return TextButton.styleFrom(
      foregroundColor: LandingColors.textSecondary,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
    );
  }

  Widget _buildMenu() {
    return PopupMenuButton<_AccountAction>(
      tooltip: 'Account menu',
      icon: Icon(
        Icons.account_circle_outlined,
        color: LandingColors.textPrimary,
        size: 24,
      ),
      onSelected: (action) {
        switch (action) {
          case _AccountAction.profile:
            onProfile();
          case _AccountAction.logout:
            onLogout();
        }
      },
      itemBuilder: (context) => [
        PopupMenuItem(
          value: _AccountAction.profile,
          child: _menuRow(Icons.person_outline_rounded, 'Profile / Settings'),
        ),
        PopupMenuItem(
          value: _AccountAction.logout,
          child: _menuRow(Icons.logout_rounded, 'Logout'),
        ),
      ],
    );
  }

  Widget _menuRow(IconData icon, String label) {
    return Row(
      children: [
        Icon(icon, size: 18, color: LandingColors.textSecondary),
        const SizedBox(width: 10),
        Text(
          label,
          style: TextStyle(color: LandingColors.textPrimary, fontSize: 14),
        ),
      ],
    );
  }
}

/// Page title, short description and the Add Household button.
/// Side by side on wide screens; stacked on narrow screens.
class _DashboardHeader extends StatelessWidget {
  final VoidCallback onAddHousehold;

  const _DashboardHeader({required this.onAddHousehold});

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < 640;

    final titleBlock = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'My Households',
          style: TextStyle(
            color: LandingColors.textPrimary,
            fontSize: 28,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Manage the households registered to your account.',
          style: TextStyle(
            color: LandingColors.textSecondary,
            fontSize: 14,
            height: 1.5,
          ),
        ),
      ],
    );

    final addButton = LandingPrimaryButton(
      label: 'Add Household',
      large: false,
      onPressed: onAddHousehold,
    );

    if (compact) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          titleBlock,
          const SizedBox(height: 16),
          SizedBox(width: double.infinity, child: addButton),
        ],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(child: titleBlock),
        const SizedBox(width: 16),
        addButton,
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
        const _SampleDataNotice(),
        const SizedBox(height: 20),
        _HouseholdGrid(
          households: households,
          onViewHousehold: onViewHousehold,
        ),
      ],
    );
  }
}

/// Friendly message shown when the user has no households.
/// Its button uses the same Add Household action as the header button.
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
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: LandingColors.periwinkleTint,
                borderRadius: BorderRadius.circular(LandingRadius.card),
              ),
              child: Icon(
                Icons.home_work_outlined,
                color: LandingColors.primary,
                size: 32,
              ),
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

/// A notice that explains which households are demo data and that added
/// households are not stored permanently yet.
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
              'previewing the layout. Households you add are kept for this '
              'session only and are not saved to a server yet.',
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

/// SAMPLE DATA ONLY. These are made-up placeholders, not real households.
/// The rate and billing day are placeholders too.
const List<Household> _sampleHouseholds = [
  Household(
    name: 'Sample Household 1',
    street: 'Sample Street, Sample Barangay',
    city: 'Sample City',
    occupants: 4,
    provider: 'Sample Electric Provider',
    ratePerKwh: 10.0,
    billingCycleDay: 1,
    isSample: true,
  ),
  Household(
    name: 'Sample Household 2',
    street: 'Example Avenue, Example Barangay',
    city: 'Example City',
    occupants: 2,
    provider: 'Sample Electric Provider',
    ratePerKwh: 10.0,
    billingCycleDay: 1,
    isSample: true,
  ),
  Household(
    name: 'Sample Household 3 (Boarding House)',
    street: 'Demo Road, Demo Barangay',
    city: 'Demo City',
    occupants: 1,
    provider: 'Demo Electric Cooperative',
    ratePerKwh: 10.0,
    billingCycleDay: 1,
    isSample: true,
  ),
];

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

        // 3 columns on wide screens, 2 on tablets, 1 on phones.
        final columns = width >= 900 ? 3 : (width >= 600 ? 2 : 1);

        // Share the available width evenly. floorToDouble avoids tiny
        // rounding errors that could push a card onto the next row.
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
                  occupants: h.occupants,
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
