import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'student_onboarding_model.dart';

class Step1IdentityPage extends StatelessWidget {
  final StudentOnboardingModel model;
  final VoidCallback onNext;
  final VoidCallback? onBack;

  const Step1IdentityPage({
    super.key,
    required this.model,
    required this.onNext,
    this.onBack,
  });

  static const _brandBlue = Color(0xFF011F7B);
  static const _brandGold = Color(0xFFFFBA09);

  static const List<String> educationLevels = [
    'Secondary school student',
    'Secondary school graduate',
    "Bachelor's in progress",
    "Bachelor's graduate",
    "Master's in progress",
    "Master's graduate",
    'Dropout',
    'Other',
  ];

  static const List<String> degreeLevels = [
    "Bachelor's",
    "Master's",
    'PhD',
    'Diploma / Vocational',
  ];

  static const List<String> fieldsOfInterest = [
    'Medicine & Health Sciences',
    'Engineering & Technology',
    'Computer Science & IT',
    'Business & Management',
    'Law & Legal Studies',
    'Education & Teaching',
    'Arts & Humanities',
    'Social Sciences',
    'Natural Sciences',
    'Agriculture & Environmental Studies',
    'Architecture & Urban Planning',
    'Media & Communications',
    'Economics & Finance',
    'Political Science & International Relations',
    'Psychology & Counseling',
    'Mathematics & Statistics',
    'Other',
  ];

  static const List<String> timelines = [
    'This year',
    'Next year',
    'Just exploring',
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : const Color(0xFF1A1A2E);
    final subtitleColor = isDark
        ? Colors.white.withValues(alpha: 0.6)
        : const Color(0xFF1A1A2E).withValues(alpha: 0.6);

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with icon
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  color: _brandBlue.withValues(alpha: 0.1),
                ),
                child: const FaIcon(FontAwesomeIcons.graduationCap, color: _brandBlue, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Identity & Academic Stage',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: textColor,
                        letterSpacing: -0.5,
                      ),
                    ),
                    Text(
                      'Tell us about your current academic status and goals.',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w400,
                        color: subtitleColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // ── Education Level ──
          _sectionLabel(FontAwesomeIcons.school, 'Current Education Level', isDark),
          const SizedBox(height: 8),
          _buildDropdown<String>(
            context,
            value: model.educationLevel,
            items: educationLevels,
            hint: 'Select your current level',
            onChanged: (v) => model.educationLevel = v,
          ),
          const SizedBox(height: 20),

          // ── Desired Degree Level ──
          _sectionLabel(FontAwesomeIcons.award, 'Desired Degree Level', isDark),
          const SizedBox(height: 8),
          _buildDropdown<String>(
            context,
            value: model.desiredDegreeLevel,
            items: degreeLevels,
            hint: 'Select desired degree',
            onChanged: (v) => model.desiredDegreeLevel = v,
          ),
          const SizedBox(height: 20),

          // ── Fields of Interest ──
          _sectionLabel(FontAwesomeIcons.bookOpen, 'Field(s) of Interest / Intended Major', isDark),
          const SizedBox(height: 8),
          _buildMultiSelectChips(
            context,
            options: fieldsOfInterest,
            selected: model.fieldsOfInterest,
            onToggle: (v) => model.toggleFieldOfInterest(v),
          ),
          const SizedBox(height: 20),

          // ── Target Timeline ──
          _sectionLabel(FontAwesomeIcons.calendarDays, 'Target Start Timeline', isDark),
          const SizedBox(height: 8),
          _buildChipGroup(
            context,
            options: timelines,
            selected: model.targetTimeline,
            onSelected: (v) => model.targetTimeline = v,
          ),
          const SizedBox(height: 32),

          // Next button
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: model.step1Valid ? onNext : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: _brandBlue,
                disabledBackgroundColor: isDark
                    ? Colors.white.withValues(alpha: 0.06)
                    : _brandBlue.withValues(alpha: 0.04),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(28),
                ),
                elevation: model.step1Valid ? 4 : 0,
                shadowColor: _brandBlue.withValues(alpha: 0.3),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Continue',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: model.step1Valid ? Colors.white : subtitleColor,
                    ),
                  ),
                  if (model.step1Valid) ...[
                    const SizedBox(width: 8),
                    const FaIcon(FontAwesomeIcons.arrowRight, color: Colors.white, size: 16),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionLabel(FaIconData icon, String label, bool isDark) {
    return Row(
      children: [
        FaIcon(icon, size: 14, color: _brandBlue),
        const SizedBox(width: 8),
        Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white.withValues(alpha: 0.8) : _brandBlue,
            letterSpacing: 0.2,
          ),
        ),
      ],
    );
  }

  Widget _buildDropdown<T>(
    BuildContext context, {
    required T? value,
    required List<T> items,
    required String hint,
    required ValueChanged<T?> onChanged,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: isDark
            ? const Color(0xFF323232).withValues(alpha: 0.6)
            : Colors.white.withValues(alpha: 0.9),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.08)
              : _brandBlue.withValues(alpha: 0.08),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          isExpanded: true,
          hint: Text(
            hint,
            style: GoogleFonts.inter(
              fontSize: 15,
              color: isDark
                  ? Colors.white.withValues(alpha: 0.3)
                  : _brandBlue.withValues(alpha: 0.3),
            ),
          ),
          style: GoogleFonts.inter(
            fontSize: 15,
            color: isDark ? Colors.white : const Color(0xFF1A1A2E),
          ),
          dropdownColor: isDark ? const Color(0xFF323232) : Colors.white,
          icon: const FaIcon(FontAwesomeIcons.chevronDown, size: 14),
          borderRadius: BorderRadius.circular(14),
          items: items.map((item) {
            return DropdownMenuItem<T>(
              value: item,
              child: Text(item.toString()),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildMultiSelectChips(
    BuildContext context, {
    required List<String> options,
    required List<String> selected,
    required ValueChanged<String> onToggle,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: options.map((option) {
        final isSelected = selected.contains(option);
        return GestureDetector(
          onTap: () => onToggle(option),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              color: isSelected
                  ? _brandBlue
                  : isDark
                      ? const Color(0xFF323232).withValues(alpha: 0.6)
                      : Colors.white.withValues(alpha: 0.9),
              border: Border.all(
                color: isSelected
                    ? _brandBlue
                    : isDark
                        ? Colors.white.withValues(alpha: 0.08)
                        : _brandBlue.withValues(alpha: 0.08),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  option,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                    color: isSelected
                        ? Colors.white
                        : isDark
                            ? Colors.white.withValues(alpha: 0.7)
                            : const Color(0xFF1A1A2E).withValues(alpha: 0.7),
                  ),
                ),
                if (isSelected) ...[
                  const SizedBox(width: 6),
                  const FaIcon(FontAwesomeIcons.check, color: _brandGold, size: 12),
                ],
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildChipGroup(
    BuildContext context, {
    required List<String> options,
    required String? selected,
    required ValueChanged<String> onSelected,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: options.map((option) {
        final isSel = selected == option;
        return GestureDetector(
          onTap: () => onSelected(option),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              color: isSel
                  ? _brandBlue
                  : isDark
                      ? const Color(0xFF323232).withValues(alpha: 0.6)
                      : Colors.white.withValues(alpha: 0.9),
              border: Border.all(
                color: isSel
                    ? _brandBlue
                    : isDark
                        ? Colors.white.withValues(alpha: 0.08)
                        : _brandBlue.withValues(alpha: 0.08),
              ),
              boxShadow: isSel
                  ? [
                      BoxShadow(
                        color: _brandBlue.withValues(alpha: 0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ]
                  : null,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  option,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    fontWeight: isSel ? FontWeight.w700 : FontWeight.w500,
                    color: isSel
                        ? Colors.white
                        : isDark
                            ? Colors.white.withValues(alpha: 0.7)
                            : const Color(0xFF1A1A2E).withValues(alpha: 0.7),
                  ),
                ),
                if (isSel) ...[
                  const SizedBox(width: 6),
                  const FaIcon(FontAwesomeIcons.circleCheck, color: _brandGold, size: 16),
                ],
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}