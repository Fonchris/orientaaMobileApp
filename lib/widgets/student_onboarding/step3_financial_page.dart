import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'student_onboarding_model.dart';

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

  static const _brandBlue = Color(0xFF011F7B);
  static const _brandGold = Color(0xFFFFBA09);

  static const List<double> budgetRanges = [
    1000, 3000, 5000, 8000, 10000, 15000, 20000, 30000, 50000,
  ];

  static const List<String> incomeBrackets = [
    'Less than \$5,000', '\$5,000 – \$10,000', '\$10,000 – \$20,000',
    '\$20,000 – \$35,000', '\$35,000 – \$50,000', '\$50,000 – \$75,000',
    '\$75,000 – \$100,000', 'Over \$100,000', 'Prefer not to say',
  ];

  String _formatBudget(double budget) {
    if (budget >= 1000) return '\$${(budget / 1000).toStringAsFixed(0)}k';
    return '\$${budget.toStringAsFixed(0)}';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : const Color(0xFF1A1A2E);
    final subtitleColor = isDark
        ? Colors.white.withValues(alpha: 0.6)
        : const Color(0xFF1A1A2E).withValues(alpha: 0.6);
    final currency = model.currency ?? 'USD';

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with icon
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  color: _brandBlue.withValues(alpha: 0.1),
                ),
                child: const FaIcon(FontAwesomeIcons.moneyBillWave, color: _brandBlue, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Financial Information',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 22, fontWeight: FontWeight.w800, color: textColor, letterSpacing: -0.5,
                      ),
                    ),
                    Text(
                      'Help us match you with affordable options.',
                      style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w400, color: subtitleColor),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Explanatory note
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              color: _brandGold.withValues(alpha: 0.1),
              border: Border.all(color: _brandGold.withValues(alpha: 0.2)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                FaIcon(FontAwesomeIcons.circleInfo, color: _brandGold, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'We ask for financial information to recommend universities, scholarships, and student loan options that match your budget. Your data is kept private and secure.',
                    style: GoogleFonts.inter(
                      fontSize: 13, fontWeight: FontWeight.w400,
                      color: isDark ? Colors.white.withValues(alpha: 0.7) : const Color(0xFF1A1A2E).withValues(alpha: 0.7),
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // ── Budget Range ──
          _sectionLabel(FontAwesomeIcons.wallet, 'Annual Fee / Budget Range', isDark),
          const SizedBox(height: 4),
          Text(
            'Currency: $currency (auto-set based on your home country)',
            style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w400, color: subtitleColor),
          ),
          const SizedBox(height: 12),
          _buildBudgetSelector(context, currency),
          const SizedBox(height: 20),

          // ── Annual Household Income (Optional) ──
          Row(
            children: [
              FaIcon(FontAwesomeIcons.houseChimney, size: 14, color: _brandBlue),
              const SizedBox(width: 8),
              _sectionLabel(FontAwesomeIcons.houseChimney, 'Annual Household Income', isDark),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8), color: _brandGold.withValues(alpha: 0.15),
                ),
                child: Text('Optional', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: _brandGold)),
              ),
              const SizedBox(width: 6),
              FaIcon(FontAwesomeIcons.lock, size: 12, color: subtitleColor),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'This helps us find scholarships and financial aid you may qualify for.',
            style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w400, color: subtitleColor),
          ),
          const SizedBox(height: 8),
          _buildDropdown<String>(
            context,
            value: model.annualIncome?.toStringAsFixed(0),
            items: incomeBrackets,
            hint: 'Select income bracket (optional)',
            onChanged: (v) {
              if (v != null) {
                double? parsedValue;
                if (v.startsWith('Less than')) { parsedValue = 2500; }
                else if (v.startsWith('Over')) { parsedValue = 100000; }
                else if (v == 'Prefer not to say') { parsedValue = 0; }
                else {
                  final parts = v.split(' – ');
                  if (parts.isNotEmpty) {
                    parsedValue = double.tryParse(parts[0].replaceAll('\$', '').replaceAll(',', ''));
                  }
                }
                model.annualIncome = parsedValue;
              } else {
                model.annualIncome = null;
              }
            },
          ),
          const SizedBox(height: 20),

          // ── Scholarship Seeking ──
          _sectionLabel(FontAwesomeIcons.graduationCap, 'Are you seeking scholarships?', isDark),
          const SizedBox(height: 8),
          _buildToggleSwitch(context),
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
                    onPressed: model.step3Valid ? onNext : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _brandBlue,
                      disabledBackgroundColor: isDark ? Colors.white.withValues(alpha: 0.06) : _brandBlue.withValues(alpha: 0.04),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
                      elevation: model.step3Valid ? 4 : 0,
                      shadowColor: _brandBlue.withValues(alpha: 0.3),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('Continue', style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.w600, color: model.step3Valid ? Colors.white : subtitleColor)),
                        if (model.step3Valid) ...[const SizedBox(width: 8), const FaIcon(FontAwesomeIcons.arrowRight, color: Colors.white, size: 16)],
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

  Widget _buildBudgetSelector(BuildContext context, String currency) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Wrap(
      spacing: 8, runSpacing: 8,
      children: budgetRanges.map((budget) {
        final isSelected = model.budgetPerYear == budget;
        return GestureDetector(
          onTap: () => model.budgetPerYear = budget,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              color: isSelected ? _brandBlue : isDark ? const Color(0xFF323232).withValues(alpha: 0.6) : Colors.white.withValues(alpha: 0.9),
              border: Border.all(color: isSelected ? _brandBlue : isDark ? Colors.white.withValues(alpha: 0.08) : _brandBlue.withValues(alpha: 0.08)),
            ),
            child: Text('$currency ${_formatBudget(budget)}', style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500, color: isSelected ? Colors.white : isDark ? Colors.white.withValues(alpha: 0.7) : const Color(0xFF1A1A2E).withValues(alpha: 0.7))),
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
        borderRadius: BorderRadius.circular(14),
        color: isDark ? const Color(0xFF323232).withValues(alpha: 0.6) : Colors.white.withValues(alpha: 0.9),
        border: Border.all(color: isDark ? Colors.white.withValues(alpha: 0.08) : _brandBlue.withValues(alpha: 0.08)),
      ),
      child: SwitchListTile(
        title: Text(
          model.seekingScholarship ? 'Yes, I want scholarship information' : 'Not currently seeking scholarships',
          style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w500, color: isDark ? Colors.white : const Color(0xFF1A1A2E)),
        ),
        value: model.seekingScholarship,
        onChanged: (v) => model.seekingScholarship = v,
        activeTrackColor: _brandBlue.withValues(alpha: 0.3),
        activeThumbColor: _brandBlue,
        contentPadding: EdgeInsets.zero,
      ),
    );
  }

  Widget _buildDropdown<T>(BuildContext context, {required T? value, required List<T> items, required String hint, required ValueChanged<T?> onChanged}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: isDark ? const Color(0xFF323232).withValues(alpha: 0.6) : Colors.white.withValues(alpha: 0.9),
        border: Border.all(color: isDark ? Colors.white.withValues(alpha: 0.08) : _brandBlue.withValues(alpha: 0.08)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value, isExpanded: true,
          hint: Text(hint, style: GoogleFonts.inter(fontSize: 15, color: isDark ? Colors.white.withValues(alpha: 0.3) : _brandBlue.withValues(alpha: 0.3))),
          style: GoogleFonts.inter(fontSize: 15, color: isDark ? Colors.white : const Color(0xFF1A1A2E)),
          dropdownColor: isDark ? const Color(0xFF323232) : Colors.white,
          icon: const FaIcon(FontAwesomeIcons.chevronDown, size: 14),
          borderRadius: BorderRadius.circular(14),
          items: items.map((item) => DropdownMenuItem<T>(value: item, child: Text(item.toString()))).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}