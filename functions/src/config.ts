/**
 * Fixed business rules for the Counselors module.
 *
 * These MUST stay in sync with `lib/widgets/counselors/counselor_constants.dart`
 * on the Flutter side (the client mirrors the same values for UI display).
 */
export const SESSION_DURATION_MIN = 60;
export const PLATFORM_COMMISSION_RATE = 0.1;
export const AUTO_CONFIRM_TIMEOUT_HOURS = 48;
export const CONFIRM_REMINDER_DELAY_HOURS = 24;
export const SESSION_COMPLETION_GRACE_MIN = 30;
export const PRE_SESSION_REMINDER_MIN = 15;
export const ONLINE_STALE_AFTER_MIN = 10;

/** Booking statuses that occupy a calendar slot. */
export const SLOT_OCCUPYING_STATUSES = [
  'payment_pending',
  'confirmed',
  'in_progress',
];

export const MIN_RATING = 1;
export const MAX_RATING = 5;

// ── Environment (set in Firebase project settings -> service accounts) ───

function requiredEnv(name: string): string {
  const value = process.env[name];
  if (!value || value.trim().length === 0) {
    throw new Error(`Missing required environment variable: ${name}`);
  }
  return value;
}

export const env = {
  get flutterwaveSecretKey() {
    return requiredEnv('FLUTTERWAVE_SECRET_KEY');
  },
  get flutterwaveWebhookHash() {
    return requiredEnv('FLUTTERWAVE_WEBHOOK_HASH');
  },
  get flutterwaveBaseUrl() {
    return process.env.FLUTTERWAVE_BASE_URL ?? 'https://api.flutterwave.com/v3';
  },
};
