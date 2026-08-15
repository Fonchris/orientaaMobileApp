/// Fixed business rules for the Counselors module, plus the small shared UI
/// helpers (initials, amount formatting) used across the counselor screens.
///
/// The business rules are deliberately hardcoded here (not user-configurable)
/// so they are trivial to change later. The Cloud Functions side keeps the
/// exact same values in `functions/src/config.ts` — keep the two in sync.
library;

/// Every session is exactly this long (minutes). The counselor's
/// `hourlyRate` field IS the per-session fee.
const int sessionDurationMinutes = 60;

/// Platform commission taken from the session fee at payout time. It is
/// deducted from the counselor's payout, never added on top of what the
/// student pays.
const double platformCommissionRate = 0.10;

/// If the student has neither confirmed nor disputed by this long after
/// `scheduledEnd`, the booking is auto-confirmed and paid out.
const Duration disputeAutoConfirmTimeout = Duration(hours: 48);

/// Push notification sent to the student this long after `scheduledEnd` if
/// they still haven't confirmed or disputed.
const Duration confirmReminderDelay = Duration(hours: 24);

/// Sessions transition to `completed` this long after `scheduledEnd`, even
/// if neither party marked it done. The client UI also blocks messaging
/// after this point.
const Duration sessionCompletionGrace = Duration(minutes: 30);

/// Chat unlocks this long before `scheduledStart` (and only when the
/// booking is `confirmed`).
const int chatUnlockLeadMinutes = 10;

/// "Session starts soon" push sent to both parties this long before the
/// start time.
const Duration preSessionReminderLead = Duration(minutes: 15);

/// Directory page size for infinite scroll.
const int directoryPageSize = 20;

/// Directory source batch: how many approved profiles are fetched from
/// Firestore per network request before the specialty/language/price/online
/// filters are applied in memory. Filtering client-side over a curated
/// marketplace avoids an explosion of composite indexes while keeping
/// infinite scroll correct.
const int directoryFetchBatchSize = 100;

/// How many days of availability the client asks the server to generate.
const int availabilityWindowDays = 14;

/// A counselor whose `lastActiveAt` is older than this is treated as
/// offline by the scheduled maintenance function.
const Duration onlineStaleAfter = Duration(minutes: 10);

/// Recommended-score recency decay: the recency bonus is halved every N
/// days since `lastActiveAt` (simple activity factor used by the
/// "Recommended" sort).
const int recommendedRecencyHalfLifeDays = 14;

/// Max bonus a perfectly-fresh counselor gets on top of their rating
/// (score = ratingAverage * (1 + bonus), bonus in [0, max]).
const double recommendedRecencyMaxBonus = 0.5;

/// Currency codes offered when a counselor sets up their profile.
const List<String> counselorCurrencies = [
  'NGN',
  'GHS',
  'KES',
  'ZAR',
  'UGX',
  'TZS',
  'RWF',
  'ETB',
  'MAD',
  'EGP',
  'XOF',
  'XAF',
  'USD',
  'EUR',
  'GBP',
];

/// Preset specialty tags offered in the counselor profile editor. Counselors
/// may add their own as well.
const List<String> counselorSpecialtyPresets = [
  'STEM guidance',
  'Scholarships',
  'Study abroad',
  'Career change',
  'University applications',
  'Visa & immigration',
  'Essay review',
  'Interview prep',
  'Financial aid',
  'Language tests (IELTS/TOEFL)',
];

/// Up-to-two-letter initials for an avatar, from the first two words of
/// [name]. Used by the directory cards, admin screens and the counselor
/// forms (previously each screen carried its own copy).
String counselorInitials(String name, {String fallback = 'O'}) {
  final raw = name.trim();
  if (raw.isEmpty) return fallback;
  final parts = raw.split(RegExp(r'\s+')).where((p) => p.isNotEmpty);
  final letters = parts.take(2).map((p) => p[0].toUpperCase()).join();
  return letters.isEmpty ? fallback : letters;
}

/// Compact amount formatting shared by every counselor screen: whole amounts
/// render without decimals, otherwise two places. Named `formatAmount` (not
/// `formatMoney`) to avoid clashing with the discovery module's
/// `formatMoney(amount, currency)` which adds currency symbols/thousands
/// separators.
String formatAmount(double amount) =>
    amount == amount.roundToDouble()
        ? amount.toStringAsFixed(0)
        : amount.toStringAsFixed(2);
