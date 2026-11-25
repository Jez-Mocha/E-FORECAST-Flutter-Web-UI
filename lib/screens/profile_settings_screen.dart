import 'package:flutter/material.dart';

import '../landing/landing_widgets.dart'
    show LandingCard, LandingContainer, LandingSecondaryButton;
import '../models/account_profile.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../theme/app_tokens.dart';
import '../theme/landing_colors.dart';
import '../widgets/app_back_link.dart';
import '../widgets/app_message.dart';
import '../widgets/app_top_bar.dart';
import 'home_screen.dart';

/// Profile & Settings.
/// - Profile: reads and edits the signed-in user's username and email.
/// - Appearance: a working light/dark switch, remembered in this browser.
/// - Account: Logout, which clears the login token.
class ProfileSettingsScreen extends StatefulWidget {
  const ProfileSettingsScreen({super.key});

  @override
  State<ProfileSettingsScreen> createState() => _ProfileSettingsScreenState();
}

class _ProfileSettingsScreenState extends State<ProfileSettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _username = TextEditingController();
  final _email = TextEditingController();
  AccountProfile? _profile;
  bool _loading = true;
  bool _editing = false;
  bool _saving = false;
  String? _loadError;
  String? _saveError;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    _username.dispose();
    _email.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    setState(() {
      _loading = true;
      _loadError = null;
    });
    try {
      final profile = await ApiService.getMyProfile();
      if (!mounted) return;
      setState(() {
        _setProfile(profile);
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _loadError = error is ApiException
            ? error.message
            : 'Could not load your profile. Please try again.';
      });
    }
  }

  void _setProfile(AccountProfile profile) {
    _profile = profile;
    _username.text = profile.username;
    _email.text = profile.email;
  }

  void _cancelEdit() {
    final profile = _profile;
    if (profile == null) return;
    _formKey.currentState?.reset();
    setState(() {
      _setProfile(profile);
      _editing = false;
      _saveError = null;
    });
  }

  Future<void> _saveProfile() async {
    if (!_editing || _saving || !(_formKey.currentState?.validate() ?? false)) {
      return;
    }
    setState(() {
      _saving = true;
      _saveError = null;
    });
    try {
      final profile = await ApiService.updateMyProfile(
        username: _username.text,
        email: _email.text,
      );
      if (!mounted) return;
      setState(() {
        _setProfile(profile);
        _editing = false;
        _saving = false;
      });
      showTemporaryMessage(context, 'Profile updated successfully.');
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _saveError = error is ApiException
            ? error.message
            : 'Could not save your profile. Please try again.';
      });
    }
  }

  String? _validateUsername(String? value) {
    final length = (value ?? '').trim().runes.length;
    return length < 3 || length > 50 ? 'Use 3–50 characters.' : null;
  }

  String? _validateEmail(String? value) {
    final email = (value ?? '').trim();
    if (email.length > 100 ||
        !RegExp(
          r'^[^@\s]+@gmail\.com$',
          caseSensitive: false,
        ).hasMatch(email)) {
      return 'Enter a valid Gmail address of up to 100 characters.';
    }
    return null;
  }

  /// Clears the login token and returns to the landing page.
  void _logout(BuildContext context) {
    ApiService.logout();
    ThemeController.resetToLight();
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const HomeScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
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
                child: LandingContainer(
                  maxWidth: 960,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 40),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AppBackLink(
                          label: 'My Households',
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        Text(
                          'Profile & Settings',
                          style: TextStyle(
                            color: LandingColors.textPrimary,
                            fontSize: AppText.pageTitle,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.3,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Manage your account details and how E-FORECAST '
                          'looks.',
                          style: TextStyle(
                            color: LandingColors.textSecondary,
                            fontSize: AppText.body,
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xl),
                        _buildProfileCard(),
                        const SizedBox(height: AppSpacing.xl),
                        _buildAppearanceCard(),
                        const SizedBox(height: AppSpacing.xl),
                        _buildAccountCard(context),
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

  /// Profile fields stay read-only until the user chooses Edit Profile.
  Widget _buildProfileCard() {
    return _SettingsCard(
      icon: Icons.person_outline_rounded,
      title: 'Profile',
      child: Form(
        key: _formKey,
        autovalidateMode: _editing
            ? AutovalidateMode.onUserInteraction
            : AutovalidateMode.disabled,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_loading) ...[
              const LinearProgressIndicator(semanticsLabel: 'Loading profile'),
              const SizedBox(height: AppSpacing.sm),
              const Text('Loading profile…'),
              const SizedBox(height: AppSpacing.lg),
            ],
            if (_loadError case final error?) ...[
              _profileError(error),
              const SizedBox(height: AppSpacing.lg),
            ],
            TextFormField(
              controller: _username,
              enabled: _profile != null,
              readOnly: !_editing || _saving,
              validator: _validateUsername,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(labelText: 'Username'),
            ),
            const SizedBox(height: AppSpacing.lg),
            TextFormField(
              controller: _email,
              enabled: _profile != null,
              readOnly: !_editing || _saving,
              validator: _validateEmail,
              keyboardType: TextInputType.emailAddress,
              onFieldSubmitted: (_) => _saveProfile(),
              decoration: const InputDecoration(labelText: 'Email'),
            ),
            if (_saveError case final error?) ...[
              const SizedBox(height: AppSpacing.sm),
              _profileError(error),
            ],
            const SizedBox(height: AppSpacing.lg),
            if (_editing)
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: [
                  ElevatedButton(
                    onPressed: _saving ? null : _saveProfile,
                    child: Text(_saving ? 'Saving…' : 'Save Changes'),
                  ),
                  OutlinedButton(
                    onPressed: _saving ? null : _cancelEdit,
                    child: const Text('Cancel'),
                  ),
                ],
              )
            else if (_loadError != null)
              OutlinedButton(
                onPressed: _loadProfile,
                child: const Text('Retry'),
              )
            else
              OutlinedButton(
                onPressed: _profile == null
                    ? null
                    : () => setState(() => _editing = true),
                child: const Text('Edit Profile'),
              ),
          ],
        ),
      ),
    );
  }

  Widget _profileError(String error) => Semantics(
    liveRegion: true,
    child: Text(
      error,
      style: TextStyle(color: Theme.of(context).colorScheme.error),
    ),
  );

  /// Appearance: the light/dark switch. It saves in this browser only.
  Widget _buildAppearanceCard() {
    return _SettingsCard(
      icon: Icons.palette_outlined,
      title: 'Appearance',
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Dark mode',
                  style: TextStyle(
                    color: LandingColors.textPrimary,
                    fontSize: AppText.body,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Saved on this browser only.',
                  style: TextStyle(
                    color: LandingColors.textSecondary,
                    fontSize: AppText.caption,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: ThemeController.isDark,
            onChanged: (_) => ThemeController.toggle(),
          ),
        ],
      ),
    );
  }

  /// Account: Logout.
  Widget _buildAccountCard(BuildContext context) {
    return _SettingsCard(
      icon: Icons.manage_accounts_outlined,
      title: 'Account',
      child: Row(
        children: [
          Expanded(
            child: Text(
              'Log out of E-FORECAST on this browser.',
              style: TextStyle(
                color: LandingColors.textSecondary,
                fontSize: AppText.body,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.lg),
          LandingSecondaryButton(
            label: 'Logout',
            onPressed: () => _logout(context),
          ),
        ],
      ),
    );
  }
}

/// A card with an icon, a title and some content.
class _SettingsCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final Widget child;

  const _SettingsCard({
    required this.icon,
    required this.title,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: LandingCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 20, color: LandingColors.primary),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  title,
                  style: TextStyle(
                    color: LandingColors.textPrimary,
                    fontSize: AppText.sectionTitle,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            child,
          ],
        ),
      ),
    );
  }
}
