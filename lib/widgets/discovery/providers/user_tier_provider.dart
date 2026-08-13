import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../models/university_models.dart';

/// Global [ChangeNotifier] that exposes the signed-in user's subscription
/// tier. This is the single source of truth for every gate in the discovery
/// module — screens listen to it instead of re-fetching `subscription_tier`
/// individually.
///
/// Follows the app's existing pattern of global ChangeNotifier singletons
/// (see `themeProvider` / `localeProvider` in main.dart).
class UserTierProvider extends ChangeNotifier {
  UserTier _tier = UserTier.free;
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _sub;
  String? _watchedUid;

  /// Defaults to [UserTier.free] until the user document is read.
  UserTier get tier => _tier;

  bool get isFree => _tier == UserTier.free;
  bool get isAtLeastPro => _tier.isAtLeastPro;
  bool get isPremium => _tier.isPremium;

  /// Starts (or switches) a live subscription to `users/{uid}` so tier
  /// changes — e.g. an upgrade processed on another device — apply
  /// immediately without a manual refresh. Safe to call repeatedly.
  void watch(String uid) {
    if (_watchedUid == uid) return;
    _watchedUid = uid;
    _sub?.cancel();
    _sub = FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .snapshots()
        .listen(
      (snapshot) {
        final raw = snapshot.data()?['subscription_tier'] as String?;
        final parsed = UserTier.fromString(raw);
        if (parsed != _tier) {
          _tier = parsed;
          notifyListeners();
        }
      },
      onError: (Object e) {
        debugPrint('UserTierProvider: watch failed ($e)');
      },
    );
  }

  /// One-shot fetch of the tier (used before login state settles). Does not
  /// replace the stream.
  Future<void> refresh(String uid) async {
    try {
      final snap = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .get();
      final parsed =
          UserTier.fromString(snap.data()?['subscription_tier'] as String?);
      if (parsed != _tier) {
        _tier = parsed;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('UserTierProvider: refresh failed ($e)');
    }
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}

/// Global instance — import this wherever tier state is needed.
final UserTierProvider userTierProvider = UserTierProvider();
