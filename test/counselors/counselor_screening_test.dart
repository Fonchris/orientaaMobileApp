import 'package:flutter_test/flutter_test.dart';

import 'package:orientaa_mobile_app/widgets/counselors/models/counselor_models.dart';

void main() {
  group('SocialLinks', () {
    test('parses from map and exposes only non-empty entries', () {
      final links = SocialLinks.fromMap({
        'linkedin': 'https://linkedin.com/in/a',
        'x': '',
        'instagram': 'https://instagram.com/a',
        'tiktok': 'https://tiktok.com/@a',
      });
      expect(links.linkedin, 'https://linkedin.com/in/a');
      expect(links.hasAny, isTrue);
      expect(links.entries.map((e) => e.$1), ['linkedin', 'instagram', 'tiktok']);
      expect(links.entries.first.$2, 'https://linkedin.com/in/a');
      expect(links.toMap()['x'], '');
    });

    test('empty or null data has no links', () {
      expect(const SocialLinks().hasAny, isFalse);
      expect(SocialLinks.fromMap(null).entries, isEmpty);
      expect(SocialLinks.fromMap(const {}).hasAny, isFalse);
    });
  });

  group('CounselorApplication (AI screening)', () {
    CounselorApplication app({
      String status = '',
      List<String> issues = const [],
      DateTime? createdAt,
    }) =>
        CounselorApplication(
          profile: CounselorProfile(
            uid: 'c1',
            displayName: 'Amina Yusuf',
            createdAt: createdAt ?? DateTime(2026, 1, 1),
          ),
          private: {
            'aiScreeningResult': {'status': status, 'issues': issues},
          },
        );

    test('status getters map the stored screening result', () {
      expect(app(status: 'needs_attention').needsAttention, isTrue);
      expect(app(status: 'looks_complete').looksComplete, isTrue);
      expect(app(status: 'not_checked').aiNotChecked, isTrue);
      expect(app().aiNotChecked, isTrue); // never ran
      expect(
        app(status: 'needs_attention', issues: ['Blank document']).aiIssues,
        ['Blank document'],
      );
    });

    test('isOverdue only when AI-flagged AND pending past the 48h SLA', () {
      final now = DateTime(2026, 2, 1);
      final flaggedOld = app(
        status: 'needs_attention',
        createdAt: now.subtract(const Duration(hours: 60)),
      );
      final cleanOld = app(
        status: 'looks_complete',
        createdAt: now.subtract(const Duration(hours: 60)),
      );
      final flaggedRecent = app(
        status: 'needs_attention',
        createdAt: now.subtract(const Duration(hours: 1)),
      );

      expect(flaggedOld.isOverdue(now), isTrue);
      expect(cleanOld.isOverdue(now), isFalse);
      expect(flaggedRecent.isOverdue(now), isFalse);
      expect(flaggedOld.pendingOverSla(now), isTrue);
    });
  });
}
