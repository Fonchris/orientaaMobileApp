import * as admin from 'firebase-admin';
import { CallableRequest, HttpsError, onCall } from 'firebase-functions/v2/https';

import { PLATFORM_COMMISSION_RATE, SESSION_DURATION_MIN, SLOT_OCCUPYING_STATUSES } from './config';
import { initializePayment, verifyTransactionByRef } from './flutterwave';
import { generateSlots, isValidSlot, roundMoney } from './helpers';
import { notifyBothParties } from './notifications';
import { Booking, CounselorProfile } from './types';

const db = admin.firestore();
type Payload = Record<string, any>;

// ── Shared helpers ─────────────────────────────────────────────────────────

function assertAuth(request: CallableRequest<Payload>): string {
  if (!request.auth?.uid) {
    throw new HttpsError('unauthenticated', 'You must be signed in.');
  }
  return request.auth.uid;
}

async function getProfile(counselorUid: string): Promise<CounselorProfile | null> {
  const snap = await db.collection('counselorProfiles').doc(counselorUid).get();
  return snap.exists ? (snap.data() as CounselorProfile) : null;
}

async function getBooking(bookingId: string): Promise<Booking | null> {
  const snap = await db.collection('bookings').doc(bookingId).get();
  return snap.exists ? (snap.data() as Booking) : null;
}

/** Reserves a 60-minute slot inside a transaction (race-safe). Returns the
 * booking id, or null if the slot is already taken. */
async function tryReserveSlot(
  counselorUid: string,
  studentUid: string,
  start: Date,
  end: Date,
  feeAmount: number,
  currency: string,
): Promise<string | null> {
  let bookingId = '';
  await db.runTransaction(async (tx) => {
    const overlaps = await tx.get(
      db
        .collection('bookings')
        .where('counselorUid', '==', counselorUid)
        .where('scheduledStart', '==', start),
    );
    const taken = overlaps.docs.some(
      (d) => SLOT_OCCUPYING_STATUSES.includes((d.data() as Booking).status),
    );
    if (taken) return;

    const ref = db.collection('bookings').doc();
    bookingId = ref.id;
    const now = admin.firestore.FieldValue.serverTimestamp();
    tx.set(ref, {
      studentUid,
      counselorUid,
      scheduledStart: start,
      scheduledEnd: end,
      feeAmount: roundMoney(feeAmount),
      currency,
      platformCommission: roundMoney(feeAmount * PLATFORM_COMMISSION_RATE),
      counselorPayoutAmount: roundMoney(feeAmount * (1 - PLATFORM_COMMISSION_RATE)),
      status: 'requested',
      createdAt: now,
      updatedAt: now,
    });
  });
  return bookingId || null;
}

// ── Callables ──────────────────────────────────────────────────────────────

/** Screen 2 preview + booking-flow slot picker. Server-generated slots. */
export const getAvailableSlots = onCall(async (request: CallableRequest<Payload>) => {
  assertAuth(request);
  const data = request.data ?? {};
  const counselorUid: string = data.counselorUid ?? '';
  if (!counselorUid) {
    throw new HttpsError('invalid-argument', 'counselorUid is required.');
  }
  const rangeStart = new Date(data.rangeStart as string);
  let rangeEnd = new Date(data.rangeEnd as string);
  if (Number.isNaN(rangeStart.getTime()) || Number.isNaN(rangeEnd.getTime()) || rangeEnd <= rangeStart) {
    throw new HttpsError('invalid-argument', 'Invalid date range.');
  }
  // Clamp the window so a huge range can't force an unbounded slot scan.
  const MAX_SLOT_RANGE_DAYS = 90;
  if (rangeEnd.getTime() - rangeStart.getTime() > MAX_SLOT_RANGE_DAYS * 86400000) {
    rangeEnd = new Date(rangeStart.getTime() + MAX_SLOT_RANGE_DAYS * 86400000);
  }

  const profile = await getProfile(counselorUid);
  if (!profile || profile.verificationStatus !== 'approved') {
    return { slots: [] };
  }

  const existing = await db
    .collection('bookings')
    .where('counselorUid', '==', counselorUid)
    .where('scheduledStart', '>=', rangeStart)
    .where('scheduledStart', '<=', rangeEnd)
    .get();

  const occupying = existing.docs
    .filter((d) => SLOT_OCCUPYING_STATUSES.includes((d.data() as Booking).status))
    .map((d) => {
      const b = d.data() as Booking;
      return {
        scheduledStart: b.scheduledStart.toDate(),
        scheduledEnd: b.scheduledEnd.toDate(),
      };
    });

  const slots = generateSlots(profile.availability, rangeStart, rangeEnd, occupying);
  return { slots };
});

/**
 * Step B — creates the booking (status requested -> payment_pending) with
 * server-computed end time / fee / commission, re-validating the slot in a
 * transaction, then initializes the Flutterwave checkout.
 */
export const createBooking = onCall(async (request: CallableRequest<Payload>) => {
  const studentUid = assertAuth(request);
  const data = request.data ?? {};
  const counselorUid: string = data.counselorUid ?? '';
  const scheduledStart = new Date(data.scheduledStart as string);
  if (!counselorUid || Number.isNaN(scheduledStart.getTime())) {
    throw new HttpsError('invalid-argument', 'counselorUid and scheduledStart are required.');
  }
  if (counselorUid === studentUid) {
    throw new HttpsError('invalid-argument', "You can't book a session with yourself.");
  }
  if (scheduledStart.getTime() <= Date.now()) {
    throw new HttpsError('failed-precondition', 'That time has already passed.');
  }

  const profile = await getProfile(counselorUid);
  if (!profile || profile.verificationStatus !== 'approved') {
    throw new HttpsError('failed-precondition', 'This counselor is not bookable yet.');
  }
  if (!isValidSlot(profile.availability, scheduledStart)) {
    throw new HttpsError('failed-precondition', "That slot is not in the counselor's availability.");
  }

  const scheduledEnd = new Date(scheduledStart.getTime() + SESSION_DURATION_MIN * 60000);
  const feeAmount = profile.hourlyRate;

  const bookingId = await tryReserveSlot(
    counselorUid,
    studentUid,
    scheduledStart,
    scheduledEnd,
    feeAmount,
    profile.currency,
  );
  if (!bookingId) {
    throw new HttpsError('aborted', 'That slot was just booked — pick another.');
  }

  // Initialize payment; on failure the booking stays 'requested' (slot free).
  const userSnap = await db.collection('users').doc(studentUid).get();
  const userData = userSnap.data() ?? {};
  const payment = await initializePayment({
    amount: feeAmount,
    currency: profile.currency,
    txRef: `booking_${bookingId}`,
    customer: {
      email: (userData.email as string) ?? `${studentUid}@orientaa.app`,
      name: (userData.displayName as string) ?? 'Orientaa student',
    },
    meta: { bookingId, redirectUrl: '' },
  });

  await db.collection('bookings').doc(bookingId).update({
    status: 'payment_pending',
    paymentProvider: 'flutterwave',
    paymentTxRef: `booking_${bookingId}`,
    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
  });

  return {
    bookingId,
    feeAmount: roundMoney(feeAmount),
    currency: profile.currency,
    paymentLink: payment.link,
  };
});

/** Re-initializes payment for an existing booking (retry after failure). */
export const retryPayment = onCall(async (request: CallableRequest<Payload>) => {
  const studentUid = assertAuth(request);
  const data = request.data ?? {};
  const bookingId: string = data.bookingId ?? '';
  const booking = await getBooking(bookingId);
  if (!booking || booking.studentUid !== studentUid) {
    throw new HttpsError('not-found', 'Booking not found.');
  }
  if (booking.status !== 'requested' && booking.status !== 'payment_pending') {
    throw new HttpsError('failed-precondition', "This booking can't be retried.");
  }

  // A failed payment released the slot; re-validate it's still free before
  // re-initializing payment so two students can't end up paying for the
  // same slot (one of them would be double-booked).
  const slotFree = await db.runTransaction(async (tx) => {
    const overlaps = await tx.get(
      db
        .collection('bookings')
        .where('counselorUid', '==', booking.counselorUid)
        .where('scheduledStart', '==', booking.scheduledStart),
    );
    return !overlaps.docs.some(
      (d) => d.id !== bookingId && SLOT_OCCUPYING_STATUSES.includes((d.data() as Booking).status),
    );
  });
  if (!slotFree) {
    throw new HttpsError('aborted', 'That slot was just booked by someone else.');
  }

  const userSnap = await db.collection('users').doc(studentUid).get();
  const userData = userSnap.data() ?? {};
  const payment = await initializePayment({
    amount: booking.feeAmount,
    currency: booking.currency,
    txRef: `booking_${bookingId}`,
    customer: {
      email: (userData.email as string) ?? `${studentUid}@orientaa.app`,
      name: (userData.displayName as string) ?? 'Orientaa student',
    },
    meta: { bookingId, redirectUrl: '' },
  });

  await db.collection('bookings').doc(bookingId).update({
    status: 'payment_pending',
    paymentProvider: 'flutterwave',
    paymentTxRef: `booking_${bookingId}`,
    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
  });

  return {
    bookingId,
    feeAmount: roundMoney(booking.feeAmount),
    currency: booking.currency,
    paymentLink: payment.link,
  };
});

/**
 * Releases a payment_pending (or requested) booking back to 'requested' so
 * its slot frees up — used when the student abandons or fails payment.
 */
export const cancelBooking = onCall(async (request: CallableRequest<Payload>) => {
  const studentUid = assertAuth(request);
  const data = request.data ?? {};
  const bookingId: string = data.bookingId ?? '';
  const booking = await getBooking(bookingId);
  if (!booking || booking.studentUid !== studentUid) {
    throw new HttpsError('not-found', 'Booking not found.');
  }
  if (booking.status !== 'payment_pending' && booking.status !== 'requested') {
    throw new HttpsError('failed-precondition', "This booking can't be cancelled.");
  }
  await db.collection('bookings').doc(bookingId).update({
    status: 'requested',
    paymentTxRef: admin.firestore.FieldValue.delete(),
    paymentProvider: admin.firestore.FieldValue.delete(),
    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
  });
  return { status: 'requested' };
});

/**
 * Client-side verification fallback: re-checks the payment status with
 * Flutterwave when the webhook hasn't landed yet. Only the verified webhook
 * (or this call after a server-side verification) may confirm a booking.
 */
export const verifyPayment = onCall(async (request: CallableRequest<Payload>) => {
  const studentUid = assertAuth(request);
  const data = request.data ?? {};
  const bookingId: string = data.bookingId ?? '';
  const booking = await getBooking(bookingId);
  if (!booking || booking.studentUid !== studentUid) {
    throw new HttpsError('not-found', 'Booking not found.');
  }

  if (booking.status === 'confirmed' || booking.status === 'in_progress') {
    return { status: 'confirmed' };
  }
  if (booking.status !== 'payment_pending') {
    return { status: booking.status };
  }

  const txRef = booking.paymentTxRef ?? `booking_${bookingId}`;
  const tx = await verifyTransactionByRef(txRef);
  if (tx && tx.status === 'successful' && Math.abs(tx.amount - booking.feeAmount) < 0.01) {
    await confirmPaidBooking(bookingId, String(tx.id), txRef);
    return { status: 'confirmed' };
  }
  return { status: 'payment_pending' };
});

/**
 * Shared, idempotent transition payment_pending -> confirmed. Used by the
 * webhook and verifyPayment. Sends the confirmation push to both parties.
 */
export async function confirmPaidBooking(
  bookingId: string,
  flutterwaveTransactionId: string,
  txRef: string,
): Promise<void> {
  const ref = db.collection('bookings').doc(bookingId);
  let booking: Booking | null = null;

  // Transactional read-modify-write so the webhook and verifyPayment can't
  // race each other into a duplicate confirmation / double notification.
  try {
    await db.runTransaction(async (tx) => {
      const snap = await tx.get(ref);
      if (!snap.exists) return;
      const b = snap.data() as Booking;
      if (b.status === 'confirmed' || b.status === 'in_progress') return;
      if (b.status !== 'payment_pending') return;
      booking = b;
      tx.update(ref, {
        status: 'confirmed',
        paymentReference: flutterwaveTransactionId,
        paymentTxRef: txRef,
        paymentProvider: 'flutterwave',
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      });
    });
  } catch (err) {
    console.error(`confirmPaidBooking: transaction failed for ${bookingId}`, err);
    return;
  }

  if (!booking) return;
  await notifyBothParties(
    booking,
    'Booking confirmed',
    'Your session is confirmed. A reminder will arrive 15 minutes before it starts.',
    { type: 'booking_confirmed', bookingId },
  );
}
