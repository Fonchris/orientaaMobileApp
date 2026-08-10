import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../app_theme.dart';
import '../google_fonts.dart';
import 'student_onboarding_model.dart';
import 'step_ui.dart';

class Step3FinancialPage extends StatelessWidget {
  final StudentOnboardingModel model;
  final VoidCallback onNext;
  final VoidCallback? onBack;

  const Step3FinancialPage({
    super.key,
    required this.model,
    required this.onNext,
    this.onBack,
  });

  static const List<double> budgetRanges = [
    1000,
    3000,
    5000,
    8000,
    10000,
    15000,
    20000,
    30000,
    50000,
  ];

  static const List<String> incomeBrackets = [
    'Less than \$5,000',
    '\$5,000 – \$10,000',
    '\$10,000 – \$20,000',
    '\$20,000 – \$35,000',
    '\$35,000 – \$50,000',
    '\$50,000 – \$75,000',
    '\$75,000 – \$100,000',
    'Over \$100,000',
    'Prefer not to say',
  ];

  String _formatBudget(double budget) {
    if (budget >= 1000) return '\$${(budget / 1000).toStringAsFixed(0)}k';
    return '\$${budget.toStringAsFixed(0)}';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currency = model.currency ?? 'USD';

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
                    icon: FontAwesomeIcons.moneyBillWave,
                    title: 'Financial Information',
                    subtitle:
                        'Help us match you with affordable universities, scholarships and loans.',
                    chips: ['Auto currency', 'Private & secure'],
                  ),
                ),
                const SizedBox(height: 16),

                // Explanatory note
                StepReveal(
                  delay: const Duration(milliseconds: 70),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(18),
                      color: AppTheme.brandGold.withValues(alpha: 0.1),
                      border: Border.all(
                        color: AppTheme.brandGold.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppTheme.brandGold.withValues(alpha: 0.18),
                          ),
                          child: const FaIcon(
                            FontAwesomeIcons.circleInfo,
                            color: AppTheme.brandGold,
                            size: 15,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Your data is kept private and secure — we only use it to recommend options that fit your budget.',
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w400,
                              color: isDark
                                  ? Colors.white.withValues(alpha: 0.75)
                                  : AppTheme.brandInk.withValues(alpha: 0.75),
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 22),

                // ── Budget Range ──
                StepReveal(
                  delay: const Duration(milliseconds: 120),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const StepSectionLabel(
                        icon: FontAwesomeIcons.wallet,
                        label: 'Annual Fee / Budget Range',
                        helper: 'Currency auto-set from your home country',
                      ),
                      const SizedBox(height: 12),
                      _buildBudgetSelector(context, currency),
                    ],
                  ),
                ),
                const SizedBox(height: 22),

                // ── Annual Household Income (Optional) ──
                StepReveal(
                  delay: const Duration(milliseconds: 160),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const StepSectionLabel(
                        icon: FontAwesomeIcons.houseChimney,
                        label: 'Annual Household Income',
                        badge: 'Optional',
                        helper:
                            'Helps us find scholarships and financial aid you may qualify for.',
                      ),
                      const SizedBox(height: 10),
                      _buildDropdown<String>(
                        context,
                        value: model.annualIncomeLabel,
                        items: incomeBrackets,
                        hint: 'Select income bracket',
                        onChanged: (v) {
                          // Always keep the displayed label in sync so the
                          // DropdownButton value always matches one of its items.
                          model.annualIncomeLabel = v;
                          if (v != null) {
                            double? parsedValue;
                            if (v.startsWith('Less than')) {
                              parsedValue = 2500;
                            } else if (v.startsWith('Over')) {
                              parsedValue = 100000;
                            } else if (v == 'Prefer not to say') {
                              parsedValue = 0;
                            } else {
                              final parts = v.split(' – ');
                              if (parts.isNotEmpty) {
                                parsedValue = double.tryParse(
                                  parts[0]
                                      .replaceAll('\$', '')
                                      .replaceAll(',', ''),
                                );
                              }
                            }
                            model.annualIncome = parsedValue;
                          } else {
                            model.annualIncome = null;
                          }
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 22),

                // ── Scholarship Seeking ──
                StepReveal(
                  delay: const Duration(milliseconds: 200),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const StepSectionLabel(
                        icon: FontAwesomeIcons.graduationCap,
                        label: 'Are you seeking scholarships?',
                      ),
                      const SizedBox(height: 10),
                      _buildToggleSwitch(context),
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
          nextLabel: model.step3Valid ? 'Continue' : 'Select a budget',
          nextEnabled: model.step3Valid,
          hint: model.step3Valid ? null : 'Select a budget to continue',
        ),
      ],
    );
  }

  Widget _buildBudgetSelector(BuildContext context, String currency) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: budgetRanges.map((budget) {
        final isSelected = model.budgetPerYear == budget;
        return GestureDetector(
          onTap: () => model.budgetPerYear = budget,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(999),
              color: isSelected
                  ? AppTheme.brandYellow
                  : isDark
                  ? Colors.white.withValues(alpha: 0.05)
                  : Colors.white.withValues(alpha: 0.9),
              border: Border.all(
                color: isSelected
                    ? AppTheme.brandYellow
                    : isDark
                    ? Colors.white.withValues(alpha: 0.1)
                    : AppTheme.brandYellow.withValues(alpha: 0.25),
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.25),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ]
                  : null,
            ),
            child: Text(
              '$currency ${_formatBudget(budget)}',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
                color: isSelected
                    ? AppTheme.brandInk
                    : isDark
                    ? Colors.white.withValues(alpha: 0.75)
                    : AppTheme.brandInk.withValues(alpha: 0.75),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildToggleSwitch(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: isDark
            ? Colors.white.withValues(alpha: 0.05)
            : Colors.white.withValues(alpha: 0.9),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.1)
              : AppTheme.brandYellow.withValues(alpha: 0.2),
        ),
      ),
      child: SwitchListTile(
        title: Text(
          model.seekingScholarship
              ? 'Yes, I want scholarship information'
              : 'Not currently seeking scholarships',
          style: GoogleFonts.inter(
            fontSize: 15,
            fontWeight: FontWeight.w500,
            color: isDark ? Colors.white : AppTheme.brandInk,
          ),
        ),
        value: model.seekingScholarship,
        onChanged: (v) => model.seekingScholarship = v,
        activeTrackColor: AppTheme.brandYellow.withValues(alpha: 0.3),
        activeThumbColor: AppTheme.brandYellow,
        contentPadding: EdgeInsets.zero,
      ),
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
    final scheme = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: isDark
            ? Colors.white.withValues(alpha: 0.05)
            : Colors.white.withValues(alpha: 0.9),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.1)
              : scheme.outline.withValues(alpha: 0.55),
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
                ? Colors.white.withValues(alpha: 0.35)
                : AppTheme.brandInk.withValues(alpha: 0.35),
            ),
          ),
          style: GoogleFonts.inter(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white : AppTheme.brandInk,
          ),
          dropdownColor: isDark ? AppTheme.brandInk : Colors.white,
          borderRadius: BorderRadius.circular(16),
          icon: FaIcon(
            FontAwesomeIcons.chevronDown,
            size: 13,
            color: isDark
                ? Colors.white.withValues(alpha: 0.5)
                : AppTheme.brandInk.withValues(alpha: 0.5),
          ),
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
}
