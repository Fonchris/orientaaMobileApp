import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../app_theme.dart';
import '../google_fonts.dart';
import 'student_onboarding_model.dart';

class Step1IdentityPage extends StatefulWidget {
  final StudentOnboardingModel model;
  final VoidCallback onNext;
  final VoidCallback? onBack;

  const Step1IdentityPage({
    super.key,
    required this.model,
    required this.onNext,
    this.onBack,
  });

  /// Shared education-level options. Public so the discovery module's
  /// filters reuse the same catalog as onboarding.
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

  /// Shared degree-level options (also used by the discovery filters).
  static const List<String> degreeLevels = [
    "Bachelor's",
    "Master's",
    'PhD',
    'Diploma / Vocational',
  ];

  /// Shared fields-of-interest options (also used by the discovery filters).
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

  @override
  State<Step1IdentityPage> createState() => _Step1IdentityPageState();
}

class _Step1IdentityPageState extends State<Step1IdentityPage> {
  final ScrollController _scrollController = ScrollController();
  int _currentPage = 0;

  StudentOnboardingModel get model => widget.model;
  VoidCallback get onNext => widget.onNext;
  VoidCallback? get onBack => widget.onBack;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _goToPage(int page) {
    if (page < 0 || page > 1) return;
    setState(() => _currentPage = page);
    if (_scrollController.hasClients) {
      _scrollController.jumpTo(0);
    }
  }

  static const _brandYellow = Color(0xFFFFC700);
  static const _brandAmber = Color(0xFFF5B800);
  static const _brandInk = Color(0xFF141414);

  static const String _otherField = 'Other';

  static const List<String> _months = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : AppTheme.brandInk;
    final subtitleColor = isDark
        ? Colors.white.withValues(alpha: 0.6)
        : AppTheme.brandInk.withValues(alpha: 0.6);

    return Container(
      color: isDark ? const Color(0xFF121212) : const Color(0xFFF5F5F2),
      child: CustomScrollView(
            controller: _scrollController,
            physics: const BouncingScrollPhysics(
              parent: AlwaysScrollableScrollPhysics(),
            ),
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                sliver: SliverToBoxAdapter(
                  child: _buildHeroCard(isDark, textColor, subtitleColor),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                sliver: SliverToBoxAdapter(child: _buildPageControls(isDark)),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 18, 16, 0),
                sliver: SliverToBoxAdapter(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 220),
                    switchInCurve: Curves.easeOutCubic,
                    switchOutCurve: Curves.easeInCubic,
                    child: _currentPage == 0
                        ? _buildInfoPage(context, isDark)
                        : _buildDatePage(
                            context,
                            isDark,
                            textColor,
                            subtitleColor,
                          ),
                  ),
                ),
              ),
            ],
          ),
    );
  }

  Widget _buildPageControls(bool isDark) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.white,
            border: Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.08)
                  : _brandYellow.withValues(alpha: 0.08),
            ),
          ),
          child: Text(
            _currentPage == 0 ? 'Page 1 of 2' : 'Page 2 of 2',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: isDark
                  ? Colors.white.withValues(alpha: 0.85)
                  : _brandInk.withValues(alpha: 0.75),
            ),
          ),
        ),
        const Spacer(),
        if (_currentPage == 1)
          _buildNavChip(
            label: 'Back',
            icon: FontAwesomeIcons.arrowLeft,
            isDark: isDark,
            onTap: () => _goToPage(0),
          )
        else
          _buildNavChip(
            label: 'Next',
            icon: FontAwesomeIcons.arrowRight,
            isDark: isDark,
            onTap: () => _goToPage(1),
          ),
      ],
    );
  }

  Widget _buildNavChip({
    required String label,
    required FaIconData icon,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(999),
          color: _brandYellow,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            FaIcon(icon, size: 13, color: _brandInk),
            const SizedBox(width: 8),
            Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: _brandInk,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoPage(BuildContext context, bool isDark) {
    return Column(
      key: const ValueKey('page1'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSection(
          icon: FontAwesomeIcons.school,
          label: 'Current Education Level',
          isDark: isDark,
          child: _buildDropdown<String>(
            context,
            value: model.educationLevel,
            items: Step1IdentityPage.educationLevels,
            hint: 'Select your current level',
            onChanged: (v) => model.educationLevel = v,
            isDark: isDark,
          ),
        ),
        const SizedBox(height: 22),
        _buildSection(
          icon: FontAwesomeIcons.award,
          label: 'Desired Degree Level',
          isDark: isDark,
          child: _buildDropdown<String>(
            context,
            value: model.desiredDegreeLevel,
            items: Step1IdentityPage.degreeLevels,
            hint: 'Select desired degree',
            onChanged: (v) => model.desiredDegreeLevel = v,
            isDark: isDark,
          ),
        ),
        const SizedBox(height: 22),
        _buildSection(
          icon: FontAwesomeIcons.bookOpen,
          label: 'Field(s) of Interest',
          isDark: isDark,
          child: _buildMultiSelectChips(
            context,
            options: Step1IdentityPage.fieldsOfInterest,
            selected: model.fieldsOfInterest,
            onToggle: (v) => model.toggleFieldOfInterest(v),
            isDark: isDark,
          ),
        ),
        if (model.fieldsOfInterest.contains(_otherField)) ...[
          const SizedBox(height: 10),
          _buildCustomFieldInput(context, isDark),
        ],
      ],
    );
  }

  Widget _buildDatePage(
    BuildContext context,
    bool isDark,
    Color textColor,
    Color subtitleColor,
  ) {
    return Column(
      key: const ValueKey('page2'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSection(
          icon: FontAwesomeIcons.calendarDays,
          label: 'When do you plan to start?',
          isDark: isDark,
          child: _buildDatePickerButton(context, isDark),
        ),
        const SizedBox(height: 18),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white,
            border: Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.08)
                  : _brandYellow.withValues(alpha: 0.08),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _brandAmber.withValues(alpha: 0.18),
                    ),
                    child: const FaIcon(
                      FontAwesomeIcons.circleInfo,
                      size: 14,
                      color: _brandAmber,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      model.step1Valid
                          ? 'Ready to continue'
                          : 'Complete all fields',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: textColor,
                      ),
                    ),
                  ),
                ],
              ),
              if (!model.step1Valid) ...[
                const SizedBox(height: 8),
                Text(
                  _validationHint(model),
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: _brandAmber,
                  ),
                ),
              ],
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: model.step1Valid ? onNext : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _brandYellow,
                    foregroundColor: _brandInk,
                    disabledBackgroundColor: isDark
                        ? Colors.white.withValues(alpha: 0.08)
                        : _brandYellow.withValues(alpha: 0.08),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                  child: Text(
                    model.step1Valid ? 'Continue' : 'Complete all fields',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: model.step1Valid ? _brandInk : subtitleColor,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHeroCard(bool isDark, Color textColor, Color subtitleColor) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.08)
              : const Color(0xFFE3E3DE),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.05),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _brandYellow,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: const Center(
              child: FaIcon(
                FontAwesomeIcons.graduationCap,
                color: _brandInk,
                size: 26,
              ),
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
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: textColor,
                    height: 1.05,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Tell us about your academic status and goals',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: subtitleColor,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _buildHeroChip(
                      label: 'Profile setup',
                      icon: FontAwesomeIcons.solidStar,
                      isDark: isDark,
                    ),
                    _buildHeroChip(
                      label: 'Swipe to continue',
                      icon: FontAwesomeIcons.handPointer,
                      isDark: isDark,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroChip({
    required String label,
    required FaIconData icon,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: isDark
            ? Colors.white.withValues(alpha: 0.08)
            : _brandYellow.withValues(alpha: 0.08),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.08)
              : _brandYellow.withValues(alpha: 0.1),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          FaIcon(
            icon,
            size: 11,
            color: isDark ? Colors.white.withValues(alpha: 0.75) : _brandInk,
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white.withValues(alpha: 0.8) : _brandInk,
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildSection({
    required FaIconData icon,
    required String label,
    required bool isDark,
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
                  color: _brandYellow.withValues(alpha: 0.08),
                ),
                child: FaIcon(icon, size: 13, color: _brandYellow),
              ),
              const SizedBox(width: 10),
              Text(
                label,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.9)
                      : _brandInk,
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
              : _brandYellow.withValues(alpha: 0.08),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.15)
                : _brandYellow.withValues(alpha: 0.04),
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
                  : _brandInk.withValues(alpha: 0.4),
            ),
          ),
          style: GoogleFonts.inter(
            fontSize: 15,
            fontWeight: FontWeight.w500,
            color: isDark ? Colors.white : AppTheme.brandInk,
          ),
          dropdownColor: isDark ? const Color(0xFF323232) : Colors.white,
          icon: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              color: _brandYellow.withValues(alpha: isDark ? 0.15 : 0.08),
            ),
            child: const FaIcon(
              FontAwesomeIcons.chevronDown,
              size: 12,
              color: _brandYellow,
            ),
          ),
          borderRadius: BorderRadius.circular(16),
          items: items
              .map(
                (item) => DropdownMenuItem<T>(
                  value: item,
                  child: Text(item.toString()),
                ),
              )
              .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildDatePickerButton(BuildContext context, bool isDark) {
    return GestureDetector(
      onTap: () {
        debugPrint('Date picker tapped!');
        _showMonthYearPicker(context, isDark);
      },
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: isDark
              ? const Color(0xFF323232).withValues(alpha: 0.8)
              : Colors.white,
          border: Border.all(
            color: model.startLabel != null
                ? _brandYellow
                : isDark
                ? Colors.white.withValues(alpha: 0.08)
                : _brandYellow.withValues(alpha: 0.08),
            width: model.startLabel != null ? 2 : 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: isDark
                  ? Colors.black.withValues(alpha: 0.15)
                  : _brandYellow.withValues(alpha: 0.04),
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
                color: _brandYellow.withValues(alpha: isDark ? 0.15 : 0.08),
              ),
              child: const FaIcon(
                FontAwesomeIcons.calendar,
                size: 14,
                color: _brandYellow,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                model.startLabel ?? 'Tap to select month & year',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: model.startLabel != null
                      ? FontWeight.w600
                      : FontWeight.w400,
                  color: model.startLabel != null
                      ? (isDark ? Colors.white : AppTheme.brandInk)
                      : (isDark
                            ? Colors.white.withValues(alpha: 0.3)
                            : AppTheme.brandInk.withValues(alpha: 0.4)),
                ),
              ),
            ),
            SizedBox(
              width: 22,
              height: 22,
              child: model.startLabel != null
                  ? Container(
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        color: _brandAmber.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const FaIcon(
                        FontAwesomeIcons.check,
                        color: _brandAmber,
                        size: 12,
                      ),
                    )
                  : const FaIcon(
                      FontAwesomeIcons.chevronDown,
                      size: 14,
                      color: _brandYellow,
                    ),
            ),
          ],
        ),
      ),
    );
  }

  void _showMonthYearPicker(BuildContext context, bool isDark) {
    debugPrint('_showMonthYearPicker called');
    int selectedMonth = model.startMonth ?? DateTime.now().month;
    int selectedYear = model.startYear ?? DateTime.now().year;
    final currentYear = DateTime.now().year;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? AppTheme.brandInk : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 420),
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      const SizedBox(height: 12),
                      Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Select intake period',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: isDark
                              ? Colors.white
                              : AppTheme.brandInk,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'When do you plan to begin your studies?',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.5)
                              : AppTheme.brandInk.withValues(alpha: 0.5),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Month',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: isDark ? _brandYellow : _brandInk,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: List.generate(12, (i) {
                                final month = i + 1;
                                final isSelected = selectedMonth == month;
                                return GestureDetector(
                                  onTap: () => setDialogState(
                                    () => selectedMonth = month,
                                  ),
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 200),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 14,
                                      vertical: 8,
                                    ),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(12),
                                      color: isSelected
                                          ? _brandYellow
                                          : isDark
                                          ? const Color(
                                              0xFF323232,
                                            ).withValues(alpha: 0.6)
                                          : Colors.grey.withValues(alpha: 0.06),
                                      border: Border.all(
                                        color: isSelected
                                            ? _brandYellow
                                            : isDark
                                            ? Colors.white.withValues(
                                                alpha: 0.08,
                                              )
                                            : _brandYellow.withValues(
                                                alpha: 0.08,
                                              ),
                                      ),
                                    ),
                                    child: Text(
                                      _months[i],
                                      style: GoogleFonts.inter(
                                        fontSize: 13,
                                        fontWeight: isSelected
                                            ? FontWeight.w600
                                            : FontWeight.w400,
                                        color: isSelected
                                            ? _brandInk
                                            : isDark
                                            ? Colors.white.withValues(
                                                alpha: 0.7,
                                              )
                                            : _brandInk.withValues(alpha: 0.7),
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
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Row(
                          children: [
                            Text(
                              'Year',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: isDark ? _brandYellow : _brandInk,
                              ),
                            ),
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
                                        onTap: () => setDialogState(
                                          () => selectedYear = year,
                                        ),
                                        child: AnimatedContainer(
                                          duration: const Duration(
                                            milliseconds: 200,
                                          ),
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 20,
                                            vertical: 12,
                                          ),
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                            color: isSelected
                                                ? _brandYellow
                                                : isDark
                                                ? const Color(
                                                    0xFF323232,
                                                  ).withValues(alpha: 0.6)
                                                : Colors.grey.withValues(
                                                    alpha: 0.06,
                                                  ),
                                            border: Border.all(
                                              color: isSelected
                                                  ? _brandYellow
                                                  : isDark
                                                  ? Colors.white.withValues(
                                                      alpha: 0.08,
                                                    )
                                                  : _brandYellow.withValues(
                                                      alpha: 0.08,
                                                    ),
                                            ),
                                          ),
                                          child: Text(
                                            '$year',
                                            style: GoogleFonts.plusJakartaSans(
                                              fontSize: 14,
                                              fontWeight: isSelected
                                                  ? FontWeight.w700
                                                  : FontWeight.w500,
                                              color: isSelected
                                                  ? _brandInk
                                                  : isDark
                                                  ? Colors.white.withValues(
                                                      alpha: 0.7,
                                                    )
                                                  : _brandInk.withValues(
                                                      alpha: 0.7,
                                                    ),
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
                              backgroundColor: _brandYellow,
                              foregroundColor: _brandInk,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(999),
                              ),
                            ),
                            child: Text(
                              'Select ${_months[selectedMonth - 1]} $selectedYear',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: _brandInk,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  String _validationHint(StudentOnboardingModel m) {
    if (m.educationLevel == null && m.desiredDegreeLevel == null) {
      return 'Select your education level and desired degree';
    }
    if (m.educationLevel == null) {
      return 'Select your current education level';
    }
    if (m.desiredDegreeLevel == null) {
      return 'Select your desired degree level';
    }
    if (m.fieldsOfInterest.isEmpty) {
      return 'Select at least one field of interest';
    }
    if (m.startMonth == null) {
      return 'Select when you plan to start';
    }
    return '';
  }

  Widget _buildCustomFieldInput(BuildContext context, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: isDark
            ? const Color(0xFF323232).withValues(alpha: 0.8)
            : Colors.white,
        border: Border.all(
          color: _brandYellow.withValues(alpha: 0.15),
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          const FaIcon(FontAwesomeIcons.pen, size: 14, color: _brandYellow),
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
                color: isDark ? Colors.white : AppTheme.brandInk,
              ),
              decoration: InputDecoration(
                hintText: 'Enter your field of interest...',
                hintStyle: GoogleFonts.inter(
                  fontSize: 14,
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.3)
                      : AppTheme.brandInk.withValues(alpha: 0.35),
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
                  ? _brandYellow
                  : isDark
                  ? const Color(0xFF323232).withValues(alpha: 0.8)
                  : Colors.white,
              border: Border.all(
                color: isSelected
                    ? _brandYellow
                    : isDark
                    ? Colors.white.withValues(alpha: 0.08)
                    : _brandYellow.withValues(alpha: 0.08),
                width: isSelected ? 2 : 1.5,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.25),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ]
                  : [
                      BoxShadow(
                        color: isDark
                            ? Colors.black.withValues(alpha: 0.1)
                            : _brandYellow.withValues(alpha: 0.03),
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
                        ? _brandInk
                        : isDark
                        ? Colors.white.withValues(alpha: 0.7)
                        : _brandInk.withValues(alpha: 0.75),
                  ),
                ),
                const SizedBox(width: 8),
                // Fixed 16x16 space for checkmark - prevents layout shift
                SizedBox(
                  width: 16,
                  height: 16,
                  child: isSelected
                      ? Container(
                          padding: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            color: _brandAmber.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: FaIcon(
                            FontAwesomeIcons.check,
                            color: _brandAmber,
                            size: 10,
                          ),
                        )
                      : const SizedBox.shrink(),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}
