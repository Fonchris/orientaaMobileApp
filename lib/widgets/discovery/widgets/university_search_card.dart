import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../../app_theme.dart';
import '../../google_fonts.dart';
import '../models/university_models.dart';
import '../screens/university_detail_page.dart';
import 'country_flag.dart';
import 'match_reasons.dart';
import 'save_button.dart';

/// Full-width result card for the discovery/search list.
///
/// Shows program name, university, country, annual fee, degree level, a
/// "Match: NN%" tag derived from the engine's similarity score, the
/// pre-computed match reasons, and a save button. In Premium compare mode a
/// selection toggle is rendered instead of the chevron.
class UniversitySearchCard extends StatelessWidget {
  final RecommendedProgram program;
  final UserTier tier;

  /// Premium compare mode: when true, renders a selection checkbox and
  /// notifies [onSelectionChanged] with the new selected state.
  final bool compareMode;
  final bool selected;
  final ValueChanged<bool>? onSelectionChanged;

  const UniversitySearchCard({
    super.key,
    required this.program,
    required this.tier,
    this.compareMode = false,
    this.selected = false,
    this.onSelectionChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final percent = program.matchPercent;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: isDark ? Colors.white.withValues(alpha: 0.04) : Colors.white,
        border: Border.all(
          color: compareMode && selected
              ? AppTheme.brandYellow
              : isDark
                  ? Colors.white.withValues(alpha: 0.07)
                  : AppTheme.brandLightOutline,
          width: compareMode && selected ? 1.6 : 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(18),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: compareMode
              ? () => onSelectionChanged?.call(!selected)
              : () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => UniversityDetailPage(
                        universityId: program.universityId,
                        initialProgram: program,
                      ),
                    ),
                  ),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _Logo(program: program),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  program.programName,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 14.5,
                                    fontWeight: FontWeight.w800,
                                    color: isDark
                                        ? Colors.white
                                        : AppTheme.brandInk,
                                    letterSpacing: -0.2,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  program.universityName,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    color: isDark
                                        ? Colors.white.withValues(alpha: 0.55)
                                        : AppTheme.brandInk.withValues(
                                            alpha: 0.55,
                                          ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          SaveButton(program: program, iconSize: 13),
                        ],
                      ),
                      const SizedBox(height: 8),
                      // Meta row: country · degree · fee
                      Wrap(
                        spacing: 10,
                        runSpacing: 4,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          CountryFlag(
                            countryCode: program.countryCode,
                            countryName: program.country,
                            flagSize: 12,
                          ),
                          if (program.degreeLevel != null)
                            _metaItem(
                              FontAwesomeIcons.graduationCap,
                              program.degreeLevel!,
                              isDark,
                            ),
                          if (program.fee != null)
                            _metaItem(
                              FontAwesomeIcons.wallet,
                              formatMoney(program.fee, program.currency),
                              isDark,
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: MatchReasons(
                              program: program,
                              tier: tier,
                              dense: true,
                            ),
                          ),
                          if (percent != null) ...[
                            const SizedBox(width: 8),
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
                        ],
                      ),
                    ],
                  ),
                ),
                if (compareMode) ...[
                  const SizedBox(width: 10),
                  _SelectionToggle(
                    selected: selected,
                    onChanged: (v) => onSelectionChanged?.call(v),
                  ),
                ] else
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: FaIcon(
                      FontAwesomeIcons.chevronRight,
                      size: 12,
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.3)
                          : AppTheme.brandInk.withValues(alpha: 0.3),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _metaItem(FaIconData icon, String label, bool isDark) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        FaIcon(icon, size: 10, color: AppTheme.brandAmber),
        const SizedBox(width: 4),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 11.5,
            fontWeight: FontWeight.w500,
            color: isDark
                ? Colors.white.withValues(alpha: 0.65)
                : AppTheme.brandInk.withValues(alpha: 0.6),
          ),
        ),
      ],
    );
  }
}

class _SelectionToggle extends StatelessWidget {
  final bool selected;
  final ValueChanged<bool> onChanged;

  const _SelectionToggle({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => onChanged(!selected),
      child: Container(
        width: 24,
        height: 24,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: selected ? AppTheme.brandYellow : Colors.transparent,
          border: Border.all(
            color: selected ? AppTheme.brandYellow : Colors.grey.shade400,
            width: 1.6,
          ),
        ),
        child: selected
            ? const Center(
                child: FaIcon(
                  FontAwesomeIcons.check,
                  size: 11,
                  color: AppTheme.brandInk,
                ),
              )
            : null,
      ),
    );
  }
}

class _Logo extends StatelessWidget {
  final RecommendedProgram program;

  const _Logo({required this.program});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final url = program.logoUrl;
    if (url != null && url.isNotEmpty) {
      return Container(
        width: 46,
        height: 46,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(13),
          color: isDark ? AppTheme.brandCard : AppTheme.brandLight,
        ),
        child: Image.network(
          url,
          width: 46,
          height: 46,
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
      width: 46,
      height: 46,
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
