import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
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
    final textColor = isDark ? Colors.white : const Color(0xFF1A1A2E);
    final subtitleColor = isDark
        ? Colors.white.withValues(alpha: 0.6)
        : const Color(0xFF1A1A2E).withValues(alpha: 0.6);

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: isDark
              ? [
                  const Color(0xFF0F1115),
                  const Color(0xFF151A26),
                  const Color(0xFF0F1115),
                ]
              : [
                  const Color(0xFFF6F8FF),
                  const Color(0xFFF0F5FF),
                  const Color(0xFFFFFFFF),
                ],
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            top: -40,
            right: -30,
            child: _backgroundGlow(
              color: _brandGold.withValues(alpha: isDark ? 0.18 : 0.22),
              size: 120,
            ),
          ),
          Positioned(
            top: 90,
            left: -50,
            child: _backgroundGlow(
              color: _brandBlue.withValues(alpha: isDark ? 0.12 : 0.12),
              size: 140,
            ),
          ),
          CustomScrollView(
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
                  : _brandBlue.withValues(alpha: 0.08),
            ),
          ),
          child: Text(
            _currentPage == 0 ? 'Page 1 of 2' : 'Page 2 of 2',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white.withValues(alpha: 0.85) : _brandBlue,
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
          gradient: LinearGradient(
            colors: [
              _brandBlue.withValues(alpha: 0.95),
              _brandGold.withValues(alpha: 0.9),
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: _brandBlue.withValues(alpha: 0.25),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            FaIcon(icon, size: 13, color: Colors.white),
            const SizedBox(width: 8),
            Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: Colors.white,
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
            items: educationLevels,
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
            items: degreeLevels,
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
            options: fieldsOfInterest,
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
                  : _brandBlue.withValues(alpha: 0.08),
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
                      color: _brandGold.withValues(alpha: 0.18),
                    ),
                    child: const FaIcon(
                      FontAwesomeIcons.circleInfo,
                      size: 14,
                      color: _brandGold,
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
                    color: _brandGold,
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
                    backgroundColor: _brandBlue,
                    disabledBackgroundColor: isDark
                        ? Colors.white.withValues(alpha: 0.08)
                        : _brandBlue.withValues(alpha: 0.08),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                  child: Text(
                    model.step1Valid ? 'Continue' : 'Complete all fields',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: model.step1Valid ? Colors.white : subtitleColor,
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
        borderRadius: BorderRadius.circular(26),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [
                  const Color(0xFF1A1A2E),
                  const Color(0xFF243B7A),
                  const Color(0xFF10131D),
                ]
              : [
                  Colors.white,
                  const Color(0xFFEAF1FF),
                  const Color(0xFFFDF8E8),
                ],
        ),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.06)
              : _brandBlue.withValues(alpha: 0.08),
        ),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.3)
                : _brandBlue.withValues(alpha: 0.1),
            blurRadius: 24,
            offset: const Offset(0, 10),
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
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [_brandGold, _brandBlue.withValues(alpha: 0.95)],
              ),
              boxShadow: [
                BoxShadow(
                  color: _brandBlue.withValues(alpha: 0.28),
                  blurRadius: 16,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: const Center(
              child: FaIcon(
                FontAwesomeIcons.graduationCap,
                color: Colors.white,
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
            : _brandBlue.withValues(alpha: 0.08),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.08)
              : _brandBlue.withValues(alpha: 0.1),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          FaIcon(
            icon,
            size: 11,
            color: isDark ? Colors.white.withValues(alpha: 0.75) : _brandBlue,
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white.withValues(alpha: 0.8) : _brandBlue,
            ),
          ),
        ],
      ),
    );
  }

  Widget _backgroundGlow({required Color color, required double size}) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(colors: [color, color.withValues(alpha: 0.0)]),
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
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.9)
                      : _brandBlue,
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
              : _brandBlue.withValues(alpha: 0.08),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.15)
                : _brandBlue.withValues(alpha: 0.04),
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
            child: const FaIcon(
              FontAwesomeIcons.chevronDown,
              size: 12,
              color: _brandBlue,
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
                ? _brandBlue
                : isDark
                ? Colors.white.withValues(alpha: 0.08)
                : _brandBlue.withValues(alpha: 0.08),
            width: model.startLabel != null ? 2 : 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: isDark
                  ? Colors.black.withValues(alpha: 0.15)
                  : _brandBlue.withValues(alpha: 0.04),
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
              child: const FaIcon(
                FontAwesomeIcons.calendar,
                size: 14,
                color: _brandBlue,
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
                      ? (isDark ? Colors.white : const Color(0xFF1A1A2E))
                      : (isDark
                            ? Colors.white.withValues(alpha: 0.3)
                            : _brandBlue.withValues(alpha: 0.35)),
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
                        color: _brandGold.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const FaIcon(
                        FontAwesomeIcons.check,
                        color: _brandGold,
                        size: 12,
                      ),
                    )
                  : const FaIcon(
                      FontAwesomeIcons.chevronDown,
                      size: 14,
                      color: _brandBlue,
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
      backgroundColor: isDark ? const Color(0xFF1A1A2E) : Colors.white,
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
                              : const Color(0xFF1A1A2E),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'When do you plan to begin your studies?',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.5)
                              : const Color(0xFF1A1A2E).withValues(alpha: 0.5),
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
                                fontWeight: FontWeight.w600,
                                color: _brandBlue,
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
                                          ? _brandBlue
                                          : isDark
                                          ? const Color(
                                              0xFF323232,
                                            ).withValues(alpha: 0.6)
                                          : Colors.grey.withValues(alpha: 0.06),
                                      border: Border.all(
                                        color: isSelected
                                            ? _brandBlue
                                            : isDark
                                            ? Colors.white.withValues(
                                                alpha: 0.08,
                                              )
                                            : _brandBlue.withValues(
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
                                            ? Colors.white
                                            : isDark
                                            ? Colors.white.withValues(
                                                alpha: 0.7,
                                              )
                                            : const Color(
                                                0xFF1A1A2E,
                                              ).withValues(alpha: 0.7),
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
                                fontWeight: FontWeight.w600,
                                color: _brandBlue,
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
                                                ? _brandBlue
                                                : isDark
                                                ? const Color(
                                                    0xFF323232,
                                                  ).withValues(alpha: 0.6)
                                                : Colors.grey.withValues(
                                                    alpha: 0.06,
                                                  ),
                                            border: Border.all(
                                              color: isSelected
                                                  ? _brandBlue
                                                  : isDark
                                                  ? Colors.white.withValues(
                                                      alpha: 0.08,
                                                    )
                                                  : _brandBlue.withValues(
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
                                                  ? Colors.white
                                                  : isDark
                                                  ? Colors.white.withValues(
                                                      alpha: 0.7,
                                                    )
                                                  : const Color(
                                                      0xFF1A1A2E,
                                                    ).withValues(alpha: 0.7),
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
                              backgroundColor: _brandBlue,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            child: Text(
                              'Select ${_months[selectedMonth - 1]} $selectedYear',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
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
                        color: isDark
                            ? Colors.black.withValues(alpha: 0.1)
                            : _brandBlue.withValues(alpha: 0.03),
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
                const SizedBox(width: 8),
                // Fixed 16x16 space for checkmark - prevents layout shift
                SizedBox(
                  width: 16,
                  height: 16,
                  child: isSelected
                      ? Container(
                          padding: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            color: _brandGold.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const FaIcon(
                            FontAwesomeIcons.check,
                            color: _brandGold,
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
