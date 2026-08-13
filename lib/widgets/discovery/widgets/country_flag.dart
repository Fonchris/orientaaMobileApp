import 'package:flutter/material.dart';

import '../../app_theme.dart';
import '../../google_fonts.dart';
import '../models/university_models.dart';

/// Compact flag chip: flag emoji (+ optional country name) rendered from an
/// ISO 3166-1 alpha-2 code. Falls back to a globe emoji for missing codes.
class CountryFlag extends StatelessWidget {
  final String? countryCode;
  final String? countryName;
  final double flagSize;
  final bool showName;

  const CountryFlag({
    super.key,
    this.countryCode,
    this.countryName,
    this.flagSize = 16,
    this.showName = true,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final label = Text(
      flagEmojiFor(countryCode),
      style: TextStyle(fontSize: flagSize, height: 1),
    );

    if (!showName || countryName == null) return label;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        label,
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            countryName!,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: isDark
                  ? Colors.white.withValues(alpha: 0.65)
                  : AppTheme.brandInk.withValues(alpha: 0.6),
            ),
          ),
        ),
      ],
    );
  }
}
