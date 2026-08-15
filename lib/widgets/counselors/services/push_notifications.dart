import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

/// Initializes Firebase Cloud Messaging for push notifications.
///
/// The device token is stored on `users/{uid}/devices/main` (with a
/// timestamp) — an owner-only subcollection — because the `users/{uid}`
/// document itself is readable by every signed-in user for search and
/// connections, and a device token must never be exposed to other users.
/// The Cloud Functions that send booking/payment/session notifications read
/// the token from there. A [onForeground] callback lets the app show in-app
/// alerts when a notification arrives while the app is open.
class PushNotifications {
  PushNotifications._();

  static final PushNotifications instance = PushNotifications._();

  /// Handles a push notification received while the app is in the
  /// foreground (system trays don't show foreground messages on Android).
  void Function(Map<String, dynamic> message)? onForeground;

  Future<void> init() async {
    final messaging = FirebaseMessaging.instance;
    await messaging.requestPermission();

    await _syncToken(await messaging.getToken());
    FirebaseMessaging.instance.onTokenRefresh.listen((token) => _syncToken(token));

    FirebaseMessaging.onMessage.listen((message) {
      onForeground?.call(message.data);
    });
  }

  Future<void> _syncToken(String? token) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (token == null || uid == null) return;
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('devices')
          .doc('main')
          .set({
            'fcmToken': token,
            'fcmTokenUpdatedAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));
    } catch (_) {
      // Token sync is best-effort; notifications simply won't arrive until
      // the next refresh.
    }
  }
}
