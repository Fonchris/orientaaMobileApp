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
  static const _brandYellow = Color(0xFFFFDB00);

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
    'Arts & Design',
    'Biology',
    'Business',
    'Chemistry',
    'Computer Science',
    'Economics',
    'Engineering',
    'Environmental Science',
    'Liberal Arts & Social Sciences',
    'Mathematics',
    'Medicine',
    'Physics',
    'Psychology',
    'Other',
  ];

  static const String _otherField = 'Other';

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

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [const Color(0xFF1A1A2E), const Color(0xFF0F1115)]
              : [const Color(0xFFF8F9FF), Colors.white],
        ),
      ),
      child: Stack(
        children: [
          // Decorative background elements
          ..._buildBackgroundDecorations(isDark),
          // Main content with pinned button
          Column(
            children: [
              // Scrollable form content
              Expanded(
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Premium header with icon
                      _buildPremiumHeader(isDark, textColor, subtitleColor),
                      const SizedBox(height: 28),

                      // Education Level
                      _buildSection(
                        icon: FontAwesomeIcons.school,
                        label: 'Current Education Level',
                        isDark: isDark,
                        subtitleColor: subtitleColor,
                        child: _buildDropdown<String>(
                          context,
                          value: model.educationLevel,
                          items: educationLevels,
                          hint: 'Select your current level',
                          onChanged: (v) => model.educationLevel = v,
                          isDark: isDark,
                        ),
                      ),
                      const SizedBox(height: 22),

                      // Desired Degree Level
                      _buildSection(
                        icon: FontAwesomeIcons.award,
                        label: 'Desired Degree Level',
                        isDark: isDark,
                        subtitleColor: subtitleColor,
                        child: _buildDropdown<String>(
                          context,
                          value: model.desiredDegreeLevel,
                          items: degreeLevels,
                          hint: 'Select desired degree',
                          onChanged: (v) => model.desiredDegreeLevel = v,
                          isDark: isDark,
                        ),
                      ),
                      const SizedBox(height: 22),

                      // Fields of Interest
                      _buildSection(
                        icon: FontAwesomeIcons.bookOpen,
                        label: 'Field(s) of Interest',
                        isDark: isDark,
                        subtitleColor: subtitleColor,
                        child: _buildMultiSelectChips(
                          context,
                          options: fieldsOfInterest,
                          selected: model.fieldsOfInterest,
                          onToggle: (v) => model.toggleFieldOfInterest(v),
                          isDark: isDark,
                        ),
                      ),
                      // Custom field input when "Other" is selected
                      if (model.fieldsOfInterest.contains(_otherField)) ...[
                        const SizedBox(height: 10),
                        _buildCustomFieldInput(context, isDark),
                      ],
                      const SizedBox(height: 22),

                      // Target Timeline
                      _buildSection(
                        icon: FontAwesomeIcons.calendarDays,
                        label: 'When do you plan to start?',
                        isDark: isDark,
                        subtitleColor: subtitleColor,
                        child: _buildChipGroup(
                          context,
                          options: timelines,
                          selected: model.targetTimeline,
                          onSelected: (v) => model.targetTimeline = v,
                          isDark: isDark,
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
              // Pinned bottom button with validation hint
              Container(
                padding: EdgeInsets.fromLTRB(20, 12, 20, MediaQuery.of(context).padding.bottom + 12),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1A1A2E) : Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: isDark ? Colors.black.withValues(alpha: 0.3) : _brandBlue.withValues(alpha: 0.08),
                      blurRadius: 16,
                      offset: const Offset(0, -4),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Validation hint
                    if (!model.step1Valid)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const FaIcon(FontAwesomeIcons.circleInfo, size: 12, color: _brandGold),
                            const SizedBox(width: 6),
                            Text(
                              _validationHint(model),
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: _brandGold,
                              ),
                            ),
                          ],
                        ),
                      ),
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
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: model.step1Valid ? 6 : 0,
                          shadowColor: _brandBlue.withValues(alpha: 0.4),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              model.step1Valid ? 'Continue' : 'Complete all fields',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: model.step1Valid ? Colors.white : subtitleColor,
                                letterSpacing: 0.3,
                              ),
                            ),
                            if (model.step1Valid) ...[
                              const SizedBox(width: 10),
                              Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: _brandGold.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const FaIcon(FontAwesomeIcons.arrowRight, color: Colors.white, size: 14),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Decorative Background Elements ──
  List<Widget> _buildBackgroundDecorations(bool isDark) {
    return [
      // Top-right gradient blob
      Positioned(
        top: -60,
        right: -40,
        child: Container(
          width: 200,
          height: 200,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [
                _brandBlue.withValues(alpha: isDark ? 0.08 : 0.04),
                _brandBlue.withValues(alpha: 0),
              ],
            ),
          ),
        ),
      ),
      // Bottom-left floating circle
      Positioned(
        bottom: 80,
        left: -30,
        child: Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [
                _brandGold.withValues(alpha: isDark ? 0.06 : 0.03),
                _brandGold.withValues(alpha: 0),
              ],
            ),
          ),
        ),
      ),
      // Mid-right abstract shape
      Positioned(
        top: 250,
        right: -20,
        child: Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: RadialGradient(
              colors: [
                _brandYellow.withValues(alpha: isDark ? 0.05 : 0.03),
                _brandYellow.withValues(alpha: 0),
              ],
            ),
          ),
        ),
      ),
    ];
  }

  // ── Premium Header ──
  Widget _buildPremiumHeader(bool isDark, Color textColor, Color subtitleColor) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          colors: isDark
              ? [const Color(0xFF323232).withValues(alpha: 0.6), const Color(0xFF1A1A2E)]
              : [Colors.white, const Color(0xFFF8F9FF)],
        ),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.06)
              : _brandBlue.withValues(alpha: 0.06),
        ),
        boxShadow: [
          BoxShadow(
            color: _brandBlue.withValues(alpha: isDark ? 0.1 : 0.04),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Icon with gradient background
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: const LinearGradient(
                colors: [_brandBlue, Color(0xFF1F6FEB)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: _brandBlue.withValues(alpha: 0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Center(
              child: FaIcon(FontAwesomeIcons.graduationCap, color: Colors.white, size: 26),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Identity & Academic',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: textColor,
                    letterSpacing: -0.5,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Tell us about your academic status and goals',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w400,
                    color: subtitleColor,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Section Builder ──
  Widget _buildSection({
    required FaIconData icon,
    required String label,
    required bool isDark,
    required Color subtitleColor,
    required Widget child,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 10),
          child: Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: _brandBlue.withValues(alpha: 0.08),
                ),
                child: FaIcon(icon, size: 13, color: _brandBlue),
              ),
              const SizedBox(width: 10),
              Text(
                label,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white.withValues(alpha: 0.9) : _brandBlue,
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),
        ),
        child,
      ],
    );
  }

  // ── Premium Dropdown ──
  Widget _buildDropdown<T>(
    BuildContext context, {
    required T? value,
    required List<T> items,
    required String hint,
    required ValueChanged<T?> onChanged,
    required bool isDark,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: isDark
            ? const Color(0xFF323232).withValues(alpha: 0.8)
            : Colors.white,
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.08)
              : _brandBlue.withValues(alpha: 0.08),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black.withValues(alpha: 0.15) : _brandBlue.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
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
                  : _brandBlue.withValues(alpha: 0.35),
            ),
          ),
          style: GoogleFonts.inter(
            fontSize: 15,
            fontWeight: FontWeight.w500,
            color: isDark ? Colors.white : const Color(0xFF1A1A2E),
          ),
          dropdownColor: isDark ? const Color(0xFF323232) : Colors.white,
          icon: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              color: _brandBlue.withValues(alpha: isDark ? 0.15 : 0.08),
            ),
            child: const FaIcon(FontAwesomeIcons.chevronDown, size: 12, color: _brandBlue),
          ),
          borderRadius: BorderRadius.circular(16),
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

  // ── Validation Hint ──
  String _validationHint(StudentOnboardingModel m) {
    if (m.educationLevel == null && m.desiredDegreeLevel == null) {
      return 'Select your education level and desired degree';
    }
    if (m.educationLevel == null) return 'Select your current education level';
    if (m.desiredDegreeLevel == null) return 'Select your desired degree level';
    if (m.fieldsOfInterest.isEmpty) return 'Select at least one field of interest';
    if (m.targetTimeline == null) return 'Select when you plan to start';
    return '';
  }

  // ── Custom Field Input (for "Other") ──
  Widget _buildCustomFieldInput(BuildContext context, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: isDark
            ? const Color(0xFF323232).withValues(alpha: 0.8)
            : Colors.white,
        border: Border.all(
          color: _brandBlue.withValues(alpha: 0.15),
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          const FaIcon(FontAwesomeIcons.pen, size: 14, color: _brandBlue),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: TextEditingController(text: model.customField ?? '')
                ..selection = TextSelection.fromPosition(
                  TextPosition(offset: model.customField?.length ?? 0),
                ),
              onChanged: (v) => model.customField = v,
              style: GoogleFonts.inter(
                fontSize: 14,
                color: isDark ? Colors.white : const Color(0xFF1A1A2E),
              ),
              decoration: InputDecoration(
                hintText: 'Enter your field of interest...',
                hintStyle: GoogleFonts.inter(
                  fontSize: 14,
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.3)
                      : _brandBlue.withValues(alpha: 0.3),
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Premium Multi-Select Chips ──
  Widget _buildMultiSelectChips(
    BuildContext context, {
    required List<String> options,
    required List<String> selected,
    required ValueChanged<String> onToggle,
    required bool isDark,
  }) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: options.map((option) {
        final isSelected = selected.contains(option);
        return GestureDetector(
          onTap: () => onToggle(option),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              color: isSelected
                  ? _brandBlue
                  : isDark
                      ? const Color(0xFF323232).withValues(alpha: 0.8)
                      : Colors.white,
              border: Border.all(
                color: isSelected
                    ? _brandBlue
                    : isDark
                        ? Colors.white.withValues(alpha: 0.08)
                        : _brandBlue.withValues(alpha: 0.08),
                width: isSelected ? 2 : 1.5,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: _brandBlue.withValues(alpha: 0.35),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ]
                  : [
                      BoxShadow(
                        color: isDark ? Colors.black.withValues(alpha: 0.1) : _brandBlue.withValues(alpha: 0.03),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
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
                            : const Color(0xFF1A1A2E).withValues(alpha: 0.75),
                  ),
                ),
                if (isSelected) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: _brandGold.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const FaIcon(FontAwesomeIcons.check, color: _brandGold, size: 10),
                  ),
                ],
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  // ── Premium Chip Group (Single Select) ──
  Widget _buildChipGroup(
    BuildContext context, {
    required List<String> options,
    required String? selected,
    required ValueChanged<String> onSelected,
    required bool isDark,
  }) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: options.map((option) {
        final isSel = selected == option;
        return GestureDetector(
          onTap: () => onSelected(option),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: isSel
                  ? _brandBlue
                  : isDark
                      ? const Color(0xFF323232).withValues(alpha: 0.8)
                      : Colors.white,
              border: Border.all(
                color: isSel
                    ? _brandBlue
                    : isDark
                        ? Colors.white.withValues(alpha: 0.08)
                        : _brandBlue.withValues(alpha: 0.08),
                width: isSel ? 2 : 1.5,
              ),
              boxShadow: isSel
                  ? [
                      BoxShadow(
                        color: _brandBlue.withValues(alpha: 0.35),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ]
                  : [
                      BoxShadow(
                        color: isDark ? Colors.black.withValues(alpha: 0.1) : _brandBlue.withValues(alpha: 0.03),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
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
                            : const Color(0xFF1A1A2E).withValues(alpha: 0.75),
                  ),
                ),
                if (isSel) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      color: _brandGold.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const FaIcon(FontAwesomeIcons.circleCheck, color: _brandGold, size: 14),
                  ),
                ],
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}