import { Router } from 'express';
import { timingSafeEqual } from 'node:crypto';
import { db } from '../db/index.js';
import { subscriptions } from '../db/schema.js';
import { requireAuth } from '../middleware/auth.js';
import { env } from '../lib/env.js';
import { eq, and } from 'drizzle-orm';

const router = Router();

// ---------------------------------------------------------------------------
// GET /api/purchase/status
// Returns the active premium status for the authenticated user. Read-only —
// the source of truth is updated by RevenueCat via the webhook below.
// ---------------------------------------------------------------------------
router.get('/status', requireAuth, async (req, res) => {
  try {
    const userId = req.userId!;
    const [sub] = await db.select()
      .from(subscriptions)
      .where(and(
        eq(subscriptions.userId, userId),
        eq(subscriptions.active, true),
      ))
      .limit(1);

    if (!sub) {
      res.json({ premium: false });
      return;
    }

    if (sub.expiresAt && sub.expiresAt < new Date()) {
      await db.update(subscriptions)
        .set({ active: false, updatedAt: new Date() })
        .where(eq(subscriptions.id, sub.id));
      res.json({ premium: false });
      return;
    }

    res.json({ premium: true, productId: sub.productId, expiresAt: sub.expiresAt });
  } catch (err) {
    console.error('Purchase status error:', err);
    res.status(500).json({ error: 'Server error' });
  }
});

// ---------------------------------------------------------------------------
// POST /api/purchase/webhook
// RevenueCat → us. Configure the webhook in the RC dashboard
// (Integrations → Webhooks) with this URL and the secret below as the
// Authorization header.
// Docs: https://www.revenuecat.com/docs/integrations/webhooks
//
// Note: RC does NOT sign the body with HMAC. The only auth is the static
// secret echoed back in the `Authorization` header. See:
//   ~/Documents/Coding/playbook/third-party/revenuecat.md
// ---------------------------------------------------------------------------
type RcEventType =
  | 'INITIAL_PURCHASE'
  | 'RENEWAL'
  | 'NON_RENEWING_PURCHASE'
  | 'PRODUCT_CHANGE'
  | 'CANCELLATION'
  | 'UNCANCELLATION'
  | 'EXPIRATION'
  | 'BILLING_ISSUE'
  | 'SUBSCRIPTION_PAUSED'
  | 'SUBSCRIPTION_EXTENDED'
  | 'TRANSFER'
  | 'SUBSCRIBER_ALIAS'
  | 'TEST';

interface RcEvent {
  type: RcEventType;
  app_user_id: string;
  original_app_user_id?: string;
  product_id?: string;
  store?: string;
  expiration_at_ms?: number;
  purchased_at_ms?: number;
  original_transaction_id?: string;
  transaction_id?: string;
}

/// Constant-time comparison of the `Authorization` header against the
/// configured secret. Fails closed (returns false) when either is missing —
/// which yields a 401 from the handler so RC stops retrying instead of
/// looping on a 5xx until the secret is set.
function verifyAuthorization(header: string | undefined): boolean {
  if (!header) return false;
  const secret = process.env.REVENUECAT_WEBHOOK_SECRET;
  if (!secret) return false;
  const a = Buffer.from(header, 'utf8');
  const b = Buffer.from(secret, 'utf8');
  if (a.length !== b.length) return false; // timingSafeEqual requires equal-length buffers
  return timingSafeEqual(a, b);
}

router.post('/webhook', async (req, res) => {
  if (!process.env.REVENUECAT_WEBHOOK_SECRET) {
    console.error('REVENUECAT_WEBHOOK_SECRET not configured');
  }
  if (!verifyAuthorization(req.headers.authorization)) {
    res.status(401).json({ error: 'Unauthorized' });
    return;
  }

  const event = req.body?.event as RcEvent | undefined;
  if (!event || !event.type || !event.app_user_id) {
    res.status(400).json({ error: 'Invalid event' });
    return;
  }

  try {
    await handleRcEvent(event);
    res.json({ ok: true });
  } catch (err) {
    console.error('RC webhook error:', err);
    res.status(500).json({ error: 'Server error' });
  }
});

async function handleRcEvent(event: RcEvent): Promise<void> {
  const userId = event.app_user_id;
  // RC sends anonymous IDs for unidentified users — ignore until logIn happens.
  if (userId.startsWith('$RCAnonymousID:')) return;

  const productId = event.product_id || '';
  const store = mapStore(event.store);
  const txId = event.original_transaction_id || event.transaction_id || '';
  const expiresAt = event.expiration_at_ms ? new Date(event.expiration_at_ms) : null;

  switch (event.type) {
    case 'INITIAL_PURCHASE':
    case 'RENEWAL':
    case 'NON_RENEWING_PURCHASE':
    case 'PRODUCT_CHANGE':
    case 'UNCANCELLATION':
    case 'SUBSCRIPTION_EXTENDED':
      await upsertSubscription({ userId, store, productId, txId, expiresAt, active: true });
      break;

    case 'CANCELLATION':
      // User turned off auto-renew but is still entitled until expiration —
      // keep active=true; expiration handled by EXPIRATION.
      break;

    case 'EXPIRATION':
    case 'BILLING_ISSUE':
    case 'SUBSCRIPTION_PAUSED':
      await deactivateByTransaction(txId);
      break;

    case 'TRANSFER':
    case 'SUBSCRIBER_ALIAS':
    case 'TEST':
      // No-op: alias / transfer / test events don't change entitlement state
      // for the destination user — purchase events follow.
      break;
  }
}

interface UpsertParams {
  userId: string;
  store: string;
  productId: string;
  txId: string;
  expiresAt: Date | null;
  active: boolean;
}

/// Atomic upsert keyed by original_transaction_id. RC may retry the same
/// event if we don't 2xx in 60s, so we need this to be idempotent — running
/// the same event twice must converge to the same row, not error out on the
/// unique constraint.
async function upsertSubscription(params: UpsertParams): Promise<void> {
  if (!params.txId) return; // can't dedupe without a transaction id

  await db.insert(subscriptions)
    .values({
      userId: params.userId,
      store: params.store,
      productId: params.productId,
      originalTransactionId: params.txId,
      expiresAt: params.expiresAt,
      active: params.active,
    })
    .onConflictDoUpdate({
      target: subscriptions.originalTransactionId,
      set: {
        active: params.active,
        productId: params.productId,
        expiresAt: params.expiresAt,
        updatedAt: new Date(),
      },
    });
}

async function deactivateByTransaction(txId: string): Promise<void> {
  if (!txId) return;
  await db.update(subscriptions)
    .set({ active: false, updatedAt: new Date() })
    .where(eq(subscriptions.originalTransactionId, txId));
}

function mapStore(rcStore: string | undefined): string {
  if (rcStore === 'APP_STORE' || rcStore === 'MAC_APP_STORE') return 'apple';
  if (rcStore === 'PLAY_STORE') return 'google';
  return rcStore?.toLowerCase() || 'unknown';
}

// `env` is imported to fail fast at startup if env loading regresses; the
// webhook secret itself is read directly from process.env so it can rotate
// without a code change.
void env;

export default router;
