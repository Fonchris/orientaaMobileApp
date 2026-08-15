import * as admin from 'firebase-admin';
import * as functions from 'firebase-functions';

import { confirmPaidBooking } from './bookings';
import { env } from './config';
import { verifyTransactionByRef } from './flutterwave';

/**
 * Flutterwave webhook (https endpoint).
 *
 * Security model:
 *  - The `verif-hash` header must match FLUTTERWAVE_WEBHOOK_HASH.
 *  - The transaction is re-verified server-side before any state change.
 *  - Only this handler (or verifyPayment after a server-side check) may move
 *    a booking to 'confirmed' — never a raw client callback.
 *
 * Configure the webhook URL in the Flutterwave dashboard as:
 *   https://<region>-<project>.cloudfunctions.net/flutterwaveWebhook
 */
export const flutterwaveWebhook = functions.https.onRequest(async (req, res) => {
  if (req.method !== 'POST') {
    res.status(405).send('Method not allowed');
    return;
  }

  const signature = req.headers['verif-hash'] ?? req.headers['verif_hash'];
  if (!signature || signature !== env.flutterwaveWebhookHash) {
    res.status(401).send('Invalid signature');
    return;
  }

  const body = req.body ?? {};
  const event = body.event as string;
  const tx = body.data ?? {};

  try {
    if (event === 'charge.completed' || event === 'charge.success') {
      if (tx.status === 'successful') {
        const txRef = String(tx.tx_ref ?? '');
        const bookingId = txRef.startsWith('booking_') ? txRef.slice('booking_'.length) : txRef;
        if (bookingId) {
          // Server-side re-verification before trusting the webhook payload:
          // the transaction must exist, be successful, match the exact
          // transaction id, and settle the exact fee in the exact currency.
          const verifiedTx = await verifyTransactionByRef(txRef);
          if (verifiedTx === null || verifiedTx.status !== 'successful') {
            res.status(200).send('OK');
            return;
          }
          if (tx.id == null || String(verifiedTx.id) !== String(tx.id)) {
            res.status(200).send('OK');
            return;
          }

          const bookingSnap = await admin
            .firestore()
            .collection('bookings')
            .doc(bookingId)
            .get();
          if (!bookingSnap.exists) {
            res.status(200).send('OK');
            return;
          }
          const booking = bookingSnap.data();
          // Only a booking that is actually awaiting payment can be confirmed
          // (mirrors the guard on the failure path). confirmPaidBooking also
          // re-checks, so a stale webhook can never re-confirm a paid session.
          if (booking?.status !== 'payment_pending') {
            res.status(200).send('OK');
            return;
          }
          const amountMatches =
            booking?.feeAmount !== undefined &&
            Math.abs((verifiedTx.amount ?? 0) - booking.feeAmount) < 0.01;
          const currencyMatches =
            booking?.currency !== undefined &&
            String(verifiedTx.currency ?? '').toUpperCase() ===
              String(booking.currency).toUpperCase();
          if (amountMatches && currencyMatches) {
            await confirmPaidBooking(bookingId, String(verifiedTx.id), txRef);
          }
        }
      }
    } else if (event === 'charge.failed' || event === 'charge.cancelled') {
      const txRef = String(tx.tx_ref ?? '');
      const bookingId = txRef.startsWith('booking_') ? txRef.slice('booking_'.length) : txRef;
      if (bookingId) {
        // Release the slot: payment_pending -> requested. Clear the payment
        // references so a stale tx ref can't be reused for retry.
        const snap = await admin.firestore().collection('bookings').doc(bookingId).get();
        if (snap.exists && snap.data()?.status === 'payment_pending') {
          await snap.ref.update({
            status: 'requested',
            paymentTxRef: admin.firestore.FieldValue.delete(),
            paymentProvider: admin.firestore.FieldValue.delete(),
            updatedAt: admin.firestore.FieldValue.serverTimestamp(),
          });
        }
      }
    }

    res.status(200).send('OK');
  } catch (err) {
    console.error('Webhook processing failed', err);
    // Acknowledge so Flutterwave doesn't retry into an infinite loop.
    res.status(200).send('OK');
  }
});
