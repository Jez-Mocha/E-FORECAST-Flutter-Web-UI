import 'package:flutter/material.dart';

import '../landing/landing_widgets.dart'
    show LandingCard, LandingContainer, LandingSecondaryButton;
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../theme/app_tokens.dart';
import '../theme/landing_colors.dart';
import '../widgets/app_back_link.dart';
import '../widgets/app_top_bar.dart';
import 'home_screen.dart';

class ProfileSettingsScreen extends StatefulWidget {
  const ProfileSettingsScreen({super.key});

  @override
  State<ProfileSettingsScreen> createState() =>
      _ProfileSettingsScreenState();
}

class _ProfileSettingsScreenState extends State<ProfileSettingsScreen> {
  final _profileFormKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();

  bool _isLoadingProfile = true;
  bool _isEditing = false;
  bool _isSaving = false;

  String? _profileError;
  String _savedUsername = '';
  String _savedEmail = '';

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  // Retrieve the actual profile from the backend.
  Future<void> _loadProfile() async {
    setState(() {
      _isLoadingProfile = true;
      _profileError = null;
    });

    try {
      final profile = await ApiService.getMyProfile();

      if (!mounted) return;

      _savedUsername = profile['username']?.toString() ?? '';
      _savedEmail = profile['email']?.toString() ?? '';

      _usernameController.text = _savedUsername;
      _emailController.text = _savedEmail;

      setState(() {
        _isLoadingProfile = false;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _isLoadingProfile = false;
        _profileError = error is ApiException
            ? error.message
            : 'Unable to load your profile. Please try again.';
      });
    }
  }

  // Enable profile editing.
  void _startEditing() {
    setState(() {
      _usernameController.text = _savedUsername;
      _emailController.text = _savedEmail;
      _isEditing = true;
      _profileError = null;
    });
  }

  // Restore the original profile values.
  void _cancelEditing() {
    setState(() {
      _usernameController.text = _savedUsername;
      _emailController.text = _savedEmail;
      _isEditing = false;
      _profileError = null;
    });
  }

  // Save profile changes through the backend.
  Future<void> _saveProfile() async {
    if (!_profileFormKey.currentState!.validate()) return;

    setState(() {
      _isSaving = true;
      _profileError = null;
    });

    try {
      final result = await ApiService.updateMyProfile(
        username: _usernameController.text,
        email: _emailController.text,
      );

      if (!mounted) return;

      _savedUsername = result['username']?.toString() ??
          _usernameController.text.trim();
      _savedEmail = result['email']?.toString() ??
          _emailController.text.trim();

      setState(() {
        _usernameController.text = _savedUsername;
        _emailController.text = _savedEmail;
        _isEditing = false;
        _isSaving = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profile updated successfully.'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _isSaving = false;
        _profileError = error is ApiException
            ? error.message
            : 'Unable to update your profile. Please try again.';
      });
    }
  }

  // Clear the login token and return to the landing page.
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
                          'Manage your account details and how E-FORECAST looks.',
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
                        _buildAccountCard(),
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

  // Profile information and editing controls.
  Widget _buildProfileCard() {
    return _SettingsCard(
      icon: Icons.person_outline_rounded,
      title: 'Profile',
      child: _isLoadingProfile
          ? const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: CircularProgressIndicator(),
              ),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_profileError != null) ...[
                  Text(
                    _profileError!,
                    style: const TextStyle(
                      color: Colors.red,
                      fontSize: AppText.body,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  if (!_isEditing)
                    OutlinedButton.icon(
                      onPressed: _loadProfile,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Retry'),
                    ),
                  if (_isEditing)
                    const SizedBox(height: AppSpacing.sm),
                ],
                Form(
                  key: _profileFormKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextFormField(
                        controller: _usernameController,
                        enabled: _isEditing && !_isSaving,
                        maxLength: 50,
                        decoration: const InputDecoration(
                          labelText: 'Username',
                          prefixIcon: Icon(Icons.person_outline),
                          counterText: '',
                        ),
                        validator: (value) {
                          final username = value?.trim() ?? '';

                          if (username.length < 3) {
                            return 'Username must contain at least 3 characters.';
                          }

                          if (username.length > 50) {
                            return 'Username must not exceed 50 characters.';
                          }

                          return null;
                        },
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      TextFormField(
                        controller: _emailController,
                        enabled: _isEditing && !_isSaving,
                        keyboardType: TextInputType.emailAddress,
                        decoration: const InputDecoration(
                          labelText: 'Email',
                          prefixIcon: Icon(Icons.email_outlined),
                        ),
                        validator: (value) {
                          final email = value?.trim() ?? '';

                          if (!RegExp(
                            r'^[^@\s]+@gmail\.com$',
                            caseSensitive: false,
                          ).hasMatch(email)) {
                            return 'Please enter a valid Gmail address.';
                          }

                          return null;
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                if (_isEditing)
                  Wrap(
                    spacing: AppSpacing.md,
                    runSpacing: AppSpacing.sm,
                    children: [
                      ElevatedButton(
                        onPressed: _isSaving ? null : _saveProfile,
                        child: _isSaving
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text('Save Changes'),
                      ),
                      OutlinedButton(
                        onPressed: _isSaving ? null : _cancelEditing,
                        child: const Text('Cancel'),
                      ),
                    ],
                  )
                else
                  OutlinedButton.icon(
                    onPressed: _startEditing,
                    icon: const Icon(Icons.edit_outlined),
                    label: const Text('Edit Profile'),
                  ),
              ],
            ),
    );
  }

  // Appearance settings.
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

  // Account settings.
  Widget _buildAccountCard() {
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
            onPressed: _logout,
          ),
        ],
      ),
    );
  }
}

// A reusable settings card.
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
