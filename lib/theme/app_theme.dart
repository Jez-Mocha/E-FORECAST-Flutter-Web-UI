import 'package:flutter/material.dart';

import 'landing_colors.dart';

/// The two Flutter themes of the app.
///
/// Light and dark are built separately from their own color sets
/// (AppPalette.light and AppPalette.dark in landing_colors.dart).
/// main.dart picks one with the existing ThemeController.
class AppTheme {
  AppTheme._();

  /// NOTE: screens wrap themselves in this theme, so it follows the mode
  /// that is currently on screen (light or dark), despite its name.
  static ThemeData get lightTheme =>
      _build(ThemeController.isDark ? AppPalette.dark : AppPalette.light);

  static ThemeData get darkTheme => _build(AppPalette.dark);

  static ThemeData _build(AppPalette p) {
    final isDark = p.brightness == Brightness.dark;

    final scheme = ColorScheme(
      brightness: p.brightness,
      primary: p.primary,
      onPrimary: p.onPrimary,
      secondary: p.secondary,
      onSecondary: isDark ? p.background : Colors.white,
      error: p.danger,
      onError: isDark ? p.background : Colors.white,
      surface: p.surface,
      onSurface: p.textPrimary,
      outline: p.border,
    );

    final base = ThemeData(
      useMaterial3: true,
      brightness: p.brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: p.background,
    );

    OutlineInputBorder inputBorder(Color color, [double width = 1]) {
      return OutlineInputBorder(
        borderRadius: BorderRadius.circular(LandingRadius.control),
        borderSide: BorderSide(color: color, width: width),
      );
    }

    return base.copyWith(
      textTheme: base.textTheme.apply(
        bodyColor: p.textPrimary,
        displayColor: p.textPrimary,
      ),
      dividerTheme: DividerThemeData(color: p.border, thickness: 1),
      cardTheme: CardThemeData(
        color: p.surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(LandingRadius.card),
          side: BorderSide(color: p.border),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: p.primary,
          foregroundColor: p.onPrimary,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(LandingRadius.control),
          ),
          textStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.2,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: p.textPrimary,
          side: BorderSide(color: p.border),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(LandingRadius.control),
          ),
          textStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            letterSpacing: 0.2,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: p.primary),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: p.backgroundSoft,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        labelStyle: TextStyle(color: p.textSecondary, fontSize: 14),
        floatingLabelStyle: TextStyle(color: p.primary, fontSize: 14),
        hintStyle: TextStyle(
          color: p.textSecondary.withValues(alpha: 0.7),
          fontSize: 14,
        ),
        border: inputBorder(p.border),
        enabledBorder: inputBorder(p.border),
        focusedBorder: inputBorder(p.primary, 1.5),
        errorBorder: inputBorder(p.danger),
        focusedErrorBorder: inputBorder(p.danger, 1.5),
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: p.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 6,
        shadowColor: p.shadowDark,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(color: p.border),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: p.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(LandingRadius.card),
          side: BorderSide(color: p.border),
        ),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? p.onPrimary
              : p.textSecondary,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? p.primary
              : p.backgroundSoft,
        ),
        trackOutlineColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? Colors.transparent
              : p.border,
        ),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(color: p.primary),
    );
  }
}
