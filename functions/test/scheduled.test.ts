import { FakeFirestore } from './firestore_fake';

var mockDb: FakeFirestore;
var mockInitiateTransfer: jest.Mock;
var mockNotifyBothParties: jest.Mock;

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
  // FieldValue/Timestamp are accessed as `admin.firestore.FieldValue`, i.e.
  // properties of the firestore() function itself.
  const stable: any = {
    collection: (name: string) => mockDb.collection(name),
    runTransaction: (cb: any) => mockDb.runTransaction(cb),
  };
  const fs: any = () => stable;
  fs.FieldValue = FieldValue;
  fs.Timestamp = Timestamp;
  return { firestore: fs };
});

jest.mock('firebase-functions', () => ({
  scheduler: { onSchedule: (_opts: any, fn: any) => fn },
  https: { onRequest: (fn: any) => fn },
}));

jest.mock('../src/flutterwave', () => ({
  initiateTransfer: (...args: any[]) => mockInitiateTransfer(...args),
  refundTransaction: jest.fn(),
}));

jest.mock('../src/counselor', () => ({ markStaleOffline: jest.fn() }));

jest.mock('../src/notifications', () => ({
  notifyUser: jest.fn(),
  notifyBothParties: (...args: any[]) => mockNotifyBothParties(...args),
}));

import { payOutCounselor } from '../src/scheduled';

function seedCompletedBooking(overrides: Record<string, any> = {}) {
  mockDb = new FakeFirestore({
    'bookings/b1': {
      studentUid: 'student-1',
      counselorUid: 'counselor-1',
      scheduledStart: { toMillis: () => 0 },
      scheduledEnd: { toMillis: () => 0 },
      feeAmount: 100,
      currency: 'NGN',
      platformCommission: 10,
      counselorPayoutAmount: 90,
      status: 'completed',
      ...overrides,
    },
    'counselorPrivate/counselor-1': {
      payoutAccountDetails: {
        provider: 'mobile_money',
        accountName: 'Amina Yusuf',
        accountNumber: '0551234567',
      },
    },
  });
}

describe('payOutCounselor', () => {
  beforeEach(() => {
    mockInitiateTransfer = jest.fn().mockResolvedValue({ reference: 'ref-1' });
    mockNotifyBothParties = jest.fn().mockResolvedValue(undefined);
  });

  it('pays out an eligible completed booking and marks it paid_out', async () => {
    seedCompletedBooking();
    const ok = await payOutCounselor('b1');

    expect(ok).toBe(true);
    expect(mockInitiateTransfer).toHaveBeenCalledWith(
      expect.objectContaining({
        amount: 90,
        currency: 'NGN',
        accountNumber: '0551234567',
        reference: 'payout_b1',
      }),
    );
    const booking = mockDb.store.get('bookings/b1');
    expect(booking.status).toBe('paid_out');
    expect(booking.payoutState).toBe('paid');
    expect(booking.payoutReference).toBe('ref-1');
    expect(booking.studentConfirmedAt).toBeDefined(); // auto-confirmed
    expect(mockNotifyBothParties).toHaveBeenCalled();
  });

  it('refuses to pay out a disputed booking unless explicitly allowed', async () => {
    seedCompletedBooking({ status: 'disputed' });
    const ok = await payOutCounselor('b1');
    expect(ok).toBe(false);
    expect(mockInitiateTransfer).not.toHaveBeenCalled();
    expect(mockDb.store.get('bookings/b1').status).toBe('disputed');
  });

  it('pays out a dispute-rejected booking when allowDisputed is set', async () => {
    seedCompletedBooking({ status: 'disputed' });
    const ok = await payOutCounselor('b1', true);
    expect(ok).toBe(true);
    expect(mockInitiateTransfer).toHaveBeenCalled();
    expect(mockDb.store.get('bookings/b1').status).toBe('paid_out');
  });

  it('marks the payout failed when the counselor has no payout account', async () => {
    seedCompletedBooking();
    mockDb.store.set('counselorPrivate/counselor-1', {});
    const ok = await payOutCounselor('b1');
    expect(ok).toBe(false);
    expect(mockInitiateTransfer).not.toHaveBeenCalled();
    expect(mockDb.store.get('bookings/b1').payoutState).toBe('failed');
  });

  it('never double-pays a booking that already has payoutState paid', async () => {
    seedCompletedBooking({ payoutState: 'paid' });
    const ok = await payOutCounselor('b1');
    expect(ok).toBe(false);
    expect(mockInitiateTransfer).not.toHaveBeenCalled();
  });

  it('backs off while a transfer is processing within the cooldown window', async () => {
    seedCompletedBooking({
      payoutState: 'processing',
      payoutAttemptedAt: { toMillis: () => Date.now() },
    });
    const ok = await payOutCounselor('b1');
    expect(ok).toBe(false);
    expect(mockInitiateTransfer).not.toHaveBeenCalled();
  });

  it('returns false for an unknown booking', async () => {
    mockDb = new FakeFirestore();
    expect(await payOutCounselor('nope')).toBe(false);
    expect(mockInitiateTransfer).not.toHaveBeenCalled();
  });
});
