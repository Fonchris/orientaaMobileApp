import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

/// Appends interaction events to `user_interactions/{uid}/events` for the
/// recommendation engine (views, saves, unsaves, searches, compares).
///
/// All writes are fire-and-forget: they are awaited by the caller when
/// convenient but must never block UI rendering or throw into the widget
/// tree — failures are logged and swallowed.
class UserInteractionsService {
  const UserInteractionsService();

  CollectionReference<Map<String, dynamic>> _events(String uid) =>
      FirebaseFirestore.instance
          .collection('user_interactions')
          .doc(uid)
          .collection('events');

  /// Logs one event. `type` follows the recommendation engine spec, e.g.
  /// `university_view`, `save`, `unsave`, `search`, `compare`.
  Future<void> log({
    required String uid,
    required String type,
    String? programId,
    String? universityId,
    Map<String, dynamic>? extra,
  }) async {
    if (uid.isEmpty) return;
    try {
      await _events(uid).add({
        'type': type,
        'programId': ?programId,
        'universityId': ?universityId,
        'timestamp': FieldValue.serverTimestamp(),
        'client': 'flutter',
        ...?extra,
      });
    } catch (e) {
      debugPrint('UserInteractionsService: failed to log "$type" ($e)');
    }
  }
}
