import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:orientaa_mobile_app/widgets/discovery/models/university_models.dart';
import 'package:orientaa_mobile_app/widgets/discovery/services/functions_client.dart';
import 'package:orientaa_mobile_app/widgets/discovery/services/recommendation_cache.dart';
import 'package:orientaa_mobile_app/widgets/discovery/services/recommendation_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('RecommendationService.fetchRecommendations', () {
    test('fetches and parses recommendations and caches the payload', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final client = FunctionsClient(invoker: (name, data) async {
        expect(name, RecommendationService.getRecommendationsFunction);
        expect(data['uid'], 'user1');
        return {
          'results': [
            {
              'universityId': 'u1',
              'programId': 'p1',
              'universityName': 'UCT',
              'programName': 'CS',
              'similarity': 0.9,
            },
          ],
          'hasMore': false,
        };
      });
      final service = RecommendationService(
        functions: client,
        cache: RecommendationCache(prefs: prefs),
      );

      final result = await service.fetchRecommendations(uid: 'user1');
      expect(result.fromCache, isFalse);
      expect(result.data.results.single.universityName, 'UCT');
      expect(result.data.results.single.matchPercent, 90);

      // The cache write is fire-and-forget — let it flush, then verify.
      await pumpEventQueue();
      final cached = await RecommendationCache(prefs: prefs).load(
        uid: 'user1',
        filterKey: RecommendationFilters.none.cacheKey,
      );
      expect(cached, isNotNull);
      expect(cached!.results.single.programId, 'p1');
    });

    test('passes filter params to the function', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final filters = const RecommendationFilters(
        countryCode: 'NG',
        degreeLevel: "Bachelor's",
        sort: SortOption.feeAscending,
        pageSize: 20,
      );
      final client = FunctionsClient(invoker: (name, data) async {
        expect(data['countryCode'], 'NG');
        expect(data['degreeLevel'], "Bachelor's");
        expect(data['sort'], 'fee_asc');
        return {'results': <Map<String, dynamic>>[]};
      });
      final service = RecommendationService(
        functions: client,
        cache: RecommendationCache(prefs: prefs),
      );

      final result = await service.fetchRecommendations(
        uid: 'user1',
        filters: filters,
      );
      expect(result.data.results, isEmpty);
      // cache is keyed by the filters so the dashboard fetch never collides
      await pumpEventQueue();
      final cached = await RecommendationCache(prefs: prefs)
          .load(uid: 'user1', filterKey: filters.cacheKey);
      expect(cached, isNotNull);
    });

    test('falls back to the cached payload when the function is unavailable',
        () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final cache = RecommendationCache(prefs: prefs);
      await cache.save(
        uid: 'user1',
        filterKey: RecommendationFilters.none.cacheKey,
        response: RecommendationResponse(
          results: const [
            RecommendedProgram(
              universityId: 'u1',
              programId: 'p1',
              universityName: 'Stellenbosch',
              programName: 'Law',
            ),
          ],
        ),
      );

      final client = FunctionsClient(invoker: (name, data) async {
        throw const FunctionCallException('unavailable', 'down');
      });
      final service = RecommendationService(functions: client, cache: cache);

      final result = await service.fetchRecommendations(uid: 'user1');
      expect(result.fromCache, isTrue);
      expect(result.data.results.single.universityName, 'Stellenbosch');
    });

    test('rethrows when the function fails and no cache exists', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final client = FunctionsClient(invoker: (name, data) async {
        throw const FunctionCallException('unavailable', 'down');
      });
      final service = RecommendationService(
        functions: client,
        cache: RecommendationCache(prefs: prefs),
      );

      await expectLater(
        service.fetchRecommendations(uid: 'user1'),
        throwsA(isA<FunctionCallException>()),
      );
    });
  });

  group('RecommendationService.explainRecommendation', () {
    test('returns a plain string sentence', () async {
      final client = FunctionsClient(invoker: (name, data) async {
        expect(name, RecommendationService.explainRecommendationFunction);
        expect(data['programId'], 'p1');
        return 'This university matches your budget and field of interest.';
      });
      final service = RecommendationService(
        functions: client,
        cache: RecommendationCache(),
      );

      final text = await service.explainRecommendation(uid: 'u1', programId: 'p1');
      expect(text, 'This university matches your budget and field of interest.');
    });

    test('returns the sentence from a map envelope', () async {
      final client = FunctionsClient(invoker: (name, data) async {
        return {'explanation': 'A strong fit for Computer Science.'};
      });
      final service = RecommendationService(
        functions: client,
        cache: RecommendationCache(),
      );

      expect(
        await service.explainRecommendation(uid: 'u1', programId: 'p1'),
        'A strong fit for Computer Science.',
      );
    });

    test('returns null when the function fails (bullet fallback)', () async {
      final client = FunctionsClient(invoker: (name, data) async {
        throw const FunctionCallException('unavailable', 'down');
      });
      final service = RecommendationService(
        functions: client,
        cache: RecommendationCache(),
      );

      expect(await service.explainRecommendation(uid: 'u1', programId: 'p1'),
          isNull);
    });
  });
}
