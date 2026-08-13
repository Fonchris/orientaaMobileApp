import 'package:flutter_test/flutter_test.dart';

import 'package:orientaa_mobile_app/widgets/discovery/models/university_models.dart';

void main() {
  group('UserTier', () {
    test('parses stored values', () {
      expect(UserTier.fromString('free'), UserTier.free);
      expect(UserTier.fromString('pro'), UserTier.pro);
      expect(UserTier.fromString('premium'), UserTier.premium);
      expect(UserTier.fromString('PREMIUM'), UserTier.premium);
      expect(UserTier.fromString('  Pro  '), UserTier.pro);
      expect(UserTier.fromString(null), UserTier.free);
      expect(UserTier.fromString(''), UserTier.free);
      expect(UserTier.fromString('enterprise'), UserTier.free);
    });

    test('isAtLeastPro and isPremium', () {
      expect(UserTier.free.isAtLeastPro, isFalse);
      expect(UserTier.pro.isAtLeastPro, isTrue);
      expect(UserTier.premium.isAtLeastPro, isTrue);
      expect(UserTier.premium.isPremium, isTrue);
      expect(UserTier.pro.isPremium, isFalse);
    });
  });

  group('RecommendedProgram.fromJson', () {
    test('parses camelCase fields and normalizes 0-1 similarity', () {
      final p = RecommendedProgram.fromJson({
        'universityId': 'u1',
        'programId': 'p1',
        'universityName': 'Cape Town',
        'programName': 'CS',
        'country': 'South Africa',
        'countryCode': 'ZA',
        'fee': 12000,
        'currency': 'USD',
        'degreeLevel': "Bachelor's",
        'similarity': 0.92,
        'matchReasons': ['Within budget', 'Matches your field'],
        'lat': -33.9,
        'lng': 18.4,
      });
      expect(p.universityId, 'u1');
      expect(p.programId, 'p1');
      expect(p.universityName, 'Cape Town');
      expect(p.matchReasons, ['Within budget', 'Matches your field']);
      expect(p.matchPercent, 92);
      expect(p.latitude, -33.9);
      expect(p.longitude, 18.4);
    });

    test('parses snake_case keys and percentage similarity', () {
      final p = RecommendedProgram.fromJson({
        'university_id': 'u2',
        'programme_id': 'p2',
        'university_name': 'Makerere',
        'program_name': 'Medicine',
        'country_code': 'UG',
        'match_score': 87,
        'reasons': ['Affordable', 'Strong program'],
      });
      expect(p.universityId, 'u2');
      expect(p.programId, 'p2');
      expect(p.universityName, 'Makerere');
      expect(p.countryCode, 'UG');
      expect(p.matchPercent, 87);
    });

    test('handles missing fields gracefully', () {
      final p = RecommendedProgram.fromJson({'id': 'x'});
      expect(p.universityId, 'x');
      expect(p.programName, '');
      expect(p.matchPercent, isNull);
      expect(p.matchReasons, isEmpty);
    });

    test('clamps similarity to 0-100', () {
      final p = RecommendedProgram.fromJson({'similarity': 150});
      expect(p.matchPercent, 100);
    });
  });

  group('RecommendationResponse.fromJson', () {
    test('parses a bare list', () {
      final r = RecommendationResponse.fromJson([
        {'universityId': 'u1', 'programId': 'p1'},
        {'universityId': 'u2', 'programId': 'p2'},
      ]);
      expect(r.results.length, 2);
      expect(r.hasMore, isFalse);
    });

    test('parses results envelope with hasMore/cursor/total', () {
      final r = RecommendationResponse.fromJson({
        'results': [
          {'universityId': 'u1', 'programId': 'p1'},
        ],
        'hasMore': true,
        'nextCursor': 'abc',
        'total': 42,
      });
      expect(r.results.length, 1);
      expect(r.hasMore, isTrue);
      expect(r.cursor, 'abc');
      expect(r.total, 42);
    });

    test('accepts universities/items/data envelopes', () {
      for (final key in ['universities', 'items', 'data']) {
        final r = RecommendationResponse.fromJson({
          key: [
            {'universityId': 'u1', 'programId': 'p1'},
          ],
        });
        expect(r.results.length, 1, reason: 'envelope key: $key');
      }
    });

    test('drops items without ids', () {
      final r = RecommendationResponse.fromJson([
        {'universityId': 'u1', 'programId': 'p1'},
        {'random': 'x'},
      ]);
      expect(r.results.length, 1);
    });
  });

  group('RecommendationFilters', () {
    test('isEmpty reflects the default', () {
      expect(RecommendationFilters.none.isEmpty, isTrue);
      expect(const RecommendationFilters(countryCode: 'NG').isEmpty, isFalse);
    });

    test('toFunctionData includes all set values', () {
      final f = const RecommendationFilters(
        countryCode: 'NG',
        region: 'West Africa',
        degreeLevel: "Bachelor's",
        minFee: 1000,
        maxFee: 20000,
        currency: 'USD',
        fields: ['Computer Science', 'Engineering'],
        language: 'English',
        sort: SortOption.feeAscending,
        pageSize: 20,
      );
      final data = f.toFunctionData();
      expect(data['countryCode'], 'NG');
      expect(data['region'], 'West Africa');
      expect(data['minFee'], 1000);
      expect(data['fields'], ['Computer Science', 'Engineering']);
      expect(data['sort'], 'fee_asc');
      expect(data['pageSize'], 20);
    });

    test('copyWith clears flags', () {
      const f = RecommendationFilters(
        country: 'Nigeria',
        countryCode: 'NG',
        degreeLevel: 'PhD',
      );
      final cleared = f.copyWith(
        clearCountry: true,
        clearCountryCode: true,
        clearDegree: true,
      );
      expect(cleared.country, isNull);
      expect(cleared.countryCode, isNull);
      expect(cleared.degreeLevel, isNull);
    });

    test('cacheKey is deterministic and scoped to filters', () {
      const a = RecommendationFilters(countryCode: 'NG', fields: ['CS']);
      const b = RecommendationFilters(countryCode: 'NG', fields: ['CS']);
      const c = RecommendationFilters(countryCode: 'GH', fields: ['CS']);
      expect(a.cacheKey, b.cacheKey);
      expect(a.cacheKey, isNot(c.cacheKey));
      expect(RecommendationFilters.none.cacheKey, isNotEmpty);
    });
  });

  group('display helpers', () {
    test('flagEmojiFor maps ISO codes to flag emoji', () {
      expect(flagEmojiFor('NG'), '🇳🇬');
      expect(flagEmojiFor('za'), '🇿🇦');
      expect(flagEmojiFor(null), '🌍');
      expect(flagEmojiFor(''), '🌍');
      expect(flagEmojiFor('USA'), '🌍');
    });

    test('formatMoney formats fees with currency symbols', () {
      expect(formatMoney(12000, 'USD'), r'$12,000');
      expect(formatMoney(12000, 'NGN'), '₦12,000');
      expect(formatMoney(12000.5, 'USD'), r'$12,000.5');
      expect(formatMoney(100, null), '100');
      expect(formatMoney(null, 'USD'), '');
      expect(formatMoney(5000, 'XYZ'), '5,000 XYZ');
    });
  });
}
