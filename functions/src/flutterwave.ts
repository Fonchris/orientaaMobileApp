import axios from 'axios';
import { env } from './config';

const client = () =>
  axios.create({
    baseURL: env.flutterwaveBaseUrl,
    headers: { Authorization: `Bearer ${env.flutterwaveSecretKey}` },
    timeout: 15000,
  });

export interface PaymentInitParams {
  amount: number;
  currency: string;
  txRef: string;
  customer: { email: string; name: string };
  /** Booked slot copy shown on the hosted checkout page. */
  meta?: Record<string, unknown>;
}

/** Creates a hosted checkout session and returns the payment link. */
export async function initializePayment(
  params: PaymentInitParams,
): Promise<{ link: string; id: string }> {
  const { data } = await client().post('/payments', {
    tx_ref: params.txRef,
    amount: params.amount,
    currency: params.currency,
    redirect_url: params.meta?.redirectUrl ?? undefined,
    customer: {
      email: params.customer.email,
      name: params.customer.name,
    },
    customizations: {
      title: 'Orientaa session',
      description: '1:1 counseling session booking',
    },
    meta: { ...(params.meta ?? {}), tx_ref: params.txRef },
    payment_options: 'card, mobilemoneyuganda,mobilemoneyrwanda,mobilemoneyghana,mobilemoneyzambia,mobilemoneyfranco,mobilemoneykenya,mpesa,mtn,orange,moov,flooz',
  });
  return { link: data?.data?.link, id: String(data?.data?.id ?? '') };
}

/** Verifies a transaction by tx_ref. Returns the raw data or null. */
export async function verifyTransactionByRef(
  txRef: string,
): Promise<FlutterwaveTransaction | null> {
  const { data } = await client().get(`/transactions/verify_by_reference?tx_ref=${encodeURIComponent(txRef)}`);
  if (data?.status !== 'success' || !data?.data) return null;
  return data.data as FlutterwaveTransaction;
}

export interface FlutterwaveTransaction {
  id: number;
  tx_ref: string;
  amount: number;
  currency: string;
  status: string; // 'successful' | 'failed' | ...
  created_at?: string;
}

export interface TransferParams {
  amount: number;
  currency: string;
  /** e.g. 'MTN-MOMO' for mobile money, or a bank code. */
  accountBank: string;
  accountNumber: string;
  accountName?: string;
  reference: string;
  narration?: string;
}

/** Initiates a payout (counselor payment). Returns the transfer reference. */
export async function initiateTransfer(
  params: TransferParams,
): Promise<{ reference: string }> {
  const { data } = await client().post('/transfers', {
    amount: params.amount,
    currency: params.currency,
    account_bank: params.accountBank,
    account_number: params.accountNumber,
    account_name: params.accountName ?? 'Orientaa Counselor',
    reference: params.reference,
    narration: params.narration ?? 'Orientaa session payout',
  });
  return { reference: String(data?.data?.reference ?? params.reference) };
}

/** Refunds a settled transaction (dispute upheld). */
export async function refundTransaction(transactionId: string): Promise<void> {
  await client().post(`/transactions/${encodeURIComponent(transactionId)}/refund`, {
    amount: 0, // full refund
  });
}
