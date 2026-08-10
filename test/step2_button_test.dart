import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:orientaa_mobile_app/l10n/app_localizations.dart';
import 'package:orientaa_mobile_app/widgets/student_onboarding/step2_location_page.dart';
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
      body: Step2LocationPage(
        model: widget.model,
        onNext: widget.onNext,
        onBack: () {},
      ),
    );
  }
}

void main() {
  testWidgets('Continue button enables and navigates after required fields are filled',
      (tester) async {
    final model = StudentOnboardingModel();
    var nextCalled = false;

    await tester.pumpWidget(MaterialApp(
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: _Harness(model: model, onNext: () => nextCalled = true),
    ));

    // Initially the button is disabled (label says what's missing).
    expect(find.text('Complete required fields'), findsOneWidget);

    // Simulate the country picker result.
    model.homeCountry = 'Nigeria (West Africa)';
    model.homeCountryCode = 'NG';
    await tester.pump();

    // Type the home city.
    await tester.enterText(find.byType(TextField), 'Lagos');
    await tester.pump();

    // Button should now be enabled with a "Continue" label.
    expect(find.text('Continue'), findsOneWidget);

    await tester.ensureVisible(find.text('Continue'));
    await tester.pump();
    await tester.tap(find.text('Continue'));
    await tester.pump();

    expect(nextCalled, isTrue);
  });
}
