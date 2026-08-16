/**
 * End-to-end integration test for the counselor AI pre-screening flow.
 *
 * Unlike the unit tests (which stub firebase-admin and the Firestore store),
 * this drives the REAL handler through REAL Firestore + Storage emulators —
 * actual document writes/reads, real Storage metadata + downloads — with only
 * the Gemini model faked (no external AI calls, no network).
 *
 * Run with:  npm run test:integration
 * (starts the firestore + storage emulators via `firebase emulators:exec`,
 * then runs this file against them and tears the emulators down).
 *
 * Scope note: the handler runs through the Admin SDK, which bypasses security
 * rules — this proves the screening logic end-to-end, not rule enforcement.
 * Rule access control is verified separately (manual two-account emulator
 * check; see DEPLOYMENT.md §10).
 */

import * as admin from 'firebase-admin';

// Emulator connectivity — `firebase emulators:exec` exports these to the
// child process; the fallbacks let the file run from an IDE against a
// manually-started emulator too.
process.env.FIRESTORE_EMULATOR_HOST ||= 'localhost:8080';
process.env.STORAGE_EMULATOR_HOST ||= 'localhost:9199';
process.env.FIREBASE_STORAGE_EMULATOR_HOST ||= 'localhost:9199';
process.env.GCLOUD_PROJECT ||= 'demo-orientaa';
// Satisfies the geminiModel() API-key guard; the model below is faked anyway.
process.env.GEMINI_API_KEY = 'fake-key-for-integration-test';

// ── Faked Gemini ─────────────────────────────────────────────────────────
// Returns the queued structured verdicts (strings = JSON) or throws when the
// queued item is an Error — mirroring the real API contract so the handler's
// success AND failure paths are exercised.
const mockGeminiVerdicts: (string | Error)[] = [];
let mockGeminiCallCount = 0;
jest.mock('@google/generative-ai', () => ({
  GoogleGenerativeAI: jest.fn().mockImplementation(() => ({
    getGenerativeModel: () => ({
      generateContent: jest.fn().mockImplementation(async () => {
        mockGeminiCallCount += 1;
        const next = mockGeminiVerdicts.shift();
        if (next instanceof Error) throw next;
        return {
          response: {
            text: () =>
              next ?? '{"isValid": true, "isBlank": false, "reason": "ok"}',
          },
        };
      }),
    }),
  })),
}));

const PROJECT_ID = 'demo-orientaa';
const BUCKET = `${PROJECT_ID}.appspot.com`;
const DOC_PATH = 'counselor_ids/c1/document.jpg';
// The handler only parses the storage path out of this URL — the actual
// download goes through the admin SDK to the emulator, never through this URL.
const DOC_URL =
  `https://firebasestorage.googleapis.com/v0/b/${BUCKET}/o/` +
  'counselor_ids%2Fc1%2Fdocument.jpg?alt=media';

const VALID_VERDICT =
  '{"isValid": true, "isBlank": false, "reason": "looks like a valid ID"}';
const BLANK_VERDICT =
  '{"isValid": false, "isBlank": true, "reason": "blank page"}';

type Handler = (
  uid: string,
  after: Record<string, unknown> | undefined,
) => Promise<void>;

let screenHandler: Handler;

const db = () => admin.firestore();
const bucket = () => admin.storage().bucket(BUCKET);

beforeAll(async () => {
  admin.initializeApp({ projectId: PROJECT_ID, storageBucket: BUCKET });
  const mod = await import('../../src/ai_screening');
  screenHandler = mod.screenCounselorApplicationHandler;
}, 60000);

afterEach(async () => {
  mockGeminiVerdicts.length = 0;
  mockGeminiCallCount = 0;
  await bucket()
    .file(DOC_PATH)
    .delete()
    .catch(() => {});
  await db().collection('counselorPrivate').doc('c1').delete().catch(() => {});
  await db().collection('counselorProfiles').doc('c1').delete().catch(() => {});
});

afterAll(async () => {
  await admin.app().delete();
});

/** Uploads the "verification document" to the emulator's Storage. */
async function uploadDocument(
  contentType = 'image/jpeg',
  bytes = Buffer.from('fake-document-bytes'),
): Promise<void> {
  await bucket().file(DOC_PATH).save(bytes, {
    contentType,
    metadata: { metadata: { firebaseStorageDownloadTokens: 'test-token' } },
  });
}

async function seedPrivate(urls: { id?: string; credentials?: string }) {
  await db().collection('counselorPrivate').doc('c1').set({
    idDocumentUrl: urls.id ?? DOC_URL,
    credentialsUrl: urls.credentials ?? DOC_URL,
  });
}

async function seedProfile(overrides: Record<string, unknown> = {}) {
  await db().collection('counselorProfiles').doc('c1').set({
    uid: 'c1',
    displayName: 'Amina Yusuf',
    verificationStatus: 'pending',
    ...overrides,
  });
}

function submissionAfter(overrides: Record<string, unknown> = {}) {
  return {
    verificationStatus: 'pending',
    // A real Firestore Timestamp — the handler only checks truthiness, but
    // this matches the trigger's runtime shape exactly.
    submittedAt: admin.firestore.Timestamp.now(),
    legalName: 'Amina Yusuf',
    socialLinks: {},
    ...overrides,
  };
}

async function readScreeningResult(): Promise<Record<string, any>> {
  const snap = await db().collection('counselorPrivate').doc('c1').get();
  expect(snap.exists).toBe(true);
  return snap.data()?.aiScreeningResult ?? {};
}

describe('screenCounselorApplication — emulator integration', () => {
  it('screens two uploaded documents through real Storage and writes looks_complete', async () => {
    await uploadDocument();
    await seedPrivate({});
    await seedProfile();
    mockGeminiVerdicts.push(VALID_VERDICT, VALID_VERDICT);

    await screenHandler('c1', submissionAfter());

    const screening = await readScreeningResult();
    expect(screening.status).toBe('looks_complete');
    expect(screening.issues).toEqual([]);
    expect(screening.inputHash).toBeDefined();
    // One Gemini call per document.
    expect(mockGeminiCallCount).toBe(2);

    // The trigger must never touch verificationStatus — still pending.
    const profile = (await db().collection('counselorProfiles').doc('c1').get()).data();
    expect(profile?.verificationStatus).toBe('pending');
  });

  it('flags a blank document as needs_attention with a human-readable issue', async () => {
    await uploadDocument();
    await seedPrivate({});
    await seedProfile();
    mockGeminiVerdicts.push(BLANK_VERDICT, BLANK_VERDICT);

    await screenHandler('c1', submissionAfter());

    const screening = await readScreeningResult();
    expect(screening.status).toBe('needs_attention');
    expect(screening.issues.join(' ')).toContain('blank or unreadable');
  });

  it('flags a document that is missing from Storage without calling Gemini', async () => {
    // seedPrivate points at the path, but the file is never uploaded.
    await seedPrivate({});
    await seedProfile();

    await screenHandler('c1', submissionAfter());

    const screening = await readScreeningResult();
    expect(screening.status).toBe('needs_attention');
    expect(screening.issues.join(' ')).toContain('could not be read from storage');
    // No document reached Gemini.
    expect(mockGeminiCallCount).toBe(0);
  });

  it('degrades to not_checked when the AI call fails and never blocks the application', async () => {
    await uploadDocument();
    await seedPrivate({});
    await seedProfile();
    mockGeminiVerdicts.push(new Error('upstream timeout'), new Error('upstream timeout'));

    await screenHandler('c1', submissionAfter());

    const screening = await readScreeningResult();
    expect(screening.status).toBe('not_checked');
    expect(screening.issues).toEqual([]);
    const profile = (await db().collection('counselorProfiles').doc('c1').get()).data();
    expect(profile?.verificationStatus).toBe('pending');
  });

  it('flags a malformed social link without any network call', async () => {
    await uploadDocument();
    await seedPrivate({});
    await seedProfile();
    mockGeminiVerdicts.push(VALID_VERDICT, VALID_VERDICT);

    await screenHandler(
      'c1',
      submissionAfter({ socialLinks: { linkedin: 'not-a-url' } }),
    );

    const screening = await readScreeningResult();
    expect(screening.status).toBe('needs_attention');
    expect(screening.issues.join(' ')).toContain('LinkedIn URL is not a valid');
  });

  it('is idempotent — a second identical submission is not re-screened', async () => {
    await uploadDocument();
    await seedPrivate({});
    await seedProfile();
    mockGeminiVerdicts.push(VALID_VERDICT, VALID_VERDICT);

    await screenHandler('c1', submissionAfter());
    await screenHandler('c1', submissionAfter());

    const screening = await readScreeningResult();
    expect(screening.status).toBe('looks_complete');
    // Only the first run hit Gemini (2 calls for 2 documents).
    expect(mockGeminiCallCount).toBe(2);
  });

  it('ignores non-pending profiles (e.g. an admin approval write)', async () => {
    await seedPrivate({});
    await seedProfile();

    await screenHandler('c1', {
      verificationStatus: 'approved',
      legalName: 'Amina Yusuf',
    });

    expect(mockGeminiCallCount).toBe(0);
    const snap = await db().collection('counselorPrivate').doc('c1').get();
    expect(snap.data()?.aiScreeningResult).toBeUndefined();
  });
});
