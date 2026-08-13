import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:orientaa_mobile_app/widgets/discovery/models/university_models.dart';
import 'package:orientaa_mobile_app/widgets/discovery/widgets/country_flag.dart';
import 'package:orientaa_mobile_app/widgets/discovery/widgets/match_reasons.dart';
import 'package:orientaa_mobile_app/widgets/discovery/widgets/skeleton_card.dart';
import 'package:orientaa_mobile_app/widgets/discovery/widgets/tier_upgrade_banner.dart';

void main() {
  Widget wrap(Widget child) =>
      MaterialApp(home: Scaffold(body: Center(child: child)));

  testWidgets('CountryFlag renders emoji and country name', (tester) async {
    await tester.pumpWidget(
      wrap(const CountryFlag(countryCode: 'NG', countryName: 'Nigeria')),
    );
    expect(find.text('🇳🇬'), findsOneWidget);
    expect(find.text('Nigeria'), findsOneWidget);
  });

  testWidgets('CountryFlag falls back to globe without a code', (tester) async {
    await tester.pumpWidget(wrap(const CountryFlag()));
    expect(find.text('🌍'), findsOneWidget);
  });

  testWidgets('MatchReasons renders engine reasons as tags for free tier',
      (tester) async {
    const program = RecommendedProgram(
      universityId: 'u1',
      programId: 'p1',
      universityName: 'UCT',
      programName: 'CS',
      matchReasons: ['Within budget', 'Matches your field'],
    );
    await tester.pumpWidget(
      wrap(const MatchReasons(program: program, tier: UserTier.free)),
    );
    expect(find.text('Within budget'), findsOneWidget);
    expect(find.text('Matches your field'), findsOneWidget);
  });

  testWidgets('MatchReasons renders nothing when there are no reasons',
      (tester) async {
    const program = RecommendedProgram(
      universityId: 'u1',
      programId: 'p1',
      universityName: 'UCT',
      programName: 'CS',
    );
    await tester.pumpWidget(
      wrap(const MatchReasons(program: program, tier: UserTier.free)),
    );
    expect(find.byType(MatchReasons), findsOneWidget);
  });

  testWidgets('SkeletonBlock renders a placeholder rectangle', (tester) async {
    await tester.pumpWidget(wrap(const SkeletonBlock(width: 50, height: 20)));
    expect(find.byType(SkeletonBlock), findsOneWidget);
    // No spinner — skeletons replace CircularProgressIndicator.
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });

  testWidgets('TierUpgradeBanner shows message and opens the stub sheet',
      (tester) async {
    await tester.pumpWidget(
      wrap(const TierUpgradeBanner(message: 'Upgrade to see all matches')),
    );
    expect(find.text('Upgrade to see all matches'), findsOneWidget);

    await tester.tap(find.text('Upgrade'));
    await tester.pumpAndSettle();
    expect(find.text('Unlock Orientaa Pro & Premium'), findsOneWidget);
  });
}
