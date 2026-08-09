import 'package:cloud_firestore/cloud_firestore.dart';

import 'profile_models.dart';

/// Firestore data access for profiles, connections, posts and notifications.
///
/// Follows the existing app convention of reading `users/{uid}` directly;
/// this service centralises the queries so UI widgets stay thin. No data is
/// fabricated here — empty/missing collections simply stream empty lists.
class ProfileService {
  CollectionReference<Map<String, dynamic>> get _users =>
      FirebaseFirestore.instance.collection('users');

  CollectionReference<Map<String, dynamic>> get _posts =>
      FirebaseFirestore.instance.collection('posts');

  // ── Profile ─────────────────────────────────────────────────────────────

  Stream<DocumentSnapshot<Map<String, dynamic>>> watchUser(String uid) =>
      _users.doc(uid).snapshots();

  Future<DocumentSnapshot<Map<String, dynamic>>> fetchUser(String uid) =>
      _users.doc(uid).get();

  /// Merges the given top-level fields into `users/{uid}` without touching
  /// `onboardingData`. Dotted keys update nested onboarding fields.
  Future<void> saveProfileFields(
    String uid,
    Map<String, dynamic> fields,
  ) {
    return _users.doc(uid).set(fields, SetOptions(merge: true));
  }

  Future<void> saveSettings(String uid, ProfileSettings settings) {
    return _users
        .doc(uid)
        .set({'settings': settings.toMap()}, SetOptions(merge: true));
  }

  // ── Followers / Following ──────────────────────────────────────────────

  Future<void> follow({
    required String targetUid,
    required String myUid,
    required String myName,
    String? myPhotoUrl,
  }) async {
    final batch = FirebaseFirestore.instance.batch();
    batch.set(
      _users.doc(targetUid).collection('followers').doc(myUid),
      {
        'uid': myUid,
        'displayName': myName,
        'photoUrl': myPhotoUrl,
        'followedAt': FieldValue.serverTimestamp(),
      },
    );
    batch.set(
      _users.doc(myUid).collection('following').doc(targetUid),
      {
        'uid': targetUid,
        'followedAt': FieldValue.serverTimestamp(),
      },
    );
    batch.update(_users.doc(targetUid), {
      'followersCount': FieldValue.increment(1),
    });
    batch.update(_users.doc(myUid), {
      'followingCount': FieldValue.increment(1),
    });
    await batch.commit();
  }

  Future<void> unfollow({
    required String targetUid,
    required String myUid,
  }) async {
    final batch = FirebaseFirestore.instance.batch();
    batch.delete(_users.doc(targetUid).collection('followers').doc(myUid));
    batch.delete(_users.doc(myUid).collection('following').doc(targetUid));
    batch.update(_users.doc(targetUid), {
      'followersCount': FieldValue.increment(-1),
    });
    batch.update(_users.doc(myUid), {
      'followingCount': FieldValue.increment(-1),
    });
    await batch.commit();
  }

  Future<bool> isFollowing(String myUid, String targetUid) async {
    final doc = await _users
        .doc(myUid)
        .collection('following')
        .doc(targetUid)
        .get();
    return doc.exists;
  }

  Stream<List<ConnectionUser>> watchFollowers(String uid) =>
      _users
          .doc(uid)
          .collection('followers')
          .snapshots()
          .map((snap) =>
              snap.docs.map(ConnectionUser.fromSnapshot).toList());

  Stream<List<ConnectionUser>> watchFollowing(String uid) =>
      _users
          .doc(uid)
          .collection('following')
          .snapshots()
          .map((snap) =>
              snap.docs.map(ConnectionUser.fromSnapshot).toList());

  // ── Posts ──────────────────────────────────────────────────────────────

  /// Streams a user's posts, newest first (sorted client-side so no composite
  /// Firestore index is required).
  Stream<List<PostData>> watchPosts(String uid) => _posts
      .where('authorId', isEqualTo: uid)
      .snapshots()
      .map((snap) {
        final posts = snap.docs.map(PostData.fromSnapshot).toList();
        posts.sort((a, b) {
          final at = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
          final bt = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
          return bt.compareTo(at);
        });
        return posts;
      });

  Future<void> likePost(String postId, String uid, {required bool liked}) {
    return _posts.doc(postId).update({
      'likedBy': liked
          ? FieldValue.arrayUnion([uid])
          : FieldValue.arrayRemove([uid]),
      'likesCount': FieldValue.increment(liked ? 1 : -1),
    });
  }

  /// Deletes a post and decrements the author's `postsCount` in one batch.
  Future<void> deletePost(String postId) async {
    final snap = await _posts.doc(postId).get();
    final batch = FirebaseFirestore.instance.batch();
    batch.delete(_posts.doc(postId));
    final authorId = snap.data()?['authorId'] as String?;
    if (authorId != null && authorId.isNotEmpty) {
      batch.update(_users.doc(authorId), {
        'postsCount': FieldValue.increment(-1),
      });
    }
    await batch.commit();
  }

  Future<void> updatePost(String postId, String content) =>
      _posts.doc(postId).update({'content': content});

  // ── Notifications ──────────────────────────────────────────────────────

  Stream<List<NotificationData>> watchNotifications(String uid) =>
      _users
          .doc(uid)
          .collection('notifications')
          .snapshots()
          .map((snap) {
            final items = snap.docs.map(NotificationData.fromSnapshot).toList();
            items.sort((a, b) {
              final at = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
              final bt = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
              return bt.compareTo(at);
            });
            return items;
          });

  Future<void> markNotificationsRead(String uid) async {
    final snap = await _users
        .doc(uid)
        .collection('notifications')
        .where('read', isEqualTo: false)
        .get();
    final batch = FirebaseFirestore.instance.batch();
    for (final doc in snap.docs) {
      batch.update(doc.reference, {'read': true});
    }
    await batch.commit();
  }
}
