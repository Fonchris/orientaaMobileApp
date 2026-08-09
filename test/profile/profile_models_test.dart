import 'package:flutter_test/flutter_test.dart';

import 'package:orientaa_mobile_app/widgets/profile/profile_models.dart';

void main() {
  group('initialsFor', () {
    test('derives initials from a name', () {
      expect(initialsFor('Ada Lovelace'), 'AL');
      expect(initialsFor('Grace Hopper'), 'GH');
    });

    test('derives initials from an email', () {
      expect(initialsFor('ada.lovelace@example.com'), 'AL');
      expect(initialsFor('grace_hopper@example.com'), 'GH');
      expect(initialsFor('ada@example.com'), 'A');
    });

    test('falls back for empty input', () {
      expect(initialsFor(''), 'O');
      expect(initialsFor('   '), 'O');
    });
  });

  group('relativeTime', () {
    final now = DateTime(2026, 8, 9, 12, 0, 0);

    test('recent times', () {
      expect(relativeTime(now, now: now), 'Just now');
      expect(
        relativeTime(now.subtract(const Duration(minutes: 5)), now: now),
        '5m',
      );
      expect(
        relativeTime(now.subtract(const Duration(hours: 2)), now: now),
        '2h',
      );
      expect(
        relativeTime(now.subtract(const Duration(days: 3)), now: now),
        '3d',
      );
    });

    test('older times fall back to a date', () {
      final old = DateTime(2026, 1, 5);
      expect(relativeTime(old, now: now), '5/1/2026');
    });

    test('null time renders empty', () {
      expect(relativeTime(null), '');
    });
  });

  group('ProfileSettings', () {
    test('defaults are applied', () {
      const s = ProfileSettings();
      expect(s.notifyNewFollowers, isTrue);
      expect(s.language, 'English');
      expect(s.messagePrivacy, 'everyone');
      expect(s.showSavedUniversities, isTrue);
    });

    test('parses stored values with fallbacks', () {
      final s = ProfileSettings.fromMap(const {
        'notifyNewFollowers': false,
        'language': 'French',
        'messagePrivacy': 'followers',
        'showSavedUniversities': false,
      });
      expect(s.notifyNewFollowers, isFalse);
      expect(s.notifyMessages, isTrue); // default
      expect(s.language, 'French');
      expect(s.messagePrivacy, 'followers');
      expect(s.showSavedUniversities, isFalse);
    });

    test('copyWith updates only provided fields', () {
      const s = ProfileSettings();
      final updated = s.copyWith(
        notifyMessages: false,
        messagePrivacy: 'followers',
      );
      expect(updated.notifyMessages, isFalse);
      expect(updated.notifyNewFollowers, isTrue);
      expect(updated.messagePrivacy, 'followers');
      expect(updated.language, 'English');
    });

    test('round-trips through toMap', () {
      const s = ProfileSettings(messagePrivacy: 'followers');
      final parsed = ProfileSettings.fromMap(s.toMap());
      expect(parsed.messagePrivacy, 'followers');
      expect(parsed.language, s.language);
      expect(parsed.notifyBookingReminders, s.notifyBookingReminders);
    });
  });

  group('ProfileData', () {
    test('parses top-level fields and onboarding data', () {
      final p = ProfileData.fromMap(
        {
          'displayName': 'Ada Lovelace',
          'bio': 'Mathematician',
          'country': 'Nigeria',
          'city': 'Lagos',
          'role': 'counsellor',
          'isVerified': true,
          'followersCount': 12,
          'followingCount': 3,
          'postsCount': 4,
          'onboardingComplete': true,
          'onboardingData': {
            'educationLevel': "Bachelor's graduate",
            'desiredDegreeLevel': "Master's",
          },
          'settings': {'messagePrivacy': 'followers'},
        },
        uid: 'user1',
        email: 'ada@example.com',
      );
      expect(p.displayName, 'Ada Lovelace');
      expect(p.bio, 'Mathematician');
      expect(p.location, 'Lagos, Nigeria');
      expect(p.role, 'counsellor');
      expect(p.isVerified, isTrue);
      expect(p.followersCount, 12);
      expect(p.postsCount, 4);
      expect(p.onboardingComplete, isTrue);
      expect(p.onboardingData['educationLevel'], "Bachelor's graduate");
      expect(p.settings.messagePrivacy, 'followers');
      expect(p.isCounsellor, isTrue);
      expect(p.ownedBy('user1'), isTrue);
      expect(p.ownedBy('other'), isFalse);
    });

    test('derives display name and role fallback', () {
      final p = ProfileData.fromMap(
        const {},
        uid: 'user1',
        email: 'ada.lovelace@example.com',
      );
      expect(p.displayName, 'Ada Lovelace');
      expect(p.role, 'student');
      expect(p.location, isNull);
      expect(p.followersCount, 0);
    });

    test('initials come from the display name', () {
      final p = ProfileData.fromMap(
        {'displayName': 'Grace Hopper'},
        uid: 'u',
        email: 'g@example.com',
      );
      expect(p.initials, 'GH');
    });
  });
}
