import { FakeFirestore } from './firestore_fake';

var mockDb: FakeFirestore;
var mockVerify: jest.Mock;
var mockConfirm: jest.Mock;

jest.mock('firebase-admin', () => {
  const FieldValue = {
    serverTimestamp: () => ({ toMillis: () => Date.now() }),
    delete: () => 'DEL',
  };
  // Stable object so `admin.firestore()` stays valid across per-test fake
  // reassignments. FieldValue lives on the firestore() function itself, as
  // the production code accesses `admin.firestore.FieldValue`.
  const stable: any = {
    collection: (name: string) => mockDb.collection(name),
  };
  const fs: any = () => stable;
  fs.FieldValue = FieldValue;
  return { firestore: fs };
});

jest.mock('firebase-functions', () => ({
  https: { onRequest: (fn: any) => fn },
}));

jest.mock('../src/config', () => ({
  env: { flutterwaveWebhookHash: 'test-hash' },
}));

jest.mock('../src/flutterwave', () => ({
  verifyTransactionByRef: (...args: any[]) => mockVerify(...args),
}));

jest.mock('../src/bookings', () => ({
  confirmPaidBooking: (...args: any[]) => mockConfirm(...args),
}));

import { flutterwaveWebhook } from '../src/payments';

function makeReq(overrides: Record<string, any> = {}): any {
  return { method: 'POST', headers: {}, body: {}, ...overrides };
}

function makeRes(): any {
  const res: any = { statusCode: 200, body: '' };
  res.status = jest.fn((code: number) => {
    res.statusCode = code;
    return res;
  });
  res.send = jest.fn((b: string) => {
    res.body = b;
    return res;
  });
  return res;
}

function seedBooking(overrides: Record<string, any> = {}) {
  mockDb = new FakeFirestore({
    'bookings/b1': {
      status: 'payment_pending',
      feeAmount: 100,
      currency: 'NGN',
      ...overrides,
    },
  });
}

function successBody(overrides: Record<string, any> = {}) {
  return {
    event: 'charge.completed',
    data: {
      id: 123,
      tx_ref: 'booking_b1',
      status: 'successful',
      amount: 100,
      currency: 'NGN',
      ...overrides,
    },
  };
}

const VERIFIED_TX = {
  id: 123,
  tx_ref: 'booking_b1',
  status: 'successful',
  amount: 100,
  currency: 'NGN',
};

describe('flutterwaveWebhook', () => {
  beforeEach(() => {
    mockVerify = jest.fn();
    mockConfirm = jest.fn();
    seedBooking();
  });

  it('rejects non-POST requests with 405', async () => {
    const res = makeRes();
    await flutterwaveWebhook(makeReq({ method: 'GET' }), res);
    expect(res.statusCode).toBe(405);
    expect(mockConfirm).not.toHaveBeenCalled();
  });

  it('rejects requests with a missing or wrong signature', async () => {
    const res = makeRes();
    await flutterwaveWebhook(makeReq({ body: successBody() }), res);
    expect(res.statusCode).toBe(401);

    const res2 = makeRes();
    await flutterwaveWebhook(
      makeReq({ headers: { 'verif-hash': 'wrong' }, body: successBody() }),
      res2,
    );
    expect(res2.statusCode).toBe(401);
    expect(mockConfirm).not.toHaveBeenCalled();
  });

  it('confirms a booking only after verifying signature, tx id, amount and currency', async () => {
    mockVerify.mockResolvedValue(VERIFIED_TX);
    const res = makeRes();
    await flutterwaveWebhook(
      makeReq({ headers: { 'verif-hash': 'test-hash' }, body: successBody() }),
      res,
    );
    expect(res.statusCode).toBe(200);
    expect(mockConfirm).toHaveBeenCalledWith('b1', '123', 'booking_b1');
  });

  it('does not confirm when the server-side verification fails', async () => {
    mockVerify.mockResolvedValue(null);
    const res = makeRes();
    await flutterwaveWebhook(
      makeReq({ headers: { 'verif-hash': 'test-hash' }, body: successBody() }),
      res,
    );
    expect(mockConfirm).not.toHaveBeenCalled();
  });

  it('does not confirm when the webhook tx id does not match the verified one', async () => {
    mockVerify.mockResolvedValue(VERIFIED_TX);
    const res = makeRes();
    await flutterwaveWebhook(
      makeReq({
        headers: { 'verif-hash': 'test-hash' },
        body: successBody({ id: 999 }),
      }),
      res,
    );
    expect(mockConfirm).not.toHaveBeenCalled();
  });

  it('does not confirm when the webhook payload omits the tx id', async () => {
    mockVerify.mockResolvedValue(VERIFIED_TX);
    const res = makeRes();
    const body = successBody();
    const data = body.data as Record<string, unknown>;
    delete data.id;
    await flutterwaveWebhook(
      makeReq({ headers: { 'verif-hash': 'test-hash' }, body }),
      res,
    );
    expect(mockConfirm).not.toHaveBeenCalled();
  });

  it('does not confirm when the paid amount differs from the booking fee', async () => {
    mockVerify.mockResolvedValue({ ...VERIFIED_TX, amount: 99.5 });
    const res = makeRes();
    await flutterwaveWebhook(
      makeReq({
        headers: { 'verif-hash': 'test-hash' },
        body: successBody({ amount: 99.5 }),
      }),
      res,
    );
    expect(mockConfirm).not.toHaveBeenCalled();
  });

  it('does not confirm when the currency differs from the booking currency', async () => {
    mockVerify.mockResolvedValue({ ...VERIFIED_TX, currency: 'GHS' });
    const res = makeRes();
    await flutterwaveWebhook(
      makeReq({
        headers: { 'verif-hash': 'test-hash' },
        body: successBody({ currency: 'GHS' }),
      }),
      res,
    );
    expect(mockConfirm).not.toHaveBeenCalled();
  });

  it('does not confirm a booking that is no longer payment_pending', async () => {
    seedBooking({ status: 'confirmed' });
    mockVerify.mockResolvedValue(VERIFIED_TX);
    const res = makeRes();
    await flutterwaveWebhook(
      makeReq({ headers: { 'verif-hash': 'test-hash' }, body: successBody() }),
      res,
    );
    expect(mockConfirm).not.toHaveBeenCalled();
  });

  it('releases the slot (payment_pending -> requested) on a failed/cancelled charge', async () => {
    const res = makeRes();
    await flutterwaveWebhook(
      makeReq({
        headers: { 'verif-hash': 'test-hash' },
        body: { event: 'charge.failed', data: { tx_ref: 'booking_b1', status: 'failed' } },
      }),
      res,
    );
    const booking = mockDb.store.get('bookings/b1');
    expect(booking.status).toBe('requested');
    expect(booking.paymentTxRef).toBeUndefined();
  });

  it('does not downgrade an already-confirmed booking on a late failure event', async () => {
    seedBooking({ status: 'confirmed' });
    const res = makeRes();
    await flutterwaveWebhook(
      makeReq({
        headers: { 'verif-hash': 'test-hash' },
        body: { event: 'charge.cancelled', data: { tx_ref: 'booking_b1' } },
      }),
      res,
    );
    expect(mockDb.store.get('bookings/b1').status).toBe('confirmed');
  });
});
