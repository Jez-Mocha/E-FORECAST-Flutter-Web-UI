import 'dart:async';

import 'package:flutter/material.dart';

import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'services/api_service.dart';
import 'theme/app_theme.dart';
import 'theme/landing_colors.dart';

final ValueNotifier<ThemeMode> themeNotifier = ValueNotifier(ThemeMode.light);

void main() {
  runApp(const EForecastApp());
}

class EForecastApp extends StatefulWidget {
  const EForecastApp({super.key});

  @override
  State<EForecastApp> createState() => _EForecastAppState();
}

class _EForecastAppState extends State<EForecastApp> {
  final _navigatorKey = GlobalKey<NavigatorState>();
  late final StreamSubscription<void> _expirySubscription;

  @override
  void initState() {
    super.initState();
    _expirySubscription = ApiService.sessionExpired.listen((_) {
      final navigator = _navigatorKey.currentState;
      if (navigator == null || ApiService.session != null) return;
      ThemeController.resetToLight();
      navigator.pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (_) => const LoginScreen(sessionExpired: true),
        ),
        (_) => false,
      );
    });
  }

  @override
  void dispose() {
    _expirySubscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeNotifier,
      builder: (context, mode, _) {
        return MaterialApp(
          navigatorKey: _navigatorKey,
          debugShowCheckedModeBanner: false,
          title: 'E-FORECAST | Intelligent Energy Forecasting',
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: mode,
          home: const HomeScreen(),
        );
      },
    );
  }
}
