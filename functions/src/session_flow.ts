import * as admin from 'firebase-admin';
import { CallableRequest, HttpsError, onCall } from 'firebase-functions/v2/https';

import { MAX_RATING, MIN_RATING } from './config';
import { refundTransaction } from './flutterwave';
import { roundMoney } from './helpers';
import { notifyBothParties } from './notifications';
import { Booking, CounselorProfile } from './types';

const db = admin.firestore();
type Payload = Record<string, any>;

function assertAuth(request: CallableRequest<Payload>): string {
  if (!request.auth?.uid) {
    throw new HttpsError('unauthenticated', 'You must be signed in.');
  }
  return request.auth.uid;
}

async function getBooking(bookingId: string): Promise<Booking | null> {
  const snap = await db.collection('bookings').doc(bookingId).get();
  return snap.exists ? (snap.data() as Booking) : null;
}

/**
 * Sets studentConfirmedAt / counselorConfirmedAt depending on the caller.
 * When both sides have confirmed, the scheduled payout function picks the
 * booking up — funds move only via that path (never here directly).
 */
export const confirmSession = onCall(async (request: CallableRequest<Payload>) => {
  const uid = assertAuth(request);
  const data = request.data ?? {};
  const bookingId: string = data.bookingId ?? '';
  const booking = await getBooking(bookingId);
  if (!booking) {
    throw new HttpsError('not-found', 'Booking not found.');
  }
  if (booking.studentUid !== uid && booking.counselorUid !== uid) {
    throw new HttpsError('permission-denied', 'Not a participant.');
  }
  if (booking.status !== 'completed') {
    throw new HttpsError('failed-precondition', 'Sessions can only be confirmed after completion.');
  }

  const isStudent = booking.studentUid === uid;
  const field = isStudent ? 'studentConfirmedAt' : 'counselorConfirmedAt';
  const update: Record<string, unknown> = {
    [field]: admin.firestore.FieldValue.serverTimestamp(),
    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
  };

  await db.runTransaction(async (tx) => {
    const ref = db.collection('bookings').doc(bookingId);
    const snap = await tx.get(ref);
    const current = snap.data() as Booking;
    if (current.status !== 'completed') {
      throw new HttpsError('failed-precondition', 'Booking is not completed.');
    }
    if (current[field as 'studentConfirmedAt']) {
      return; // idempotent
    }
    tx.update(ref, update);
  });

  await notifyBothParties(
    booking,
    'Session confirmed',
    isStudent ? "Thanks! The counselor's payout is being processed." : 'Thanks for confirming the session.',
    { type: 'session_confirmed', bookingId },
  );

  return { status: 'confirmed' };
});

/**
 * Writes ratings/{bookingId} and recalculates the counselor's ratingAverage /
 * ratingCount inside a Firestore transaction (race-safe). Re-ratings replace
 * the previous rating's contribution rather than double-counting.
 */
export const submitRating = onCall(async (request: CallableRequest<Payload>) => {
  const studentUid = assertAuth(request);
  const data = request.data ?? {};
  const bookingId: string = data.bookingId ?? '';
  const stars: number = data.stars ?? 0;
  const reviewText: string = String(data.reviewText ?? '').slice(0, 500);

  if (stars < MIN_RATING || stars > MAX_RATING || !Number.isInteger(stars)) {
    throw new HttpsError('invalid-argument', `Stars must be an integer ${MIN_RATING}-${MAX_RATING}.`);
  }

  const booking = await getBooking(bookingId);
  if (!booking) {
    throw new HttpsError('not-found', 'Booking not found.');
  }
  if (booking.studentUid !== studentUid) {
    throw new HttpsError('permission-denied', 'Only the student can rate.');
  }
  if (booking.status !== 'completed') {
    throw new HttpsError('failed-precondition', 'You can only rate completed sessions.');
  }

  const userSnap = await db.collection('users').doc(studentUid).get();
  const displayName = (userSnap.data()?.displayName as string) ?? 'Student';
  const studentFirstName = displayName.trim().split(/\s+/)[0] ?? 'Student';

  await db.runTransaction(async (tx) => {
    const ratingRef = db.collection('ratings').doc(bookingId);
    const profileRef = db.collection('counselorProfiles').doc(booking.counselorUid);

    const ratingSnap = await tx.get(ratingRef);
    const existing = ratingSnap.exists ? (ratingSnap.data() as { stars?: number }) : null;

    const profileSnap = await tx.get(profileRef);
    const profile = profileSnap.exists ? (profileSnap.data() as CounselorProfile) : null;
    if (!profile) {
      throw new HttpsError('not-found', 'Counselor profile not found.');
    }

    let count = profile.ratingCount ?? 0;
    let sum = (profile.ratingAverage ?? 0) * count;

    if (existing) {
      sum -= existing.stars ?? 0; // replace old contribution
    } else {
      count += 1;
    }
    sum += stars;

    tx.set(ratingRef, {
      studentUid,
      counselorUid: booking.counselorUid,
      stars,
      reviewText,
      studentFirstName,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    tx.update(profileRef, {
      ratingAverage: roundMoney(count === 0 ? 0 : sum / count),
      ratingCount: count,
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });
  });

  return { status: 'rated' };
});

/**
 * Student reports a problem: booking -> 'disputed', reason written to
 * adminDisputeQueue for manual review. A disputed booking is excluded from
 * the auto-confirm timer — it stays blocked until an admin resolves it.
 */
export const raiseDispute = onCall(async (request: CallableRequest<Payload>) => {
  const studentUid = assertAuth(request);
  const data = request.data ?? {};
  const bookingId: string = data.bookingId ?? '';
  const reason: string = String(data.reason ?? '').trim().slice(0, 1000);
  if (!reason) {
    throw new HttpsError('invalid-argument', 'A reason is required.');
  }

  const booking = await getBooking(bookingId);
  if (!booking) {
    throw new HttpsError('not-found', 'Booking not found.');
  }
  if (booking.studentUid !== studentUid) {
    throw new HttpsError('permission-denied', 'Only the student can dispute.');
  }
  if (booking.status !== 'completed' && booking.status !== 'in_progress') {
    throw new HttpsError('failed-precondition', "This session can't be disputed.");
  }

  // Denormalized display data for the admin UI, fetched BEFORE the
  // transaction so the status flip + queue entry are written atomically — a
  // disputed booking must never end up stranded with no review entry.
  const [studentSnap, counselorSnap] = await Promise.all([
    db.collection('users').doc(studentUid).get(),
    db.collection('users').doc(booking.counselorUid).get(),
  ]);

  await db.runTransaction(async (tx) => {
    const ref = db.collection('bookings').doc(bookingId);
    const snap = await tx.get(ref);
    const current = snap.data() as Booking;
    if (current.status === 'disputed' || current.status === 'paid_out' || current.status === 'refunded') {
      throw new HttpsError('failed-precondition', 'This session is already resolved.');
    }
    tx.update(ref, {
      status: 'disputed',
      disputeReason: reason,
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });
    tx.set(db.collection('adminDisputeQueue').doc(bookingId), {
      bookingId,
      studentUid,
      studentName: (studentSnap.data()?.displayName as string) ?? 'Student',
      counselorUid: booking.counselorUid,
      counselorName: (counselorSnap.data()?.displayName as string) ?? 'Counselor',
      counselorPhotoUrl: (counselorSnap.data()?.photoUrl as string) ?? null,
      scheduledStart: booking.scheduledStart,
      scheduledEnd: booking.scheduledEnd,
      feeAmount: booking.feeAmount,
      currency: booking.currency,
      reason,
      status: 'open',
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });
  });

  await notifyBothParties(
    booking,
    'Session disputed',
    'A session issue has been reported. Our team will review it shortly.',
    { type: 'dispute_raised', bookingId },
  );

  return { status: 'disputed' };
});

/**
 * Admin-only (custom claim `admin: true`): resolves a disputed booking to
 * 'paid_out' (dispute rejected — pay the counselor as normal) or 'refunded'
 * (dispute upheld — Flutterwave refund to the student).
 */
export const resolveDispute = onCall(async (request: CallableRequest<Payload>) => {
  const adminUid = assertAuth(request);
  const isAdmin = request.auth?.token?.admin === true;
  if (!isAdmin) {
    throw new HttpsError('permission-denied', 'Admins only.');
  }

  const data = request.data ?? {};
  const bookingId: string = data.bookingId ?? '';
  const outcome: string = data.outcome ?? '';
  if (outcome !== 'paid_out' && outcome !== 'refunded') {
    throw new HttpsError('invalid-argument', 'Outcome must be paid_out or refunded.');
  }

  const booking = await getBooking(bookingId);
  if (!booking) {
    throw new HttpsError('not-found', 'Booking not found.');
  }
  if (booking.status !== 'disputed') {
    throw new HttpsError('failed-precondition', 'Booking is not disputed.');
  }

  if (outcome === 'refunded') {
    if (!booking.paymentReference) {
      throw new HttpsError('failed-precondition', 'No payment reference to refund.');
    }
    // CAS the resolution so two concurrent admin calls can't both reach the
    // Flutterwave refund API (a double refund). The payout path has the same
    // guard via payOutCounselor's payoutState CAS.
    await db.runTransaction(async (tx) => {
      const ref = db.collection('bookings').doc(bookingId);
      const snap = await tx.get(ref);
      const current = snap.data() as Booking;
      if (current.status !== 'disputed' || current.disputeResolutionState === 'processing') {
        throw new HttpsError('failed-precondition', 'This dispute is already being resolved.');
      }
      tx.update(ref, {
        disputeResolutionState: 'processing',
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      });
    });
    await refundTransaction(booking.paymentReference);
    await db.collection('bookings').doc(bookingId).update({
      status: 'refunded',
      disputeResolutionState: 'resolved',
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });
  } else {
    // Dispute rejected: pay out via the shared payout path. The booking is
    // still 'disputed' at this point, so allow the payout to treat a
    // dispute-rejected booking as eligible; only report success when the
    // transfer was actually claimed so the admin sees the real outcome.
    const { payOutCounselor } = await import('./scheduled');
    const paid = await payOutCounselor(bookingId, true);
    if (!paid) {
      throw new HttpsError('aborted', 'Payout could not be initiated — please retry.');
    }
  }

  await db.collection('adminDisputeQueue').doc(bookingId).update({
    status: outcome === 'refunded' ? 'resolved_refunded' : 'resolved_paid_out',
    resolvedBy: adminUid,
    resolvedAt: admin.firestore.FieldValue.serverTimestamp(),
  });

  await notifyBothParties(
    booking,
    outcome === 'refunded' ? 'Dispute resolved — refunded' : 'Dispute resolved',
    outcome === 'refunded'
      ? 'Your refund has been initiated. It may take a few days to appear.'
      : 'Your session issue was reviewed and the session was paid out.',
    { type: 'dispute_resolved', bookingId, outcome },
  );

  return { status: outcome };
});
