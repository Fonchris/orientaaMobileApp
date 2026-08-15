import { FakeFirestore } from './firestore_fake';

var mockDb: FakeFirestore;
var mockGenerateContent: jest.Mock;
var mockDownload: jest.Mock;
var mockGetMetadata: jest.Mock;
var mockFetchImpl: jest.Mock;

jest.mock('firebase-admin', () => {
  const FieldValue = {
    serverTimestamp: () => ({ toMillis: () => Date.now() }),
    delete: () => 'DEL',
    increment: (n: number) => n,
  };
  const stable: any = {
    collection: (name: string) => mockDb.collection(name),
    runTransaction: (cb: any) => mockDb.runTransaction(cb),
  };
  const fs: any = () => stable;
  fs.FieldValue = FieldValue;
  const storage: any = () => ({
    bucket: () => ({
      file: (path: string) => ({
        getMetadata: () => mockGetMetadata(path),
        download: () => mockDownload(path),
      }),
    }),
  });
  return { firestore: fs, storage };
});

// The trigger/scheduler subpaths are not covered by a root 'firebase-functions'
// mock — mirror the pattern used by counselor.test.ts and scheduled.test.ts.
jest.mock('firebase-functions/v2/firestore', () => ({
  onDocumentWritten: (_opts: any, fn: any) => fn,
}));

jest.mock('firebase-functions/v2/scheduler', () => ({
  onSchedule: (_opts: any, fn: any) => fn,
}));

jest.mock('firebase-functions/params', () => ({
  defineSecret: (name: string) => ({ name }),
}));

jest.mock('@google/generative-ai', () => ({
  GoogleGenerativeAI: jest.fn().mockImplementation(() => ({
    getGenerativeModel: () => ({
      generateContent: (...args: any[]) => mockGenerateContent(...args),
    }),
  })),
}));

import {
  cleanTitle,
  flagOverdueApplicationsNow,
  nameSimilarity,
  screenCounselorApplication,
  similarName,
  socialLinkIssues,
  storagePathFromUrl,
  urlWellFormed,
} from '../src/ai_screening';

const screen = screenCounselorApplication as unknown as (event: {
  params: { uid: string };
  data?: { after?: { data: () => Record<string, any> } };
}) => Promise<void>;

const DOC_URL =
  'https://firebasestorage.googleapis.com/v0/b/orientaa/o/counselor_ids%2Fc1%2Fdocument.jpg?alt=media&token=abc';

function submissionEvent(uid: string, profile: Record<string, any>) {
  return {
    params: { uid },
    data: {
      after: {
        // The screening trigger only fires on the submitVerification write,
        // which stamps `submittedAt` after the documents are in place.
        data: () => ({ submittedAt: { toMillis: () => Date.now() }, ...profile }),
      },
    },
  };
}

function seed(overrides: Record<string, any> = {}) {
  mockDb = new FakeFirestore({
    'counselorPrivate/c1': {
      idDocumentUrl: DOC_URL,
      credentialsUrl: DOC_URL,
      ...overrides,
    },
  });
  mockGetMetadata = jest
    .fn()
    .mockResolvedValue([{ size: '2048', contentType: 'image/jpeg' }]);
  mockDownload = jest.fn().mockResolvedValue([Buffer.from('fake-doc-bytes')]);
  mockGenerateContent = jest.fn().mockResolvedValue({
    response: {
      text: () => '{"isValid": true, "isBlank": false, "reason": "looks good"}',
    },
  });
  mockFetchImpl = jest
    .fn()
    .mockResolvedValue(new Response('<title>Amina Yusuf - LinkedIn</title>', { status: 200 }));
  (globalThis as any).fetch = mockFetchImpl;
}

describe('screenCounselorApplication', () => {
  beforeEach(() => {
    process.env.GEMINI_API_KEY = 'test-key';
    seed();
  });

  it('ignores profiles that are not pending (e.g. an admin approval)', async () => {
    await screen(submissionEvent('c1', { verificationStatus: 'approved' }));
    expect(mockGenerateContent).not.toHaveBeenCalled();
    expect(mockDb.store.get('counselorPrivate/c1')?.aiScreeningResult).toBeUndefined();
  });

  it('waits for submittedAt so the credentials-upload race never flags a fresh submission', async () => {
    await screen(
      submissionEvent('c1', {
        verificationStatus: 'pending',
        legalName: 'Amina Yusuf',
      }),
    );
    // Override: a profile write without submittedAt (e.g. the create write).
    await screen({
      params: { uid: 'c1' },
      data: {
        after: { data: () => ({ verificationStatus: 'pending', legalName: 'Amina Yusuf' }) },
      },
    });
    // Only the submittedAt run screened — the second call added nothing.
    expect(mockGenerateContent).toHaveBeenCalledTimes(2);
    expect(mockDb.store.get('counselorPrivate/c1').aiScreeningResult.status).toBe('looks_complete');
  });

  it('screens documents + social links and writes looks_complete when everything passes', async () => {
    await screen(
      submissionEvent('c1', {
        verificationStatus: 'pending',
        legalName: 'Amina Yusuf',
        socialLinks: { linkedin: 'https://www.linkedin.com/in/aminayusuf' },
      }),
    );

    const screening = mockDb.store.get('counselorPrivate/c1').aiScreeningResult;
    expect(screening.status).toBe('looks_complete');
    expect(screening.issues).toEqual([]);
    expect(screening.inputHash).toBeDefined();
    // Two documents, each sent to Gemini.
    expect(mockGenerateContent).toHaveBeenCalledTimes(2);
  });

  it('flags a blank/unreadable document as needs_attention', async () => {
    mockGenerateContent.mockResolvedValue({
      response: {
        text: () =>
          '{"isValid": false, "isBlank": true, "reason": "blank page"}',
      },
    });
    await screen(
      submissionEvent('c1', {
        verificationStatus: 'pending',
        legalName: 'Amina Yusuf',
      }),
    );
    const screening = mockDb.store.get('counselorPrivate/c1').aiScreeningResult;
    expect(screening.status).toBe('needs_attention');
    expect(screening.issues.join(' ')).toContain('blank or unreadable');
  });

  it('flags missing documents', async () => {
    seed({ idDocumentUrl: '', credentialsUrl: '' });
    await screen(
      submissionEvent('c1', {
        verificationStatus: 'pending',
        legalName: 'Amina Yusuf',
      }),
    );
    const screening = mockDb.store.get('counselorPrivate/c1').aiScreeningResult;
    expect(screening.status).toBe('needs_attention');
    expect(screening.issues).toHaveLength(2);
    expect(screening.issues.join(' ')).toContain('missing');
  });

  it('degrades to not_checked (never blocks) when the AI call fails', async () => {
    mockGenerateContent.mockRejectedValue(new Error('timeout'));
    await screen(
      submissionEvent('c1', {
        verificationStatus: 'pending',
        legalName: 'Amina Yusuf',
      }),
    );
    const screening = mockDb.store.get('counselorPrivate/c1').aiScreeningResult;
    expect(screening.status).toBe('not_checked');
    expect(screening.issues).toEqual([]);
  });

  it('is idempotent: identical inputs are not re-screened', async () => {
    await screen(
      submissionEvent('c1', {
        verificationStatus: 'pending',
        legalName: 'Amina Yusuf',
      }),
    );
    await screen(
      submissionEvent('c1', {
        verificationStatus: 'pending',
        legalName: 'Amina Yusuf',
      }),
    );
    expect(mockGenerateContent).toHaveBeenCalledTimes(2); // one full run only
  });

  it('re-screens when inputs changed (e.g. documents replaced)', async () => {
    await screen(
      submissionEvent('c1', {
        verificationStatus: 'pending',
        legalName: 'Amina Yusuf',
      }),
    );
    // Simulate the counselor re-uploading a credential after submission —
    // the hash differs so the screening runs again (no-op otherwise).
    mockDb.store.set('counselorPrivate/c1', {
      idDocumentUrl: DOC_URL,
      credentialsUrl: DOC_URL + '2',
    });
    await screen(
      submissionEvent('c1', {
        verificationStatus: 'pending',
        legalName: 'Amina Yusuf',
      }),
    );
    expect(mockGenerateContent).toHaveBeenCalledTimes(4); // two full runs
  });
});

describe('flagOverdueApplicationsNow', () => {
  it('flags a needs_attention application pending past the 48h SLA', async () => {
    mockDb = new FakeFirestore({
      'counselorProfiles/c1': {
        uid: 'c1',
        displayName: 'Amina Yusuf',
        verificationStatus: 'pending',
        createdAt: { toMillis: () => Date.now() - 3 * 86400000 },
      },
      'counselorPrivate/c1': {
        aiScreeningResult: {
          status: 'needs_attention',
          issues: ['LinkedIn URL did not resolve'],
        },
      },
    });

    const flagged = await flagOverdueApplicationsNow();
    expect(flagged).toBe(1);

    const alerts = [...mockDb.store.entries()].filter(([p]) =>
      p.startsWith('adminAlerts/'),
    );
    expect(alerts).toHaveLength(1);
    expect(alerts[0][1]).toMatchObject({
      type: 'overdue_application',
      counselorUid: 'c1',
      counselorName: 'Amina Yusuf',
      issuesCount: 1,
    });
    const screening =
      mockDb.store.get('counselorPrivate/c1').aiScreeningResult;
    expect(screening.overdueFlaggedAt).toBeDefined();
  });

  it('counts the SLA from the latest submittedAt, not the original createdAt', async () => {
    mockDb = new FakeFirestore({
      // Created 30 days ago but RE-submitted 2 hours ago — the 48h window
      // restarts on resubmission, so it must NOT be flagged yet.
      'counselorProfiles/c1': {
        uid: 'c1',
        verificationStatus: 'pending',
        createdAt: { toMillis: () => Date.now() - 30 * 86400000 },
        submittedAt: { toMillis: () => Date.now() - 2 * 3600000 },
      },
      'counselorPrivate/c1': {
        aiScreeningResult: { status: 'needs_attention', issues: ['x'] },
      },
    });
    expect(await flagOverdueApplicationsNow()).toBe(0);
  });

  it('skips clean, not_checked, recent and already-flagged applications', async () => {
    mockDb = new FakeFirestore({
      'counselorProfiles/clean': {
        uid: 'clean',
        verificationStatus: 'pending',
        createdAt: { toMillis: () => Date.now() - 3 * 86400000 },
      },
      'counselorPrivate/clean': {
        aiScreeningResult: { status: 'looks_complete', issues: [] },
      },
      'counselorProfiles/recent': {
        uid: 'recent',
        verificationStatus: 'pending',
        createdAt: { toMillis: () => Date.now() - 3600000 },
      },
      'counselorPrivate/recent': {
        aiScreeningResult: { status: 'needs_attention', issues: ['x'] },
      },
      'counselorProfiles/flagged': {
        uid: 'flagged',
        verificationStatus: 'pending',
        createdAt: { toMillis: () => Date.now() - 3 * 86400000 },
      },
      'counselorPrivate/flagged': {
        aiScreeningResult: {
          status: 'needs_attention',
          issues: ['x'],
          overdueFlaggedAt: { toMillis: () => Date.now() },
        },
      },
    });

    const flagged = await flagOverdueApplicationsNow();
    expect(flagged).toBe(0);
    expect([...mockDb.store.keys()].filter((p) => p.startsWith('adminAlerts/'))).toHaveLength(0);
  });
});

describe('pure helpers', () => {
  it('storagePathFromUrl extracts the object path from a download URL', () => {
    expect(storagePathFromUrl(DOC_URL)).toBe('counselor_ids/c1/document.jpg');
    expect(storagePathFromUrl('https://example.com/x.pdf')).toBeNull();
    expect(storagePathFromUrl('not a url')).toBeNull();
  });

  it('urlWellFormed checks http(s) + expected host', () => {
    expect(urlWellFormed('https://www.linkedin.com/in/a', 'linkedin')).toBe(true);
    expect(urlWellFormed('https://twitter.com/a', 'x')).toBe(true);
    expect(urlWellFormed('https://example.com/a', 'linkedin')).toBe(false);
    expect(urlWellFormed('ftp://linkedin.com/a', 'linkedin')).toBe(false);
    expect(urlWellFormed('garbage', 'instagram')).toBe(false);
  });

  it('nameSimilarity + cleanTitle power the fuzzy name check', () => {
    expect(nameSimilarity('Amina Yusuf', 'amina yusuf linkedin')).toBeCloseTo(1);
    expect(cleanTitle('Amina Yusuf (@aminayusuf) | LinkedIn')).toBe('Amina Yusuf');
    expect(similarName('Amina Yusuf', 'Amina Yusuf | LinkedIn')).toBe(true);
    expect(similarName('Amina Yusuf', 'Marketing Professional | LinkedIn')).toBe(false);
  });

  it('socialLinkIssues flags malformed, unresolvable and mismatched links', async () => {
    // Fresh Response per call — a body stream can only be read once (real
    // fetches return a new Response every request).
    const fetchOk = jest
      .fn()
      .mockImplementation(() =>
        Promise.resolve(
          new Response('<title>John Smith - LinkedIn</title>', { status: 200 }),
        ),
      );
    const issues = await socialLinkIssues(
      {
        linkedin: 'https://www.linkedin.com/in/johnsmith',
        x: 'https://x.com/johnsmith',
      },
      'Amina Yusuf',
      fetchOk as typeof fetch,
    );
    // Both reachable profiles carry a name that doesn't match the legal name.
    expect(issues).toHaveLength(2);
    expect(issues.every((i) => i.includes("doesn't match"))).toBe(true);

    const fetch404 = jest.fn().mockResolvedValue(new Response('gone', { status: 404 }));
    const issues404 = await socialLinkIssues(
      { instagram: 'https://instagram.com/nope' },
      'Amina Yusuf',
      fetch404 as typeof fetch,
    );
    expect(issues404[0]).toContain('did not resolve');

    const malformed = await socialLinkIssues(
      { tiktok: 'https://example.com/not-tiktok' },
      'Amina Yusuf',
      fetchOk as typeof fetch,
    );
    expect(malformed[0]).toContain('not a valid tiktok link');
  });
});
