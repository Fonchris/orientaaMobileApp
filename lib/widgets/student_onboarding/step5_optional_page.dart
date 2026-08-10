import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../app_theme.dart';
import '../google_fonts.dart';
import 'student_onboarding_model.dart';
import 'step_ui.dart';

class Step5OptionalPage extends StatelessWidget {
  final StudentOnboardingModel model;
  final VoidCallback onNext;
  final VoidCallback? onBack;
  final VoidCallback onSkip;

  const Step5OptionalPage({
    super.key,
    required this.model,
    required this.onNext,
    this.onBack,
    required this.onSkip,
  });

  static const List<String> testTypes = [
    'WAEC / WASSCE',
    'IELTS',
    'TOEFL',
    'SAT',
    'ACT',
    'GRE',
    'GMAT',
    'PTE Academic',
    'Duolingo English Test',
    'Other',
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final subtitleColor = isDark
        ? Colors.white.withValues(alpha: 0.6)
        : AppTheme.brandInk.withValues(alpha: 0.6);

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
                    icon: FontAwesomeIcons.sliders,
                    title: 'Optional Extras',
                    subtitle:
                        'Add academic details to unlock even better recommendations.',
                    chips: ['Skippable'],
                  ),
                ),
                const SizedBox(height: 22),

                // GPA
                StepReveal(
                  delay: const Duration(milliseconds: 100),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const StepSectionLabel(
                        icon: FontAwesomeIcons.graduationCap,
                        label: 'Prior GPA / Academic Performance',
                        helper: 'Approximate grade average',
                      ),
                      const SizedBox(height: 10),
                      BrandTextField(
                        initialText: model.gpa ?? '',
                        label: 'GPA',
                        hint: 'e.g. 3.5 / 4.0, 75%, or B+ average',
                        prefixIcon: FontAwesomeIcons.graduationCap,
                        onChanged: (v) => model.gpa = v,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 22),

                // Test Scores
                StepReveal(
                  delay: const Duration(milliseconds: 140),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const StepSectionLabel(
                        icon: FontAwesomeIcons.fileLines,
                        label: 'Standardized Test Scores',
                        helper: 'WAEC, IELTS, TOEFL, SAT, etc.',
                      ),
                      const SizedBox(height: 10),
                      _buildTestScoresSection(context),
                    ],
                  ),
                ),
                const SizedBox(height: 22),

                // Accessibility
                StepReveal(
                  delay: const Duration(milliseconds: 180),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const StepSectionLabel(
                        icon: FontAwesomeIcons.wheelchair,
                        label: 'Accessibility Needs',
                        helper:
                            'Any special accommodations or support you may need',
                      ),
                      const SizedBox(height: 10),
                      BrandTextField(
                        initialText: model.accessibilityNeeds ?? '',
                        label: 'Accessibility',
                        hint: 'Describe any needs or accommodations...',
                        prefixIcon: FontAwesomeIcons.handshakeAngle,
                        maxLines: 3,
                        onChanged: (v) => model.accessibilityNeeds = v,
                      ),
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
          nextLabel: 'Submit',
          nextEnabled: true,
          nextIcon: FontAwesomeIcons.paperPlane,
          extra: SizedBox(
            width: double.infinity,
            height: 44,
            child: TextButton(
              onPressed: onSkip,
              child: Text(
                "Skip this step — I'll add details later",
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: subtitleColor,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTestScoresSection(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ...List.generate(model.testScores.length, (index) {
          final score = model.testScores[index];
          return TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: 1),
            duration: const Duration(milliseconds: 320),
            curve: Curves.easeOutBack,
            builder: (context, value, child) {
              return Transform.scale(scale: value, child: child);
            },
            child: Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                color: isDark
                    ? Colors.white.withValues(alpha: 0.05)
                    : Colors.white.withValues(alpha: 0.9),
                border: Border.all(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.1)
                      : AppTheme.brandYellow.withValues(alpha: 0.2),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      color: AppTheme.brandYellow.withValues(alpha: 0.14),
                    ),
                    child: const FaIcon(
                      FontAwesomeIcons.fileLines,
                      size: 14,
                      color: AppTheme.brandAmber,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      '${score.testName}: ${score.score}',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : AppTheme.brandInk,
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => model.removeTestScore(index),
                    child: FaIcon(
                      FontAwesomeIcons.xmark,
                      size: 16,
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.5)
                          : AppTheme.brandInk.withValues(alpha: 0.5),
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
        GestureDetector(
          onTap: () => _showAddTestScoreDialog(context),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 13),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.15)
                    : AppTheme.brandYellow.withValues(alpha: 0.3),
              ),
              color: isDark
                  ? Colors.white.withValues(alpha: 0.03)
                  : Colors.white.withValues(alpha: 0.5),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                FaIcon(
                  FontAwesomeIcons.plus,
                  size: 13,
                  color: isDark ? AppTheme.brandGold : AppTheme.brandInk,
                ),
                const SizedBox(width: 8),
                Text(
                  'Add Test Score',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: isDark ? AppTheme.brandGold : AppTheme.brandInk,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _showAddTestScoreDialog(BuildContext context) async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    String? selectedTest = testTypes.first;
    final scoreController = TextEditingController();

    await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: isDark ? AppTheme.brandInk : Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: Text(
                'Add Test Score',
                style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : AppTheme.brandInk,
                ),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<String>(
                    initialValue: selectedTest,
                    decoration: InputDecoration(
                      labelText: 'Test Type',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    items: testTypes
                        .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                        .toList(),
                    onChanged: (v) => setDialogState(() => selectedTest = v),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: scoreController,
                    decoration: InputDecoration(
                      labelText: 'Score',
                      hintText: 'e.g. 7.5, 1450, B2',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () {
                    if (scoreController.text.trim().isNotEmpty &&
                        selectedTest != null) {
                      model.addTestScore(
                        TestScore(
                          testName: selectedTest!,
                          score: scoreController.text.trim(),
                        ),
                      );
                      Navigator.pop(ctx, true);
                    }
                  },
                  child: const Text('Add'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
