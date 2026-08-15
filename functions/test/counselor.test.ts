import { FakeFirestore } from './firestore_fake';

var mockDb: FakeFirestore;
var mockNotifyUser: jest.Mock;

jest.mock('firebase-admin', () => {
  const FieldValue = {
    serverTimestamp: () => ({ toMillis: () => Date.now() }),
    delete: () => 'DEL',
    increment: (n: number) => n,
  };
  const Timestamp = {
    now: () => ({ toMillis: () => Date.now() }),
    fromDate: (d: Date) => ({ toMillis: () => d.getTime() }),
  };
  // `db` is captured once at module import, so firestore() must return a
  // stable object that delegates to the per-test FakeFirestore instance.
  // FieldValue is accessed as `admin.firestore.FieldValue` — a property of
  // the firestore() function itself.
  const stable: any = {
    collection: (name: string) => mockDb.collection(name),
    runTransaction: (cb: any) => mockDb.runTransaction(cb),
  };
  const fs: any = () => stable;
  fs.FieldValue = FieldValue;
  fs.Timestamp = Timestamp;
  return { firestore: fs };
});

// Mock the exact subpath used by counselor.ts — a jest.mock of the root
// 'firebase-functions' package does not intercept 'firebase-functions/v2/https'.
jest.mock('firebase-functions/v2/https', () => ({
  onCall: (fn: any) => fn,
  HttpsError: class HttpsError extends Error {
    code: string;
    constructor(code: string, message: string) {
      super(message);
      this.code = code;
    }
  },
}));

jest.mock('../src/notifications', () => ({
  notifyUser: (...args: any[]) => mockNotifyUser(...args),
  notifyBothParties: jest.fn(),
}));

import { reviewCounselorApplication } from '../src/counselor';

// The real export is an onCall-wrapped RequestHandler (req, res); at runtime
// the firebase-functions mock turns it back into the raw handler, so cast to
// the callable shape here to keep ts-jest happy.
const review = reviewCounselorApplication as unknown as (request: {
  auth?: { uid: string; token?: Record<string, unknown> };
  data?: Record<string, unknown>;
}) => Promise<{ status: string }>;

function seedProfile(overrides: Record<string, any> = {}) {
  mockDb = new FakeFirestore({
    'counselorProfiles/c1': {
      uid: 'c1',
      displayName: 'Amina Yusuf',
      verificationStatus: 'pending',
      ...overrides,
    },
  });
}

function adminRequest(data: Record<string, any> = {}) {
  return { auth: { uid: 'admin-1', token: { admin: true } }, data };
}

describe('reviewCounselorApplication', () => {
  beforeEach(() => {
    mockNotifyUser = jest.fn().mockResolvedValue(undefined);
  });

  it('rejects callers without the admin custom claim', async () => {
    seedProfile();
    await expect(
      review({
        auth: { uid: 'student-1', token: {} },
        data: { uid: 'c1', action: 'approve' },
      }),
    ).rejects.toMatchObject({ code: 'permission-denied' });
    // The application is untouched.
    expect(mockDb.store.get('counselorProfiles/c1').verificationStatus).toBe('pending');
    expect(mockNotifyUser).not.toHaveBeenCalled();
  });

  it('rejects unauthenticated callers', async () => {
    seedProfile();
    await expect(
      review({ data: { uid: 'c1', action: 'approve' } }),
    ).rejects.toMatchObject({ code: 'unauthenticated' });
  });

  it('approves a pending application, stamps reviewedAt and notifies once', async () => {
    seedProfile();
    const result = await review(
      adminRequest({ uid: 'c1', action: 'approve' }),
    );
    expect(result).toEqual({ status: 'approved' });
    const profile = mockDb.store.get('counselorProfiles/c1');
    expect(profile.verificationStatus).toBe('approved');
    expect(profile.reviewedAt).toBeDefined();
    expect(mockNotifyUser).toHaveBeenCalledTimes(1);
    expect(mockNotifyUser.mock.calls[0][0]).toBe('c1');
  });

  it('rejects an application and notifies the counselor', async () => {
    seedProfile();
    await review(
      adminRequest({ uid: 'c1', action: 'reject' }),
    );
    expect(mockDb.store.get('counselorProfiles/c1').verificationStatus).toBe('rejected');
    expect(mockNotifyUser).toHaveBeenCalledTimes(1);
  });

  it('is idempotent: re-approving an approved profile sends no duplicate notification', async () => {
    seedProfile({ verificationStatus: 'approved' });
    const result = await review(
      adminRequest({ uid: 'c1', action: 'approve' }),
    );
    expect(result).toEqual({ status: 'approved' });
    expect(mockNotifyUser).not.toHaveBeenCalled();
    expect(mockDb.store.get('counselorProfiles/c1').verificationStatus).toBe('approved');
  });

  it('blocks an admin from reviewing their own application', async () => {
    seedProfile();
    await expect(
      review({
        auth: { uid: 'c1', token: { admin: true } },
        data: { uid: 'c1', action: 'approve' },
      }),
    ).rejects.toMatchObject({ code: 'invalid-argument' });
  });

  it('returns not-found when the target has no counselor profile', async () => {
    mockDb = new FakeFirestore();
    await expect(
      review(adminRequest({ uid: 'ghost', action: 'approve' })),
    ).rejects.toMatchObject({ code: 'not-found' });
  });

  it('rejects an unknown action', async () => {
    seedProfile();
    await expect(
      review(adminRequest({ uid: 'c1', action: 'ban' })),
    ).rejects.toMatchObject({ code: 'invalid-argument' });
    expect(mockDb.store.get('counselorProfiles/c1').verificationStatus).toBe('pending');
  });
});
