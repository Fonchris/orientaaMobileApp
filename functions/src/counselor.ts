import * as admin from 'firebase-admin';
import { CallableRequest, HttpsError, onCall } from 'firebase-functions/v2/https';

import { ONLINE_STALE_AFTER_MIN } from './config';
import { CounselorProfile } from './types';

const db = admin.firestore();
type Payload = Record<string, any>;

function assertAuth(request: CallableRequest<Payload>): string {
  if (!request.auth?.uid) {
    throw new HttpsError('unauthenticated', 'You must be signed in.');
  }
  return request.auth.uid;
}

/**
 * Validates a payout-target payload and returns a sanitized copy, or null
 * when the payload is absent/empty. Only string fields are kept so a client
 * can't smuggle in arbitrary objects.
 */
function sanitizePayout(value: unknown): Record<string, string> | null {
  if (!value || typeof value !== 'object' || Array.isArray(value)) return null;
  const raw = value as Record<string, unknown>;
  const str = (k: string): string =>
    typeof raw[k] === 'string' ? (raw[k] as string).trim().slice(0, 100) : '';
  const out: Record<string, string> = {};
  for (const k of ['provider', 'accountName', 'accountNumber', 'bankCode']) {
    const v = str(k);
    if (v) out[k] = v;
  }
  return Object.keys(out).length > 0 ? out : null;
}

/** Computes the marketplace "recommended" score: rating * recency factor. */
export function recommendedScore(profile: Pick<CounselorProfile, 'ratingAverage' | 'lastActiveAt'>): number {
  const rating = profile.ratingAverage ?? 0;
  const lastActive = profile.lastActiveAt?.toDate() ?? new Date(0);
  const daysInactive = Math.max(0, (Date.now() - lastActive.getTime()) / 86400000);
  const halfLifeDays = 14;
  const maxBonus = 0.5;
  const bonus = maxBonus * Math.pow(0.5, daysInactive / halfLifeDays);
  return Math.round(rating * (1 + bonus) * 100) / 100;
}

/**
 * Owner-only profile editor. Whitelists exactly the client-editable fields;
 * verificationStatus, ratings, presence and credentialsUrl can only be set by
 * functions/admin and are never accepted from the client payload.
 */
export const saveCounselorProfile = onCall(async (request: CallableRequest<Payload>) => {
  const uid = assertAuth(request);
  const fields = (request.data?.fields as Record<string, unknown> | undefined) ?? {};
  if (!fields || typeof fields !== 'object') {
    throw new HttpsError('invalid-argument', 'fields is required.');
  }

  const ref = db.collection('counselorProfiles').doc(uid);
  const snap = await ref.get();
  const now = admin.firestore.FieldValue.serverTimestamp();

  // Note: payoutAccountDetails is deliberately NOT part of the profile
  // payload — it's persisted to the private `counselorPrivate/{uid}` doc so
  // students (who read approved profiles) can never see the payout target.
  const allowed: Record<string, unknown> = {
    displayName: typeof fields.displayName === 'string' ? fields.displayName.slice(0, 80) : undefined,
    photoUrl: typeof fields.photoUrl === 'string' ? fields.photoUrl : undefined,
    bio: typeof fields.bio === 'string' ? fields.bio.slice(0, 2000) : undefined,
    specialties: Array.isArray(fields.specialties)
      ? (fields.specialties as unknown[]).filter((s): s is string => typeof s === 'string').slice(0, 20)
      : undefined,
    languages: Array.isArray(fields.languages)
      ? (fields.languages as unknown[]).filter((s): s is string => typeof s === 'string').slice(0, 10)
      : undefined,
    hourlyRate: typeof fields.hourlyRate === 'number' && fields.hourlyRate >= 0 ? fields.hourlyRate : undefined,
    currency: typeof fields.currency === 'string' ? fields.currency.slice(0, 3).toUpperCase() : undefined,
    availability: Array.isArray(fields.availability) ? fields.availability.slice(0, 50) : undefined,
  };

  const sanitized = Object.fromEntries(
    Object.entries(allowed).filter(([, v]) => v !== undefined),
  );

  if (snap.exists) {
    await ref.update({ ...sanitized, updatedAt: now });
  } else {
    await ref.set({
      uid,
      displayName: (sanitized.displayName as string) ?? 'Counselor',
      photoUrl: sanitized.photoUrl ?? null,
      bio: sanitized.bio ?? '',
      specialties: sanitized.specialties ?? [],
      languages: sanitized.languages ?? [],
      hourlyRate: sanitized.hourlyRate ?? 0,
      currency: sanitized.currency ?? 'USD',
      verificationStatus: 'pending',
      isOnline: false,
      lastActiveAt: null,
      ratingAverage: 0,
      ratingCount: 0,
      availability: sanitized.availability ?? [],
      recommendedScore: 0,
      createdAt: now,
      updatedAt: now,
    });
  }

  // Persist the payout target privately (owner + admins only). When the key
  // is present — even empty — write the sanitized value so a counselor who
  // clears their account actually removes it (an empty target makes the
  // payout fail cleanly with "no payout account" instead of paying an old
  // account).
  if ('payoutAccountDetails' in fields) {
    await db.collection('counselorPrivate').doc(uid).set(
      { payoutAccountDetails: sanitizePayout(fields.payoutAccountDetails) ?? {}, updatedAt: now },
      { merge: true },
    );
  }

  return { status: 'saved' };
});

/**
 * Owner submits (or re-submits) verification credentials. Only moves
 * verificationStatus to 'pending' — approval happens manually in the
 * Firebase console (or an admin tool later).
 */
export const submitVerification = onCall(async (request: CallableRequest<Payload>) => {
  const uid = assertAuth(request);
  const credentialUrl: string = request.data?.credentialUrl ?? '';
  if (!credentialUrl.startsWith('https://firebasestorage.googleapis.com/')) {
    throw new HttpsError('invalid-argument', 'credentialsUrl must be a Firebase Storage URL.');
  }

  // Credentials are sensitive (proof of qualification) — store the URL on
  // the private doc, not the public profile students read.
  await db.collection('counselorPrivate').doc(uid).set(
    {
      credentialsUrl: credentialUrl,
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    },
    { merge: true },
  );
  await db.collection('counselorProfiles').doc(uid).update({
    verificationStatus: 'pending',
    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
  });

  return { status: 'pending' };
});

/**
 * Counselor presence heartbeat: marks the counselor online and refreshes the
 * recommended-score recency factor. The maintenance scheduler flips stale
 * profiles back to offline.
 */
export const heartbeat = onCall(async (request: CallableRequest<Payload>) => {
  const uid = assertAuth(request);
  const now = new Date();

  await db.runTransaction(async (tx) => {
    const ref = db.collection('counselorProfiles').doc(uid);
    const snap = await tx.get(ref);
    if (!snap.exists) return;
    const profile = snap.data() as CounselorProfile;
    tx.update(ref, {
      isOnline: true,
      lastActiveAt: now,
      recommendedScore: recommendedScore(profile),
      updatedAt: now,
    });
  });

  return { status: 'online' };
});

/** Shared with scheduled.ts: flips stale profiles to offline. */
export async function markStaleOffline(): Promise<number> {
  const staleBefore = new Date(Date.now() - ONLINE_STALE_AFTER_MIN * 60000);
  const online = await db
    .collection('counselorProfiles')
    .where('isOnline', '==', true)
    .get();

  let flipped = 0;
  await Promise.all(
    online.docs.map(async (doc) => {
      const profile = doc.data() as CounselorProfile;
      const lastActive = profile.lastActiveAt?.toDate();
      if (!lastActive || lastActive.getTime() < staleBefore.getTime()) {
        await doc.ref.update({ isOnline: false, updatedAt: new Date() });
        flipped += 1;
      }
    }),
  );
  return flipped;
}
