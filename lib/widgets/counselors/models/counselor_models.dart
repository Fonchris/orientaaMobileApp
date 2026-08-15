import 'package:cloud_firestore/cloud_firestore.dart';

import '../counselor_constants.dart';

/// Lifecycle of a `bookings/{bookingId}` document.
///
/// ```
/// requested -> payment_pending -> confirmed -> in_progress -> completed
///                                                          -> paid_out
///                                        \-> cancelled / disputed -> refunded
/// ```
enum BookingStatus {
  requested,
  paymentPending,
  confirmed,
  inProgress,
  completed,
  cancelled,
  disputed,
  refunded,
  paidOut;

  static BookingStatus fromString(String? raw) {
    switch (raw) {
      case 'requested':
        return BookingStatus.requested;
      case 'payment_pending':
        return BookingStatus.paymentPending;
      case 'confirmed':
        return BookingStatus.confirmed;
      case 'in_progress':
        return BookingStatus.inProgress;
      case 'completed':
        return BookingStatus.completed;
      case 'cancelled':
        return BookingStatus.cancelled;
      case 'disputed':
        return BookingStatus.disputed;
      case 'refunded':
        return BookingStatus.refunded;
      case 'paid_out':
        return BookingStatus.paidOut;
      default:
        return BookingStatus.requested;
    }
  }

  String get storageValue {
    switch (this) {
      case BookingStatus.requested:
        return 'requested';
      case BookingStatus.paymentPending:
        return 'payment_pending';
      case BookingStatus.confirmed:
        return 'confirmed';
      case BookingStatus.inProgress:
        return 'in_progress';
      case BookingStatus.completed:
        return 'completed';
      case BookingStatus.cancelled:
        return 'cancelled';
      case BookingStatus.disputed:
        return 'disputed';
      case BookingStatus.refunded:
        return 'refunded';
      case BookingStatus.paidOut:
        return 'paid_out';
    }
  }

  /// Statuses whose bookings occupy a calendar slot (excluded from
  /// getAvailableSlots). A `requested` booking has its slot released.
  bool get occupiesSlot => this == BookingStatus.paymentPending ||
      this == BookingStatus.confirmed ||
      this == BookingStatus.inProgress;

  /// Statuses where the session chat should be usable (rules enforce the
  /// time window too).
  bool get chatOpen => this == BookingStatus.confirmed ||
      this == BookingStatus.inProgress;

  bool get isActive =>
      this == BookingStatus.requested ||
      this == BookingStatus.paymentPending ||
      this == BookingStatus.confirmed ||
      this == BookingStatus.inProgress;
}

/// A single recurring availability rule from `counselorProfiles/{uid}`
/// (`availability: [{dayOfWeek, startTime, endTime}]`).
class AvailabilityRule {
  /// 1 = Monday … 7 = Sunday (matches Dart's [DateTime.weekday]).
  final int dayOfWeek;
  final String startTime; // "09:00"
  final String endTime; // "17:00"

  const AvailabilityRule({
    required this.dayOfWeek,
    required this.startTime,
    required this.endTime,
  });

  int get startMinutes {
    final parts = startTime.split(':');
    return (int.tryParse(parts[0]) ?? 0) * 60 +
        (parts.length > 1 ? (int.tryParse(parts[1]) ?? 0) : 0);
  }

  int get endMinutes {
    final parts = endTime.split(':');
    return (int.tryParse(parts[0]) ?? 0) * 60 +
        (parts.length > 1 ? (int.tryParse(parts[1]) ?? 0) : 0);
  }

  factory AvailabilityRule.fromMap(Map<String, dynamic> map) {
    return AvailabilityRule(
      dayOfWeek: (map['dayOfWeek'] as num?)?.toInt() ?? 1,
      startTime: map['startTime'] as String? ?? '09:00',
      endTime: map['endTime'] as String? ?? '17:00',
    );
  }

  Map<String, dynamic> toMap() => {
        'dayOfWeek': dayOfWeek,
        'startTime': startTime,
        'endTime': endTime,
      };
}

/// A concrete bookable 60-minute window returned by the
/// `getAvailableSlots` Cloud Function. Sent over the wire as ISO-8601
/// strings so callable serialization is deterministic.
class AvailableSlot {
  final DateTime start;
  final DateTime end;

  const AvailableSlot({required this.start, required this.end});

  factory AvailableSlot.fromJson(Map<String, dynamic> json) {
    return AvailableSlot(
      start: DateTime.parse(json['start'] as String),
      end: DateTime.parse(json['end'] as String),
    );
  }

  int get dayKey =>
      DateTime(start.year, start.month, start.day).millisecondsSinceEpoch;

  String get label12h {
    final h = start.hour % 12 == 0 ? 12 : start.hour % 12;
    final suffix = start.hour < 12 ? 'AM' : 'PM';
    final mm = start.minute.toString().padLeft(2, '0');
    return '$h:$mm $suffix';
  }
}

/// Snapshot of a `counselorProfiles/{uid}` document.
class CounselorProfile {
  final String uid;
  final String displayName;
  final String? photoUrl;
  final String bio;
  final List<String> specialties;
  final List<String> languages;
  final double hourlyRate;
  final String currency;
  final String? credentialsUrl;
  final String verificationStatus; // pending | approved | rejected
  final bool isOnline;
  final DateTime? lastActiveAt;
  final double ratingAverage;
  final int ratingCount;
  final List<AvailabilityRule> availability;
  final Map<String, dynamic> payoutAccountDetails;
  final double? recommendedScore;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const CounselorProfile({
    required this.uid,
    required this.displayName,
    this.photoUrl,
    this.bio = '',
    this.specialties = const [],
    this.languages = const [],
    this.hourlyRate = 0,
    this.currency = 'USD',
    this.credentialsUrl,
    this.verificationStatus = 'pending',
    this.isOnline = false,
    this.lastActiveAt,
    this.ratingAverage = 0,
    this.ratingCount = 0,
    this.availability = const [],
    this.payoutAccountDetails = const {},
    this.recommendedScore,
    this.createdAt,
    this.updatedAt,
  });

  bool get isApproved => verificationStatus == 'approved';
  bool get isVerified => isApproved;

  factory CounselorProfile.fromSnapshot(
    DocumentSnapshot<Map<String, dynamic>> s,
  ) {
    final d = s.data() ?? const <String, dynamic>{};
    return CounselorProfile.fromMap(d, uid: s.id);
  }

  factory CounselorProfile.fromMap(
    Map<String, dynamic> d, {
    required String uid,
  }) {
    return CounselorProfile(
      uid: uid,
      displayName: d['displayName'] as String? ?? 'Counselor',
      photoUrl: d['photoUrl'] as String?,
      bio: d['bio'] as String? ?? '',
      specialties: (d['specialties'] as List?)?.cast<String>() ?? const [],
      languages: (d['languages'] as List?)?.cast<String>() ?? const [],
      hourlyRate: (d['hourlyRate'] as num?)?.toDouble() ?? 0,
      currency: d['currency'] as String? ?? 'USD',
      credentialsUrl: d['credentialsUrl'] as String?,
      verificationStatus: d['verificationStatus'] as String? ?? 'pending',
      isOnline: d['isOnline'] == true,
      lastActiveAt: (d['lastActiveAt'] as Timestamp?)?.toDate(),
      ratingAverage: (d['ratingAverage'] as num?)?.toDouble() ?? 0,
      ratingCount: (d['ratingCount'] as num?)?.toInt() ?? 0,
      availability: ((d['availability'] as List?) ?? const [])
          .whereType<Map>()
          .map((m) => AvailabilityRule.fromMap(Map<String, dynamic>.from(m)))
          .toList(),
      payoutAccountDetails: (d['payoutAccountDetails'] as Map?)?.cast<String, dynamic>() ??
          const {},
      recommendedScore: (d['recommendedScore'] as num?)?.toDouble(),
      createdAt: (d['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (d['updatedAt'] as Timestamp?)?.toDate(),
    );
  }
}

/// Snapshot of a `bookings/{bookingId}` document.
class Booking {
  final String id;
  final String studentUid;
  final String counselorUid;
  final DateTime scheduledStart;
  final DateTime scheduledEnd;
  final double feeAmount;
  final String currency;
  final double platformCommission;
  final double counselorPayoutAmount;
  final BookingStatus status;
  final String? paymentReference;
  final String? paymentProvider;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? studentConfirmedAt;
  final DateTime? counselorConfirmedAt;
  final DateTime? autoConfirmDeadline;
  final DateTime? reminderSentAt;
  final String? disputeReason;

  const Booking({
    required this.id,
    required this.studentUid,
    required this.counselorUid,
    required this.scheduledStart,
    required this.scheduledEnd,
    required this.feeAmount,
    required this.currency,
    required this.platformCommission,
    required this.counselorPayoutAmount,
    required this.status,
    this.paymentReference,
    this.paymentProvider,
    this.createdAt,
    this.updatedAt,
    this.studentConfirmedAt,
    this.counselorConfirmedAt,
    this.autoConfirmDeadline,
    this.reminderSentAt,
    this.disputeReason,
  });

  bool get isStudent => studentUid.isNotEmpty;

  bool isParticipant(String uid) =>
      uid == studentUid || uid == counselorUid;

  /// The chat may open within [chatUnlockLeadMinutes] before start while
  /// the booking is confirmed/in_progress.
  bool chatOpenAt(DateTime now) {
    if (!status.chatOpen) return false;
    final unlockAt = scheduledStart.subtract(
      const Duration(minutes: chatUnlockLeadMinutes),
    );
    return !now.isBefore(unlockAt);
  }

  bool get bothConfirmed =>
      studentConfirmedAt != null && counselorConfirmedAt != null;

  factory Booking.fromSnapshot(
    DocumentSnapshot<Map<String, dynamic>> s,
  ) {
    final d = s.data() ?? const <String, dynamic>{};
    return Booking.fromMap(d, id: s.id);
  }

  factory Booking.fromMap(Map<String, dynamic> d, {required String id}) {
    return Booking(
      id: id,
      studentUid: d['studentUid'] as String? ?? '',
      counselorUid: d['counselorUid'] as String? ?? '',
      scheduledStart: (d['scheduledStart'] as Timestamp?)?.toDate() ??
          DateTime.fromMillisecondsSinceEpoch(0),
      scheduledEnd: (d['scheduledEnd'] as Timestamp?)?.toDate() ??
          DateTime.fromMillisecondsSinceEpoch(0),
      feeAmount: (d['feeAmount'] as num?)?.toDouble() ?? 0,
      currency: d['currency'] as String? ?? 'USD',
      platformCommission: (d['platformCommission'] as num?)?.toDouble() ?? 0,
      counselorPayoutAmount:
          (d['counselorPayoutAmount'] as num?)?.toDouble() ?? 0,
      status: BookingStatus.fromString(d['status'] as String?),
      paymentReference: d['paymentReference'] as String?,
      paymentProvider: d['paymentProvider'] as String?,
      createdAt: (d['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (d['updatedAt'] as Timestamp?)?.toDate(),
      studentConfirmedAt: (d['studentConfirmedAt'] as Timestamp?)?.toDate(),
      counselorConfirmedAt:
          (d['counselorConfirmedAt'] as Timestamp?)?.toDate(),
      autoConfirmDeadline: (d['autoConfirmDeadline'] as Timestamp?)?.toDate(),
      reminderSentAt: (d['reminderSentAt'] as Timestamp?)?.toDate(),
      disputeReason: d['disputeReason'] as String?,
    );
  }
}

/// A single message from `bookings/{bookingId}/messages/{messageId}`.
class BookingMessage {
  final String id;
  final String senderUid;
  final String text;
  final DateTime? sentAt;
  final DateTime? readAt;

  const BookingMessage({
    required this.id,
    required this.senderUid,
    required this.text,
    this.sentAt,
    this.readAt,
  });

  factory BookingMessage.fromSnapshot(
    DocumentSnapshot<Map<String, dynamic>> s,
  ) {
    final d = s.data() ?? const <String, dynamic>{};
    return BookingMessage(
      id: s.id,
      senderUid: d['senderUid'] as String? ?? '',
      text: d['text'] as String? ?? '',
      sentAt: (d['sentAt'] as Timestamp?)?.toDate(),
      readAt: (d['readAt'] as Timestamp?)?.toDate(),
    );
  }
}

/// A row from `adminDisputeQueue/{bookingId}` (admin-only read).
class DisputeEntry {
  final String bookingId;
  final String studentUid;
  final String studentName;
  final String counselorUid;
  final String counselorName;
  final String? counselorPhotoUrl;
  final DateTime? scheduledStart;
  final double feeAmount;
  final String currency;
  final String reason;
  final String status; // open | resolved_paid_out | resolved_refunded
  final DateTime? createdAt;

  const DisputeEntry({
    required this.bookingId,
    required this.studentUid,
    required this.studentName,
    required this.counselorUid,
    required this.counselorName,
    this.counselorPhotoUrl,
    this.scheduledStart,
    this.feeAmount = 0,
    this.currency = 'USD',
    this.reason = '',
    this.status = 'open',
    this.createdAt,
  });

  bool get isOpen => status == 'open';
  bool get resolvedAsPaidOut => status == 'resolved_paid_out';
  bool get resolvedAsRefunded => status == 'resolved_refunded';

  factory DisputeEntry.fromSnapshot(
    DocumentSnapshot<Map<String, dynamic>> s,
  ) {
    final d = s.data() ?? const <String, dynamic>{};
    return DisputeEntry(
      bookingId: s.id,
      studentUid: d['studentUid'] as String? ?? '',
      studentName: d['studentName'] as String? ?? 'Student',
      counselorUid: d['counselorUid'] as String? ?? '',
      counselorName: d['counselorName'] as String? ?? 'Counselor',
      counselorPhotoUrl: d['counselorPhotoUrl'] as String?,
      scheduledStart: (d['scheduledStart'] as Timestamp?)?.toDate(),
      feeAmount: (d['feeAmount'] as num?)?.toDouble() ?? 0,
      currency: d['currency'] as String? ?? 'USD',
      reason: d['reason'] as String? ?? '',
      status: d['status'] as String? ?? 'open',
      createdAt: (d['createdAt'] as Timestamp?)?.toDate(),
    );
  }
}

/// A rating from `ratings/{bookingId}`.
class CounselorRating {
  final String bookingId;
  final String studentUid;
  final String counselorUid;
  final int stars;
  final String reviewText;
  final DateTime? createdAt;
  final String studentFirstName;

  const CounselorRating({
    required this.bookingId,
    required this.studentUid,
    required this.counselorUid,
    required this.stars,
    this.reviewText = '',
    this.createdAt,
    this.studentFirstName = '',
  });

  factory CounselorRating.fromSnapshot(
    DocumentSnapshot<Map<String, dynamic>> s, {
    String studentFirstName = '',
  }) {
    final d = s.data() ?? const <String, dynamic>{};
    return CounselorRating(
      bookingId: s.id,
      studentUid: d['studentUid'] as String? ?? '',
      counselorUid: d['counselorUid'] as String? ?? '',
      stars: (d['stars'] as num?)?.toInt() ?? 0,
      reviewText: d['reviewText'] as String? ?? '',
      createdAt: (d['createdAt'] as Timestamp?)?.toDate(),
      // Stored by the submitRating function so reviews never require a
      // second lookup; only the first name is kept for privacy.
      studentFirstName:
          (d['studentFirstName'] as String?)?.trim().isNotEmpty == true
              ? d['studentFirstName'] as String
              : studentFirstName,
    );
  }
}
