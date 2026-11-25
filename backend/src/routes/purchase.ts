import { Router } from 'express';
import { timingSafeEqual } from 'node:crypto';
import { db } from '../db/index.js';
import { subscriptions, subscriptionEvents, users } from '../db/schema.js';
import { requireAuth } from '../middleware/auth.js';
import { env } from '../lib/env.js';
import { entitlementAction, parseRcEvent, rcEventAccountId, subscriptionEventRow, type EntitlementAction, type RcEvent } from '../lib/rcEvent.js';
import { eq, and, inArray, lt } from 'drizzle-orm';

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
// Auth: RevenueCat sends the value typed in its dashboard verbatim in the
// `Authorization` header, and that static secret is what is checked here.
// See ~/Documents/Coding/playbook/third-party/revenuecat.md
//
// Every authenticated event is first kept as it arrived in
// `subscription_events` (what was bought, at what price, trial or not, why
// it ended), then applied to `subscriptions`, the current state. Reading
// the event is in lib/rcEvent.ts.
//
// RevenueCat retries anything but a 200 (5 times, over about 80 minutes),
// so an event this server can read but has nothing to do with — an account
// it does not know, a type it does not handle, a transfer, which carries no
// `app_user_id` — is answered 200, not refused.
// ---------------------------------------------------------------------------
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

  const event = parseRcEvent(req.body);
  if (!event) {
    res.status(400).json({ error: 'Invalid event' });
    return;
  }

  try {
    // The account the event is about, when it is one of ours and still
    // exists: not an anonymous RevenueCat id (a device not logged in yet),
    // not an account deleted since.
    const accountId = rcEventAccountId(event);
    const userId = accountId !== null && (await accountExists(accountId)) ? accountId : null;

    await recordEvent(event, userId);
    await applyEntitlement(entitlementAction(event), userId);
    res.json({ ok: true });
  } catch (err) {
    console.error('RC webhook error:', err);
    res.status(500).json({ error: 'Server error' });
  }
});

async function accountExists(id: string): Promise<boolean> {
  const [row] = await db.select({ id: users.id }).from(users).where(eq(users.id, id)).limit(1);
  return row !== undefined;
}

/// Keeps the event as it arrived. A retried delivery reuses the event's id
/// and is one row. This is measurement: a failure is logged and goes no
/// further, so it can neither fail a purchase nor make RevenueCat retry it.
async function recordEvent(event: RcEvent, userId: string | null): Promise<void> {
  const row = subscriptionEventRow(event, new Date());
  if (!row) return;
  try {
    await db.insert(subscriptionEvents)
      .values({ ...row, userId })
      .onConflictDoNothing({ target: subscriptionEvents.rcEventId });
  } catch (err) {
    console.error('RC webhook: event not recorded:', err);
  }
}

async function applyEntitlement(action: EntitlementAction, userId: string | null): Promise<void> {
  switch (action.kind) {
    case 'upsert':
      // A purchase with no account of ours behind it has no one to entitle.
      if (userId === null) return;
      await upsertSubscription({
        userId,
        store: action.store,
        productId: action.productId,
        txId: action.txId,
        expiresAt: action.expiresAt,
        active: true,
      });
      return;
    case 'deactivate':
      await deactivateByTransaction(action.txId);
      return;
    case 'extend':
      // Only ever later, and never on a purchase with no end (a lifetime's
      // `expires_at` is null, which `lt` does not match). The subscription
      // is reopened too: GET /status closes a period it sees expired, and
      // the app may well ask before RevenueCat's event gets here.
      await db.update(subscriptions)
        .set({ expiresAt: action.until, active: true, updatedAt: new Date() })
        .where(and(
          eq(subscriptions.originalTransactionId, action.txId),
          lt(subscriptions.expiresAt, action.until),
        ));
      return;
    case 'transfer':
      // `userId` is the transfer's destination when that account exists.
      if (userId !== action.to) return;
      await db.update(subscriptions)
        .set({ userId: action.to, updatedAt: new Date() })
        .where(inArray(subscriptions.userId, action.from));
      return;
    case 'none':
      return;
    default: {
      // A new kind of action must be handled here: the compiler says so.
      const unhandled: never = action;
      throw new Error(`Unhandled entitlement action: ${JSON.stringify(unhandled)}`);
    }
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

// `env` is imported to fail fast at startup if env loading regresses; the
// webhook secret itself is read directly from process.env so it can rotate
// without a code change.
void env;

export default router;
