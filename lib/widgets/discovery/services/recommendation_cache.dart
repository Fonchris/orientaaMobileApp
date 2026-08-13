import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/university_models.dart';

/// SharedPreferences-backed offline cache for recommendation responses.
///
/// Firestore's built-in offline persistence covers document reads, but the
/// recommendation data comes from a Cloud Function, which has no offline
/// cache of its own. When the function is unreachable, screens fall back to
/// the last successful payload so the dashboard is never blank with no
/// connection. Keys are scoped per uid + filter combination.
class RecommendationCache {
  RecommendationCache({SharedPreferences? prefs}) : _prefs = prefs;

  SharedPreferences? _prefs;
  static const String _keyPrefix = 'recommendation_cache_v1:';

  Future<SharedPreferences> get _instance async =>
      _prefs ??= await SharedPreferences.getInstance();

  Future<void> save({
    required String uid,
    required String filterKey,
    required RecommendationResponse response,
  }) async {
    try {
      final prefs = await _instance;
      await prefs.setString(
        '$_keyPrefix$uid:$filterKey',
        jsonEncode(response.toJson()),
      );
    } catch (e) {
      // Cache writes must never break the main flow.
      debugPrint('RecommendationCache: failed to save ($e)');
    }
  }

  Future<RecommendationResponse?> load({
    required String uid,
    required String filterKey,
  }) async {
    try {
      final prefs = await _instance;
      final raw = prefs.getString('$_keyPrefix$uid:$filterKey');
      if (raw == null) return null;
      final decoded = jsonDecode(raw);
      return RecommendationResponse.fromJson(decoded);
    } catch (e) {
      debugPrint('RecommendationCache: failed to load ($e)');
      return null;
    }
  }
}
