import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../app_theme.dart';
import '../google_fonts.dart';
import 'student_onboarding_model.dart';
import 'step_ui.dart';

class Step4SelfAssessmentPage extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
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
                const SizedBox(height: 22),

                // Strengths
                StepReveal(
                  delay: const Duration(milliseconds: 100),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const StepSectionLabel(
                        icon: FontAwesomeIcons.star,
                        label: 'Strengths',
                        helper: 'Select subjects or skills you excel in',
                      ),
                      const SizedBox(height: 10),
                      _buildTagPicker(
                        context,
                        options: strengthOptions,
                        selected: model.strengths,
                        onToggle: (v) => model.toggleStrength(v),
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
                      const StepSectionLabel(
                        icon: FontAwesomeIcons.arrowTrendDown,
                        label: 'Weaknesses',
                        helper: "Select areas you'd like to improve",
                      ),
                      const SizedBox(height: 10),
                      _buildTagPicker(
                        context,
                        options: weaknessOptions,
                        selected: model.weaknesses,
                        onToggle: (v) => model.toggleWeakness(v),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 22),

                // Interests
                StepReveal(
                  delay: const Duration(milliseconds: 180),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const StepSectionLabel(
                        icon: FontAwesomeIcons.heart,
                        label: 'Interests',
                        helper:
                            'Hobbies, extracurriculars, or broader interests',
                      ),
                      const SizedBox(height: 10),
                      _buildTagPicker(
                        context,
                        options: interestOptions,
                        selected: model.interests,
                        onToggle: (v) => model.toggleInterest(v),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 22),

                // Career Goals
                StepReveal(
                  delay: const Duration(milliseconds: 220),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const StepSectionLabel(
                        icon: FontAwesomeIcons.briefcase,
                        label: 'Career Goals',
                        helper:
                            'The category that best matches your career aspirations',
                      ),
                      const SizedBox(height: 10),
                      _buildCareerGoalPicker(context),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
        StepNavBar(
          onBack: onBack,
          onNext: onNext,
          nextLabel: model.step4Valid ? 'Continue' : 'Complete all sections',
          nextEnabled: model.step4Valid,
          hint: model.step4Valid
              ? null
              : 'Pick at least one strength, weakness and interest, then a career goal',
        ),
      ],
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
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400,
                    color: isSelected
                        ? Colors.white
                        : isDark
                        ? Colors.white.withValues(alpha: 0.75)
                        : const Color(0xFF1A1A2E).withValues(alpha: 0.75),
                  ),
                ),
                if (isSelected) ...[
                  const SizedBox(width: 6),
                  const FaIcon(
                    FontAwesomeIcons.check,
                    color: AppTheme.brandGold,
                    size: 12,
                  ),
                ],
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
      children: careerGoalOptions.map((option) {
        final isSelected = model.careerGoals == option;
        return GestureDetector(
          onTap: () => model.careerGoals = option,
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
                    fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
                    color: isSelected
                        ? Colors.white
                        : isDark
                        ? Colors.white.withValues(alpha: 0.75)
                        : const Color(0xFF1A1A2E).withValues(alpha: 0.75),
                  ),
                ),
                if (isSelected) ...[
                  const SizedBox(width: 6),
                  const FaIcon(
                    FontAwesomeIcons.circleCheck,
                    color: AppTheme.brandGold,
                    size: 16,
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
