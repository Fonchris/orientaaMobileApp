import 'package:flutter/material.dart';

import 'google_fonts.dart';

/// Orientaa design system — black/charcoal + yellow-amber.
///
/// Rules: flat solid fills only (no gradients, no glow), pill-shaped CTAs,
/// charcoal cards with subtle radius, and a single warm yellow accent.
class AppTheme {
  // ---- Brand palette -----------------------------------------------------
  /// Primary accent / CTA color (warm yellow-amber).
  static const Color brandYellow = Color(0xFFFFC700);
  static const Color brandAmber = Color(0xFFF5B800);

  /// Near-black ink used for text and "on-yellow" content.
  static const Color brandInk = Color(0xFF141414);

  /// Dark surfaces (background -> card -> elevated card hierarchy).
  static const Color brandDark = Color(0xFF121212); // app background
  static const Color brandSurface = Color(0xFF1E1E1E); // base card
  static const Color brandCard = Color(0xFF2A2A2A); // elevated / list rows

  /// Light surfaces.
  static const Color brandLight = Color(0xFFF5F5F2); // app background
  static const Color brandLightCard = Color(0xFFFFFFFF);
  static const Color brandLightOutline = Color(0xFFE3E3DE);

  // Semantic flat colors (no gradients).
  static const Color success = Color(0xFF34C759);
  static const Color danger = Color(0xFFE5484D);
  static const Color info = Color(0xFF5AC8FA);
  static const Color violet = Color(0xFFAF52DE);
  static const Color orange = Color(0xFFFF9500);
  static const Color mint = Color(0xFF66D9A6);

  // ---- Legacy aliases ----------------------------------------------------
  // Old blue/gold names now resolve to the new black+yellow palette so every
  // pre-existing reference re-themes automatically. Kept during the migration
  // sweep; remove once all call sites use the new names.
  static const Color brandBlue = brandYellow;
  static const Color brandGold = brandAmber;
  static const Color brandIvory = brandLight;
  static const Color brandNavySurface = brandDark;
  static const Color brandSlate = brandCard;

  static ThemeData light() {
    final scheme = ColorScheme(
      brightness: Brightness.light,
      primary: brandYellow,
      onPrimary: brandInk,
      secondary: brandAmber,
      onSecondary: brandInk,
      tertiary: orange,
      onTertiary: brandInk,
      error: danger,
      onError: Colors.white,
      surface: brandLightCard,
      onSurface: brandInk,
      surfaceContainerHighest: const Color(0xFFF0F0EC),
      onSurfaceVariant: const Color(0xFF5C5C5A),
      outline: const Color(0xFFD9D9D4),
    );

    return _buildTheme(scheme).copyWith(
      scaffoldBackgroundColor: brandLight,
    );
  }

  static ThemeData dark() {
    final scheme = ColorScheme(
      brightness: Brightness.dark,
      primary: brandYellow,
      onPrimary: brandInk,
      secondary: brandAmber,
      onSecondary: brandInk,
      tertiary: orange,
      onTertiary: brandInk,
      error: const Color(0xFFFF6B70),
      onError: brandInk,
      surface: brandSurface,
      onSurface: const Color(0xFFF5F5F5),
      surfaceContainerHighest: brandCard,
      onSurfaceVariant: const Color(0xFF9C9C9C),
      outline: const Color(0xFF3A3A3A),
    );

    final base = _buildTheme(scheme);
    return base.copyWith(
      scaffoldBackgroundColor: brandDark,
      // Input wells sit one step above the card color so they read as inset
      // fields instead of blending into the surface.
      inputDecorationTheme: base.inputDecorationTheme.copyWith(
        fillColor: const Color(0xFF262626),
      ),
    );
  }

  static ThemeData _buildTheme(ColorScheme scheme) {
    final textTheme = GoogleFonts.plusJakartaSansTextTheme();

    // Pill-shaped primary CTA (solid yellow fill, dark label).
    final elevatedButton = ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: scheme.primary,
        foregroundColor: scheme.onPrimary,
        disabledBackgroundColor: scheme.onSurface.withValues(alpha: 0.08),
        disabledForegroundColor: scheme.onSurface.withValues(alpha: 0.3),
        elevation: 0,
        shape: const StadiumBorder(),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        textStyle: GoogleFonts.plusJakartaSans(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.2,
        ),
      ),
    );

    final filledButton = FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: scheme.primary,
        foregroundColor: scheme.onPrimary,
        disabledBackgroundColor: scheme.onSurface.withValues(alpha: 0.08),
        disabledForegroundColor: scheme.onSurface.withValues(alpha: 0.3),
        shape: const StadiumBorder(),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        textStyle: GoogleFonts.plusJakartaSans(
          fontSize: 15,
          fontWeight: FontWeight.w700,
        ),
      ),
    );

    final outlinedButton = OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: scheme.onSurface,
        side: BorderSide(color: scheme.outline),
        shape: const StadiumBorder(),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        textStyle: GoogleFonts.plusJakartaSans(
          fontSize: 15,
          fontWeight: FontWeight.w600,
        ),
      ),
    );

    final chipTheme = ChipThemeData(
      backgroundColor: scheme.surfaceContainerHighest,
      selectedColor: scheme.primary,
      labelStyle: GoogleFonts.inter(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: scheme.onSurface,
      ),
      side: BorderSide(color: scheme.outline),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      textTheme: textTheme.apply(
        bodyColor: scheme.onSurface,
        displayColor: scheme.onSurface,
      ),
      scaffoldBackgroundColor: scheme.surface,
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: scheme.onSurface,
        elevation: 0,
        centerTitle: true,
      ),
      cardTheme: CardThemeData(
        color: scheme.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: scheme.outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: scheme.outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: scheme.primary, width: 1.6),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      dividerTheme: DividerThemeData(color: scheme.outline, thickness: 1),
      elevatedButtonTheme: elevatedButton,
      filledButtonTheme: filledButton,
      outlinedButtonTheme: outlinedButton,
      chipTheme: chipTheme,
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: scheme.primary,
        linearTrackColor: scheme.surfaceContainerHighest,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: scheme.onSurface,
        contentTextStyle: GoogleFonts.inter(
          fontSize: 14,
          color: scheme.surface,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        behavior: SnackBarBehavior.floating,
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: scheme.surface,
        selectedItemColor: scheme.primary,
        unselectedItemColor: scheme.onSurfaceVariant,
        type: BottomNavigationBarType.fixed,
      ),
    );
  }
}
