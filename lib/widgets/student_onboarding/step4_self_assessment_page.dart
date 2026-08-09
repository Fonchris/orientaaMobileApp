import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../app_theme.dart';
import '../google_fonts.dart';
import 'student_onboarding_model.dart';
import 'step_ui.dart';

class Step4SelfAssessmentPage extends StatefulWidget {
  final StudentOnboardingModel model;
  final VoidCallback onNext;
  final VoidCallback? onBack;

  const Step4SelfAssessmentPage({
    super.key,
    required this.model,
    required this.onNext,
    this.onBack,
  });

  static const List<String> strengthOptions = [
    'Mathematics',
    'Science',
    'Writing',
    'Public Speaking',
    'Critical Thinking',
    'Problem Solving',
    'Creativity',
    'Leadership',
    'Teamwork',
    'Research',
    'Organization',
    'Time Management',
    'Languages',
    'Technology',
    'Art & Design',
    'Music',
    'Sports',
    'Coding / Programming',
    'Data Analysis',
    'Communication',
  ];

  static const List<String> weaknessOptions = [
    'Mathematics',
    'Science',
    'Writing',
    'Public Speaking',
    'Critical Thinking',
    'Time Management',
    'Organization',
    'Test Taking',
    'Focus / Concentration',
    'Procrastination',
    'Reading Comprehension',
    'Memorization',
    'Group Work',
    'Independent Study',
    'Foreign Languages',
    'Technology',
    'Art & Design',
    'Physical Education',
  ];

  static const List<String> interestOptions = [
    'Reading & Literature',
    'Sports & Athletics',
    'Music & Performing Arts',
    'Visual Arts & Design',
    'Technology & Gaming',
    'Science & Experiments',
    'Community Service',
    'Debate & Public Speaking',
    'Cooking & Baking',
    'Travel & Exploration',
    'Photography & Film',
    'Writing & Journalism',
    'Coding & Programming',
    'Entrepreneurship',
    'Gardening & Nature',
    'Fashion & Style',
    'Fitness & Health',
    'Board Games & Puzzles',
    'Volunteering',
    'Mentoring & Tutoring',
  ];

  static const List<String> careerGoalOptions = [
    'Medicine & Healthcare',
    'Engineering & Technology',
    'Computer Science & IT',
    'Business & Entrepreneurship',
    'Law & Legal Services',
    'Education & Academia',
    'Arts & Creative Industries',
    'Science & Research',
    'Social Work & Nonprofit',
    'Government & Public Policy',
    'Media & Communications',
    'Finance & Banking',
    'Consulting',
    'Architecture & Construction',
    'Environmental & Sustainability',
    'Sports & Recreation',
    'Hospitality & Tourism',
    'Agriculture & Food Science',
    'Military & Defense',
    'Undecided / Exploring',
  ];

  @override
  State<Step4SelfAssessmentPage> createState() =>
      Step4SelfAssessmentPageState();
}

class Step4SelfAssessmentPageState extends State<Step4SelfAssessmentPage> {
  /// 0 = Strengths & Weaknesses, 1 = Interests & Career Goals.
  int _subStep = 0;

  bool get _part1Valid =>
      widget.model.strengths.isNotEmpty && widget.model.weaknesses.isNotEmpty;

  bool get _part2Valid =>
      widget.model.interests.isNotEmpty &&
      (widget.model.careerGoals?.trim().isNotEmpty ?? false);

  void _nextPart() {
    if (_subStep == 0) {
      if (_part1Valid) {
        setState(() => _subStep = 1);
      }
    } else {
      widget.onNext();
    }
  }

  void _backPart() {
    if (_subStep == 1) {
      setState(() => _subStep = 0);
    } else {
      widget.onBack?.call();
    }
  }

  /// Handles the header back arrow: steps back one internal part first and
  /// returns true if the press was consumed (so the parent doesn't also
  /// navigate to the previous step).
  bool handleHeaderBack() {
    if (_subStep == 1) {
      setState(() => _subStep = 0);
      return true;
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            switchInCurve: Curves.easeOutCubic,
            switchOutCurve: Curves.easeInCubic,
            transitionBuilder: (child, animation) {
              final slide = Tween<Offset>(
                begin: const Offset(0.06, 0),
                end: Offset.zero,
              ).animate(animation);
              return FadeTransition(
                opacity: animation,
                child: SlideTransition(position: slide, child: child),
              );
            },
            child: _subStep == 0
                ? _buildPartOne(context)
                : _buildPartTwo(context),
          ),
        ),
        StepNavBar(
          onBack: _backPart,
          onNext: _nextPart,
          nextLabel: _subStep == 0
              ? (_part1Valid ? 'Next: Interests & Goals' : 'Select strengths')
              : (_part2Valid ? 'Continue' : 'Complete all sections'),
          nextEnabled: _subStep == 0 ? _part1Valid : _part2Valid,
          hint: _subStep == 0
              ? 'Pick at least one strength and one weakness to continue'
              : 'Pick at least one interest and a career goal',
        ),
      ],
    );
  }

  Widget _buildPartOne(BuildContext context) {
    return SingleChildScrollView(
      key: const ValueKey('self-assessment-part-1'),
      physics: const BouncingScrollPhysics(
        parent: AlwaysScrollableScrollPhysics(),
      ),
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const StepReveal(
            child: StepHeroCard(
              icon: FontAwesomeIcons.userCheck,
              title: 'Self-Assessment',
              subtitle:
                  'Understand your strengths, interests and career ambitions.',
              chips: ['Multi-select', 'No wrong answers'],
            ),
          ),
          const SizedBox(height: 14),
          _buildPartIndicator(context),
          const SizedBox(height: 20),

          // Strengths
          StepReveal(
            delay: const Duration(milliseconds: 100),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                StepSectionLabel(
                  icon: FontAwesomeIcons.star,
                  label: 'Strengths',
                  helper: 'Select subjects or skills you excel in',
                  badge: '${Step4SelfAssessmentPage.strengthOptions.length}',
                ),
                const SizedBox(height: 10),
                _buildTagPicker(
                  context,
                  options: Step4SelfAssessmentPage.strengthOptions,
                  selected: widget.model.strengths,
                  onToggle: widget.model.toggleStrength,
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),

          // Weaknesses
          StepReveal(
            delay: const Duration(milliseconds: 140),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                StepSectionLabel(
                  icon: FontAwesomeIcons.arrowTrendDown,
                  label: 'Weaknesses',
                  helper: "Select areas you'd like to improve",
                  badge: '${Step4SelfAssessmentPage.weaknessOptions.length}',
                ),
                const SizedBox(height: 10),
                _buildTagPicker(
                  context,
                  options: Step4SelfAssessmentPage.weaknessOptions,
                  selected: widget.model.weaknesses,
                  onToggle: widget.model.toggleWeakness,
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildPartTwo(BuildContext context) {
    return SingleChildScrollView(
      key: const ValueKey('self-assessment-part-2'),
      physics: const BouncingScrollPhysics(
        parent: AlwaysScrollableScrollPhysics(),
      ),
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const StepReveal(
            child: StepHeroCard(
              icon: FontAwesomeIcons.userCheck,
              title: 'Interests & Goals',
              subtitle:
                  'Almost done — tell us what you love and where you\'re headed.',
              chips: ['Multi-select', 'No wrong answers'],
            ),
          ),
          const SizedBox(height: 14),
          _buildPartIndicator(context),
          const SizedBox(height: 20),

          // Interests
          StepReveal(
            delay: const Duration(milliseconds: 100),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                StepSectionLabel(
                  icon: FontAwesomeIcons.heart,
                  label: 'Interests',
                  helper: 'Hobbies, extracurriculars, or broader interests',
                  badge: '${Step4SelfAssessmentPage.interestOptions.length}',
                ),
                const SizedBox(height: 10),
                _buildTagPicker(
                  context,
                  options: Step4SelfAssessmentPage.interestOptions,
                  selected: widget.model.interests,
                  onToggle: widget.model.toggleInterest,
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),

          // Career Goals
          StepReveal(
            delay: const Duration(milliseconds: 140),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                StepSectionLabel(
                  icon: FontAwesomeIcons.briefcase,
                  label: 'Career Goals',
                  helper:
                      'The category that best matches your career aspirations',
                  badge: '${Step4SelfAssessmentPage.careerGoalOptions.length}',
                ),
                const SizedBox(height: 10),
                _buildCareerGoalPicker(context),
              ],
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  /// Two-segment pill that shows which part of the self-assessment you're on.
  Widget _buildPartIndicator(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Widget segment(String number, String label, bool active) {
      return Expanded(
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: active
                ? const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [AppTheme.brandBlue, Color(0xFF1F4ED8)],
                  )
                : null,
            color: active
                ? null
                : isDark
                ? Colors.white.withValues(alpha: 0.05)
                : AppTheme.brandBlue.withValues(alpha: 0.05),
            border: Border.all(
              color: active
                  ? AppTheme.brandBlue
                  : isDark
                  ? Colors.white.withValues(alpha: 0.08)
                  : AppTheme.brandBlue.withValues(alpha: 0.12),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 18,
                height: 18,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: active
                      ? Colors.white.withValues(alpha: 0.2)
                      : AppTheme.brandBlue.withValues(alpha: 0.08),
                ),
                child: Text(
                  number,
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: active
                        ? Colors.white
                        : isDark
                        ? Colors.white.withValues(alpha: 0.6)
                        : AppTheme.brandBlue.withValues(alpha: 0.7),
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: active
                        ? Colors.white
                        : isDark
                        ? Colors.white.withValues(alpha: 0.55)
                        : AppTheme.brandBlue.withValues(alpha: 0.6),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: isDark
            ? Colors.white.withValues(alpha: 0.04)
            : AppTheme.brandBlue.withValues(alpha: 0.04),
      ),
      child: Row(
        children: [
          segment('1', 'Strengths & Weaknesses', _subStep == 0),
          const SizedBox(width: 4),
          segment('2', 'Interests & Goals', _subStep == 1),
        ],
      ),
    );
  }

  Widget _buildTagPicker(
    BuildContext context, {
    required List<String> options,
    required List<String> selected,
    required ValueChanged<String> onToggle,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: options.map((option) {
        final isSelected = selected.contains(option);
        return GestureDetector(
          onTap: () => onToggle(option),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              color: isSelected
                  ? AppTheme.brandBlue
                  : isDark
                  ? Colors.white.withValues(alpha: 0.05)
                  : Colors.white.withValues(alpha: 0.9),
              border: Border.all(
                color: isSelected
                    ? AppTheme.brandBlue
                    : isDark
                    ? Colors.white.withValues(alpha: 0.1)
                    : AppTheme.brandBlue.withValues(alpha: 0.1),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  option,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    // Constant weight so text width never changes and chips
                    // never reflow inside the Wrap on selection.
                    fontWeight: FontWeight.w600,
                    color: isSelected
                        ? Colors.white
                        : isDark
                        ? Colors.white.withValues(alpha: 0.75)
                        : const Color(0xFF1A1A2E).withValues(alpha: 0.75),
                  ),
                ),
                const SizedBox(width: 6),
                // Fixed-size slot: always present, icon fades in. This keeps
                // every chip exactly the same width whether selected or not,
                // so toggling never pushes neighbouring chips down.
                SizedBox(
                  width: 14,
                  height: 14,
                  child: AnimatedOpacity(
                    duration: const Duration(milliseconds: 200),
                    opacity: isSelected ? 1 : 0,
                    child: const FaIcon(
                      FontAwesomeIcons.check,
                      color: AppTheme.brandGold,
                      size: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildCareerGoalPicker(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: Step4SelfAssessmentPage.careerGoalOptions.map((option) {
        final isSelected = widget.model.careerGoals == option;
        return GestureDetector(
          onTap: () => widget.model.careerGoals = option,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              gradient: isSelected
                  ? const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [AppTheme.brandBlue, Color(0xFF1F4ED8)],
                    )
                  : null,
              color: isSelected
                  ? null
                  : isDark
                  ? Colors.white.withValues(alpha: 0.05)
                  : Colors.white.withValues(alpha: 0.9),
              border: Border.all(
                color: isSelected
                    ? AppTheme.brandBlue
                    : isDark
                    ? Colors.white.withValues(alpha: 0.1)
                    : AppTheme.brandBlue.withValues(alpha: 0.1),
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: AppTheme.brandBlue.withValues(alpha: 0.3),
                        blurRadius: 14,
                        offset: const Offset(0, 5),
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
                    fontSize: 13,
                    // Constant weight — see note in _buildTagPicker.
                    fontWeight: FontWeight.w600,
                    color: isSelected
                        ? Colors.white
                        : isDark
                        ? Colors.white.withValues(alpha: 0.75)
                        : const Color(0xFF1A1A2E).withValues(alpha: 0.75),
                  ),
                ),
                const SizedBox(width: 6),
                SizedBox(
                  width: 16,
                  height: 16,
                  child: AnimatedOpacity(
                    duration: const Duration(milliseconds: 200),
                    opacity: isSelected ? 1 : 0,
                    child: const FaIcon(
                      FontAwesomeIcons.circleCheck,
                      color: AppTheme.brandGold,
                      size: 16,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}
