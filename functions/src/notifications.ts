import * as admin from 'firebase-admin';

/**
 * Sends a push notification (FCM) to a user and writes an in-app
 * notification document under `users/{uid}/notifications` so the bell in the
 * app shows it too.
 *
 * The device token is stored on `users/{uid}/devices/main` (owner-only via
 * rules) — never on the `users/{uid}` doc itself, which is readable by every
 * signed-in user for search/connections. Synced by the Flutter client via
 * the PushNotifications service.
 */
export async function notifyUser(
  uid: string,
  title: string,
  body: string,
  data: Record<string, string> = {},
): Promise<void> {
  const db = admin.firestore();
  try {
    const deviceSnap = await db
      .collection('users')
      .doc(uid)
      .collection('devices')
      .doc('main')
      .get();
    const token = deviceSnap.data()?.fcmToken as string | undefined;

    await db.collection('users').doc(uid).collection('notifications').add({
      title,
      body,
      read: false,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    if (token) {
      await admin.messaging().send({
        token,
        notification: { title, body },
        data: { ...data, title, body },
      });
    }
  } catch (err) {
    // Notifications are best-effort; never fail the triggering operation.
    console.warn('notifyUser failed', uid, err);
  }
}

export async function notifyBothParties(
  booking: { studentUid: string; counselorUid: string },
  title: string,
  body: string,
  data: Record<string, string> = {},
): Promise<void> {
  await Promise.all([
    notifyUser(booking.studentUid, title, body, data),
    notifyUser(booking.counselorUid, title, body, data),
  ]);
}
