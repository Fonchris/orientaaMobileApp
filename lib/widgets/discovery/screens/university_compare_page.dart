import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../../../l10n/app_localizations.dart';
import '../../app_theme.dart';
import '../../google_fonts.dart';
import '../models/university_models.dart';
import '../widgets/country_flag.dart';

/// Stub comparison screen reached from the Premium compare bar.
///
/// The full side-by-side comparison module is a separate deliverable; this
/// screen wires the navigation + selected-items state and renders the chosen
/// programs' key attributes so the flow is complete end-to-end.
class UniversityComparePage extends StatelessWidget {
  final List<RecommendedProgram> programs;

  const UniversityComparePage({super.key, required this.programs});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          l10n.compare,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.3,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              color: isDark
                  ? Colors.white.withValues(alpha: 0.04)
                  : Colors.white,
              border: Border.all(
                color: AppTheme.brandYellow.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              children: [
                const FaIcon(
                  FontAwesomeIcons.clockRotateLeft,
                  size: 18,
                  color: AppTheme.brandAmber,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    l10n.compareStubMessage,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      height: 1.4,
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.7)
                          : AppTheme.brandInk.withValues(alpha: 0.7),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          ...programs.map((p) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _compareRow(context, p),
              )),
        ],
      ),
    );
  }

  Widget _compareRow(BuildContext context, RecommendedProgram p) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: isDark ? AppTheme.brandSurface : Colors.white,
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.06)
              : AppTheme.brandLightOutline,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            p.programName,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14.5,
              fontWeight: FontWeight.w800,
              color: isDark ? Colors.white : AppTheme.brandInk,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            p.universityName,
            style: GoogleFonts.inter(
              fontSize: 12.5,
              color: isDark
                  ? Colors.white.withValues(alpha: 0.55)
                  : AppTheme.brandInk.withValues(alpha: 0.55),
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 14,
            runSpacing: 6,
            children: [
              CountryFlag(
                countryCode: p.countryCode,
                countryName: p.country,
                flagSize: 13,
              ),
              if (p.degreeLevel != null)
                _attr(FontAwesomeIcons.graduationCap, p.degreeLevel!, isDark),
              if (p.fee != null)
                _attr(
                  FontAwesomeIcons.wallet,
                  formatMoney(p.fee, p.currency),
                  isDark,
                ),
              if (p.matchPercent != null)
                _attr(
                  FontAwesomeIcons.bullseye,
                  'Match: ${p.matchPercent}%',
                  isDark,
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _attr(FaIconData icon, String label, bool isDark) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        FaIcon(icon, size: 11, color: AppTheme.brandAmber),
        const SizedBox(width: 5),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 12,
            color: isDark
                ? Colors.white.withValues(alpha: 0.65)
                : AppTheme.brandInk.withValues(alpha: 0.6),
          ),
        ),
      ],
    );
  }
}
