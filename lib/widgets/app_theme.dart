import 'package:flutter/material.dart';

import 'google_fonts.dart';

class AppTheme {
  static const Color brandBlue = Color(0xFF011F7B);
  static const Color brandGold = Color(0xFFFFBA09);
  static const Color brandIvory = Color(0xFFF7F5EF);
  static const Color brandInk = Color(0xFF101828);
  static const Color brandNavySurface = Color(0xFF0F1115);
  static const Color brandSlate = Color(0xFF1B2333);

  static ThemeData light() {
    final scheme = ColorScheme(
      brightness: Brightness.light,
      primary: brandBlue,
      onPrimary: Colors.white,
      secondary: brandGold,
      onSecondary: brandInk,
      tertiary: const Color(0xFF3B82F6),
      onTertiary: Colors.white,
      error: const Color(0xFFB42318),
      onError: Colors.white,
      surface: Colors.white,
      onSurface: brandInk,
      surfaceContainerHighest: const Color(0xFFF1F5FB),
      onSurfaceVariant: const Color(0xFF475467),
      outline: const Color(0xFFD0D5DD),
    );

    return _buildTheme(scheme).copyWith(
      scaffoldBackgroundColor: const Color(0xFFF7F9FC),
    );
  }

  static ThemeData dark() {
    final scheme = ColorScheme(
      brightness: Brightness.dark,
      primary: const Color(0xFF7EA2FF),
      onPrimary: brandNavySurface,
      secondary: brandGold,
      onSecondary: brandInk,
      tertiary: const Color(0xFFFFD667),
      onTertiary: brandInk,
      error: const Color(0xFFF97066),
      onError: Colors.black,
      surface: brandNavySurface,
      onSurface: Colors.white,
      surfaceContainerHighest: brandSlate,
      onSurfaceVariant: const Color(0xFFB4B9C6),
      outline: const Color(0xFF344054),
    );

    final base = _buildTheme(scheme);
    return base.copyWith(
      scaffoldBackgroundColor: const Color(0xFF0F1115),
      // Slightly lighter than the card (0xFF232C3F) so input fields read as
      // visible inset wells instead of blending into a black slab.
      inputDecorationTheme: base.inputDecorationTheme.copyWith(
        fillColor: const Color(0xFF151B29),
      ),
    );
  }

  static ThemeData _buildTheme(ColorScheme scheme) {
    final textTheme = GoogleFonts.plusJakartaSansTextTheme();

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      textTheme: textTheme.apply(
        bodyColor: scheme.onSurface,
        displayColor: scheme.onSurface,
      ),
      scaffoldBackgroundColor: scheme.surface,
      appBarTheme: AppBarTheme(
        backgroundColor: scheme.surface,
        foregroundColor: scheme.onSurface,
        elevation: 0,
        centerTitle: true,
      ),
      cardTheme: CardThemeData(
        color: scheme.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: scheme.outline.withValues(alpha: 0.55)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: scheme.outline.withValues(alpha: 0.55)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: scheme.primary, width: 1.4),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      dividerTheme: DividerThemeData(color: scheme.outline.withValues(alpha: 0.6), thickness: 1),
    );
  }
}