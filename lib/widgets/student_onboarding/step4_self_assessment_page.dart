import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'student_onboarding_model.dart';

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

  static const _brandBlue = Color(0xFF011F7B);
  static const _brandGold = Color(0xFFFFBA09);

  static const List<String> strengthOptions = [
    'Mathematics', 'Science', 'Writing', 'Public Speaking', 'Critical Thinking',
    'Problem Solving', 'Creativity', 'Leadership', 'Teamwork', 'Research',
    'Organization', 'Time Management', 'Languages', 'Technology', 'Art & Design',
    'Music', 'Sports', 'Coding / Programming', 'Data Analysis', 'Communication',
  ];

  static const List<String> weaknessOptions = [
    'Mathematics', 'Science', 'Writing', 'Public Speaking', 'Critical Thinking',
    'Time Management', 'Organization', 'Test Taking', 'Focus / Concentration',
    'Procrastination', 'Reading Comprehension', 'Memorization', 'Group Work',
    'Independent Study', 'Foreign Languages', 'Technology', 'Art & Design', 'Physical Education',
  ];

  static const List<String> interestOptions = [
    'Reading & Literature', 'Sports & Athletics', 'Music & Performing Arts', 'Visual Arts & Design',
    'Technology & Gaming', 'Science & Experiments', 'Community Service', 'Debate & Public Speaking',
    'Cooking & Baking', 'Travel & Exploration', 'Photography & Film', 'Writing & Journalism',
    'Coding & Programming', 'Entrepreneurship', 'Gardening & Nature', 'Fashion & Style',
    'Fitness & Health', 'Board Games & Puzzles', 'Volunteering', 'Mentoring & Tutoring',
  ];

  static const List<String> careerGoalOptions = [
    'Medicine & Healthcare', 'Engineering & Technology', 'Computer Science & IT',
    'Business & Entrepreneurship', 'Law & Legal Services', 'Education & Academia',
    'Arts & Creative Industries', 'Science & Research', 'Social Work & Nonprofit',
    'Government & Public Policy', 'Media & Communications', 'Finance & Banking',
    'Consulting', 'Architecture & Construction', 'Environmental & Sustainability',
    'Sports & Recreation', 'Hospitality & Tourism', 'Agriculture & Food Science',
    'Military & Defense', 'Undecided / Exploring',
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
          // Header
          Row(
            children: [
              Container(
                width: 48, height: 48,
                decoration: BoxDecoration(borderRadius: BorderRadius.circular(14), color: _brandBlue.withValues(alpha: 0.1)),
                child: const FaIcon(FontAwesomeIcons.userCheck, color: _brandBlue, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Self-Assessment', style: GoogleFonts.plusJakartaSans(fontSize: 22, fontWeight: FontWeight.w800, color: textColor, letterSpacing: -0.5)),
                    Text('Help us understand your strengths and interests.', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w400, color: subtitleColor)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Strengths
          _sectionLabel(FontAwesomeIcons.star, 'Strengths', isDark),
          const SizedBox(height: 4),
          Text('Select subjects or skills you excel in', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w400, color: subtitleColor)),
          const SizedBox(height: 8),
          _buildTagPicker(context, options: strengthOptions, selected: model.strengths, onToggle: (v) => model.toggleStrength(v)),
          const SizedBox(height: 20),

          // Weaknesses
          _sectionLabel(FontAwesomeIcons.arrowTrendDown, 'Weaknesses', isDark),
          const SizedBox(height: 4),
          Text("Select areas you'd like to improve", style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w400, color: subtitleColor)),
          const SizedBox(height: 8),
          _buildTagPicker(context, options: weaknessOptions, selected: model.weaknesses, onToggle: (v) => model.toggleWeakness(v)),
          const SizedBox(height: 20),

          // Interests
          _sectionLabel(FontAwesomeIcons.heart, 'Interests', isDark),
          const SizedBox(height: 4),
          Text('Select hobbies, extracurriculars, or broader interests', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w400, color: subtitleColor)),
          const SizedBox(height: 8),
          _buildTagPicker(context, options: interestOptions, selected: model.interests, onToggle: (v) => model.toggleInterest(v)),
          const SizedBox(height: 20),

          // Career Goals
          _sectionLabel(FontAwesomeIcons.briefcase, 'Career Goals', isDark),
          const SizedBox(height: 4),
          Text('Select the category that best matches your career aspirations', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w400, color: subtitleColor)),
          const SizedBox(height: 8),
          _buildCareerGoalPicker(context),
          const SizedBox(height: 32),

          // Navigation buttons
          Row(
            children: [
              if (onBack != null)
                Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: SizedBox(
                    height: 56, child: OutlinedButton(
                      onPressed: onBack,
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: isDark ? Colors.white.withValues(alpha: 0.15) : _brandBlue.withValues(alpha: 0.2)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                      ),
                      child: Text('Back', style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.w600, color: isDark ? Colors.white.withValues(alpha: 0.7) : _brandBlue.withValues(alpha: 0.7))),
                    ),
                  ),
                ),
              Expanded(
                child: SizedBox(
                  height: 56,
                  child: ElevatedButton(
                    onPressed: model.step4Valid ? onNext : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _brandBlue,
                      disabledBackgroundColor: isDark ? Colors.white.withValues(alpha: 0.06) : _brandBlue.withValues(alpha: 0.04),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
                      elevation: model.step4Valid ? 4 : 0,
                      shadowColor: _brandBlue.withValues(alpha: 0.3),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('Continue', style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.w600, color: model.step4Valid ? Colors.white : subtitleColor)),
                        if (model.step4Valid) ...[const SizedBox(width: 8), const FaIcon(FontAwesomeIcons.arrowRight, color: Colors.white, size: 16)],
                      ],
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

  Widget _sectionLabel(FaIconData icon, String label, bool isDark) {
    return Row(
      children: [
        FaIcon(icon, size: 14, color: _brandBlue),
        const SizedBox(width: 8),
        Text(label, style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w600, color: isDark ? Colors.white.withValues(alpha: 0.8) : _brandBlue, letterSpacing: 0.2)),
      ],
    );
  }

  Widget _buildTagPicker(BuildContext context, {required List<String> options, required List<String> selected, required ValueChanged<String> onToggle}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Wrap(
      spacing: 6, runSpacing: 6,
      children: options.map((option) {
        final isSelected = selected.contains(option);
        return GestureDetector(
          onTap: () => onToggle(option),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              color: isSelected ? _brandBlue : isDark ? const Color(0xFF323232).withValues(alpha: 0.6) : Colors.white.withValues(alpha: 0.9),
              border: Border.all(color: isSelected ? _brandBlue : isDark ? Colors.white.withValues(alpha: 0.08) : _brandBlue.withValues(alpha: 0.08)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(option, style: GoogleFonts.inter(fontSize: 12, fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400, color: isSelected ? Colors.white : isDark ? Colors.white.withValues(alpha: 0.7) : const Color(0xFF1A1A2E).withValues(alpha: 0.7))),
                if (isSelected) ...[const SizedBox(width: 6), FaIcon(FontAwesomeIcons.check, color: _brandGold, size: 12)],
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
      spacing: 6, runSpacing: 6,
      children: careerGoalOptions.map((option) {
        final isSelected = model.careerGoals == option;
        return GestureDetector(
          onTap: () => model.careerGoals = option,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              color: isSelected ? _brandBlue : isDark ? const Color(0xFF323232).withValues(alpha: 0.6) : Colors.white.withValues(alpha: 0.9),
              border: Border.all(color: isSelected ? _brandBlue : isDark ? Colors.white.withValues(alpha: 0.08) : _brandBlue.withValues(alpha: 0.08)),
              boxShadow: isSelected ? [BoxShadow(color: _brandBlue.withValues(alpha: 0.3), blurRadius: 12, offset: const Offset(0, 4))] : null,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(option, style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500, color: isSelected ? Colors.white : isDark ? Colors.white.withValues(alpha: 0.7) : const Color(0xFF1A1A2E).withValues(alpha: 0.7))),
                if (isSelected) ...[const SizedBox(width: 6), FaIcon(FontAwesomeIcons.circleCheck, color: _brandGold, size: 16)],
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}