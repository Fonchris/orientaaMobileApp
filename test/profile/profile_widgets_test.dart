import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:orientaa_mobile_app/l10n/app_localizations.dart';
import 'package:orientaa_mobile_app/widgets/app_theme.dart';
import 'package:orientaa_mobile_app/widgets/profile/profile_stats.dart';
import 'package:orientaa_mobile_app/widgets/profile/role_badge.dart';

Widget _wrap(Widget child) {
  return MaterialApp(
    theme: AppTheme.light(),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(body: Center(child: child)),
  );
}

void main() {
  group('RoleBadge', () {
    testWidgets('shows Student for student role', (tester) async {
      await tester.pumpWidget(_wrap(const RoleBadge(role: 'student')));
      expect(find.text('Student'), findsOneWidget);
    });

    testWidgets('shows Counsellor for counsellor role', (tester) async {
      await tester.pumpWidget(_wrap(const RoleBadge(role: 'counsellor')));
      expect(find.text('Counsellor'), findsOneWidget);
    });

    testWidgets('shows Verified Counsellor when verified', (tester) async {
      await tester.pumpWidget(
        _wrap(const RoleBadge(role: 'counsellor', isVerified: true)),
      );
      expect(find.text('Verified Counsellor'), findsOneWidget);
      expect(find.text('Student'), findsNothing);
    });
  });

  group('ProfileStats', () {
    testWidgets('renders counts and labels', (tester) async {
      await tester.pumpWidget(
        _wrap(
          ProfileStats(
            followers: 245,
            following: 180,
            posts: 32,
            onTapFollowers: () {},
            onTapFollowing: () {},
            onTapPosts: () {},
          ),
        ),
      );
      expect(find.text('245'), findsOneWidget);
      expect(find.text('180'), findsOneWidget);
      expect(find.text('32'), findsOneWidget);
      expect(find.text('Followers'), findsOneWidget);
      expect(find.text('Following'), findsOneWidget);
      expect(find.text('Posts'), findsOneWidget);
    });

    testWidgets('stats are tappable and call their callbacks', (tester) async {
      var followersTapped = false;
      var postsTapped = false;
      await tester.pumpWidget(
        _wrap(
          ProfileStats(
            followers: 1,
            following: 2,
            posts: 3,
            onTapFollowers: () => followersTapped = true,
            onTapFollowing: () {},
            onTapPosts: () => postsTapped = true,
          ),
        ),
      );

      await tester.tap(find.text('Followers'));
      await tester.pumpAndSettle();
      expect(followersTapped, isTrue);

      await tester.tap(find.text('3'));
      await tester.pumpAndSettle();
      expect(postsTapped, isTrue);
    });
  });
}
