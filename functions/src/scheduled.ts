import * as admin from 'firebase-admin';
import * as functions from 'firebase-functions';

import {
  AUTO_CONFIRM_TIMEOUT_HOURS,
  CONFIRM_REMINDER_DELAY_HOURS,
  SESSION_COMPLETION_GRACE_MIN,
} from './config';
import { initiateTransfer } from './flutterwave';
import { markStaleOffline } from './counselor';
import { notifyBothParties, notifyUser } from './notifications';
import { Booking } from './types';

const db = admin.firestore();

async function getBooking(bookingId: string): Promise<Booking | null> {
  const snap = await db.collection('bookings').doc(bookingId).get();
  return snap.exists ? (snap.data() as Booking) : null;
}

/**
 * Transitions confirmed/in_progress sessions to 'completed' once
 * scheduledEnd + 30 min grace has passed, and stamps autoConfirmDeadline =
 * scheduledEnd + 48h at that same moment (spec: 48 hours after scheduledEnd).
 */
export const completeSessions = functions.scheduler.onSchedule(
  { schedule: 'every 5 minutes', timeZone: 'UTC' },
  async () => {
    const now = admin.firestore.Timestamp.now();
    const graceAgo = new Date(now.toMillis() - SESSION_COMPLETION_GRACE_MIN * 60000);

    const upcoming = await db
      .collection('bookings')
      .where('scheduledEnd', '<=', graceAgo)
      .where('status', 'in', ['confirmed', 'in_progress'])
      .get();

    let completed = 0;
    await Promise.all(
      upcoming.docs.map(async (doc) => {
        const b = doc.data() as Booking;
        const deadline = new Date(b.scheduledEnd.toMillis() + AUTO_CONFIRM_TIMEOUT_HOURS * 3600000);
        await doc.ref.update({
          status: 'completed',
          autoConfirmDeadline: deadline,
          updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        });
        await notifyBothParties(
          b,
          'Session ended',
          'Please confirm the session happened so the counselor can be paid.',
          { type: 'session_completed', bookingId: doc.id },
        );
        completed += 1;
      }),
    );
    console.log(`completeSessions: ${completed} session(s) completed.`);
  },
);

/**
 * Hourly reminder: for completed bookings where scheduledEnd + 24h has
 * passed, the student still hasn't confirmed, the booking isn't disputed and
 * no reminder was sent yet — nudge the student to confirm or report.
 */
export const sendConfirmReminders = functions.scheduler.onSchedule(
  { schedule: 'every 1 hour', timeZone: 'UTC' },
  async () => {
    const now = admin.firestore.Timestamp.now();
    const remindAfter = new Date(now.toMillis() - CONFIRM_REMINDER_DELAY_HOURS * 3600000);

    const candidates = await db
      .collection('bookings')
      .where('status', '==', 'completed')
      .where('scheduledEnd', '<=', remindAfter)
      .where('studentConfirmedAt', '==', null)
      .limit(200)
      .get();

    let sent = 0;
    await Promise.all(
      candidates.docs.map(async (doc) => {
        const b = doc.data() as Booking;
        if (b.status === 'disputed' || b.reminderSentAt) return;
        await doc.ref.update({
          reminderSentAt: admin.firestore.FieldValue.serverTimestamp(),
          updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        });
        await notifyUser(
          b.studentUid,
          'Confirm your session',
          'Did your session happen as scheduled? Confirm it or report an issue.',
          { type: 'confirm_reminder', bookingId: doc.id },
        );
        sent += 1;
      }),
    );
    console.log(`sendConfirmReminders: ${sent} reminder(s) sent.`);
  },
);

/**
 * Auto-confirm + payout: for completed bookings where BOTH confirmations are
 * set, OR where autoConfirmDeadline has passed with status still 'completed'
 * (not disputed), transition to 'paid_out' and transfer the counselor's
 * payout (fee minus the 10% commission already computed at booking time).
 *
 * Disputed bookings are deliberately skipped — only resolveDispute may move
 * them.
 */
export const autoConfirmAndPayOut = functions.scheduler.onSchedule(
  { schedule: 'every 10 minutes', timeZone: 'UTC' },
  async () => {
    const now = admin.firestore.Timestamp.now();

    const completed = await db
      .collection('bookings')
      .where('status', '==', 'completed')
      .limit(300)
      .get();

    const eligible = completed.docs.filter((doc) => {
      const b = doc.data() as Booking;
      if (b.status !== 'completed') return false;
      const both = Boolean(b.studentConfirmedAt && b.counselorConfirmedAt);
      const deadline = b.autoConfirmDeadline;
      const timedOut = deadline !== null && deadline !== undefined && deadline.toMillis() < now.toMillis();
      return both || timedOut;
    });

    let paid = 0;
    await Promise.all(
      eligible.map(async (doc) => {
        const ok = await payOutCounselor(doc.id);
        if (ok) paid += 1;
      }),
    );
    console.log(`autoConfirmAndPayOut: ${paid} payout(s) initiated.`);
  },
);

/**
 * Payout for a single booking. Guarded so two runs can't double-transfer:
 * a transaction CAS-es payoutState pending/processing with a 15-minute
 * cooldown, then the transfer runs outside the transaction.
 *
 * Normally only 'completed' bookings are paid. When an admin resolves a
 * dispute in the counselor's favor ([allowDisputed]), a 'disputed' booking
 * is paid out too.
 */
export async function payOutCounselor(bookingId: string, allowDisputed = false): Promise<boolean> {
  const ref = db.collection('bookings').doc(bookingId);
  const cooldown = 15 * 60000;

  // 1) Claim the payout slot.
  try {
    await db.runTransaction(async (tx) => {
      const snap = await tx.get(ref);
      const b = snap.data() as Booking | undefined;
      const eligible = allowDisputed ? b?.status === 'disputed' || b?.status === 'completed' : b?.status === 'completed';
      if (!b || !eligible) {
        throw new Error('not-eligible');
      }
      const attempted = b.payoutAttemptedAt?.toMillis() ?? 0;
      const processing = b.payoutState === 'processing';
      if (processing && Date.now() - attempted < cooldown) {
        throw new Error('in-progress');
      }
      if (b.payoutState === 'paid') {
        throw new Error('already-paid');
      }
      tx.update(ref, {
        payoutState: 'processing',
        payoutAttemptedAt: admin.firestore.FieldValue.serverTimestamp(),
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      });
    });
  } catch (err) {
    const reason = (err as Error).message;
    if (reason === 'in-progress' || reason === 'already-paid') return false;
    // not-eligible: leave it for the next pass.
    return false;
  }

  // 2) Set auto-confirm if the student never explicitly confirmed.
  const booking = await getBooking(bookingId);
  if (!booking) return false;
  if (!booking.studentConfirmedAt) {
    await ref.update({
      studentConfirmedAt: admin.firestore.FieldValue.serverTimestamp(),
    });
  }

  // 3) Initiate the transfer. Payout details live on the private
  //    `counselorPrivate/{uid}` doc (owner + admins only) — never on the
  //    public counselorProfiles doc that students read.
  const privateSnap = await db.collection('counselorPrivate').doc(booking.counselorUid).get();
  const payoutDetails = privateSnap.exists
    ? (privateSnap.data()?.payoutAccountDetails as
        | { bankCode?: string; accountNumber?: string; accountName?: string; provider?: string }
        | undefined)
    : undefined;
  const bankCode = String(payoutDetails?.bankCode ?? '');
  const accountNumber = String(payoutDetails?.accountNumber ?? '');
  const accountName = String(payoutDetails?.accountName ?? '');
  const provider = String(payoutDetails?.provider ?? 'mobile_money');

  if (!accountNumber) {
    await ref.update({ payoutState: 'failed', updatedAt: admin.firestore.FieldValue.serverTimestamp() });
    console.warn(`payOutCounselor: booking ${bookingId} has no payout account.`);
    return false;
  }

  try {
    const result = await initiateTransfer({
      amount: booking.counselorPayoutAmount,
      currency: booking.currency,
      accountBank: provider === 'bank_transfer' && bankCode ? bankCode : provider.toUpperCase().replace('_', '-'),
      accountNumber,
      accountName,
      reference: `payout_${bookingId}`,
      narration: 'Orientaa session payout',
    });
    await ref.update({
      status: 'paid_out',
      payoutState: 'paid',
      payoutReference: result.reference,
      paidOutAt: admin.firestore.FieldValue.serverTimestamp(),
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });
    await notifyBothParties(
      booking,
      'Payout sent',
      `The counselor's payout of ${booking.currency} ${booking.counselorPayoutAmount} has been initiated.`,
      { type: 'paid_out', bookingId },
    );
    return true;
  } catch (err) {
    console.error(`payOutCounselor: transfer failed for ${bookingId}`, err);
    await ref.update({ payoutState: 'failed', updatedAt: admin.firestore.FieldValue.serverTimestamp() });
    return false;
  }
}

/**
 * Presence maintenance: counselors whose lastActiveAt is older than the
 * stale threshold are flipped back to offline.
 */
export const presenceMaintenance = functions.scheduler.onSchedule(
  { schedule: 'every 5 minutes', timeZone: 'UTC' },
  async () => {
    const flipped = await markStaleOffline();
    console.log(`presenceMaintenance: ${flipped} profile(s) marked offline.`);
  },
);
