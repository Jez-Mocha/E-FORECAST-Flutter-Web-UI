import 'package:flutter/material.dart';

import '../models/auth_session.dart';
import '../services/api_service.dart';
import '../theme/app_colors.dart'; // only for status colors (error / success)
import '../theme/app_effects.dart';
import '../theme/landing_colors.dart';
import '../widgets/app_message.dart';
import 'admin_dashboard_screen.dart';
import 'dashboard_screen.dart';
import 'home_screen.dart';

class LoginScreen extends StatefulWidget {
  final int initialTab;
  final bool sessionExpired;
  const LoginScreen({
    super.key,
    this.initialTab = 0,
    this.sessionExpired = false,
  });

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tab;

  // Sign-in controllers
  final _signInIdentifierCtrl = TextEditingController();
  final _signInPassCtrl = TextEditingController();

  // Register controllers
  final _regUsernameCtrl = TextEditingController();
  final _regEmailCtrl = TextEditingController();
  final _regPassCtrl = TextEditingController();
  final _regConfirmPassCtrl = TextEditingController();

  // Visibility toggles (independent per field)
  bool _signInObscure = true;
  bool _regObscure = true;
  bool _regConfirmObscure = true;

  // Validation & loading state
  bool _confirmMismatch = false;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    if (widget.sessionExpired) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _showSnackbar(
            'Your session has expired. Please sign in again.',
            isError: true,
          );
        }
      });
    }
    _tab = TabController(
      length: 2,
      vsync: this,
      initialIndex: widget.initialTab,
    );
  }

  @override
  void dispose() {
    _tab.dispose();
    _signInIdentifierCtrl.dispose();
    _signInPassCtrl.dispose();
    _regUsernameCtrl.dispose();
    _regEmailCtrl.dispose();
    _regPassCtrl.dispose();
    _regConfirmPassCtrl.dispose();
    super.dispose();
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  int _passwordStrength(String p) {
    int score = 0;
    if (p.length >= 8) score++;
    if (p.contains(RegExp(r'[A-Z]'))) score++;
    if (p.contains(RegExp(r'[0-9]'))) score++;
    if (p.contains(RegExp(r'[!@#\$&*~%^()_\-+=]'))) score++;
    return score;
  }

  Color _strengthColor(int s) {
    switch (s) {
      case 1:
        return AppColors.rose;
      case 2:
        return AppColors.amber;
      case 3:
        return LandingColors.primary;
      case 4:
        return AppColors.emerald;
      default:
        return LandingColors.border;
    }
  }

  String _strengthLabel(int s) {
    switch (s) {
      case 1:
        return 'Weak';
      case 2:
        return 'Fair';
      case 3:
        return 'Good';
      case 4:
        return 'Strong';
      default:
        return '';
    }
  }

  void _showSnackbar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: LandingColors.background,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(LandingRadius.control),
          side: BorderSide(
            color: isError
                ? AppColors.rose.withValues(alpha: 0.4)
                : AppColors.emerald.withValues(alpha: 0.4),
          ),
        ),
        content: Row(
          children: [
            Icon(
              isError
                  ? Icons.error_outline_rounded
                  : Icons.check_circle_rounded,
              color: isError ? AppColors.rose : AppColors.emerald,
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

  Future<void> _submitSignIn() async {
    if (_loading) return;
    final identifier = _signInIdentifierCtrl.text.trim();
    final password = _signInPassCtrl.text;

    if (identifier.isEmpty || password.isEmpty) {
      _showSnackbar('Please fill in all fields.', isError: true);
      return;
    }

    setState(() => _loading = true);

    try {
      final session = await ApiService.login(
        usernameOrEmail: identifier,
        password: password,
      );
      if (!_continueSignIn(session)) return;
      await ThemeController.loadForCurrentUser();

      if (!_continueSignIn(session) || !mounted) return;

      // Centered success popup. The dashboard opens after it closes.
      await showSuccessPopup(context, message: 'Login successful!');

      if (!_continueSignIn(session) || !mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => _destination(session.role)),
      );
    } catch (e) {
      if (!mounted) return;

      setState(() => _loading = false);

      _showSnackbar(
        e is ApiException ? e.message : 'Sign-in failed. Please try again.',
        isError: true,
      );
    }
  }

  Future<void> _submitRegister() async {
    if (_loading) return;
    final username = _regUsernameCtrl.text.trim();
    final email = _regEmailCtrl.text.trim();
    final password = _regPassCtrl.text;
    final confirm = _regConfirmPassCtrl.text;

    if (username.isEmpty ||
        email.isEmpty ||
        password.isEmpty ||
        confirm.isEmpty) {
      _showSnackbar('Please fill in all fields.', isError: true);
      return;
    }

    if (username.length < 3 || username.length > 50) {
      _showSnackbar('Username must be 3–50 characters.', isError: true);
      return;
    }
    if (!RegExp(
      r'^[^@\s]+@gmail\.com$',
      caseSensitive: false,
    ).hasMatch(email)) {
      _showSnackbar('Enter a valid Gmail address.', isError: true);
      return;
    }
    if (password.length < 8) {
      _showSnackbar('Password must be at least 8 characters.', isError: true);
      return;
    }

    if (password != confirm) {
      setState(() => _confirmMismatch = true);
      return;
    }

    setState(() {
      _confirmMismatch = false;
      _loading = true;
    });

    try {
      final session = await ApiService.register(
        username: username,
        email: email,
        password: password,
      );
      if (!_continueSignIn(session)) return;
      await ThemeController.loadForCurrentUser();

      if (!_continueSignIn(session) || !mounted) return;

      setState(() => _loading = false);
      _showSnackbar('Account created successfully!');

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => _destination(session.role)),
        (route) => false,
      );
    } catch (e) {
      if (!mounted) return;

      setState(() => _loading = false);
      _showSnackbar(
        e is ApiException
            ? e.message
            : 'Registration failed. Please try again.',
        isError: true,
      );
    }
  }

  bool _continueSignIn(AuthSession session) {
    if (!identical(ApiService.session, session)) return false;
    if (mounted) return true;
    ApiService.logout();
    return false;
  }

  Widget _destination(AccountRole role) => switch (role) {
    AccountRole.admin => const AdminDashboardScreen(),
    AccountRole.household => const DashboardScreen(),
  };

  // ── build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    // Follows the app-wide light/dark theme provided by MaterialApp.
    return Scaffold(
      body: AppBackground(
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(32),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1080),
                child: Container(
                  height: 660,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(color: LandingColors.border),
                    boxShadow: AppEffects.raised,
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(28),
                    child: Row(
                      children: [
                        Expanded(flex: 5, child: _buildBrandPanel()),
                        Expanded(flex: 6, child: _buildFormPanel()),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── Left brand panel ──────────────────────────────────────────────────────

  Widget _buildBrandPanel() {
    final signIn = _tab.index == 0;
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            LandingColors.primary,
            Color.lerp(LandingColors.primary, LandingColors.purple, 0.4)!,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Stack(
        children: [
          Positioned(top: -90, right: -70, child: _ring(280, 0.10)),
          Positioned(bottom: -130, left: -90, child: _ring(320, 0.08)),
          Padding(
            padding: const EdgeInsets.all(40),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildBrandLogo(),
                const Spacer(),
                Text(
                  signIn
                      ? 'Welcome to your energy dashboard'
                      : 'Start tracking your household electricity',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 30,
                    fontWeight: FontWeight.w800,
                    height: 1.2,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  signIn
                      ? 'Sign in to monitor consumption, review your records, and view forecasts.'
                      : 'Create an account to record meter readings and explore forecasts and estimated bills.',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.88),
                    fontSize: 15,
                    height: 1.6,
                  ),
                ),
                const SizedBox(height: 28),
                _brandPoint(Icons.edit_note_rounded, 'Record meter readings'),
                const SizedBox(height: 14),
                _brandPoint(Icons.show_chart_rounded, 'Monitor usage history'),
                const SizedBox(height: 14),
                _brandPoint(
                  Icons.auto_graph_rounded,
                  'Forecast consumption and estimate bills',
                ),
                const Spacer(),
                _buildBackLink(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _ring(double size, double alpha) => IgnorePointer(
    child: Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withValues(alpha: alpha),
        border: Border.all(
          color: Colors.white.withValues(alpha: alpha * 2),
          width: 2,
        ),
      ),
    ),
  );

  // The logo on the brand panel. Clicking it goes back to the landing page.
  Widget _buildBrandLogo() {
    return Tooltip(
      message: 'Back to home',
      child: InkWell(
        borderRadius: BorderRadius.circular(LandingRadius.control),
        onTap: () => Navigator.maybePop(context),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(LandingRadius.control),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.35),
                  ),
                ),
                child: const Icon(
                  Icons.bolt_rounded,
                  color: Colors.white,
                  size: 22,
                ),
              ),
              const SizedBox(width: 10),
              const Text(
                'E-FORECAST',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.6,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _brandPoint(IconData icon, String text) {
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.18),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: Colors.white, size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  // Link back to the landing page, at the bottom of the brand panel.
  Widget _buildBackLink() {
    return Align(
      alignment: Alignment.centerLeft,
      child: TextButton.icon(
        onPressed: () {
          final navigator = Navigator.of(context);
          if (widget.sessionExpired && !navigator.canPop()) {
            navigator.pushReplacement(
              MaterialPageRoute(builder: (_) => const HomeScreen()),
            );
          } else {
            navigator.maybePop();
          }
        },
        icon: const Icon(Icons.arrow_back_rounded, size: 16),
        label: const Text('Back to home'),
        style: TextButton.styleFrom(
          foregroundColor: Colors.white.withValues(alpha: 0.92),
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
          textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  // ── Right form panel ──────────────────────────────────────────────────────

  Widget _buildFormPanel() {
    return Container(
      color: LandingColors.surface,
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 32),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildHeader(),
                const SizedBox(height: 24),
                _buildTabBar(),
                const SizedBox(height: 24),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 220),
                  switchInCurve: Curves.easeOut,
                  switchOutCurve: Curves.easeIn,
                  transitionBuilder: (child, anim) =>
                      FadeTransition(opacity: anim, child: child),
                  child: _tab.index == 0
                      ? _buildSignInForm()
                      : _buildRegisterForm(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final signIn = _tab.index == 0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          signIn ? 'Welcome' : 'Create an account',
          style: TextStyle(
            color: LandingColors.textPrimary,
            fontSize: 24,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          signIn
              ? 'Sign in to view your household electricity records.'
              : 'Register to start tracking your household electricity.',
          style: TextStyle(
            color: LandingColors.textSecondary,
            fontSize: 14,
            height: 1.5,
          ),
        ),
      ],
    );
  }

  Widget _buildTabBar() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: LandingColors.backgroundSoft,
        borderRadius: BorderRadius.circular(LandingRadius.control),
        border: Border.all(color: LandingColors.border),
      ),
      child: TabBar(
        controller: _tab,
        onTap: (_) => setState(() => _confirmMismatch = false),
        dividerColor: Colors.transparent,
        indicator: BoxDecoration(
          color: LandingColors.primary,
          borderRadius: BorderRadius.circular(6),
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        labelColor: Colors.white,
        unselectedLabelColor: LandingColors.textSecondary,
        labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        unselectedLabelStyle: const TextStyle(
          fontWeight: FontWeight.w500,
          fontSize: 14,
        ),
        tabs: const [
          Tab(text: 'Sign In'),
          Tab(text: 'Register'),
        ],
      ),
    );
  }

  // ── Sign In Form ──────────────────────────────────────────────────────────

  Widget _buildSignInForm() {
    return Column(
      key: const ValueKey('signin'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildField(
          controller: _signInIdentifierCtrl,
          label: 'Email or Username',
          hint: 'Enter your email or username',
          icon: Icons.mail_outline_rounded,
          keyboardType: TextInputType.emailAddress,
        ),
        const SizedBox(height: 14),
        _buildPasswordField(
          controller: _signInPassCtrl,
          label: 'Password',
          obscure: _signInObscure,
          onToggle: () => setState(() => _signInObscure = !_signInObscure),
        ),
        const SizedBox(height: 24),
        _buildSubmitButton(label: 'Sign In', onPressed: _submitSignIn),
        const SizedBox(height: 20),
        _buildSwitchPrompt(
          message: "Don't have an account?  ",
          action: 'Register',
          onTap: () => setState(() => _tab.animateTo(1)),
        ),
      ],
    );
  }

  // ── Register Form ─────────────────────────────────────────────────────────

  Widget _buildRegisterForm() {
    final strength = _passwordStrength(_regPassCtrl.text);
    return Column(
      key: const ValueKey('register'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildField(
          controller: _regUsernameCtrl,
          label: 'Username',
          hint: 'Enter a username',
          icon: Icons.person_outline_rounded,
        ),
        const SizedBox(height: 14),
        _buildField(
          controller: _regEmailCtrl,
          label: 'Email Address',
          hint: 'you@gmail.com',
          icon: Icons.mail_outline_rounded,
          keyboardType: TextInputType.emailAddress,
        ),
        const SizedBox(height: 14),
        _buildPasswordField(
          controller: _regPassCtrl,
          label: 'Password',
          obscure: _regObscure,
          onToggle: () => setState(() => _regObscure = !_regObscure),
          onChanged: (_) => setState(() {}),
        ),
        if (_regPassCtrl.text.isNotEmpty) ...[
          const SizedBox(height: 10),
          _buildStrengthBar(strength),
        ],
        const SizedBox(height: 14),
        _buildPasswordField(
          controller: _regConfirmPassCtrl,
          label: 'Confirm Password',
          obscure: _regConfirmObscure,
          onToggle: () =>
              setState(() => _regConfirmObscure = !_regConfirmObscure),
          isError: _confirmMismatch,
          errorText: 'Passwords do not match',
          onChanged: (_) {
            if (_confirmMismatch) setState(() => _confirmMismatch = false);
          },
        ),
        const SizedBox(height: 24),
        _buildSubmitButton(label: 'Create Account', onPressed: _submitRegister),
        const SizedBox(height: 20),
        _buildSwitchPrompt(
          message: 'Already have an account?  ',
          action: 'Sign In',
          onTap: () => setState(() => _tab.animateTo(0)),
        ),
      ],
    );
  }

  // ── Shared Widget Builders ────────────────────────────────────────────────

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      style: TextStyle(color: LandingColors.textPrimary, fontSize: 14),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, size: 18, color: LandingColors.textSecondary),
      ),
    );
  }

  Widget _buildPasswordField({
    required TextEditingController controller,
    required String label,
    required bool obscure,
    required VoidCallback onToggle,
    bool isError = false,
    String? errorText,
    ValueChanged<String>? onChanged,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      onChanged: onChanged,
      style: TextStyle(color: LandingColors.textPrimary, fontSize: 14),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(
          Icons.lock_outline_rounded,
          size: 18,
          color: LandingColors.textSecondary,
        ),
        suffixIcon: IconButton(
          icon: Icon(
            obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined,
            size: 18,
            color: LandingColors.textSecondary,
          ),
          splashRadius: 18,
          onPressed: onToggle,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(LandingRadius.control),
          borderSide: BorderSide(
            color: isError ? AppColors.rose : LandingColors.border,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(LandingRadius.control),
          borderSide: BorderSide(
            color: isError ? AppColors.rose : LandingColors.primary,
            width: 1.5,
          ),
        ),
        errorText: isError ? errorText : null,
        errorStyle: const TextStyle(color: AppColors.rose, fontSize: 12),
      ),
    );
  }

  Widget _buildStrengthBar(int strength) {
    final color = _strengthColor(strength);
    return Row(
      children: [
        Expanded(
          child: Row(
            children: List.generate(4, (i) {
              return Expanded(
                child: Container(
                  margin: EdgeInsets.only(right: i < 3 ? 5 : 0),
                  height: 3,
                  decoration: BoxDecoration(
                    color: i < strength ? color : LandingColors.border,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              );
            }),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          _strengthLabel(strength),
          style: TextStyle(
            color: color,
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildSubmitButton({
    required String label,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      height: 48,
      child: ElevatedButton(
        onPressed: _loading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: LandingColors.primary,
          disabledBackgroundColor: LandingColors.primary.withValues(alpha: 0.6),
          foregroundColor: Colors.white,
          disabledForegroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(LandingRadius.control),
          ),
          elevation: 0,
        ),
        child: _loading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : Text(
                label,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
      ),
    );
  }

  Widget _buildSwitchPrompt({
    required String message,
    required String action,
    required VoidCallback onTap,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          message,
          style: TextStyle(color: LandingColors.textSecondary, fontSize: 13),
        ),
        MouseRegion(
          cursor: SystemMouseCursors.click,
          child: GestureDetector(
            onTap: onTap,
            child: Text(
              action,
              style: TextStyle(
                color: LandingColors.primary,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
