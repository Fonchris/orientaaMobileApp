import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:orientaa_mobile_app/widgets/student_onboarding/step4_self_assessment_page.dart';
import 'package:orientaa_mobile_app/widgets/student_onboarding/student_onboarding_model.dart';

/// Mirrors how StudentOnboardingPage listens to the model and rebuilds.
class _Harness extends StatefulWidget {
  final StudentOnboardingModel model;
  final VoidCallback onNext;

  const _Harness({required this.model, required this.onNext});

  @override
  State<_Harness> createState() => _HarnessState();
}

class _HarnessState extends State<_Harness> {
  @override
  void initState() {
    super.initState();
    widget.model.addListener(_onModel);
  }

  @override
  void dispose() {
    widget.model.removeListener(_onModel);
    super.dispose();
  }

  void _onModel() => setState(() {});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Step4SelfAssessmentPage(
        model: widget.model,
        onNext: widget.onNext,
        onBack: () {},
      ),
    );
  }
}

void main() {
  testWidgets(
    'Self-assessment splits into two parts and completes the full flow',
    (tester) async {
      final model = StudentOnboardingModel();
      var nextCalled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: _Harness(model: model, onNext: () => nextCalled = true),
        ),
      );

      // Part 1 shows Strengths & Weaknesses, but not Interests/Career Goals.
      expect(find.text('Strengths'), findsOneWidget);
      expect(find.text('Weaknesses'), findsOneWidget);
      expect(find.text('Interests'), findsNothing);
      expect(find.text('Career Goals'), findsNothing);

      // Selecting a strength must not change the chip's own width: the check
      // slot is always present, so neighbouring chips never reflow.
      final chipFinder = find.ancestor(
        of: find.text('Leadership'),
        matching: find.byType(AnimatedContainer),
      );
      final chipWidthBefore = tester.getSize(chipFinder.first).width;
      await tester.tap(find.text('Leadership'));
      await tester.pumpAndSettle();
      final chipWidthAfter = tester.getSize(chipFinder.first).width;
      expect(
        chipWidthAfter,
        closeTo(chipWidthBefore, 0.5),
        reason: 'Chip must not resize when selected (prevents layout shift)',
      );

      // Pick a weakness (scroll it into view first), then move to part 2.
      await tester.ensureVisible(find.text('Procrastination'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Procrastination'));
      await tester.pump();
      await tester.ensureVisible(find.text('Next: Interests & Goals'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Next: Interests & Goals'));
      await tester.pumpAndSettle();

      // Part 2 shows Interests & Career Goals.
      expect(find.text('Interests'), findsOneWidget);
      expect(find.text('Career Goals'), findsOneWidget);

      await tester.ensureVisible(find.text('Technology & Gaming'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Technology & Gaming'));
      await tester.pump();
      await tester.ensureVisible(find.text('Computer Science & IT'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Computer Science & IT'));
      await tester.pump();

      // The nav bar is pinned below the scroll view, so it is always tappable.
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();

      expect(nextCalled, isTrue);
      expect(model.strengths, contains('Leadership'));
      expect(model.weaknesses, contains('Procrastination'));
      expect(model.interests, contains('Technology & Gaming'));
      expect(model.careerGoals, 'Computer Science & IT');
    },
  );

  testWidgets('Part 1 cannot advance without a strength and a weakness', (
    tester,
  ) async {
    final model = StudentOnboardingModel();

    await tester.pumpWidget(
      MaterialApp(
        home: _Harness(model: model, onNext: () {}),
      ),
    );

    // Disabled state shows the hint label instead of a Next button.
    expect(find.text('Select strengths'), findsOneWidget);

    // Selecting only a strength keeps it disabled.
    await tester.tap(find.text('Leadership'));
    await tester.pump();
    expect(find.text('Select strengths'), findsOneWidget);
  });
}
