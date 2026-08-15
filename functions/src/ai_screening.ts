import * as admin from 'firebase-admin';
import { onDocumentWritten } from 'firebase-functions/v2/firestore';
import { onSchedule } from 'firebase-functions/v2/scheduler';
import { defineSecret } from 'firebase-functions/params';
import { GoogleGenerativeAI } from '@google/generative-ai';

import {
  APPLICATION_REVIEW_SLA_HOURS,
  GEMINI_MODEL,
  MAX_SCREENING_BYTES,
} from './config';

const db = admin.firestore();

/**
 * AI pre-screening for counselor applications.
 *
 * Runs asynchronously after a counselor submits their application (a
 * Firestore trigger on `counselorProfiles/{uid}` when `verificationStatus`
 * becomes `pending`), so the applicant sees "under review" immediately and
 * never waits on an AI call. The result is written to
 * `counselorPrivate/{uid}.aiScreeningResult` — owner+admin read, exactly like
 * the ID/credentials documents it reports on — and is NEVER shown to the
 * applicant. It can never approve or reject: `verificationStatus` stays
 * `pending` and only the human admin action moves it.
 *
 * On any AI/API failure the result degrades to `{ status: "not_checked",
 * issues: [] }` so the application still flows to normal human review.
 */
export const geminiApiKey = defineSecret('GEMINI_API_KEY');

// ── Pure helpers (unit-testable without external calls) ─────────────────

/** Extracts the storage object path from a firebasestorage download URL. */
export function storagePathFromUrl(url: string): string | null {
  try {
    const u = new URL(url);
    if (u.hostname !== 'firebasestorage.googleapis.com') return null;
    const m = u.pathname.match(/^\/v0\/b\/[^/]+\/o\/(.+)$/);
    if (!m) return null;
    return decodeURIComponent(m[1]);
  } catch {
    return null;
  }
}

const PLATFORM_HOSTS: Record<string, string[]> = {
  linkedin: ['linkedin.com'],
  x: ['x.com', 'twitter.com'],
  instagram: ['instagram.com'],
  tiktok: ['tiktok.com'],
};

/** True when the URL is http(s) and its host belongs to the platform. */
export function urlWellFormed(url: string, platform: string): boolean {
  const hosts = PLATFORM_HOSTS[platform];
  if (!hosts) return false;
  try {
    const u = new URL(url);
    if (u.protocol !== 'https:' && u.protocol !== 'http:') return false;
    const host = u.hostname.toLowerCase();
    return hosts.some((h) => host === h || host.endsWith('.' + h));
  } catch {
    return false;
  }
}

/** Token-overlap similarity in [0, 1] between two names. */
export function nameSimilarity(a: string, b: string): number {
  const tokens = (s: string) =>
    s
      .toLowerCase()
      .split(/[^a-z0-9]+/)
      .map((t) => t.trim())
      .filter((t) => t.length >= 2);
  const at = tokens(a);
  const bt = tokens(b);
  if (at.length === 0 || bt.length === 0) return 0;
  const inter = at.filter((t) => bt.includes(t)).length;
  return inter / Math.min(at.length, bt.length);
}

const BRAND_TOKENS = new Set([
  'linkedin',
  'x',
  'twitter',
  'instagram',
  'tiktok',
  'photos',
  'videos',
  'watch',
  'on',
  'and',
]);

/** Strips handles and trailing platform branding from a profile-page title. */
export function cleanTitle(raw: string): string {
  let t = raw.replace(/\(@[^)]*\)/g, ' ');
  const parts = t.split(/\s*[|•·/-]\s*/);
  while (parts.length > 1) {
    const words = parts[parts.length - 1]
      .toLowerCase()
      .split(/[^a-z0-9]+/)
      .filter(Boolean);
    if (words.length > 0 && words.every((w) => BRAND_TOKENS.has(w))) {
      parts.pop();
    } else {
      break;
    }
  }
  return parts.join(' ').trim();
}

/**
 * Fuzzy name match between the applicant's legal name and a profile-page
 * title. A heuristic only — never used to approve or reject.
 */
export function similarName(legalName: string, pageTitle: string): boolean {
  if (nameSimilarity(legalName, pageTitle) >= 0.5) return true;
  return nameSimilarity(legalName, cleanTitle(pageTitle)) >= 0.5;
}

const FETCH_TIMEOUT_MS = 10_000;

/** Cap on how much of a profile page is read (only the <title> is used). */
const MAX_PAGE_BYTES = 1_048_576; // 1 MB

async function fetchWithTimeout(
  url: string,
  fetchImpl: typeof fetch,
): Promise<Response | null> {
  const controller = new AbortController();
  const timer = setTimeout(() => controller.abort(), FETCH_TIMEOUT_MS);
  try {
    return await fetchImpl(url, {
      redirect: 'follow',
      signal: controller.signal,
      headers: { 'user-agent': 'Mozilla/5.0 (Orientaa verification bot)' },
    });
  } catch {
    return null;
  } finally {
    clearTimeout(timer);
  }
}

/** Reads up to [capBytes] of the response body (the title is in the head). */
async function readHtml(response: Response, capBytes = MAX_PAGE_BYTES): Promise<string> {
  const reader = response.body?.getReader();
  if (!reader) return '';
  const chunks: Uint8Array[] = [];
  let total = 0;
  for (;;) {
    const { done, value } = await reader.read();
    if (done) break;
    if (!value) continue;
    total += value.byteLength;
    if (total > capBytes) break;
    chunks.push(value);
  }
  reader.cancel().catch(() => {});
  return Buffer.concat(chunks).toString('utf8');
}

function extractTitle(html: string): string {
  const m = html.match(/<title[^>]*>([\s\S]*?)<\/title>/i);
  if (!m) return '';
  return m[1]
    .replace(/<[^>]+>/g, ' ')
    .replace(/&amp;/g, '&')
    .replace(/&nbsp;/g, ' ')
    .replace(/\s+/g, ' ')
    .trim();
}

const PLATFORM_LABEL: Record<string, string> = {
  linkedin: 'LinkedIn',
  x: 'X (Twitter)',
  instagram: 'Instagram',
  tiktok: 'TikTok',
};

/**
 * Verifies the submitted social links: well-formed URL for the right domain,
 * a basic HTTP resolve check, and — when the profile page is reachable and
 * has a readable title — a best-effort fuzzy name match against the legal
 * name. Each failure yields a short human-readable issue string.
 */
export async function socialLinkIssues(
  links: Record<string, string>,
  legalName: string,
  fetchImpl: typeof fetch = fetch,
): Promise<string[]> {
  const issues: string[] = [];
  for (const platform of Object.keys(PLATFORM_LABEL)) {
    const url = (links[platform] ?? '').trim();
    if (!url) continue;
    const label = PLATFORM_LABEL[platform];

    if (!urlWellFormed(url, platform)) {
      issues.push(`${label} URL is not a valid ${platform} link.`);
      continue;
    }
    const response = await fetchWithTimeout(url, fetchImpl);
    if (!response) {
      issues.push(`${label} URL did not resolve (network error or timeout).`);
      continue;
    }
    if (response.status >= 400) {
      issues.push(`${label} URL did not resolve (HTTP ${response.status}).`);
      continue;
    }
    const html = await readHtml(response).catch(() => '');
    if (!html) continue;
    const title = extractTitle(html);
    if (title.length === 0 || title.length > 200) continue;
    if (!similarName(legalName, title)) {
      issues.push(
        `${label} profile name doesn't match the applicant's legal name.`,
      );
    }
  }
  return issues;
}

// ── Document verification (Gemini vision + PDF inline) ───────────────────

const DOC_SPECS: Record<
  'id' | 'credentials',
  { label: string; short: string; long: string }
> = {
  id: {
    label: 'Government ID',
    short: 'a government-issued ID',
    long: 'a government-issued photo ID (passport, national ID card, or driver\u2019s license) with a clear name and photo',
  },
  credentials: {
    label: 'Credentials',
    short: 'a professional credential or certificate',
    long: 'a professional credential, certificate, diploma, license, or qualification',
  },
};

function docPrompt(kind: 'id' | 'credentials'): string {
  const spec = DOC_SPECS[kind];
  return [
    'You are verifying a document uploaded by a counselor applicant for an education-guidance platform.',
    `Determine whether this file is ${spec.long}.`,
    'Reply with ONLY a JSON object: {"isValid": true|false, "isBlank": true|false, "reason": "one short sentence"}.',
    '- isBlank: true when the file is blank, unreadable, a random/unrelated image, or contains no usable text or imagery.',
    '- isValid: whether it plausibly is what was asked for, even if slightly blurry or cropped.',
    '- reason: one short, specific sentence explaining the verdict.',
  ].join('\n');
}

function geminiModel() {
  const apiKey = process.env.GEMINI_API_KEY;
  if (!apiKey) {
    throw new Error('GEMINI_API_KEY secret is not configured.');
  }
  const genAI = new GoogleGenerativeAI(apiKey);
  return genAI.getGenerativeModel({
    model: GEMINI_MODEL,
    generationConfig: { responseMimeType: 'application/json' },
  });
}

interface DocCheck {
  isValid?: boolean;
  isBlank?: boolean;
  reason?: string;
}

/**
 * Downloads one verification document from Storage, asks Gemini whether it is
 * plausibly the requested type, and returns 0 or 1 issue strings (empty = the
 * document passed). A download/storage failure is an issue; a malformed AI
 * response degrades to a generic "could not be verified" issue — the
 * application itself is never blocked by this.
 */
async function checkDocument(
  kind: 'id' | 'credentials',
  url: string,
  model: ReturnType<typeof geminiModel>,
): Promise<string[]> {
  const spec = DOC_SPECS[kind];
  const path = storagePathFromUrl(url);
  if (!path) return [`${spec.label} document could not be located.`];

  const bucket = admin.storage().bucket();
  const file = bucket.file(path);

  let meta: { size?: string | number; contentType?: string };
  try {
    [meta] = await file.getMetadata();
  } catch {
    return [`${spec.label} document could not be read from storage.`];
  }
  const size = Number(meta.size ?? 0);
  if (size > MAX_SCREENING_BYTES) {
    return [
      `${spec.label} document is too large to verify (${Math.round(size / 1048576)} MB).`,
    ];
  }

  let buf: Buffer;
  try {
    [buf] = await file.download();
  } catch {
    return [`${spec.label} document could not be downloaded.`];
  }
  if (buf.length === 0) {
    return [`${spec.label} document is empty.`];
  }

  const mimeType = typeof meta.contentType === 'string'
    ? meta.contentType
    : 'application/octet-stream';

  const result = await model.generateContent({
    contents: [
      {
        role: 'user',
        parts: [
          { text: docPrompt(kind) },
          { inlineData: { mimeType, data: buf.toString('base64') } },
        ],
      },
    ],
  });

  let parsed: DocCheck;
  try {
    parsed = JSON.parse(result.response.text()) as DocCheck;
  } catch {
    return [`${spec.label} document could not be verified.`];
  }
  if (parsed.isBlank) {
    return [`${spec.label} document appears blank or unreadable.`];
  }
  if (parsed.isValid !== true) {
    return [`${spec.label} document does not look like ${spec.short}.`];
  }
  return [];
}

// ── Trigger: screen on application submission ────────────────────────────

interface AiScreening {
  status?: string;
  issues?: string[];
  inputHash?: string;
  overdueFlaggedAt?: unknown;
}

function screeningHash(inputs: Record<string, unknown>): string {
  const raw = JSON.stringify(inputs);
  let h = 0;
  for (let i = 0; i < raw.length; i++) {
    h = (h * 31 + raw.charCodeAt(i)) | 0;
  }
  return (h >>> 0).toString(36);
}

/**
 * Fires whenever `counselorProfiles/{uid}` is written with
 * `verificationStatus == 'pending'` (first submission and re-submission after
 * a rejection). Reads the owner/admin-only private doc for the uploaded
 * documents, runs the AI checks, and writes `aiScreeningResult` back to the
 * private doc. A hash of the screened inputs makes re-runs with unchanged
 * inputs a no-op.
 */
export const screenCounselorApplication = onDocumentWritten(
  {
    document: 'counselorProfiles/{uid}',
    secrets: [geminiApiKey],
    timeoutSeconds: 300,
  },
  async (event) => {
    const uid = event.params.uid;
    const after = event.data?.after?.data();
    // Screen only on the authoritative submission write: `submitVerification`
    // stamps `submittedAt` AFTER the documents are in place. Gating on it
    // (instead of just `pending`) avoids the profile-create write racing the
    // credentials upload and transiently flagging "Credentials missing".
    if (!after || after.verificationStatus !== 'pending' || !after.submittedAt) return;

    const privateRef = db.collection('counselorPrivate').doc(uid);
    const privateSnap = await privateRef.get();
    const privateData = privateSnap.exists ? (privateSnap.data() ?? {}) : {};

    const legalName = typeof after.legalName === 'string' ? after.legalName : '';
    const socialLinks = (after.socialLinks as Record<string, unknown>) ?? {};
    const idDocumentUrl =
      typeof privateData.idDocumentUrl === 'string' ? privateData.idDocumentUrl : '';
    const credentialsUrl =
      typeof privateData.credentialsUrl === 'string' ? privateData.credentialsUrl : '';

    const inputHash = screeningHash({
      legalName,
      socialLinks,
      idDocumentUrl,
      credentialsUrl,
    });
    const existing = privateData.aiScreeningResult as AiScreening | undefined;
    if (existing?.inputHash === inputHash) return; // identical inputs, already screened

    let status: 'looks_complete' | 'needs_attention' | 'not_checked';
    let issues: string[];
    try {
      const found: string[] = [];

      if (!idDocumentUrl) {
        found.push('Government ID document is missing (not uploaded).');
      } else {
        found.push(...(await checkDocument('id', idDocumentUrl, geminiModel())));
      }
      if (!credentialsUrl) {
        found.push('Credentials document is missing (not uploaded).');
      } else {
        found.push(
          ...(await checkDocument('credentials', credentialsUrl, geminiModel())),
        );
      }

      found.push(
        ...(await socialLinkIssues(
          socialLinks as Record<string, string>,
          legalName,
        )),
      );

      status = found.length > 0 ? 'needs_attention' : 'looks_complete';
      issues = found;
    } catch (err) {
      // Never block an application because the AI call itself failed.
      console.error(`AI pre-screening failed for ${uid}:`, err);
      status = 'not_checked';
      issues = [];
    }

    await privateRef.set(
      {
        aiScreeningResult: {
          status,
          issues,
          inputHash,
          screenedAt: admin.firestore.FieldValue.serverTimestamp(),
        },
      },
      { merge: true },
    );
  },
);

// ── Scheduled: flag overdue needs_attention applications ─────────────────

function toMillis(value: unknown): number | null {
  if (!value) return null;
  if (typeof value === 'object' && 'toMillis' in (value as Record<string, unknown>)) {
    return (value as { toMillis(): number }).toMillis();
  }
  if (value instanceof Date) return value.getTime();
  return null;
}

/**
 * Hourly sweep: any `needs_attention` application that has sat pending past
 * the 48-hour SLA with no admin action gets an entry in the admin-only
 * `adminAlerts` collection (surfaced to the review team) and is marked
 * flagged so it isn't re-flagged every hour. Clean, not_checked, or
 * recently-submitted applications are ignored.
 */
export const flagOverdueApplications = onSchedule(
  { schedule: 'every 60 minutes', timeoutSeconds: 540 },
  async () => {
    await flagOverdueApplicationsNow();
  },
);

export async function flagOverdueApplicationsNow(): Promise<number> {
  const cutoff = new Date(Date.now() - APPLICATION_REVIEW_SLA_HOURS * 3_600_000);
  const snap = await db
    .collection('counselorProfiles')
    .where('verificationStatus', '==', 'pending')
    .get();

  let flagged = 0;
  await Promise.all(
    snap.docs.map(async (doc) => {
      const profile = doc.data();
      // Count the SLA from the latest submission; fall back to profile
      // creation for profiles submitted before this field existed.
      const pendingSinceMs = toMillis(profile.submittedAt) ?? toMillis(profile.createdAt);
      if (!pendingSinceMs || pendingSinceMs > cutoff.getTime()) return;

      const uid = doc.id;
      const privateRef = db.collection('counselorPrivate').doc(uid);
      const privateSnap = await privateRef.get();
      if (!privateSnap.exists) return;
      const privateData = privateSnap.data() ?? {};
      const screening = privateData.aiScreeningResult as AiScreening | undefined;
      if (!screening || screening.status !== 'needs_attention') return;
      if (screening.overdueFlaggedAt) return; // already surfaced

      await db.collection('adminAlerts').add({
        type: 'overdue_application',
        counselorUid: uid,
        counselorName:
          typeof profile.displayName === 'string' ? profile.displayName : 'Counselor',
        issuesCount: Array.isArray(screening.issues) ? screening.issues.length : 0,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
      });
      await privateRef.update({
        aiScreeningResult: {
          ...screening,
          overdueFlaggedAt: admin.firestore.FieldValue.serverTimestamp(),
        },
      });
      flagged += 1;
    }),
  );
  return flagged;
}
