import 'package:flutter/material.dart';
import '../screens/login_screen.dart';
import '../theme/app_colors.dart';

class MinimalNavbar extends StatelessWidget {
  final VoidCallback? onFeaturesTap;
  final VoidCallback? onHowItWorksTap;
  final VoidCallback? onEstimatorTap;

  const MinimalNavbar({
    super.key,
    this.onFeaturesTap,
    this.onHowItWorksTap,
    this.onEstimatorTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.background.withValues(alpha: 0.92),
        border: const Border(bottom: BorderSide(color: AppColors.borderSubtle)),
      ),
      child: SafeArea(
        bottom: false,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isDesktop = constraints.maxWidth >= 840;
            final isCompact = constraints.maxWidth < 500;

            return Row(
              children: [
                _buildLogo(),
                const SizedBox(width: 12),
                if (isDesktop) _buildStatusChip(),
                const Spacer(),
                if (isDesktop) ...[
                  _navButton('Features', onFeaturesTap),
                  _navButton('How It Works', onHowItWorksTap),
                  _navButton('Estimator', onEstimatorTap),
                  const SizedBox(width: 16),
                  _buildAuthButtons(context),
                ] else ...[
                  if (!isCompact)
                    TextButton(
                      onPressed: () => _navigateToLogin(context, 0),
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.textSecondary,
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      ),
                      child: const Text('Sign In', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                    ),
                  ElevatedButton(
                    onPressed: () => _navigateToLogin(context, 1),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      minimumSize: const Size(0, 36),
                    ),
                    child: const Text('Get Started', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                  ),
                  const SizedBox(width: 6),
                  _buildMobileMenu(context),
                ],
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildLogo() {
    return Row(
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            gradient: AppColors.primaryGradient,
            borderRadius: BorderRadius.circular(9),
          ),
          child: const Icon(Icons.bolt_rounded, color: Colors.white, size: 20),
        ),
        const SizedBox(width: 10),
        const Text(
          'E-FORECAST',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 16,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.6,
          ),
        ),
      ],
    );
  }

  Widget _buildStatusChip() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.emerald.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.emerald.withValues(alpha: 0.25)),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(radius: 3, backgroundColor: AppColors.emerald),
          SizedBox(width: 6),
          Text(
            'XGBoost Active',
            style: TextStyle(color: AppColors.emerald, fontSize: 11, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _navButton(String label, VoidCallback? onTap) {
    return TextButton(
      onPressed: onTap,
      style: TextButton.styleFrom(
        foregroundColor: AppColors.textSecondary,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      child: Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
    );
  }

  Widget _buildAuthButtons(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        TextButton(
          onPressed: () => _navigateToLogin(context, 0),
          style: TextButton.styleFrom(
            foregroundColor: AppColors.textSecondary,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          ),
          child: const Text('Sign In', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
        ),
        const SizedBox(width: 8),
        ElevatedButton(
          onPressed: () => _navigateToLogin(context, 1),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            elevation: 0,
          ),
          child: const Text('Get Started', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
        ),
      ],
    );
  }

  Widget _buildMobileMenu(BuildContext context) {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.menu_rounded, color: AppColors.textPrimary, size: 22),
      color: AppColors.card,
      elevation: 8,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppColors.border),
      ),
      offset: const Offset(0, 42),
      onSelected: (value) {
        if (value == 'features') onFeaturesTap?.call();
        if (value == 'how_it_works') onHowItWorksTap?.call();
        if (value == 'estimator') onEstimatorTap?.call();
        if (value == 'signin') _navigateToLogin(context, 0);
        if (value == 'register') _navigateToLogin(context, 1);
      },
      itemBuilder: (context) => [
        const PopupMenuItem(
          value: 'features',
          child: Row(
            children: [
              Icon(Icons.grid_view_rounded, size: 16, color: AppColors.cyan),
              SizedBox(width: 10),
              Text('Features', style: TextStyle(color: AppColors.textPrimary, fontSize: 13)),
            ],
          ),
        ),
        const PopupMenuItem(
          value: 'how_it_works',
          child: Row(
            children: [
              Icon(Icons.auto_stories_rounded, size: 16, color: AppColors.purple),
              SizedBox(width: 10),
              Text('How It Works', style: TextStyle(color: AppColors.textPrimary, fontSize: 13)),
            ],
          ),
        ),
        const PopupMenuItem(
          value: 'estimator',
          child: Row(
            children: [
              Icon(Icons.calculate_rounded, size: 16, color: AppColors.emerald),
              SizedBox(width: 10),
              Text('Live Estimator', style: TextStyle(color: AppColors.textPrimary, fontSize: 13)),
            ],
          ),
        ),
        const PopupMenuDivider(height: 8),
        const PopupMenuItem(
          value: 'signin',
          child: Row(
            children: [
              Icon(Icons.login_rounded, size: 16, color: AppColors.textSecondary),
              SizedBox(width: 10),
              Text('Sign In', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
            ],
          ),
        ),
        const PopupMenuItem(
          value: 'register',
          child: Row(
            children: [
              Icon(Icons.person_add_rounded, size: 16, color: AppColors.electricBlue),
              SizedBox(width: 10),
              Text('Register Account', style: TextStyle(color: AppColors.electricBlue, fontSize: 13, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ],
    );
  }

  void _navigateToLogin(BuildContext context, int initialTab) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => LoginScreen(initialTab: initialTab),
      ),
    );
  }
}
