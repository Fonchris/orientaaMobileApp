import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'student_onboarding_model.dart';

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

  static const _brandBlue = Color(0xFF011F7B);
  static const _brandGold = Color(0xFFFFBA09);

  static const List<String> testTypes = [
    'WAEC / WASSCE', 'IELTS', 'TOEFL', 'SAT', 'ACT', 'GRE', 'GMAT',
    'PTE Academic', 'Duolingo English Test', 'Other',
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
          // Header with skip badge
          Row(
            children: [
              Container(
                width: 48, height: 48,
                decoration: BoxDecoration(borderRadius: BorderRadius.circular(14), color: _brandBlue.withValues(alpha: 0.1)),
                child: const FaIcon(FontAwesomeIcons.sliders, color: _brandBlue, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text('Optional Extras', style: GoogleFonts.plusJakartaSans(fontSize: 22, fontWeight: FontWeight.w800, color: textColor, letterSpacing: -0.5)),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                          decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), color: _brandGold.withValues(alpha: 0.15)),
                          child: Text('Skippable', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: _brandGold)),
                        ),
                      ],
                    ),
                    Text('Add academic details to get better recommendations.', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w400, color: subtitleColor)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // GPA
          _sectionLabel(FontAwesomeIcons.graduationCap, 'Prior GPA / Academic Performance', isDark),
          const SizedBox(height: 4),
          Text('Approximate grade average (optional)', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w400, color: subtitleColor)),
          const SizedBox(height: 8),
          _buildGpaInput(context),
          const SizedBox(height: 24),

          // Test Scores
          _sectionLabel(FontAwesomeIcons.fileLines, 'Standardized Test Scores', isDark),
          const SizedBox(height: 4),
          Text('Add any test scores you have (WAEC, IELTS, TOEFL, SAT, etc.)', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w400, color: subtitleColor)),
          const SizedBox(height: 8),
          _buildTestScoresSection(context),
          const SizedBox(height: 24),

          // Accessibility
          _sectionLabel(FontAwesomeIcons.wheelchair, 'Accessibility Needs', isDark),
          const SizedBox(height: 4),
          Text('Any special accommodations or support you may need (optional)', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w400, color: subtitleColor)),
          const SizedBox(height: 8),
          _buildAccessibilityInput(context),
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
                    onPressed: onNext,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _brandBlue,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
                      elevation: 4, shadowColor: _brandBlue.withValues(alpha: 0.3),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('Submit', style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white)),
                        const SizedBox(width: 8),
                        const FaIcon(FontAwesomeIcons.paperPlane, color: Colors.white, size: 16),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity, height: 44,
            child: TextButton(
              onPressed: onSkip,
              child: Text("Skip this step — I'll add details later", style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500, color: subtitleColor, decoration: TextDecoration.underline)),
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
        Text(label, style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w600, color: isDark ? Colors.white.withValues(alpha: 0.8) : _brandBlue, letterSpacing: 0.2)),
      ],
    );
  }

  Widget _buildGpaInput(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return TextField(
      controller: TextEditingController(text: model.gpa ?? '')..selection = TextSelection.fromPosition(TextPosition(offset: model.gpa?.length ?? 0)),
      onChanged: (v) => model.gpa = v,
      style: GoogleFonts.inter(fontSize: 15, color: isDark ? Colors.white : const Color(0xFF1A1A2E)),
      decoration: InputDecoration(
        hintText: 'e.g. 3.5 / 4.0, 75%, or B+ average',
        hintStyle: GoogleFonts.inter(fontSize: 15, color: isDark ? Colors.white.withValues(alpha: 0.3) : _brandBlue.withValues(alpha: 0.3)),
        filled: true,
        fillColor: isDark ? const Color(0xFF323232).withValues(alpha: 0.6) : Colors.white.withValues(alpha: 0.9),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: isDark ? Colors.white.withValues(alpha: 0.08) : _brandBlue.withValues(alpha: 0.08))),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: isDark ? Colors.white.withValues(alpha: 0.08) : _brandBlue.withValues(alpha: 0.08))),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }

  Widget _buildTestScoresSection(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ...List.generate(model.testScores.length, (index) {
          final score = model.testScores[index];
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              color: isDark ? const Color(0xFF323232).withValues(alpha: 0.6) : Colors.white.withValues(alpha: 0.9),
              border: Border.all(color: isDark ? Colors.white.withValues(alpha: 0.08) : _brandBlue.withValues(alpha: 0.08)),
            ),
            child: Row(
              children: [
                FaIcon(FontAwesomeIcons.fileLines, size: 14, color: _brandBlue),
                const SizedBox(width: 10),
                Expanded(child: Text('${score.testName}: ${score.score}', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500, color: isDark ? Colors.white : const Color(0xFF1A1A2E)))),
                GestureDetector(
                  onTap: () => model.removeTestScore(index),
                  child: FaIcon(FontAwesomeIcons.xmark, size: 16, color: isDark ? Colors.white.withValues(alpha: 0.5) : _brandBlue.withValues(alpha: 0.5)),
                ),
              ],
            ),
          );
        }),
        GestureDetector(
          onTap: () => _showAddTestScoreDialog(context),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: isDark ? Colors.white.withValues(alpha: 0.15) : _brandBlue.withValues(alpha: 0.15)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                FaIcon(FontAwesomeIcons.plus, size: 14, color: _brandBlue),
                const SizedBox(width: 8),
                Text('Add Test Score', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: _brandBlue)),
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
              backgroundColor: isDark ? const Color(0xFF1A1A2E) : Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: Text('Add Test Score', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, color: isDark ? Colors.white : const Color(0xFF1A1A2E))),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<String>(
                    initialValue: selectedTest,
                    decoration: InputDecoration(labelText: 'Test Type', border: OutlineInputBorder(borderRadius: BorderRadius.circular(14))),
                    items: testTypes.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                    onChanged: (v) => setDialogState(() => selectedTest = v),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: scoreController,
                    decoration: InputDecoration(labelText: 'Score', hintText: 'e.g. 7.5, 1450, B2', border: OutlineInputBorder(borderRadius: BorderRadius.circular(14))),
                  ),
                ],
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                FilledButton(
                  onPressed: () {
                    if (scoreController.text.trim().isNotEmpty && selectedTest != null) {
                      model.addTestScore(TestScore(testName: selectedTest!, score: scoreController.text.trim()));
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

  Widget _buildAccessibilityInput(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return TextField(
      controller: TextEditingController(text: model.accessibilityNeeds ?? '')..selection = TextSelection.fromPosition(TextPosition(offset: model.accessibilityNeeds?.length ?? 0)),
      onChanged: (v) => model.accessibilityNeeds = v,
      maxLines: 3,
      style: GoogleFonts.inter(fontSize: 15, color: isDark ? Colors.white : const Color(0xFF1A1A2E)),
      decoration: InputDecoration(
        hintText: 'Describe any accessibility needs or accommodations...',
        hintStyle: GoogleFonts.inter(fontSize: 15, color: isDark ? Colors.white.withValues(alpha: 0.3) : _brandBlue.withValues(alpha: 0.3)),
        filled: true,
        fillColor: isDark ? const Color(0xFF323232).withValues(alpha: 0.6) : Colors.white.withValues(alpha: 0.9),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: isDark ? Colors.white.withValues(alpha: 0.08) : _brandBlue.withValues(alpha: 0.08))),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: isDark ? Colors.white.withValues(alpha: 0.08) : _brandBlue.withValues(alpha: 0.08))),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }
}