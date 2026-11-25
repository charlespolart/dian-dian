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

/**
 * The account of ours the event is about: its `app_user_id`, or for a
 * TRANSFER (which has none) the first account the purchase goes to. Null
 * when there is none, when it is one of RevenueCat's anonymous ids
 * (`$RCAnonymousID:…`, a device not logged in yet) or anything else that is
 * not one of our uuids. Whether that account still exists is the caller's
 * question.
 */
export function rcEventAccountId(event: RcEvent): string | null {
  const to = event.transferred_to;
  const candidate = event.type === 'TRANSFER' && Array.isArray(to) ? to[0] : event.app_user_id;
  const id = str(candidate);
  return id !== null && UUID.test(id) ? id.toLowerCase() : null;
}

/**
 * The row of `subscription_events` for this event, without its account
 * (looked up by the caller). Null when the event has no id of its own:
 * without it a retried delivery could not be told from a new event.
 * `now` dates an event that carries no timestamp.
 */
export function subscriptionEventRow(event: RcEvent, now: Date): Omit<NewSubscriptionEvent, 'userId'> | null {
  const rcEventId = str(event.id);
  if (rcEventId === null) return null;
  // Subscriber attributes are free-form and can hold an e-mail address or a
  // name: nothing here needs them, so they are not kept.
  const { subscriber_attributes: _attributes, ...payload } = event;
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
  | { kind: 'none' };

const NONE: EntitlementAction = { kind: 'none' };

function storeName(rcStore: unknown): string {
  if (rcStore === 'APP_STORE' || rcStore === 'MAC_APP_STORE') return 'apple';
  if (rcStore === 'PLAY_STORE') return 'google';
  return str(rcStore)?.toLowerCase() ?? 'unknown';
}

export function entitlementAction(event: RcEvent): EntitlementAction {
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
    case 'BILLING_ISSUE':
    case 'SUBSCRIPTION_PAUSED':
      return { kind: 'deactivate', txId };

    // CANCELLATION: auto-renew is off but the period already paid for runs
    // to its end, where an EXPIRATION follows. TRANSFER, SUBSCRIBER_ALIAS,
    // TEST and any type this code does not know change nothing.
    default:
      return NONE;
  }
}
