import 'package:flutter/material.dart';

import 'package:shared_preferences/shared_preferences.dart';

import '../main.dart'; // Import to use the global themeNotifier
import '../services/api_service.dart';

/// Corner sizes used across the app. Rounder than before (new design).
class LandingRadius {
  LandingRadius._();
  static const double card = 18;
  static const double control = 12;
}

/// Holds light/dark mode and rebuilds the whole app when it changes.
/// The theme is saved in this browser only, separately for each logged-in
/// user (by user id). Light mode is the default.
class ThemeController {
  ThemeController._();

  // Point mode to the global themeNotifier in main.dart
  static ValueNotifier<ThemeMode> get mode => themeNotifier;
  static bool get isDark => mode.value == ThemeMode.dark;

  /// The browser-storage name for one user's theme.
  static String _key(int userId) => 'theme_mode_user_$userId';

  /// Shows a theme everywhere. Does not save anything.
  static void setMode(ThemeMode newMode) {
    mode.value = newMode;

    // Force rebuild every element so static LandingColors update everywhere
    void rebuild(Element el) {
      el.markNeedsBuild();
      el.visitChildren(rebuild);
    }

    WidgetsBinding.instance.rootElement?.visitChildren(rebuild);
  }

  /// Used by the theme buttons and the Profile & Settings switch.
  /// Changes the theme and, if a user is logged in, saves it for that user.
  static void toggle() {
    setMode(isDark ? ThemeMode.light : ThemeMode.dark);
    _save(mode.value);
  }

  /// Saves the theme for the logged-in user. Nothing is saved if nobody is
  /// logged in (for example on the landing page).
  static Future<void> _save(ThemeMode value) async {
    final userId = ApiService.currentUserId;
    if (userId == null) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _key(userId),
        value == ThemeMode.dark ? 'dark' : 'light',
      );
    } catch (_) {
      // The theme still changes on screen; it just will not be remembered.
    }
  }

  /// Call after login: shows this user's saved theme, or light mode if they
  /// have not saved one.
  static Future<void> loadForCurrentUser() async {
    final userId = ApiService.currentUserId;
    var theme = ThemeMode.light;

    if (userId != null) {
      try {
        final prefs = await SharedPreferences.getInstance();
        if (prefs.getString(_key(userId)) == 'dark') {
          theme = ThemeMode.dark;
        }
      } catch (_) {
        // Keep light mode.
      }
    }

    setMode(theme);
  }

  /// Call at logout: shows light mode again. The saved preference is kept.
  static void resetToLight() => setMode(ThemeMode.light);
}

/// One complete set of colors for ONE mode (light or dark).
///
/// Light and dark are written out separately below, so each one can be
/// tuned on its own. [AppTheme] uses these two sets directly to build the
/// Flutter themes, and [LandingColors] picks the right set for the mode
/// that is currently on screen.
class AppPalette {
  const AppPalette({
    required this.brightness,
    required this.primary,
    required this.secondary,
    required this.purple,
    required this.orange,
    required this.background,
    required this.backgroundSoft,
    required this.surface,
    required this.gradientTop,
    required this.gradientBottom,
    required this.glowBlue,
    required this.glowGreen,
    required this.blueTint,
    required this.greenTint,
    required this.purpleTint,
    required this.orangeTint,
    required this.amberTint,
    required this.amberBorder,
    required this.amberText,
    required this.textPrimary,
    required this.textSecondary,
    required this.border,
    required this.danger,
    required this.shadowLight,
    required this.shadowDark,
    required this.glassFill,
    required this.glassBorder,
  });

  final Brightness brightness;

  // Brand and accents
  final Color primary; // blue
  final Color secondary; // green (energy)
  final Color purple; // occasional metric accent
  final Color orange; // occasional metric accent

  // Surfaces
  final Color background; // the page itself
  final Color backgroundSoft; // pressed-in areas such as text fields
  final Color surface; // raised cards

  // Page background gradient and ambient glows
  final Color gradientTop;
  final Color gradientBottom;
  final Color glowBlue;
  final Color glowGreen;

  // Soft tints for icon badges, metric cards and highlights
  final Color blueTint;
  final Color greenTint;
  final Color purpleTint;
  final Color orangeTint;
  final Color amberTint; // sample-data and warning chips
  final Color amberBorder;
  final Color amberText;

  // Text, lines, status
  final Color textPrimary;
  final Color textSecondary;
  final Color border;
  final Color danger;

  // Soft raised look (neumorphism): one light and one dark shadow
  final Color shadowLight;
  final Color shadowDark;

  // Translucent panels (glass)
  final Color glassFill;
  final Color glassBorder;

  /// Text and icons that sit on top of the primary (blue) color.
  Color get onPrimary => Colors.white;

  /// Light mode: soft sky-blue page, white glass cards, navy text.
  static const AppPalette light = AppPalette(
    brightness: Brightness.light,
    primary: Color(0xFF2563EB),
    secondary: Color(0xFF059669),
    purple: Color(0xFF7C5CFF),
    orange: Color(0xFFF97316),
    background: Color(0xFFE6EFFA),
    backgroundSoft: Color(0xFFDCE8F7),
    surface: Color(0xFFF8FBFF),
    gradientTop: Color(0xFFD9E9FF),
    gradientBottom: Color(0xFFF1F7FF),
    glowBlue: Color(0x4D60A5FA),
    glowGreen: Color(0x3334D399),
    blueTint: Color(0xFFDDEAFF),
    greenTint: Color(0xFFD8F3E6),
    purpleTint: Color(0xFFE8E1FF),
    orangeTint: Color(0xFFFFE6D2),
    amberTint: Color(0xFFFBEFD5),
    amberBorder: Color(0xFFE8CF8E),
    amberText: Color(0xFF86570A),
    textPrimary: Color(0xFF0F1F3D),
    textSecondary: Color(0xFF52627D),
    border: Color(0xFFD3E1F3),
    danger: Color(0xFFDC2626),
    shadowLight: Color(0xE6FFFFFF),
    shadowDark: Color(0x4D7B9AC4),
    glassFill: Color(0xA6FFFFFF),
    glassBorder: Color(0xCCFFFFFF),
  );

  /// Dark mode: deep navy page, dark glass cards, brighter accents.
  static const AppPalette dark = AppPalette(
    brightness: Brightness.dark,
    primary: Color(0xFF4C8DFF),
    secondary: Color(0xFF34D399),
    purple: Color(0xFFA78BFA),
    orange: Color(0xFFFB923C),
    background: Color(0xFF0B1320),
    backgroundSoft: Color(0xFF08101A),
    surface: Color(0xFF142033),
    gradientTop: Color(0xFF0E1A30),
    gradientBottom: Color(0xFF0A1220),
    glowBlue: Color(0x334C8DFF),
    glowGreen: Color(0x2234D399),
    blueTint: Color(0xFF15294D),
    greenTint: Color(0xFF10342A),
    purpleTint: Color(0xFF241F4D),
    orangeTint: Color(0xFF3A2414),
    amberTint: Color(0xFF33280F),
    amberBorder: Color(0xFF5C4718),
    amberText: Color(0xFFF2C46B),
    textPrimary: Color(0xFFE8EFFA),
    textSecondary: Color(0xFF9DB0C9),
    border: Color(0xFF22344D),
    danger: Color(0xFFF87171),
    shadowLight: Color(0x08FFFFFF),
    shadowDark: Color(0xA6000000),
    glassFill: Color(0x99142033),
    glassBorder: Color(0x1FFFFFFF),
  );
}

/// Palette used by the screens and widgets. Every color switches between
/// light and dark automatically, using [AppPalette] above.
///
/// The old names (periwinkleTint, lavenderTint, pinkTint, ...) still work so
/// no screen breaks. They point to the blue / green / amber tints.
class LandingColors {
  LandingColors._();

  static AppPalette get _p =>
      ThemeController.isDark ? AppPalette.dark : AppPalette.light;

  // Brand and accents
  static Color get primary => _p.primary;
  static Color get secondary => _p.secondary;
  static Color get purple => _p.purple;
  static Color get orange => _p.orange;
  static Color get onPrimary => _p.onPrimary;

  // Backgrounds and surfaces
  static Color get background => _p.background;
  static Color get backgroundSoft => _p.backgroundSoft;
  static Color get surface => _p.surface;

  // Page gradient and glows
  static Color get gradientTop => _p.gradientTop;
  static Color get gradientBottom => _p.gradientBottom;
  static Color get glowBlue => _p.glowBlue;
  static Color get glowGreen => _p.glowGreen;

  // Tints (new names)
  static Color get blueTint => _p.blueTint;
  static Color get greenTint => _p.greenTint;
  static Color get purpleTint => _p.purpleTint;
  static Color get orangeTint => _p.orangeTint;
  static Color get amberTint => _p.amberTint;
  static Color get amberBorder => _p.amberBorder;
  static Color get amberText => _p.amberText;

  // Tints (old names, kept so existing screens keep working)
  static Color get periwinkleTint => _p.blueTint;
  static Color get lavenderTint => _p.greenTint;
  static Color get pinkTint => _p.amberTint;
  static Color get pinkBorder => _p.amberBorder;
  static Color get pinkText => _p.amberText;

  // Text
  static Color get textPrimary => _p.textPrimary;
  static Color get textSecondary => _p.textSecondary;

  // Lines and status
  static Color get border => _p.border;
  static Color get danger => _p.danger;

  // Glass and soft-shadow colors (used by app_effects.dart)
  static Color get shadowLight => _p.shadowLight;
  static Color get shadowDark => _p.shadowDark;
  static Color get glassFill => _p.glassFill;
  static Color get glassBorder => _p.glassBorder;

  // Gradients
  static LinearGradient get primaryGradient => LinearGradient(
    colors: [primary, Color.lerp(primary, Colors.white, 0.28)!],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// Blue to green, for energy-themed highlights.
  static LinearGradient get energyGradient => LinearGradient(
    colors: [primary, secondary],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static LinearGradient get pageGradient => LinearGradient(
    colors: [gradientTop, gradientBottom],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static LinearGradient get ctaGradient => LinearGradient(
    colors: [blueTint, greenTint],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Shadows. The old name softShadow gives the small raised look.
  static List<BoxShadow> get softShadow => [
    BoxShadow(color: shadowDark, blurRadius: 12, offset: const Offset(3, 3)),
    BoxShadow(color: shadowLight, blurRadius: 12, offset: const Offset(-3, -3)),
  ];
}
