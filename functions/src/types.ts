/**
 * Mirror of `counselorProfiles/{uid}` — the PUBLIC profile document that
 * students (and the owner) read. Sensitive fields (credentialsUrl,
 * payoutAccountDetails) deliberately do NOT live here; they live on the
 * private `counselorPrivate/{uid}` document (owner + admins only).
 */
export interface CounselorProfile {
  uid: string;
  displayName: string;
  /** Full legal name — used by the verification team, separate from displayName. */
  legalName?: string | null;
  photoUrl?: string | null;
  bio: string;
  specialties: string[];
  languages: string[];
  yearsOfExperience?: number | null;
  institution?: string | null;
  /** The session rate (sessions are fixed at 60 minutes). */
  hourlyRate: number;
  currency: string;
  verificationStatus: 'pending' | 'approved' | 'rejected';
  isOnline: boolean;
  lastActiveAt?: FirebaseFirestore.Timestamp | null;
  ratingAverage: number;
  ratingCount: number;
  availability: AvailabilityRule[];
  recommendedScore?: number | null;
  createdAt: FirebaseFirestore.Timestamp;
  updatedAt: FirebaseFirestore.Timestamp;
}

/** Mirror of `counselorPrivate/{uid}` (owner + admins only). */
export interface CounselorPrivateProfile {
  /** Firebase Storage URL of the qualification document — admin review only. */
  credentialsUrl?: string | null;
  /** Firebase Storage URL of the government-issued ID — admin review only. */
  idDocumentUrl?: string | null;
  /** Flutterwave payout target. */
  payoutAccountDetails?: PayoutAccountDetails | null;
  updatedAt?: FirebaseFirestore.Timestamp;
}

export interface AvailabilityRule {
  /** 1 = Monday … 7 = Sunday. */
  dayOfWeek: number;
  /** "09:00" */
  startTime: string;
  /** "17:00" */
  endTime: string;
}

/** Flutterwave payout target (mobile money / bank / card). */
export interface PayoutAccountDetails {
  provider: 'mobile_money' | 'bank_transfer' | 'card' | string;
  accountName?: string;
  accountNumber?: string;
  bankCode?: string;
}

export type BookingStatus =
  | 'requested'
  | 'payment_pending'
  | 'confirmed'
  | 'in_progress'
  | 'completed'
  | 'cancelled'
  | 'disputed'
  | 'refunded'
  | 'paid_out';

/** Mirror of `bookings/{bookingId}`. */
export interface Booking {
  studentUid: string;
  counselorUid: string;
  scheduledStart: FirebaseFirestore.Timestamp;
  /** Always scheduledStart + 60 minutes; computed server-side only. */
  scheduledEnd: FirebaseFirestore.Timestamp;
  feeAmount: number;
  currency: string;
  /** 10% of feeAmount, computed at booking creation. */
  platformCommission: number;
  /** feeAmount - platformCommission. */
  counselorPayoutAmount: number;
  status: BookingStatus;
  /** Flutterwave transaction id (set on webhook confirmation). */
  paymentReference?: string | null;
  paymentProvider?: string | null;
  /** Our own reference handed to Flutterwave: `booking_<id>`. */
  paymentTxRef?: string | null;
  createdAt: FirebaseFirestore.Timestamp;
  updatedAt: FirebaseFirestore.Timestamp;
  studentConfirmedAt?: FirebaseFirestore.Timestamp | null;
  counselorConfirmedAt?: FirebaseFirestore.Timestamp | null;
  /** scheduledEnd + 48h, set when the session completes. */
  autoConfirmDeadline?: FirebaseFirestore.Timestamp | null;
  /** Set when the 24h confirm-reminder notification fires. */
  reminderSentAt?: FirebaseFirestore.Timestamp | null;
  disputeReason?: string | null;
  /** Payout bookkeeping (guards against double transfers). */
  payoutState?: 'pending' | 'processing' | 'failed' | 'paid' | null;
  /** Dispute-resolution bookkeeping (guards against double refunds). */
  disputeResolutionState?: 'processing' | 'resolved' | null;
  payoutAttemptedAt?: FirebaseFirestore.Timestamp | null;
  payoutReference?: string | null;
  paidOutAt?: FirebaseFirestore.Timestamp | null;
}

export const BOOKING_STATUSES: BookingStatus[] = [
  'requested',
  'payment_pending',
  'confirmed',
  'in_progress',
  'completed',
  'cancelled',
  'disputed',
  'refunded',
  'paid_out',
];

/** A concrete bookable 60-minute window (server-generated). */
export interface AvailableSlot {
  start: string; // ISO-8601
  end: string; // ISO-8601
}
