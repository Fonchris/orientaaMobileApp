import 'package:cloud_firestore/cloud_firestore.dart';

import '../counselor_constants.dart';
import '../models/counselor_models.dart';

/// Sort options for the counselor directory.
enum CounselorSort {
  recommended,
  priceAsc,
  ratingDesc,
}

/// One paginated page of the directory: the profiles that matched the
/// filters plus the cursor into the source batch (`startAfter` for the next
/// page) and whether the source query has more documents.
class DirectoryPage {
  final List<CounselorProfile> profiles;
  final DocumentSnapshot<Map<String, dynamic>>? lastDoc;
  final bool hasMore;

  const DirectoryPage({
    required this.profiles,
    this.lastDoc,
    this.hasMore = false,
  });
}

/// Immutable filter state for the directory screen.
class CounselorFilters {
  final List<String> specialties;
  final List<String> languages;
  final bool onlineOnly;
  final double? minPrice;
  final double? maxPrice;
  final CounselorSort sort;

  const CounselorFilters({
    this.specialties = const [],
    this.languages = const [],
    this.onlineOnly = false,
    this.minPrice,
    this.maxPrice,
    this.sort = CounselorSort.recommended,
  });

  bool get isEmpty => specialties.isEmpty &&
      languages.isEmpty &&
      !onlineOnly &&
      minPrice == null &&
      maxPrice == null;

  CounselorFilters copyWith({
    List<String>? specialties,
    List<String>? languages,
    bool? onlineOnly,
    double? minPrice,
    double? maxPrice,
    CounselorSort? sort,
  }) {
    return CounselorFilters(
      specialties: specialties ?? this.specialties,
      languages: languages ?? this.languages,
      onlineOnly: onlineOnly ?? this.onlineOnly,
      minPrice: minPrice ?? this.minPrice,
      maxPrice: maxPrice ?? this.maxPrice,
      sort: sort ?? this.sort,
    );
  }

  CounselorFilters clear() => const CounselorFilters();
}

/// Firestore data access for the Counselors module.
///
/// Reads only — every state-changing action (booking, payment, confirm,
/// dispute, payout, rating aggregates) goes through Cloud Functions.
class CounselorService {
  static const String profilesCollection = 'counselorProfiles';
  static const String privateCollection = 'counselorPrivate';
  static const String bookingsCollection = 'bookings';
  static const String ratingsCollection = 'ratings';
  static const String disputesCollection = 'adminDisputeQueue';

  CollectionReference<Map<String, dynamic>> get _profiles =>
      FirebaseFirestore.instance.collection(profilesCollection);

  CollectionReference<Map<String, dynamic>> get _private =>
      FirebaseFirestore.instance.collection(privateCollection);

  CollectionReference<Map<String, dynamic>> get _bookings =>
      FirebaseFirestore.instance.collection(bookingsCollection);

  // ── Directory ──────────────────────────────────────────────────────────

  /// Builds the server-side directory query for [filters].
  ///
  /// Only the status + sort reach Firestore. The specialty/language/price/
  /// online filters are applied in memory (see [_matchesFilters]) so any
  /// combination of filters works without an exponential set of composite
  /// indexes. Name search is applied by the screen over the loaded profiles
  /// (true full-text search would need Algolia/Typesense or a function).
  Query<Map<String, dynamic>> directoryQuery(CounselorFilters filters) {
    return _profiles
        .where('verificationStatus', isEqualTo: 'approved')
        .orderBy(_sortField(filters.sort), descending: filters.sort != CounselorSort.priceAsc)
        .limit(directoryFetchBatchSize);
  }

  String _sortField(CounselorSort sort) {
    switch (sort) {
      case CounselorSort.recommended:
        // Weighted score maintained by the functions; falls back to rating.
        return 'recommendedScore';
      case CounselorSort.priceAsc:
        return 'hourlyRate';
      case CounselorSort.ratingDesc:
        return 'ratingAverage';
    }
  }

  /// Client-side filter matching (specialties overlap, first language,
  /// online-only, price range). Server ordering is preserved, so filtering a
  /// batch keeps global sort correctness for infinite scroll.
  bool _matchesFilters(CounselorProfile p, CounselorFilters f) {
    if (f.specialties.isNotEmpty &&
        !p.specialties.any((s) => f.specialties.contains(s))) {
      return false;
    }
    if (f.languages.isNotEmpty && !p.languages.contains(f.languages.first)) {
      return false;
    }
    if (f.onlineOnly && !p.isOnline) return false;
    if (f.minPrice != null && p.hourlyRate < f.minPrice!) return false;
    if (f.maxPrice != null && p.hourlyRate > f.maxPrice!) return false;
    return true;
  }

  /// Loads one directory page: fetches a source batch of
  /// [directoryFetchBatchSize] approved profiles ordered by the sort, keeps
  /// up to [directoryPageSize] that match the filters, and returns the
  /// cursor into the source batch so the next page continues from the right
  /// place. [hasMore] is true while the source query has more documents.
  Future<DirectoryPage> loadDirectoryPage(
    CounselorFilters filters, {
    DocumentSnapshot<Map<String, dynamic>>? startAfter,
  }) async {
    var query = directoryQuery(filters);
    if (startAfter != null) {
      query = query.startAfterDocument(startAfter);
    }
    final snap = await query.get();
    final docs = snap.docs;
    final matches = docs
        .map(CounselorProfile.fromSnapshot)
        .where((p) => _matchesFilters(p, filters))
        .take(directoryPageSize)
        .toList();
    return DirectoryPage(
      profiles: matches,
      lastDoc: docs.isEmpty ? null : docs.last,
      hasMore: docs.length == directoryFetchBatchSize,
    );
  }

  // ── Counselor profiles ─────────────────────────────────────────────────

  Stream<CounselorProfile?> watchProfile(String uid) =>
      _profiles.doc(uid).snapshots().map(
            (s) => s.exists ? CounselorProfile.fromSnapshot(s) : null,
          );

  /// Applications awaiting (or that failed) admin review, each carrying its
  /// owner/admin-only private doc (verification documents + AI screening
  /// result). Readable only by admins (rules). `needs_attention` applications
  /// are surfaced first, then newest-first — so flagged applications land at
  /// the top of the queue instead of being buried by recency.
  Stream<List<CounselorApplication>> watchApplications() => _profiles
      .where('verificationStatus', whereIn: ['pending', 'rejected'])
      .snapshots()
      .asyncMap((snap) async {
        final profiles = snap.docs.map(CounselorProfile.fromSnapshot).toList();
        final privateMap =
            await fetchPrivateProfiles(profiles.map((p) => p.uid).toList());
        final apps = profiles
            .map((p) =>
                CounselorApplication(profile: p, private: privateMap[p.uid]))
            .toList();
        final epoch = DateTime.fromMillisecondsSinceEpoch(0);
        apps.sort((a, b) {
          final aiA = a.needsAttention ? 0 : 1;
          final aiB = b.needsAttention ? 0 : 1;
          if (aiA != aiB) return aiA.compareTo(aiB);
          return (b.createdAt ?? epoch).compareTo(a.createdAt ?? epoch);
        });
        return apps;
      });

  Future<CounselorProfile?> fetchProfile(String uid) async {
    final s = await _profiles.doc(uid).get();
    return s.exists ? CounselorProfile.fromSnapshot(s) : null;
  }

  // ── Private per-counselor document (owner-only) ────────────────────────

  /// The `counselorPrivate/{uid}` document: credentials URL + Flutterwave
  /// payout target. Readable only by the owner (rules); used by the setup
  /// page to prefill payout details and show uploaded credentials.
  Future<Map<String, dynamic>?> fetchPrivateProfile(String uid) async {
    final s = await _private.doc(uid).get();
    return s.exists ? s.data() : null;
  }

  /// Batch fetch of private docs for a list of uids (admin screens: the
  /// application list needs each applicant's AI screening + documents).
  Future<Map<String, Map<String, dynamic>>> fetchPrivateProfiles(
      List<String> uids) async {
    final docs = await Future.wait(uids.map((u) => _private.doc(u).get()));
    final out = <String, Map<String, dynamic>>{};
    for (var i = 0; i < uids.length; i++) {
      final s = docs[i];
      if (s.exists) out[uids[i]] = s.data() ?? const {};
    }
    return out;
  }

  /// Loads the public profile + owner-only private document in one shot and
  /// unpacks the document URLs and payout target. This is the shared prefill
  /// for the onboarding wizard and the setup editor — both pages used to
  /// duplicate this exact Future.wait + parse block.
  Future<CounselorDraft> fetchCounselorDraft(String uid) async {
    final results = await Future.wait([
      fetchProfile(uid),
      fetchPrivateProfile(uid),
    ]);
    final profile = results[0] as CounselorProfile?;
    final private = results[1] as Map<String, dynamic>?;
    final privateData = private ?? const <String, dynamic>{};
    final payout =
        (privateData['payoutAccountDetails'] as Map?)?.cast<String, dynamic>() ??
            const <String, dynamic>{};
    return CounselorDraft(
      profile: profile,
      credentialsUrl: privateData['credentialsUrl'] as String?,
      idDocumentUrl: privateData['idDocumentUrl'] as String?,
      payoutProvider: (payout['provider'] as String?) ?? 'mobile_money',
      accountName: (payout['accountName'] as String?) ?? '',
      accountNumber: (payout['accountNumber'] as String?) ?? '',
    );
  }

  // ── Bookings ───────────────────────────────────────────────────────────

  Stream<Booking?> watchBooking(String bookingId) =>
      _bookings.doc(bookingId).snapshots().map(
            (s) => s.exists ? Booking.fromSnapshot(s) : null,
          );

  Future<Booking?> fetchBooking(String bookingId) async {
    final s = await _bookings.doc(bookingId).get();
    return s.exists ? Booking.fromSnapshot(s) : null;
  }

  /// All bookings for the signed-in user, newest first.
  Stream<List<Booking>> watchMyBookings(String uid, {bool counselor = false}) {
    return _bookings
        .where(counselor ? 'counselorUid' : 'studentUid', isEqualTo: uid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map(Booking.fromSnapshot).toList());
  }

  /// The single most relevant upcoming booking for the dashboard card.
  Stream<Booking?> watchNextBooking(String uid, {bool counselor = false}) {
    return _bookings
        .where(counselor ? 'counselorUid' : 'studentUid', isEqualTo: uid)
        .orderBy('scheduledStart', descending: false)
        .limit(5)
        .snapshots()
        .map((snap) {
          final bookings = snap.docs.map(Booking.fromSnapshot).toList();
          final now = DateTime.now();
          for (final b in bookings) {
            if (b.status.isActive && b.scheduledEnd.isAfter(now)) return b;
          }
          return bookings.isEmpty ? null : bookings.first;
        });
  }

  // ── Booking chat ───────────────────────────────────────────────────────

  Stream<List<BookingMessage>> watchBookingMessages(String bookingId) =>
      _bookings
          .doc(bookingId)
          .collection('messages')
          .orderBy('sentAt', descending: false)
          .snapshots()
          .map((snap) => snap.docs.map(BookingMessage.fromSnapshot).toList());

  /// Reference to a single booking chat message (for read receipts).
  DocumentReference<Map<String, dynamic>> bookingMessageRef(
    String bookingId,
    String messageId,
  ) =>
      _bookings.doc(bookingId).collection('messages').doc(messageId);

  /// Sends a session chat message. The Firestore rules re-validate that the
  /// sender is a participant and that the session window is open.
  Future<void> sendBookingMessage({
    required String bookingId,
    required String senderUid,
    required String text,
  }) async {
    await _bookings.doc(bookingId).collection('messages').add({
      'senderUid': senderUid,
      'text': text,
      'sentAt': FieldValue.serverTimestamp(),
    });
  }

  // ── Admin dispute queue (admin-only read via rules) ───────────────────

  /// Streams all dispute-queue entries, newest first. The Firestore rules
  /// only allow users with the `admin` custom claim to read this collection,
  /// so the admin screen surfaces the permission error for everyone else.
  Stream<List<DisputeEntry>> watchDisputes() =>
      FirebaseFirestore.instance
          .collection(disputesCollection)
          .orderBy('createdAt', descending: true)
          .snapshots()
          .map((snap) => snap.docs.map(DisputeEntry.fromSnapshot).toList());

  // ── Ratings / reviews ──────────────────────────────────────────────────

  /// Reviews for a counselor, newest first (only the reviewer's first name
  /// is displayed for privacy).
  Stream<List<CounselorRating>> watchRatings(String counselorUid) =>
      FirebaseFirestore.instance
          .collection(ratingsCollection)
          .where('counselorUid', isEqualTo: counselorUid)
          .orderBy('createdAt', descending: true)
          .snapshots()
          .map((snap) => snap.docs.map(CounselorRating.fromSnapshot).toList());

  /// One page of a counselor's reviews, newest first. Continue by passing
  /// [RatingsPage.lastDoc] as [startAfter].
  Future<RatingsPage> loadRatingsPage(
    String counselorUid, {
    int limit = 10,
    DocumentSnapshot<Map<String, dynamic>>? startAfter,
  }) async {
    var query = FirebaseFirestore.instance
        .collection(ratingsCollection)
        .where('counselorUid', isEqualTo: counselorUid)
        .orderBy('createdAt', descending: true)
        .limit(limit);
    if (startAfter != null) {
      query = query.startAfterDocument(startAfter);
    }
    final snap = await query.get();
    final docs = snap.docs;
    return RatingsPage(
      ratings: docs.map(CounselorRating.fromSnapshot).toList(),
      lastDoc: docs.isEmpty ? null : docs.last,
      hasMore: docs.length == limit,
    );
  }
}

/// One page of a counselor's reviews plus the pagination cursor.
class RatingsPage {
  final List<CounselorRating> ratings;
  final DocumentSnapshot<Map<String, dynamic>>? lastDoc;
  final bool hasMore;

  const RatingsPage({
    required this.ratings,
    this.lastDoc,
    this.hasMore = false,
  });
}
