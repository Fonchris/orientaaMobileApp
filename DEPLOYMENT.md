# Orientaa — Deployment Checklist

This covers everything needed to take the **Counselors module** (and the rest of
the app) from code to production. The Flutter app itself is **100% Firebase** —
Firestore + Auth + Storage + Cloud Functions + Cloud Messaging — with no other
server. All payment logic runs in Cloud Functions; **no secrets live in the app**.

---

## 1. Prerequisites

- [ ] Firebase project created (console.firebase.google.com) and `.firebaserc`
      points at it (`firebase use <project-id>`).
- [ ] **Firebase Auth** enabled: Email/Password, Google, and Email Link sign-in.
- [ ] **Cloud Firestore** enabled.
- [ ] **Firebase Storage** enabled.
- [ ] **Cloud Functions** enabled (Blaze plan required for outgoing HTTP —
      Flutterwave API calls).
- [ ] **Firebase Cloud Messaging** enabled (Android + iOS apps registered;
      iOS needs an APNs key).
- [ ] Firebase CLI installed and logged in: `firebase login`.
- [ ] Android `google-services.json` + iOS `GoogleService-Info.plist` present
      (both gitignored).

---

## 2. Environment variables (Cloud Functions)

The functions read these from the environment. Use Firebase secrets so they're
encrypted and injected at deploy time:

```bash
cd functions
firebase functions:secrets:set FLUTTERWAVE_SECRET_KEY
firebase functions:secrets:set FLUTTERWAVE_WEBHOOK_HASH
# Optional: override the API base URL (defaults to https://api.flutterwave.com/v3)
firebase functions:secrets:set FLUTTERWAVE_BASE_URL
```

| Variable | Required | Purpose |
|----------|----------|---------|
| `FLUTTERWAVE_SECRET_KEY` | ✅ | Server-side Flutterwave API (verify payments, transfers, refunds). Never shipped to the app. |
| `FLUTTERWAVE_WEBHOOK_HASH` | ✅ | Must equal the **Verif Hash** set in the Flutterwave dashboard; the webhook 401s without it. |
| `FLUTTERWAVE_BASE_URL` | ❌ | Override for sandbox/testing (e.g. `https://api.flutterwave.com/v3`). |

> Local emulation: export the same names in the shell or a `functions/.env`
> file before running `firebase emulators:start`.

---

## 3. Deploy Firestore rules + indexes + Storage

```bash
# From the repo root
firebase deploy --only firestore:rules,firestore:indexes,storage
```

- `firestore.rules` — participants-only bookings, field-whitelisted counselor
  profiles, owner-only `counselorPrivate/{uid}` and `users/{uid}/devices`,
  time-windowed session chat, admin-only `adminDisputeQueue` reads.
- `firestore.indexes.json` — composite indexes for the directory sorts, the
  scheduled jobs, and the ratings feed.
- `storage.rules` — owner-scoped uploads (profile photos, posts, credentials).

> These deploy independently of the functions; do them first so the app works
> once the functions land.

---

## 4. Deploy Cloud Functions

```bash
cd functions
npm install
npm run build          # type-check + compile
cd ..
firebase deploy --only functions
```

Exported functions:

| Function | Type | Purpose |
|----------|------|---------|
| `getAvailableSlots` | callable | Server-generated 60-min slots from availability, excluding booked slots |
| `createBooking` | callable | Transactional slot reservation, fee/commission computed server-side, Flutterwave checkout link |
| `retryPayment` / `cancelBooking` / `verifyPayment` | callable | Payment retry (slot re-validated), release slot, client-side webhook fallback |
| `flutterwaveWebhook` | https | Verified payment confirmation (signature + tx id + amount + currency) |
| `confirmSession` / `submitRating` / `raiseDispute` | callable | Post-session confirm, transactional rating recalc, dispute intake |
| `resolveDispute` | callable | **Admin-only** (custom claim `admin: true`): pay counselor or refund student |
| `saveCounselorProfile` / `submitVerification` / `heartbeat` | callable | Profile editor, credentials submission (private doc), presence |
| `completeSessions` / `sendConfirmReminders` / `autoConfirmAndPayOut` / `presenceMaintenance` | scheduled | Completion at end+30min, 24h reminder, 48h auto-confirm+payout, offline sweep |

Verify deploys succeeded:

```bash
firebase functions:log
```

---

## 5. Flutterwave setup

1. Create a Flutterwave account and switch the API base to live when ready.
2. **Webhook**: Flutterwave dashboard → **Settings → Webhooks** → add:
   ```
   https://<region>-<project>.cloudfunctions.net/flutterwaveWebhook
   ```
   - Enabled events: `charge.completed`, `charge.success`, `charge.failed`,
     `charge.cancelled`.
   - Copy the dashboard **Verif Hash** into `FLUTTERWAVE_WEBHOOK_HASH` (step 2)
     and re-deploy if you changed it after deploying.
3. The app uses Flutterwave's **hosted checkout** (link returned by
   `createBooking`), so the Flutter app needs **no Flutterwave key** at all.
4. **Payouts**: counselors enter payout details (mobile money / bank) in their
   profile — stored on the private `counselorPrivate/{uid}` doc. The
   auto-confirm job transfers `counselorPayoutAmount` (fee − 10% commission)
   to that target.
5. **Sandbox**: set `FLUTTERWAVE_BASE_URL` to the test endpoint and use test
   cards/momo numbers from the Flutterwave docs.

---

## 6. Admins (dispute resolution)

`resolveDispute` only runs for users holding the custom claim `admin: true`.

- Firebase console → **Authentication → Users** → select the user →
  **Edit → Custom claims** → paste:
  ```json
  { "admin": true }
  ```
- The app shows the **Dispute review** entry (shield icon in the Counselors
  tab header) only to users with that claim. Students who raise issues land in
  the `adminDisputeQueue` collection; resolve them there to `paid_out`
  (counselor paid) or `refunded` (Flutterwave refund to the student).

---

## 7. Push notifications (FCM)

- Device tokens are stored on `users/{uid}/devices/main` (owner-only) by the
  app's `PushNotifications` service.
- The scheduled reminders and session notifications are sent via Cloud
  Messaging using those tokens; nothing to configure beyond enabling FCM and
  the platform push keys.

---

## 8. Release build

```bash
flutter build appbundle   # Android
flutter build ipa         # iOS (from macOS)
```

- [ ] App signing keys configured (gitignored keystore).
- [ ] Version bumps in `pubspec.yaml`.
- [ ] Store listing assets (icons, screenshots).

---

## 9. Go-live smoke test

- [ ] Student: browse directory → filters + sort → book a slot → pay via
      Flutterwave → webhook confirms → both parties notified.
- [ ] Chat locks before `start − 10min`, opens at the session, closes at
      `end + 30min` (rules enforce this server-side too).
- [ ] Session completes → student confirms / rates → counselor's
      `ratingAverage` updates.
- [ ] Student disputes → entry appears in `adminDisputeQueue` → admin resolves
      both ways (payout + refund).
- [ ] 48h auto-confirm pays the counselor without any action (watch
      `functions:log` for `autoConfirmAndPayOut`).
- [ ] A second user on the same device signs out/in and sees **their own** data
      (device-local session state is cleared on sign-out).
