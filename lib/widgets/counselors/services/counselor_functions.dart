import '../../discovery/services/functions_client.dart';
import '../models/counselor_models.dart';

/// Results of a createBooking / retryPayment call.
class PaymentInitResult {
  final String bookingId;
  final double feeAmount;
  final String currency;
  final String paymentLink;

  const PaymentInitResult({
    required this.bookingId,
    required this.feeAmount,
    required this.currency,
    required this.paymentLink,
  });
}

/// Thin wrappers around the counselors Cloud Functions.
///
/// Every payment-affecting state transition lives in Cloud Functions — this
/// client only *triggers* them. All datetimes cross the wire as ISO-8601
/// strings to keep callable serialization deterministic.
class CounselorFunctions {
  CounselorFunctions({FunctionsClient? client})
      : _client = client ?? FunctionsClient();

  final FunctionsClient _client;

  /// Generates 60-minute slot candidates for the counselor between
  /// [rangeStart] and [rangeEnd], excluding overlaps with existing
  /// non-cancelled bookings. Server-side only.
  Future<List<AvailableSlot>> getAvailableSlots({
    required String counselorUid,
    required DateTime rangeStart,
    required DateTime rangeEnd,
  }) async {
    final data = await _client.call('getAvailableSlots', {
      'counselorUid': counselorUid,
      'rangeStart': rangeStart.toIso8601String(),
      'rangeEnd': rangeEnd.toIso8601String(),
    });
    final slots = (data['slots'] as List?) ?? const [];
    return slots
        .whereType<Map>()
        .map((m) => AvailableSlot.fromJson(Map<String, dynamic>.from(m)))
        .toList();
  }

  /// Server-validates the slot, computes fee + commission and creates the
  /// booking in `payment_pending`, then initializes the Flutterwave payment
  /// and returns the hosted checkout link.
  Future<PaymentInitResult> createBooking({
    required String counselorUid,
    required DateTime scheduledStart,
  }) async {
    final data = await _client.call('createBooking', {
      'counselorUid': counselorUid,
      'scheduledStart': scheduledStart.toIso8601String(),
    });
    return PaymentInitResult(
      bookingId: data['bookingId'] as String,
      feeAmount: (data['feeAmount'] as num).toDouble(),
      currency: data['currency'] as String,
      paymentLink: data['paymentLink'] as String,
    );
  }

  /// Re-initializes payment for an existing `requested` booking whose slot
  /// is still free (retry after a failed/cancelled payment).
  Future<PaymentInitResult> retryPayment(String bookingId) async {
    final data = await _client.call('retryPayment', {'bookingId': bookingId});
    return PaymentInitResult(
      bookingId: bookingId,
      feeAmount: (data['feeAmount'] as num).toDouble(),
      currency: data['currency'] as String,
      paymentLink: data['paymentLink'] as String,
    );
  }

  /// Server-side verification fallback for when the webhook hasn't landed
  /// yet (the client "I've paid — check" button).
  Future<Map<String, dynamic>> verifyPayment(String bookingId) async {
    final data = await _client.call('verifyPayment', {'bookingId': bookingId});
    return Map<String, dynamic>.from(data as Map);
  }

  /// Releases a `payment_pending` booking back to `requested` so its slot
  /// frees up again (payment failed / user abandoned checkout).
  Future<void> cancelBooking(String bookingId) async {
    await _client.call('cancelBooking', {'bookingId': bookingId});
  }

  /// Sets `studentConfirmedAt` or `counselorConfirmedAt` depending on the
  /// caller; auto-pays out when both sides have confirmed.
  Future<void> confirmSession(String bookingId) async {
    await _client.call('confirmSession', {'bookingId': bookingId});
  }

  /// Writes `ratings/{bookingId}` and updates the counselor's
  /// ratingAverage/ratingCount inside a Firestore transaction.
  Future<void> submitRating({
    required String bookingId,
    required int stars,
    String reviewText = '',
  }) async {
    await _client.call('submitRating', {
      'bookingId': bookingId,
      'stars': stars,
      'reviewText': reviewText,
    });
  }

  /// Student reports a problem: status -> disputed, reason written to
  /// adminDisputeQueue for manual review.
  Future<void> raiseDispute({
    required String bookingId,
    required String reason,
  }) async {
    await _client.call('raiseDispute', {
      'bookingId': bookingId,
      'reason': reason,
    });
  }

  /// Admin-only: resolves a disputed booking to `paid_out` or `refunded`.
  Future<void> resolveDispute({
    required String bookingId,
    required String outcome,
  }) async {
    await _client.call('resolveDispute', {
      'bookingId': bookingId,
      'outcome': outcome,
    });
  }

  /// Counselor heartbeat: marks the counselor online + refreshes the
  /// recommended-score recency factor.
  Future<void> heartbeat() async {
    await _client.call('heartbeat', {});
  }

  /// Starts (or re-submits) counselor verification. `credentialUrl` is the
  /// Firebase Storage URL the client already uploaded; pass null on a
  /// resubmission that keeps the previously uploaded credential (the function
  /// then only moves `verificationStatus` back to `pending`).
  Future<void> submitVerification({String? credentialUrl}) async {
    await _client.call('submitVerification', {
      'credentialUrl': credentialUrl ?? '',
    });
  }

  /// Creates/updates the counselor's public profile fields + availability.
  /// `verificationStatus` can only be moved to `pending` by the owner.
  Future<void> saveProfile(Map<String, dynamic> profileFields) async {
    await _client.call('saveCounselorProfile', {
      'fields': profileFields,
    });
  }
}
