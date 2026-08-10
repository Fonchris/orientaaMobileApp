import 'package:flutter/material.dart';

class GoogleFonts {
  /// Active font family. Switched to the bundled Cairo font (which covers
  /// Arabic + Latin glyphs) whenever the app locale is Arabic, so Arabic text
  /// no longer falls back to a mismatched system font.
  static String _fontFamily = 'sans-serif';

  /// Updates the active family (call from the locale change handler).
  static void setFontFamily(String family) {
    _fontFamily = family;
  }

  static TextStyle plusJakartaSans({
    TextStyle? textStyle,
    Color? color,
    Color? backgroundColor,
    double? fontSize,
    FontWeight? fontWeight,
    FontStyle? fontStyle,
    double? letterSpacing,
    double? wordSpacing,
    TextBaseline? textBaseline,
    double? height,
    Locale? locale,
    Paint? foreground,
    Paint? background,
    List<Shadow>? shadows,
    List<FontFeature>? fontFeatures,
    TextDecoration? decoration,
    Color? decorationColor,
    TextDecorationStyle? decorationStyle,
    double? decorationThickness,
  }) {
    return _buildStyle(
      textStyle: textStyle,
      color: color,
      backgroundColor: backgroundColor,
      fontSize: fontSize,
      fontWeight: fontWeight,
      fontStyle: fontStyle,
      letterSpacing: letterSpacing,
      wordSpacing: wordSpacing,
      textBaseline: textBaseline,
      height: height,
      locale: locale,
      foreground: foreground,
      background: background,
      shadows: shadows,
      fontFeatures: fontFeatures,
      decoration: decoration,
      decorationColor: decorationColor,
      decorationStyle: decorationStyle,
      decorationThickness: decorationThickness,
    );
  }

  static TextStyle inter({
    TextStyle? textStyle,
    Color? color,
    Color? backgroundColor,
    double? fontSize,
    FontWeight? fontWeight,
    FontStyle? fontStyle,
    double? letterSpacing,
    double? wordSpacing,
    TextBaseline? textBaseline,
    double? height,
    Locale? locale,
    Paint? foreground,
    Paint? background,
    List<Shadow>? shadows,
    List<FontFeature>? fontFeatures,
    TextDecoration? decoration,
    Color? decorationColor,
    TextDecorationStyle? decorationStyle,
    double? decorationThickness,
  }) {
    return _buildStyle(
      textStyle: textStyle,
      color: color,
      backgroundColor: backgroundColor,
      fontSize: fontSize,
      fontWeight: fontWeight,
      fontStyle: fontStyle,
      letterSpacing: letterSpacing,
      wordSpacing: wordSpacing,
      textBaseline: textBaseline,
      height: height,
      locale: locale,
      foreground: foreground,
      background: background,
      shadows: shadows,
      fontFeatures: fontFeatures,
      decoration: decoration,
      decorationColor: decorationColor,
      decorationStyle: decorationStyle,
      decorationThickness: decorationThickness,
    );
  }

  static TextTheme plusJakartaSansTextTheme([TextTheme? textTheme]) {
    final base = textTheme ?? const TextTheme();
    return base.copyWith(
      displayLarge: plusJakartaSans(textStyle: base.displayLarge),
      displayMedium: plusJakartaSans(textStyle: base.displayMedium),
      displaySmall: plusJakartaSans(textStyle: base.displaySmall),
      headlineLarge: plusJakartaSans(textStyle: base.headlineLarge),
      headlineMedium: plusJakartaSans(textStyle: base.headlineMedium),
      headlineSmall: plusJakartaSans(textStyle: base.headlineSmall),
      titleLarge: plusJakartaSans(textStyle: base.titleLarge),
      titleMedium: plusJakartaSans(textStyle: base.titleMedium),
      titleSmall: plusJakartaSans(textStyle: base.titleSmall),
      bodyLarge: plusJakartaSans(textStyle: base.bodyLarge),
      bodyMedium: plusJakartaSans(textStyle: base.bodyMedium),
      bodySmall: plusJakartaSans(textStyle: base.bodySmall),
      labelLarge: plusJakartaSans(textStyle: base.labelLarge),
      labelMedium: plusJakartaSans(textStyle: base.labelMedium),
      labelSmall: plusJakartaSans(textStyle: base.labelSmall),
    );
  }

  static TextStyle _buildStyle({
    TextStyle? textStyle,
    Color? color,
    Color? backgroundColor,
    double? fontSize,
    FontWeight? fontWeight,
    FontStyle? fontStyle,
    double? letterSpacing,
    double? wordSpacing,
    TextBaseline? textBaseline,
    double? height,
    Locale? locale,
    Paint? foreground,
    Paint? background,
    List<Shadow>? shadows,
    List<FontFeature>? fontFeatures,
    TextDecoration? decoration,
    Color? decorationColor,
    TextDecorationStyle? decorationStyle,
    double? decorationThickness,
  }) {
    return (textStyle ?? const TextStyle()).copyWith(
      fontFamily: _fontFamily,
      color: color,
      backgroundColor: backgroundColor,
      fontSize: fontSize,
      fontWeight: fontWeight,
      fontStyle: fontStyle,
      letterSpacing: letterSpacing,
      wordSpacing: wordSpacing,
      textBaseline: textBaseline,
      height: height,
      locale: locale,
      foreground: foreground,
      background: background,
      shadows: shadows,
      fontFeatures: fontFeatures,
      decoration: decoration,
      decorationColor: decorationColor,
      decorationStyle: decorationStyle,
      decorationThickness: decorationThickness,
    );
  }
}