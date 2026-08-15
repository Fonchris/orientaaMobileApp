import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:orientaa_mobile_app/l10n/app_localizations.dart';
import 'package:orientaa_mobile_app/widgets/counselors/screens/counselor_review_screen.dart';

Widget wrap(Widget child) => MaterialApp(
      locale: const Locale('en'),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      home: Scaffold(body: child),
    );

void main() {
  group('CounselorReviewStatusView', () {
    testWidgets('pending shows the under-review card with no action button',
        (tester) async {
      await tester.pumpWidget(
        wrap(const CounselorReviewStatusView(verificationStatus: 'pending')),
      );
      expect(find.text('Application under review'), findsOneWidget);
      expect(find.byType(FilledButton), findsNothing);
    });

    testWidgets('pending card states the 48-hour review SLA', (tester) async {
      await tester.pumpWidget(
        wrap(const CounselorReviewStatusView(verificationStatus: 'pending')),
      );
      expect(
        find.text('Applications are typically reviewed within 48 hours.'),
        findsOneWidget,
      );
      // The SLA note is pending-only — rejected/approved cards don't show it.
      await tester.pumpWidget(
        wrap(const CounselorReviewStatusView(verificationStatus: 'approved')),
      );
      expect(
        find.text('Applications are typically reviewed within 48 hours.'),
        findsNothing,
      );
    });

    testWidgets('rejected shows the rejected card and fires onEdit',
        (tester) async {
      var edited = false;
      await tester.pumpWidget(
        wrap(CounselorReviewStatusView(
          verificationStatus: 'rejected',
          onEdit: () => edited = true,
        )),
      );
      expect(find.text('Application not approved'), findsOneWidget);
      expect(find.text('Edit application'), findsOneWidget);

      await tester.tap(find.text('Edit application'));
      expect(edited, isTrue);
    });

    testWidgets('approved shows the approved card and fires onGoToDashboard',
        (tester) async {
      var went = false;
      await tester.pumpWidget(
        wrap(CounselorReviewStatusView(
          verificationStatus: 'approved',
          onGoToDashboard: () => went = true,
        )),
      );
      expect(find.text("You're approved!"), findsOneWidget);
      expect(find.text('Go to dashboard'), findsOneWidget);

      await tester.tap(find.text('Go to dashboard'));
      expect(went, isTrue);
    });

    testWidgets('unknown status falls back to the pending card',
        (tester) async {
      await tester.pumpWidget(
        wrap(const CounselorReviewStatusView(verificationStatus: 'weird')),
      );
      expect(find.text('Application under review'), findsOneWidget);
    });
  });
}
