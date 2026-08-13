import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/university_models.dart';
import 'functions_client.dart';
import 'recommendation_cache.dart';

/// Data access for the recommendation engine.
///
/// Talks to the `getRecommendedUniversities` and `explainRecommendation`
/// Cloud Functions via [FunctionsClient], and transparently falls back to the
/// last-cached payload ([RecommendationCache]) when the function is
/// unreachable, so the dashboard is never blank offline.
class RecommendationService {
  RecommendationService({
    FunctionsClient? functions,
    RecommendationCache? cache,
  })  : _functions = functions ?? FunctionsClient(),
        _cache = cache ?? RecommendationCache();

  static const String getRecommendationsFunction =
      'getRecommendedUniversities';
  static const String explainRecommendationFunction = 'explainRecommendation';

  final FunctionsClient _functions;
  final RecommendationCache _cache;

  /// Fetches ranked recommendations for [uid], optionally scoped by
  /// [filters] (the paginated, filtered variant of the function).
  ///
  /// Returns a [RecommendationResult] describing both the data and its
  /// provenance (fresh / from cache) so the UI can show an offline notice.
  Future<RecommendationResult> fetchRecommendations({
    required String uid,
    RecommendationFilters filters = RecommendationFilters.none,
  }) async {
    final payload = <String, dynamic>{
      'uid': uid,
      ...filters.toFunctionData(),
    };

    try {
      final raw = await _functions.call(getRecommendationsFunction, payload);
      final response = RecommendationResponse.fromJson(raw);
      // Persist successful fetches for offline fallback — never fail the
      // call because the cache write failed.
      unawaited(
        _cache.save(uid: uid, filterKey: filters.cacheKey, response: response),
      );
      return RecommendationResult(data: response, fromCache: false);
    } on FunctionCallException catch (e) {
      debugPrint('RecommendationService: ${e.message}');
      final cached =
          await _cache.load(uid: uid, filterKey: filters.cacheKey);
      if (cached != null) {
        return RecommendationResult(data: cached, fromCache: true);
      }
      rethrow;
    }
  }

  /// Fetches a natural-language explanation for one match (Premium tier).
  /// Returns null when the function is unavailable — callers fall back to
  /// the bullet-point `match_reasons`.
  Future<String?> explainRecommendation({
    required String uid,
    required String programId,
    String? universityId,
  }) async {
    try {
      final raw = await _functions.call(explainRecommendationFunction, {
        'uid': uid,
        'programId': programId,
        'universityId': ?universityId,
      });
      if (raw is String && raw.trim().isNotEmpty) return raw.trim();
      if (raw is Map) {
        final text = raw['explanation'] ?? raw['sentence'] ?? raw['text'];
        if (text is String && text.trim().isNotEmpty) return text.trim();
      }
      return null;
    } catch (e) {
      debugPrint('RecommendationService: explain failed ($e)');
      return null;
    }
  }
}

/// A fetched recommendation payload plus its provenance.
class RecommendationResult {
  final RecommendationResponse data;
  final bool fromCache;

  const RecommendationResult({required this.data, required this.fromCache});
}
