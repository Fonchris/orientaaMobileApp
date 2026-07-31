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

  static const List<String> _months = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December',
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : const Color(0xFF1A1A2E);
    final subtitleColor = isDark
        ? Colors.white.withValues(alpha: 0.6)
        : const Color(0xFF1A1A2E).withValues(alpha: 0.6);

    // Simple Column layout - no Stack wrapper to avoid scroll conflicts
    return Column(
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

                // Start Date (Month/Year Picker)
                _buildSection(
                  icon: FontAwesomeIcons.calendarDays,
                  label: 'When do you plan to start?',
                  isDark: isDark,
                  subtitleColor: subtitleColor,
                  child: _buildDatePickerButton(context, isDark),
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
    );
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
        color: isDark ? const Color(0xFF323232).withValues(alpha: 0.8) : Colors.white,
        border: Border.all(
          color: isDark ? Colors.white.withValues(alpha: 0.08) : _brandBlue.withValues(alpha: 0.08),
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
              color: isDark ? Colors.white.withValues(alpha: 0.3) : _brandBlue.withValues(alpha: 0.35),
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
            return DropdownMenuItem<T>(value: item, child: Text(item.toString()));
          }).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  // ── Month/Year Picker Button ──
  Widget _buildDatePickerButton(BuildContext context, bool isDark) {
    return GestureDetector(
      onTap: () => _showMonthYearPicker(context, isDark),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: isDark ? const Color(0xFF323232).withValues(alpha: 0.8) : Colors.white,
          border: Border.all(
            color: model.startLabel != null
                ? _brandBlue
                : isDark
                    ? Colors.white.withValues(alpha: 0.08)
                    : _brandBlue.withValues(alpha: 0.08),
            width: model.startLabel != null ? 2 : 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: isDark ? Colors.black.withValues(alpha: 0.15) : _brandBlue.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                color: _brandBlue.withValues(alpha: isDark ? 0.15 : 0.08),
              ),
              child: const FaIcon(FontAwesomeIcons.calendar, size: 14, color: _brandBlue),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                model.startLabel ?? 'Tap to select month & year',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: model.startLabel != null ? FontWeight.w600 : FontWeight.w400,
                  color: model.startLabel != null
                      ? (isDark ? Colors.white : const Color(0xFF1A1A2E))
                      : (isDark ? Colors.white.withValues(alpha: 0.3) : _brandBlue.withValues(alpha: 0.35)),
                ),
              ),
            ),
            if (model.startLabel != null)
              Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  color: _brandGold.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const FaIcon(FontAwesomeIcons.check, color: _brandGold, size: 12),
              )
            else
              const FaIcon(FontAwesomeIcons.chevronDown, size: 14, color: _brandBlue),
          ],
        ),
      ),
    );
  }

  // ── Month/Year Picker Dialog ──
  void _showMonthYearPicker(BuildContext context, bool isDark) {
    int selectedMonth = model.startMonth ?? DateTime.now().month;
    int selectedYear = model.startYear ?? DateTime.now().year;
    final currentYear = DateTime.now().year;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? const Color(0xFF1A1A2E) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Padding(
              padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
              child: SizedBox(
                height: 420,
                child: Column(
                  children: [
                    // Handle bar
                    const SizedBox(height: 12),
                    Container(
                      width: 40, height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Title
                    Text(
                      'Select intake period',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white : const Color(0xFF1A1A2E),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'When do you plan to begin your studies?',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: isDark ? Colors.white.withValues(alpha: 0.5) : const Color(0xFF1A1A2E).withValues(alpha: 0.5),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Month selector
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Month', style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w600, color: _brandBlue)),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: List.generate(12, (i) {
                              final month = i + 1;
                              final isSelected = selectedMonth == month;
                              return GestureDetector(
                                onTap: () => setDialogState(() => selectedMonth = month),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(12),
                                    color: isSelected ? _brandBlue : isDark ? const Color(0xFF323232).withValues(alpha: 0.6) : Colors.grey.withValues(alpha: 0.06),
                                    border: Border.all(
                                      color: isSelected ? _brandBlue : isDark ? Colors.white.withValues(alpha: 0.08) : _brandBlue.withValues(alpha: 0.08),
                                    ),
                                  ),
                                  child: Text(
                                    _months[i],
                                    style: GoogleFonts.inter(
                                      fontSize: 13,
                                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                                      color: isSelected ? Colors.white : isDark ? Colors.white.withValues(alpha: 0.7) : const Color(0xFF1A1A2E).withValues(alpha: 0.7),
                                    ),
                                  ),
                                ),
                              );
                            }),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Year selector
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Row(
                        children: [
                          Text('Year', style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w600, color: _brandBlue)),
                          const SizedBox(width: 12),
                          Expanded(
                            child: SizedBox(
                              height: 44,
                              child: ListView(
                                scrollDirection: Axis.horizontal,
                                children: List.generate(10, (i) {
                                  final year = currentYear + i;
                                  final isSelected = selectedYear == year;
                                  return Padding(
                                    padding: const EdgeInsets.only(right: 8),
                                    child: GestureDetector(
                                      onTap: () => setDialogState(() => selectedYear = year),
                                      child: AnimatedContainer(
                                        duration: const Duration(milliseconds: 200),
                                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(12),
                                          color: isSelected ? _brandBlue : isDark ? const Color(0xFF323232).withValues(alpha: 0.6) : Colors.grey.withValues(alpha: 0.06),
                                          border: Border.all(
                                            color: isSelected ? _brandBlue : isDark ? Colors.white.withValues(alpha: 0.08) : _brandBlue.withValues(alpha: 0.08),
                                          ),
                                        ),
                                        child: Text(
                                          '$year',
                                          style: GoogleFonts.plusJakartaSans(
                                            fontSize: 14,
                                            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                            color: isSelected ? Colors.white : isDark ? Colors.white.withValues(alpha: 0.7) : const Color(0xFF1A1A2E).withValues(alpha: 0.7),
                                          ),
                                        ),
                                      ),
                                    ),
                                  );
                                }),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),

                    // Confirm button
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                      child: SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          onPressed: () {
                            model.setStartDate(selectedMonth, selectedYear);
                            Navigator.pop(context);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _brandBlue,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                          child: Text(
                            'Select ${_months[selectedMonth - 1]} $selectedYear',
                            style: GoogleFonts.plusJakartaSans(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.white),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
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
    if (m.startMonth == null) return 'Select when you plan to start';
    return '';
  }

  // ── Custom Field Input (for "Other") ──
  Widget _buildCustomFieldInput(BuildContext context, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: isDark ? const Color(0xFF323232).withValues(alpha: 0.8) : Colors.white,
        border: Border.all(color: _brandBlue.withValues(alpha: 0.15), width: 1.5),
      ),
      child: Row(
        children: [
          const FaIcon(FontAwesomeIcons.pen, size: 14, color: _brandBlue),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: TextEditingController(text: model.customField ?? '')
                ..selection = TextSelection.fromPosition(TextPosition(offset: model.customField?.length ?? 0)),
              onChanged: (v) => model.customField = v,
              style: GoogleFonts.inter(fontSize: 14, color: isDark ? Colors.white : const Color(0xFF1A1A2E)),
              decoration: InputDecoration(
                hintText: 'Enter your field of interest...',
                hintStyle: GoogleFonts.inter(fontSize: 14, color: isDark ? Colors.white.withValues(alpha: 0.3) : _brandBlue.withValues(alpha: 0.3)),
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
              color: isSelected ? _brandBlue : isDark ? const Color(0xFF323232).withValues(alpha: 0.8) : Colors.white,
              border: Border.all(
                color: isSelected ? _brandBlue : isDark ? Colors.white.withValues(alpha: 0.08) : _brandBlue.withValues(alpha: 0.08),
                width: isSelected ? 2 : 1.5,
              ),
              boxShadow: isSelected
                  ? [BoxShadow(color: _brandBlue.withValues(alpha: 0.35), blurRadius: 12, offset: const Offset(0, 4))]
                  : [BoxShadow(color: isDark ? Colors.black.withValues(alpha: 0.1) : _brandBlue.withValues(alpha: 0.03), blurRadius: 6, offset: const Offset(0, 2))],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(option, style: GoogleFonts.inter(fontSize: 13, fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400, color: isSelected ? Colors.white : isDark ? Colors.white.withValues(alpha: 0.7) : const Color(0xFF1A1A2E).withValues(alpha: 0.75))),
                if (isSelected) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(color: _brandGold.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(4)),
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
}