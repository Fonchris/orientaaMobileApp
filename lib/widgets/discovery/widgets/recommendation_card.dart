import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../../app_theme.dart';
import '../../google_fonts.dart';
import '../models/university_models.dart';
import '../screens/university_detail_page.dart';
import 'country_flag.dart';
import 'match_reasons.dart';
import 'save_button.dart';

/// Compact card shown in the dashboard's horizontal recommendations rail.
///
/// Shows the university logo/image, name, the top matching program, the
/// country flag and a "why recommended" summary built from the engine's
/// pre-computed `match_reasons`. Tapping opens the university detail page.
class RecommendationCard extends StatelessWidget {
  final RecommendedProgram program;
  final UserTier tier;

  const RecommendationCard({
    super.key,
    required this.program,
    required this.tier,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final percent = program.matchPercent;

    return Container(
      width: 278,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: isDark ? AppTheme.brandSurface : Colors.white,
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.06)
              : AppTheme.brandLightOutline,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.04),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => UniversityDetailPage(
                universityId: program.universityId,
                initialProgram: program,
              ),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _Logo(program: program),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            program.universityName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color:
                                  isDark ? Colors.white : AppTheme.brandInk,
                              letterSpacing: -0.2,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            program.programName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.brandAmber,
                            ),
                          ),
                        ],
                      ),
                    ),
                    SaveButton(program: program, iconSize: 14),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    CountryFlag(
                      countryCode: program.countryCode,
                      countryName: program.country,
                      flagSize: 13,
                    ),
                    const Spacer(),
                    if (percent != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(999),
                          color: AppTheme.success.withValues(alpha: 0.12),
                        ),
                        child: Text(
                          'Match: $percent%',
                          style: GoogleFonts.inter(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.success,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 10),
                // "Why recommended" summary — engine-computed reasons.
                MatchReasons(program: program, tier: tier, dense: true),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// University logo with graceful fallback to a school glyph.
class _Logo extends StatelessWidget {
  final RecommendedProgram program;

  const _Logo({required this.program});

  @override
  Widget build(BuildContext context) {
    final url = program.logoUrl;
    if (url != null && url.isNotEmpty) {
      return Container(
        width: 44,
        height: 44,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(13),
          color: AppTheme.brandLight,
        ),
        child: Image.network(
          url,
          width: 44,
          height: 44,
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => const _FallbackLogo(),
        ),
      );
    }
    return const _FallbackLogo();
  }
}

class _FallbackLogo extends StatelessWidget {
  const _FallbackLogo();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(13),
        color: AppTheme.brandYellow,
      ),
      child: const Center(
        child: FaIcon(
          FontAwesomeIcons.graduationCap,
          size: 17,
          color: AppTheme.brandInk,
        ),
      ),
    );
  }
}
