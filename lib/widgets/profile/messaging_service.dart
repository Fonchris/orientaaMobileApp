import 'package:cloud_firestore/cloud_firestore.dart';

import 'profile_models.dart';
import 'profile_service.dart';

/// A 1:1 conversation document from the `conversations` collection.
class ConversationData {
  final String id;
  final List<String> participantIds;
  final Map<String, Map<String, dynamic>> participantProfiles;
  final String lastMessage;
  final DateTime? lastMessageAt;
  final String lastSenderId;
  final Map<String, int> unreadCounts;

  const ConversationData({
    required this.id,
    required this.participantIds,
    this.participantProfiles = const {},
    this.lastMessage = '',
    this.lastMessageAt,
    this.lastSenderId = '',
    this.unreadCounts = const {},
  });

  factory ConversationData.fromSnapshot(DocumentSnapshot<Map<String, dynamic>> s) {
    final d = s.data() ?? const <String, dynamic>{};
    final ts = d['lastMessageAt'] as Timestamp?;
    final profiles =
        (d['participantProfiles'] as Map<String, dynamic>?)
                ?.map((k, v) =>
                    MapEntry(k, Map<String, dynamic>.from(v as Map)))
                .cast<String, Map<String, dynamic>>() ??
            const {};
    final unread = (d['unreadCounts'] as Map<String, dynamic>?)
            ?.map((k, v) => MapEntry(k, (v as num).toInt()))
            .cast<String, int>() ??
        const {};
    return ConversationData(
      id: s.id,
      participantIds: (d['participantIds'] as List?)?.cast<String>() ?? const [],
      participantProfiles: profiles,
      lastMessage: d['lastMessage'] as String? ?? '',
      lastMessageAt: ts?.toDate(),
      lastSenderId: d['lastSenderId'] as String? ?? '',
      unreadCounts: unread,
    );
  }

  String? otherUid(String me) {
    for (final id in participantIds) {
      if (id != me) return id;
    }
    return null;
  }

  String otherName(String me, {String fallback = 'Orientaa user'}) {
    final uid = otherUid(me);
    if (uid == null) return fallback;
    return participantProfiles[uid]?['displayName'] as String? ?? fallback;
  }

  String? otherPhotoUrl(String me) {
    final uid = otherUid(me);
    if (uid == null) return null;
    return participantProfiles[uid]?['photoUrl'] as String?;
  }

  int unreadFor(String me) => unreadCounts[me] ?? 0;
}

/// A single message inside a conversation.
class ChatMessage {
  final String id;
  final String senderId;
  final String text;
  final DateTime? createdAt;

  const ChatMessage({
    required this.id,
    required this.senderId,
    required this.text,
    this.createdAt,
  });

  factory ChatMessage.fromSnapshot(DocumentSnapshot<Map<String, dynamic>> s) {
    final d = s.data() ?? const <String, dynamic>{};
    final ts = d['createdAt'] as Timestamp?;
    return ChatMessage(
      id: s.id,
      senderId: d['senderId'] as String? ?? '',
      text: d['text'] as String? ?? '',
      createdAt: ts?.toDate(),
    );
  }
}

/// Firestore data access for 1:1 conversations.
///
/// Conversation ids are a deterministic join of both participant uids, so
/// re-starting a chat never duplicates conversations.
class MessagingService {
  CollectionReference<Map<String, dynamic>> get _conversations =>
      FirebaseFirestore.instance.collection('conversations');

  Stream<List<ConversationData>> watchConversations(String uid) =>
      _conversations
          .where('participantIds', arrayContains: uid)
          .snapshots()
          .map((snap) {
            final list = snap.docs.map(ConversationData.fromSnapshot).toList();
            list.sort((a, b) {
              final at = a.lastMessageAt ?? DateTime.fromMillisecondsSinceEpoch(0);
              final bt = b.lastMessageAt ?? DateTime.fromMillisecondsSinceEpoch(0);
              return bt.compareTo(at);
            });
            return list;
          });

  Stream<List<ChatMessage>> watchMessages(String conversationId) =>
      _conversations
          .doc(conversationId)
          .collection('messages')
          .snapshots()
          .map((snap) {
            final list = snap.docs.map(ChatMessage.fromSnapshot).toList();
            list.sort((a, b) {
              final at = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
              final bt = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
              return at.compareTo(bt);
            });
            return list;
          });

  /// Returns the existing conversation id with [otherUid], or creates one.
  Future<String> ensureConversation({
    required String myUid,
    required String otherUid,
    required Map<String, dynamic> myProfile,
    required Map<String, dynamic> otherProfile,
  }) async {
    final existing = await _conversations
        .where('participantIds', arrayContains: myUid)
        .get();
    for (final doc in existing.docs) {
      final ids = (doc.data()['participantIds'] as List?)?.cast<String>();
      if (ids != null && ids.contains(otherUid)) return doc.id;
    }

    final ids = [myUid, otherUid]..sort();
    final conversationId = '${ids[0]}_${ids[1]}';
    await _conversations.doc(conversationId).set({
      'participantIds': [myUid, otherUid],
      'participantProfiles': {myUid: myProfile, otherUid: otherProfile},
      'lastMessage': '',
      'lastMessageAt': FieldValue.serverTimestamp(),
      'lastSenderId': '',
      'unreadCounts': {myUid: 0, otherUid: 0},
    });
    return conversationId;
  }

  Future<void> sendMessage({
    required String conversationId,
    required String senderId,
    required String recipientId,
    required String text,
  }) async {
    final messageRef = _conversations
        .doc(conversationId)
        .collection('messages')
        .doc();
    final batch = FirebaseFirestore.instance.batch();
    batch.set(messageRef, {
      'senderId': senderId,
      'text': text,
      'createdAt': FieldValue.serverTimestamp(),
    });
    batch.update(_conversations.doc(conversationId), {
      'lastMessage': text,
      'lastMessageAt': FieldValue.serverTimestamp(),
      'lastSenderId': senderId,
      'unreadCounts.$recipientId': FieldValue.increment(1),
      'unreadCounts.$senderId': 0,
    });
    await batch.commit();
  }

  Future<void> markRead(String conversationId, String uid) {
    return _conversations
        .doc(conversationId)
        .update({'unreadCounts.$uid': 0});
  }

  /// Respects the recipient's privacy setting: 'everyone' allows anyone,
  /// 'followers' requires the sender to follow the recipient.
  Future<bool> canMessage(String myUid, String otherUid) async {
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(otherUid)
        .get();
    final data = doc.data() ?? const <String, dynamic>{};
    final settings = ProfileSettings.fromMap(
      (data['settings'] as Map<String, dynamic>?) ?? const {},
    );
    if (settings.messagePrivacy != 'followers') return true;
    return ProfileService().isFollowing(myUid, otherUid);
  }
}
