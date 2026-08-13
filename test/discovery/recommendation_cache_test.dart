import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:orientaa_mobile_app/widgets/discovery/models/university_models.dart';
import 'package:orientaa_mobile_app/widgets/discovery/services/recommendation_cache.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('RecommendationCache', () {
    test('round-trips a response per uid + filter key', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final cache = RecommendationCache(prefs: prefs);

      final response = RecommendationResponse(
        results: const [
          RecommendedProgram(
            universityId: 'u1',
            programId: 'p1',
            universityName: 'UCT',
            programName: 'CS',
            similarity: 0.9,
          ),
        ],
        hasMore: true,
      );

      await cache.save(uid: 'userA', filterKey: 'none', response: response);
      final loaded = await cache.load(uid: 'userA', filterKey: 'none');

      expect(loaded, isNotNull);
      expect(loaded!.results.length, 1);
      expect(loaded.results.first.universityName, 'UCT');
      expect(loaded.results.first.matchPercent, 90);
      expect(loaded.hasMore, isTrue);
    });

    test('returns null when nothing is cached', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final cache = RecommendationCache(prefs: prefs);
      expect(await cache.load(uid: 'userA', filterKey: 'none'), isNull);
    });

    test('scopes the cache per user', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final cache = RecommendationCache(prefs: prefs);

      await cache.save(
        uid: 'userA',
        filterKey: 'none',
        response: RecommendationResponse(results: const []),
      );
      expect(await cache.load(uid: 'userB', filterKey: 'none'), isNull);
    });

    test('scopes the cache per filter key', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final cache = RecommendationCache(prefs: prefs);

      await cache.save(
        uid: 'userA',
        filterKey: 'country=NG',
        response: RecommendationResponse(results: const []),
      );
      expect(await cache.load(uid: 'userA', filterKey: 'country=GH'), isNull);
    });
  });
}
