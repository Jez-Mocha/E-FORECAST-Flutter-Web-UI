import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Backgrounds (Exact palette: #050B14, #0A1424, #0D1929)
  static const Color background = Color(0xFF050B14);
  static const Color backgroundLight = Color(0xFF0A1424);
  static const Color card = Color(0xFF0D1929);
  static const Color cardHover = Color(0xFF112238);
  static const Color surfaceElevated = Color(0xFF152A47);

  // Borders
  static const Color border = Color(0x1FFFFFFF);
  static const Color borderSubtle = Color(0x0FFFFFFF);
  static const Color borderActive = Color(0x4D22D3EE);

  // Accents & Brand
  static const Color primary = Color(0xFF3B82F6);        // Electric blue
  static const Color primaryHover = Color(0xFF2563EB);
  static const Color electricBlue = Color(0xFF3B82F6);
  static const Color cyan = Color(0xFF22D3EE);            // Cyan
  static const Color emerald = Color(0xFF10B981);         // Energy green
  static const Color amber = Color(0xFFF59E0B);
  static const Color purple = Color(0xFF8B5CF6);          // ML Purple
  static const Color rose = Color(0xFFF43F5E);

  // Typography
  static const Color textPrimary = Color(0xFFF8FAFC);
  static const Color textSecondary = Color(0xFF94A3B8);
  static const Color textMuted = Color(0xFF64748B);

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF3B82F6), Color(0xFF22D3EE)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient accentGradient = LinearGradient(
    colors: [Color(0xFF22D3EE), Color(0xFF8B5CF6)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient greenGradient = LinearGradient(
    colors: [Color(0xFF10B981), Color(0xFF059669)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient heroGlow = LinearGradient(
    colors: [Color(0x2222D3EE), Color(0x00050B14)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );
}
