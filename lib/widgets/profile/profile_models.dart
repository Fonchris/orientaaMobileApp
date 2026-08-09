import 'package:cloud_firestore/cloud_firestore.dart';

/// Immutable snapshot of the top-level fields on a `users/{uid}` document.
///
/// Parses both the profile fields written by [ProfileService] and the nested
/// `onboardingData` map written during the student onboarding flow, so the
/// Profile UI can surface academic info without touching onboarding internals.
class ProfileData {
  final String uid;
  final String email;
  final String displayName;
  final String? bio;
  final String? photoUrl;

  /// 'student' | 'counsellor'. Falls back to [fallbackRole] when the document
  /// does not yet carry a role (role is currently stored in SharedPreferences).
  final String role;
  final bool isVerified;
  final String? country;
  final String? city;
  final int followersCount;
  final int followingCount;
  final int postsCount;
  final bool onboardingComplete;
  final Map<String, dynamic> onboardingData;
  final ProfileSettings settings;

  const ProfileData({
    required this.uid,
    required this.email,
    required this.displayName,
    this.bio,
    this.photoUrl,
    required this.role,
    this.isVerified = false,
    this.country,
    this.city,
    this.followersCount = 0,
    this.followingCount = 0,
    this.postsCount = 0,
    this.onboardingComplete = false,
    this.onboardingData = const {},
    this.settings = const ProfileSettings(),
  });

  factory ProfileData.fromSnapshot(
    DocumentSnapshot<Map<String, dynamic>> snapshot, {
    required String email,
    String fallbackRole = 'student',
  }) {
    return ProfileData.fromMap(
      snapshot.data() ?? const <String, dynamic>{},
      uid: snapshot.id,
      email: email,
      fallbackRole: fallbackRole,
    );
  }

  factory ProfileData.fromMap(
    Map<String, dynamic> data, {
    required String uid,
    required String email,
    String fallbackRole = 'student',
  }) {
    final onboarding =
        (data['onboardingData'] as Map<String, dynamic>?) ?? const {};
    return ProfileData(
      uid: uid,
      email: email,
      displayName:
          (data['displayName'] as String?)?.trim().isNotEmpty == true
              ? data['displayName'] as String
              : _nameFromEmail(email),
      bio: data['bio'] as String?,
      photoUrl: data['photoUrl'] as String?,
      role: (data['role'] as String?) ?? fallbackRole,
      isVerified: data['isVerified'] == true,
      country: data['country'] as String?,
      city: data['city'] as String?,
      followersCount: (data['followersCount'] as num?)?.toInt() ?? 0,
      followingCount: (data['followingCount'] as num?)?.toInt() ?? 0,
      postsCount: (data['postsCount'] as num?)?.toInt() ?? 0,
      onboardingComplete: data['onboardingComplete'] == true,
      onboardingData: onboarding,
      settings: ProfileSettings.fromMap(
        (data['settings'] as Map<String, dynamic>?) ?? const {},
      ),
    );
  }

  /// True when the viewed profile belongs to the signed-in user.
  bool ownedBy(String? currentUid) => currentUid != null && uid == currentUid;

  bool get isCounsellor => role == 'counsellor';

  String? get location {
    if (city == null && country == null) return null;
    return [city, country]
        .whereType<String>()
        .where((s) => s.trim().isNotEmpty)
        .join(', ');
  }

  /// Derived initials used for the fallback avatar.
  String get initials => initialsFor(displayName.isNotEmpty ? displayName : email);
}

/// User preference settings persisted under `users/{uid}/settings`.
class ProfileSettings {
  final bool notifyNewFollowers;
  final bool notifyMessages;
  final bool notifyClassroomActivity;
  final bool notifyBookingReminders;
  final String language;

  /// 'everyone' | 'followers'
  final String messagePrivacy;
  final bool showSavedUniversities;

  const ProfileSettings({
    this.notifyNewFollowers = true,
    this.notifyMessages = true,
    this.notifyClassroomActivity = true,
    this.notifyBookingReminders = true,
    this.language = 'English',
    this.messagePrivacy = 'everyone',
    this.showSavedUniversities = true,
  });

  factory ProfileSettings.fromMap(Map<String, dynamic> map) {
    return ProfileSettings(
      notifyNewFollowers: map['notifyNewFollowers'] != false,
      notifyMessages: map['notifyMessages'] != false,
      notifyClassroomActivity: map['notifyClassroomActivity'] != false,
      notifyBookingReminders: map['notifyBookingReminders'] != false,
      language: (map['language'] as String?) ?? 'English',
      messagePrivacy: (map['messagePrivacy'] as String?) ?? 'everyone',
      showSavedUniversities: map['showSavedUniversities'] != false,
    );
  }

  ProfileSettings copyWith({
    bool? notifyNewFollowers,
    bool? notifyMessages,
    bool? notifyClassroomActivity,
    bool? notifyBookingReminders,
    String? language,
    String? messagePrivacy,
    bool? showSavedUniversities,
  }) {
    return ProfileSettings(
      notifyNewFollowers: notifyNewFollowers ?? this.notifyNewFollowers,
      notifyMessages: notifyMessages ?? this.notifyMessages,
      notifyClassroomActivity:
          notifyClassroomActivity ?? this.notifyClassroomActivity,
      notifyBookingReminders:
          notifyBookingReminders ?? this.notifyBookingReminders,
      language: language ?? this.language,
      messagePrivacy: messagePrivacy ?? this.messagePrivacy,
      showSavedUniversities: showSavedUniversities ?? this.showSavedUniversities,
    );
  }

  Map<String, dynamic> toMap() => {
        'notifyNewFollowers': notifyNewFollowers,
        'notifyMessages': notifyMessages,
        'notifyClassroomActivity': notifyClassroomActivity,
        'notifyBookingReminders': notifyBookingReminders,
        'language': language,
        'messagePrivacy': messagePrivacy,
        'showSavedUniversities': showSavedUniversities,
      };
}

/// A single post document from the `posts` collection.
class PostData {
  final String id;
  final String authorId;
  final String authorName;
  final String? authorPhotoUrl;
  final String content;
  final DateTime? createdAt;
  final int likesCount;
  final int commentsCount;
  final int repostsCount;
  final List<String> likedBy;

  const PostData({
    required this.id,
    required this.authorId,
    required this.authorName,
    this.authorPhotoUrl,
    required this.content,
    this.createdAt,
    this.likesCount = 0,
    this.commentsCount = 0,
    this.repostsCount = 0,
    this.likedBy = const [],
  });

  factory PostData.fromSnapshot(DocumentSnapshot<Map<String, dynamic>> s) {
    final d = s.data() ?? const <String, dynamic>{};
    final ts = d['createdAt'] as Timestamp?;
    return PostData(
      id: s.id,
      authorId: d['authorId'] as String? ?? '',
      authorName: d['authorName'] as String? ?? '',
      authorPhotoUrl: d['authorPhotoUrl'] as String?,
      content: d['content'] as String? ?? '',
      createdAt: ts?.toDate(),
      likesCount: (d['likesCount'] as num?)?.toInt() ?? 0,
      commentsCount: (d['commentsCount'] as num?)?.toInt() ?? 0,
      repostsCount: (d['repostsCount'] as num?)?.toInt() ?? 0,
      likedBy: (d['likedBy'] as List?)?.cast<String>() ?? const [],
    );
  }

  bool likedByUser(String uid) => likedBy.contains(uid);
}

/// A lightweight reference to a connected or searchable user.
class ConnectionUser {
  final String uid;
  final String displayName;
  final String? photoUrl;
  final String role;

  const ConnectionUser({
    required this.uid,
    required this.displayName,
    this.photoUrl,
    this.role = 'student',
  });

  factory ConnectionUser.fromSnapshot(DocumentSnapshot<Map<String, dynamic>> s) {
    final d = s.data() ?? const <String, dynamic>{};
    return ConnectionUser(
      uid: s.id,
      displayName: d['displayName'] as String? ?? 'Orientaa user',
      photoUrl: d['photoUrl'] as String?,
      role: d['role'] as String? ?? 'student',
    );
  }
}

/// A single notification document from `users/{uid}/notifications`.
class NotificationData {
  final String id;
  final String title;
  final String body;
  final DateTime? createdAt;
  final bool read;

  const NotificationData({
    required this.id,
    required this.title,
    required this.body,
    this.createdAt,
    this.read = false,
  });

  factory NotificationData.fromSnapshot(
    DocumentSnapshot<Map<String, dynamic>> s,
  ) {
    final d = s.data() ?? const <String, dynamic>{};
    final ts = d['createdAt'] as Timestamp?;
    return NotificationData(
      id: s.id,
      title: d['title'] as String? ?? 'Notification',
      body: d['body'] as String? ?? '',
      createdAt: ts?.toDate(),
      read: d['read'] == true,
    );
  }
}

/// Builds initials from a name or email, e.g. "Ada Lovelace" -> "AL".
String initialsFor(String nameOrEmail) {
  final raw = nameOrEmail.trim();
  if (raw.isEmpty) return 'O';
  if (raw.contains('@')) {
    final parts = raw.split('@').first.trim().split(RegExp(r'[._\- ]'));
    final letters = parts
        .where((p) => p.isNotEmpty)
        .take(2)
        .map((p) => p[0].toUpperCase())
        .join();
    return letters.isEmpty ? 'O' : letters;
  }
  final parts = raw.split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
  final letters = parts
      .take(2)
      .map((p) => p[0].toUpperCase())
      .join();
  return letters.isEmpty ? 'O' : letters;
}

String _nameFromEmail(String email) {
  final raw = email.trim();
  if (raw.isEmpty) return 'Orientaa explorer';
  final local = raw.split('@').first.trim();
  if (local.isEmpty) return 'Orientaa explorer';
  final words = local
      .split(RegExp(r'[._\- ]+'))
      .where((w) => w.isNotEmpty)
      .map((w) => w[0].toUpperCase() + w.substring(1))
      .toList();
  return words.isEmpty ? 'Orientaa explorer' : words.join(' ');
}

/// Compact, human-friendly relative time ("Just now", "5m", "2h", "3d").
String relativeTime(DateTime? time, {DateTime? now}) {
  if (time == null) return '';
  final current = now ?? DateTime.now();
  final diff = current.difference(time);
  if (diff.inSeconds < 45) return 'Just now';
  if (diff.inMinutes < 60) return '${diff.inMinutes}m';
  if (diff.inHours < 24) return '${diff.inHours}h';
  if (diff.inDays < 7) return '${diff.inDays}d';
  return '${time.day}/${time.month}/${time.year}';
}
