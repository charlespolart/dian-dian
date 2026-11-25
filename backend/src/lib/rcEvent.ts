/**
 * Reading a RevenueCat webhook event. Pure functions, no database: the
 * route (`routes/purchase.ts`) decides what to store and what to change
 * from what these return.
 *
 * RevenueCat's fields are read defensively. Only `type`, `id` and
 * `event_timestamp_ms` are on every event; the rest depends on the type
 * (a TRANSFER has no `app_user_id`), new types and fields appear over time,
 * and a value can be null. A field that is missing or of the wrong type is
 * simply absent: it never throws, because a purchase must not fail on what
 * is only measurement.
 * Fields: https://www.revenuecat.com/docs/integrations/webhooks/event-types-and-fields
 */
import type { NewSubscriptionEvent } from '../db/schema.js';

export type RcEvent = Record<string, unknown> & { type: string };

const UUID = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;

const str = (v: unknown): string | null => (typeof v === 'string' && v !== '' ? v : null);
const num = (v: unknown): number | null => (typeof v === 'number' && Number.isFinite(v) ? v : null);
const bool = (v: unknown): boolean | null => (typeof v === 'boolean' ? v : null);
const date = (v: unknown): Date | null => {
  const ms = num(v);
  return ms === null ? null : new Date(ms);
};

/** The `event` of a webhook body, when it is an object with a type. */
export function parseRcEvent(body: unknown): RcEvent | null {
  if (typeof body !== 'object' || body === null) return null;
  const event = (body as { event?: unknown }).event;
  if (typeof event !== 'object' || event === null) return null;
  return str((event as { type?: unknown }).type) === null ? null : (event as RcEvent);
}

/** `value` when it is one of our account ids (a uuid), lower-cased; else null. */
function accountId(value: unknown): string | null {
  const id = str(value);
  return id !== null && UUID.test(id) ? id.toLowerCase() : null;
}

/** The account ids of ours in a list RevenueCat sends (ids and their aliases), once each. */
function accountIds(list: unknown): string[] {
  if (!Array.isArray(list)) return [];
  return [...new Set(list.map(accountId).filter((id): id is string => id !== null))];
}

/**
 * The accounts of ours the event may be about, the likeliest first: its
 * `app_user_id`, or for a TRANSFER (which has none) every account of ours
 * the purchase goes to, in the order RevenueCat gives them. Empty when there
 * is none: one of RevenueCat's anonymous ids (`$RCAnonymousID:…`, a device
 * not logged in yet) or anything else that is not one of our uuids is not an
 * account. Which of them still exists is the caller's question: the event is
 * about the first that does.
 */
export function rcEventAccountIds(event: RcEvent): string[] {
  if (event.type === 'TRANSFER') return accountIds(event.transferred_to);
  const id = accountId(event.app_user_id);
  return id === null ? [] : [id];
}

/**
 * The fields that say who an event is about. None is kept in the payload:
 * the row's `user_id` says it for an account of ours, and goes with the
 * account when it is deleted. Events keep arriving after that (deleting an
 * account does not cancel a store subscription), and a transfer names two
 * accounts: kept as received, those rows would hold an account's ids long
 * after it is gone. Subscriber attributes are free-form and can hold an
 * e-mail address or a name.
 */
const WHO = new Set(['app_user_id', 'original_app_user_id', 'aliases', 'transferred_from', 'transferred_to', 'subscriber_attributes']);

/**
 * The row of `subscription_events` for this event, without its account
 * (looked up by the caller). Null when the event has no id of its own:
 * without it a retried delivery could not be told from a new event.
 * `now` dates an event that carries no timestamp.
 */
export function subscriptionEventRow(event: RcEvent, now: Date): Omit<NewSubscriptionEvent, 'userId'> | null {
  const rcEventId = str(event.id);
  if (rcEventId === null) return null;
  const payload = Object.fromEntries(Object.entries(event).filter(([field]) => !WHO.has(field)));
  return {
    rcEventId,
    type: event.type,
    environment: str(event.environment),
    store: str(event.store),
    productId: str(event.product_id),
    periodType: str(event.period_type),
    priceUsd: num(event.price),
    priceLocal: num(event.price_in_purchased_currency),
    currency: str(event.currency),
    countryCode: str(event.country_code),
    cancelReason: str(event.cancel_reason),
    expirationReason: str(event.expiration_reason),
    isTrialConversion: bool(event.is_trial_conversion),
    originalTransactionId: str(event.original_transaction_id),
    eventAt: date(event.event_timestamp_ms) ?? now,
    purchasedAt: date(event.purchased_at_ms),
    expiresAt: date(event.expiration_at_ms),
    payload,
  };
}

/** What an event does to the `subscriptions` table (the current state). */
export type EntitlementAction =
  /** Set the subscription of this transaction for the event's account. */
  | { kind: 'upsert'; store: string; productId: string; txId: string; expiresAt: Date | null }
  /** The subscription of this transaction is over. */
  | { kind: 'deactivate'; txId: string }
  /** The subscription of this transaction stays open until `until` (a grace period). */
  | { kind: 'extend'; txId: string; until: Date }
  /**
   * The purchases of the accounts `from` now belong to the event's account
   * (`rcEventAccountIds`): those of `store` when the transfer names one,
   * all of them otherwise.
   */
  | { kind: 'transfer'; from: string[]; store: string | null }
  | { kind: 'none' };

const NONE: EntitlementAction = { kind: 'none' };

function storeName(rcStore: unknown): string {
  if (rcStore === 'APP_STORE' || rcStore === 'MAC_APP_STORE') return 'apple';
  if (rcStore === 'PLAY_STORE') return 'google';
  return str(rcStore)?.toLowerCase() ?? 'unknown';
}

export function entitlementAction(event: RcEvent): EntitlementAction {
  // Someone restored a purchase on another account: RevenueCat moved the
  // entitlement, and so do we — when both ends are accounts of ours. A
  // transfer to an anonymous id (a device not logged in) is left alone:
  // taking premium away on that would cut off a customer who paid. What is
  // restored is the purchases of one store account, and RevenueCat names
  // that store on most transfers: an account that also bought in the other
  // store keeps what it bought there.
  if (event.type === 'TRANSFER') {
    const to = accountIds(event.transferred_to);
    const from = accountIds(event.transferred_from).filter((id) => !to.includes(id));
    if (to.length === 0 || from.length === 0) return NONE;
    return { kind: 'transfer', from, store: str(event.store) === null ? null : storeName(event.store) };
  }

  // A subscription is keyed by its original transaction; without one there
  // is nothing to set or to end.
  const txId = str(event.original_transaction_id) ?? str(event.transaction_id);
  if (txId === null) return NONE;

  switch (event.type) {
    case 'INITIAL_PURCHASE':
    case 'RENEWAL':
    case 'NON_RENEWING_PURCHASE':
    case 'PRODUCT_CHANGE':
    case 'UNCANCELLATION':
    case 'SUBSCRIPTION_EXTENDED':
      return {
        kind: 'upsert',
        store: storeName(event.store),
        productId: str(event.product_id) ?? '',
        txId,
        expiresAt: date(event.expiration_at_ms),
      };

    case 'EXPIRATION':
      return { kind: 'deactivate', txId };

    // A payment failed. With a grace period (set in the store), the customer
    // keeps access until its end while the store retries; without one the
    // period paid for simply runs out. Either way access is not cut here:
    // an EXPIRATION says when it is over.
    case 'BILLING_ISSUE': {
      const until = date(event.grace_period_expiration_at_ms);
      return until === null ? NONE : { kind: 'extend', txId, until };
    }

    // CANCELLATION: auto-renew is off but the period already paid for runs
    // to its end, where an EXPIRATION follows. SUBSCRIPTION_PAUSED: the same,
    // the pause starts at an EXPIRATION. SUBSCRIBER_ALIAS, TEST and any type
    // this code does not know change nothing.
    default:
      return NONE;
  }
}
