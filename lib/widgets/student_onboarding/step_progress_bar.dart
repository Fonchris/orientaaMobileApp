import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class StepProgressBar extends StatelessWidget {
  final int totalSteps;
  final int currentStep;

  const StepProgressBar({
    super.key,
    required this.totalSteps,
    required this.currentStep,
  });

  static const List<String> stepLabels = [
    'Identity',
    'Location',
    'Financial',
    'Self',
    'Personality',
    'Extras',
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final activeColor = const Color(0xFF011F7B);
    final inactiveColor = isDark
        ? Colors.white.withValues(alpha: 0.15)
        : activeColor.withValues(alpha: 0.12);
    final doneColor = const Color(0xFFFFBA09);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: List.generate(totalSteps * 2 - 1, (index) {
          if (index.isOdd) {
            // Connector line
            final stepIndex = index ~/ 2;
            final isDone = stepIndex < currentStep;
            return Expanded(
              child: Container(
                height: 2,
                color: isDone ? doneColor : inactiveColor,
              ),
            );
          }
          // Dot with label
          final stepIndex = index ~/ 2;
          final isCurrent = stepIndex == currentStep;
          final isDone = stepIndex < currentStep;
          final label = stepIndex < stepLabels.length ? stepLabels[stepIndex] : '';

          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: isCurrent ? 14 : 10,
                height: isCurrent ? 14 : 10,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isDone
                      ? doneColor
                      : isCurrent
                          ? activeColor
                          : inactiveColor,
                  boxShadow: isCurrent
                      ? [
                          BoxShadow(
                            color: activeColor.withValues(alpha: 0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: isDone
                    ? const Icon(Icons.check, size: 8, color: Colors.white)
                    : null,
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 8,
                  fontWeight: isCurrent ? FontWeight.w600 : FontWeight.w400,
                  color: isCurrent
                      ? activeColor
                      : isDark
                          ? Colors.white.withValues(alpha: 0.4)
                          : activeColor.withValues(alpha: 0.4),
                ),
              ),
            ],
          );
        }),
      ),
    );
  }
}