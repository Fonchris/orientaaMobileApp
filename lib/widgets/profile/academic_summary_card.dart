import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../app_theme.dart';
import '../google_fonts.dart';
import 'profile_models.dart';

/// Compact academic summary surfaced from onboarding data.
///
/// Kept intentionally light: education level, degree goal, field of interest
/// and saved-universities count. Full onboarding details live behind
/// [onViewDetails].
class AcademicSummaryCard extends StatelessWidget {
  final ProfileData profile;
  final int savedUniversities;
  final VoidCallback onEditProfile;
  final VoidCallback onViewDetails;
  final VoidCallback onBrowseUniversities;

  const AcademicSummaryCard({
    super.key,
    required this.profile,
    required this.savedUniversities,
    required this.onEditProfile,
    required this.onViewDetails,
    required this.onBrowseUniversities,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final o = profile.onboardingData;

    final education = o['educationLevel'] as String?;
    final degree = o['desiredDegreeLevel'] as String?;
    final fields = o['fieldsOfInterest'];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white,
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.08)
              : AppTheme.brandBlue.withValues(alpha: 0.08),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: AppTheme.brandBlue.withValues(alpha: 0.08),
                ),
                child: const FaIcon(
                  FontAwesomeIcons.bookOpen,
                  size: 13,
                  color: AppTheme.brandBlue,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                'Academic Profile',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.9)
                      : AppTheme.brandBlue,
                  letterSpacing: 0.2,
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: onViewDetails,
                child: Text(
                  'Full details',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.brandGold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (education != null)
            _row(context, isDark, 'Education', education),
          if (degree != null) _row(context, isDark, 'Degree goal', degree),
          if (fields != null && fields is List && fields.isNotEmpty)
            _row(context, isDark, 'Field of interest', fields.join(', ')),
          const SizedBox(height: 4),
          InkWell(
            onTap: onBrowseUniversities,
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                children: [
                  const FaIcon(
                    FontAwesomeIcons.school,
                    size: 12,
                    color: AppTheme.brandGold,
                  ),
                  const SizedBox(width: 9),
                  Expanded(
                    child: Text(
                      savedUniversities > 0
                          ? '$savedUniversities saved universit${savedUniversities == 1 ? 'y' : 'ies'}'
                          : 'Save universities to build your shortlist',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.75)
                            : AppTheme.brandInk.withValues(alpha: 0.75),
                      ),
                    ),
                  ),
                  FaIcon(
                    FontAwesomeIcons.chevronRight,
                    size: 11,
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.35)
                        : AppTheme.brandInk.withValues(alpha: 0.35),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: OutlinedButton.icon(
              onPressed: onEditProfile,
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.brandBlue,
                side: BorderSide(
                  color: AppTheme.brandBlue.withValues(alpha: 0.3),
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              icon: const FaIcon(FontAwesomeIcons.penToSquare, size: 13),
              label: Text(
                'Edit Profile',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _row(BuildContext context, bool isDark, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isDark
                    ? Colors.white.withValues(alpha: 0.45)
                    : AppTheme.brandInk.withValues(alpha: 0.45),
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: isDark ? Colors.white : AppTheme.brandInk,
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
