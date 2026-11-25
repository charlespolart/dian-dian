import assert from 'node:assert/strict';
import { test } from 'node:test';
import { entitlementAction, parseRcEvent, rcEventAccountIds, subscriptionEventRow, type RcEvent } from './rcEvent.js';

const ACCOUNT = '4bedb450-8ef2-41e9-b475-0800200c9a66';
const NOW = new Date('2026-11-25T10:00:00Z');

// A trial start, shaped like RevenueCat's own sample events.
const trial: RcEvent = {
  type: 'INITIAL_PURCHASE', id: 'EVT-1', event_timestamp_ms: 1764000000000,
  app_user_id: ACCOUNT, environment: 'SANDBOX',
  store: 'APP_STORE', product_id: 'premium_yearly', period_type: 'TRIAL',
  price: 0, price_in_purchased_currency: 0, currency: 'EUR', country_code: 'FR',
  purchased_at_ms: 1764000000000, expiration_at_ms: 1764604800000,
  original_transaction_id: 'TX-1', transaction_id: 'TX-1',
  subscriber_attributes: { $email: { value: 'a@b.c' } },
};
const of = (type: string, more: Record<string, unknown> = {}): RcEvent => ({ ...trial, type, ...more });

test('parseRcEvent reads the event of a webhook body', () => {
  assert.equal(parseRcEvent({ event: trial, api_version: '1.0' }), trial);
});

test('parseRcEvent refuses a body with no typed event', () => {
  assert.equal(parseRcEvent({}), null);
  assert.equal(parseRcEvent({ event: {} }), null);
  assert.equal(parseRcEvent({ event: { type: '' } }), null);
  assert.equal(parseRcEvent({ event: { type: 42 } }), null);
  assert.equal(parseRcEvent({ event: 'INITIAL_PURCHASE' }), null);
  assert.equal(parseRcEvent(null), null);
  assert.equal(parseRcEvent(undefined), null);
});

test('subscriptionEventRow keeps what the purchase script reads', () => {
  const row = subscriptionEventRow(trial, NOW);
  assert.ok(row);
  assert.equal(row.rcEventId, 'EVT-1');
  assert.equal(row.type, 'INITIAL_PURCHASE');
  assert.equal(row.environment, 'SANDBOX');
  assert.equal(row.store, 'APP_STORE');
  assert.equal(row.productId, 'premium_yearly');
  assert.equal(row.periodType, 'TRIAL');
  assert.equal(row.priceUsd, 0);
  assert.equal(row.priceLocal, 0);
  assert.equal(row.currency, 'EUR');
  assert.equal(row.countryCode, 'FR');
  assert.equal(row.originalTransactionId, 'TX-1');
  assert.deepEqual(row.eventAt, new Date(1764000000000));
  assert.deepEqual(row.purchasedAt, new Date(1764000000000));
  assert.deepEqual(row.expiresAt, new Date(1764604800000));
});

test('the payload is the event without who it is about, and the event is left untouched', () => {
  const event: RcEvent = { ...trial, original_app_user_id: '$RCAnonymousID:first', aliases: ['$RCAnonymousID:first', ACCOUNT] };
  const row = subscriptionEventRow(event, NOW);
  assert.ok(row);
  const { subscriber_attributes: _a, app_user_id: _b, original_app_user_id: _c, aliases: _d, ...rest } = event;
  assert.deepEqual(row.payload, rest);
  assert.ok(!JSON.stringify(row.payload).includes(ACCOUNT), 'no account id is left in the payload');
  assert.ok('subscriber_attributes' in event && 'app_user_id' in event && 'aliases' in event, 'the received event is untouched');
});

test('a transfer is kept without the accounts it names', () => {
  const row = subscriptionEventRow({
    type: 'TRANSFER', id: 'EVT-T', event_timestamp_ms: 1764000000000, store: 'APP_STORE', environment: 'PRODUCTION',
    transferred_from: ['00005a1c-6091-4f81-be77-f0a83a271ab6'], transferred_to: [ACCOUNT],
  }, NOW);
  assert.deepEqual(row?.payload, { type: 'TRANSFER', id: 'EVT-T', event_timestamp_ms: 1764000000000, store: 'APP_STORE', environment: 'PRODUCTION' });
});

test('an event without its own id cannot be deduplicated: no row', () => {
  const { id: _id, ...noId } = trial;
  assert.equal(subscriptionEventRow(noId as RcEvent, NOW), null);
  assert.equal(subscriptionEventRow(of('RENEWAL', { id: 7 }), NOW), null);
  assert.equal(subscriptionEventRow(of('RENEWAL', { id: '' }), NOW), null);
});

test('an event without a timestamp is dated at reception', () => {
  const { event_timestamp_ms: _t, ...undated } = trial;
  assert.deepEqual(subscriptionEventRow(undated as RcEvent, NOW)?.eventAt, NOW);
});

test('missing, null or mistyped fields become null columns, never an exception', () => {
  const row = subscriptionEventRow({
    type: 'TRANSFER', id: 'EVT-2', price: 'x', price_in_purchased_currency: Number.NaN,
    expiration_at_ms: null, purchased_at_ms: 'yesterday', currency: 12, store: null, is_trial_conversion: 'yes',
  }, NOW);
  assert.ok(row);
  assert.equal(row.priceUsd, null);
  assert.equal(row.priceLocal, null);
  assert.equal(row.expiresAt, null);
  assert.equal(row.purchasedAt, null);
  assert.equal(row.currency, null);
  assert.equal(row.store, null);
  assert.equal(row.isTrialConversion, null);
  assert.equal(row.environment, null);
  assert.equal(row.productId, null);
  assert.equal(row.periodType, null);
  assert.equal(row.countryCode, null);
  assert.equal(row.cancelReason, null);
  assert.equal(row.expirationReason, null);
  assert.equal(row.originalTransactionId, null);
});

test('a timestamp no date can hold is left empty in the row, and an event without a readable one is dated at reception', () => {
  const row = subscriptionEventRow(of('RENEWAL', { event_timestamp_ms: 1e20, purchased_at_ms: -1e20, expiration_at_ms: 8.64e15 + 1 }), NOW);
  assert.equal(row?.eventAt, NOW);
  assert.equal(row?.purchasedAt, null);
  assert.equal(row?.expiresAt, null);
});

test('an end that cannot be read is not "no end": the entitlement keeps it unreadable, and the write refuses it', () => {
  const action = entitlementAction(of('RENEWAL', { expiration_at_ms: 1e20 }));
  assert.equal(action.kind, 'upsert');
  assert.ok(action.kind === 'upsert' && action.expiresAt !== null && Number.isNaN(action.expiresAt.getTime()), 'not null, which would be a lifetime');
  const grace = entitlementAction(of('BILLING_ISSUE', { grace_period_expiration_at_ms: 1e20 }));
  assert.ok(grace.kind === 'extend' && Number.isNaN(grace.until.getTime()));
});

test('a refund keeps its negative price', () => {
  const row = subscriptionEventRow(of('CANCELLATION', { cancel_reason: 'CUSTOMER_SUPPORT', price: -9.99, price_in_purchased_currency: -9.99 }), NOW);
  assert.equal(row?.priceUsd, -9.99);
  assert.equal(row?.priceLocal, -9.99);
});

test('the reasons and the trial conversion are kept', () => {
  assert.equal(subscriptionEventRow(of('CANCELLATION', { cancel_reason: 'UNSUBSCRIBE' }), NOW)?.cancelReason, 'UNSUBSCRIBE');
  assert.equal(subscriptionEventRow(of('EXPIRATION', { expiration_reason: 'BILLING_ERROR' }), NOW)?.expirationReason, 'BILLING_ERROR');
  assert.equal(subscriptionEventRow(of('RENEWAL', { is_trial_conversion: true }), NOW)?.isTrialConversion, true);
  assert.equal(subscriptionEventRow(of('RENEWAL', { is_trial_conversion: false }), NOW)?.isTrialConversion, false);
});

test('rcEventAccountIds is the account the event names', () => {
  assert.deepEqual(rcEventAccountIds(trial), [ACCOUNT]);
  assert.deepEqual(rcEventAccountIds(of('RENEWAL', { app_user_id: ACCOUNT.toUpperCase() })), [ACCOUNT], 'upper-case uuids are normalised');
});

test('rcEventAccountIds is empty when the event names no account of ours', () => {
  assert.deepEqual(rcEventAccountIds(of('RENEWAL', { app_user_id: '$RCAnonymousID:abc' })), []);
  assert.deepEqual(rcEventAccountIds(of('RENEWAL', { app_user_id: 'not-a-uuid' })), []);
  assert.deepEqual(rcEventAccountIds(of('RENEWAL', { app_user_id: 42 })), []);
  assert.deepEqual(rcEventAccountIds({ type: 'TEST', id: 'EVT-3' }), []);
});

test('a transfer names the account it goes to', () => {
  assert.deepEqual(rcEventAccountIds({ type: 'TRANSFER', id: 'EVT-4', transferred_from: ['00005a1c-6091-4f81-be77-f0a83a271ab6'], transferred_to: [ACCOUNT] }), [ACCOUNT]);
  assert.deepEqual(rcEventAccountIds({ type: 'TRANSFER', id: 'EVT-4', transferred_to: [] }), []);
  assert.deepEqual(rcEventAccountIds({ type: 'TRANSFER', id: 'EVT-4', transferred_to: 'x' }), []);
});

test('a transfer names every account of ours it may reach, in the order given and once each', () => {
  // The caller takes the first that still exists: the first of the list may be an account deleted since.
  const third = '9f1c2a3b-4d5e-4f60-8a7b-1c2d3e4f5a6b';
  assert.deepEqual(
    rcEventAccountIds({ type: 'TRANSFER', id: 'EVT-4', transferred_to: ['$RCAnonymousID:new', third, ACCOUNT, third.toUpperCase()] }),
    [third, ACCOUNT],
  );
});

test('a purchase, a renewal or a product change sets the subscription', () => {
  for (const type of ['INITIAL_PURCHASE', 'RENEWAL', 'NON_RENEWING_PURCHASE', 'PRODUCT_CHANGE', 'UNCANCELLATION', 'SUBSCRIPTION_EXTENDED']) {
    assert.deepEqual(entitlementAction(of(type)), {
      kind: 'upsert', store: 'apple', productId: 'premium_yearly', txId: 'TX-1', expiresAt: new Date(1764604800000),
    }, type);
  }
});

test('a lifetime purchase has no expiration', () => {
  const action = entitlementAction(of('NON_RENEWING_PURCHASE', { expiration_at_ms: null, product_id: 'premium_lifetime' }));
  assert.deepEqual(action, { kind: 'upsert', store: 'apple', productId: 'premium_lifetime', txId: 'TX-1', expiresAt: null });
});

test('the store is named the way the subscriptions table names it', () => {
  const store = (s: unknown) => {
    const a = entitlementAction(of('RENEWAL', { store: s }));
    return a.kind === 'upsert' ? a.store : null;
  };
  assert.equal(store('APP_STORE'), 'apple');
  assert.equal(store('MAC_APP_STORE'), 'apple');
  assert.equal(store('PLAY_STORE'), 'google');
  assert.equal(store('STRIPE'), 'stripe');
  assert.equal(store(undefined), 'unknown');
});

test('the transaction is the original one, else the event\'s own', () => {
  const tx = (more: Record<string, unknown>) => {
    const a = entitlementAction(of('RENEWAL', more));
    return a.kind === 'upsert' ? a.txId : null;
  };
  assert.equal(tx({ original_transaction_id: 'ORIG', transaction_id: 'T2' }), 'ORIG');
  assert.equal(tx({ original_transaction_id: undefined, transaction_id: 'T2' }), 'T2');
});

test('an expiration ends the subscription', () => {
  assert.deepEqual(entitlementAction(of('EXPIRATION')), { kind: 'deactivate', txId: 'TX-1' });
  assert.deepEqual(entitlementAction(of('EXPIRATION', { expiration_reason: 'SUBSCRIPTION_PAUSED' })), { kind: 'deactivate', txId: 'TX-1' });
});

test('a billing issue keeps the subscription until the end of its grace period', () => {
  const grace = 1764864000000;
  assert.deepEqual(
    entitlementAction(of('BILLING_ISSUE', { grace_period_expiration_at_ms: grace })),
    { kind: 'extend', txId: 'TX-1', until: new Date(grace) },
  );
});

test('a billing issue without a grace period changes nothing: the period paid for runs to its end', () => {
  assert.deepEqual(entitlementAction(of('BILLING_ISSUE', { grace_period_expiration_at_ms: null })), { kind: 'none' });
  assert.deepEqual(entitlementAction(of('BILLING_ISSUE')), { kind: 'none' });
});

test('a pause changes nothing: access ends at the expiration that follows', () => {
  assert.deepEqual(entitlementAction(of('SUBSCRIPTION_PAUSED')), { kind: 'none' });
});

test('a cancellation, an alias, a test or an unknown type changes nothing', () => {
  for (const type of ['CANCELLATION', 'SUBSCRIBER_ALIAS', 'TEST', 'REFUND_REVERSED']) {
    assert.deepEqual(entitlementAction(of(type)), { kind: 'none' }, type);
  }
});

const OTHER = '00005a1c-6091-4f81-be77-f0a83a271ab6';
const transfer = (from: unknown, to: unknown): RcEvent => ({ type: 'TRANSFER', id: 'EVT-T', transferred_from: from, transferred_to: to });

test('a transfer moves the purchases of the accounts it leaves to the event\'s account', () => {
  assert.deepEqual(entitlementAction(transfer([OTHER], [ACCOUNT])), { kind: 'transfer', from: [OTHER], store: null });
});

test('a transfer that names its store moves the purchases of that store only', () => {
  const stored = (store: unknown) => entitlementAction({ ...transfer([OTHER], [ACCOUNT]), store });
  assert.deepEqual(stored('PLAY_STORE'), { kind: 'transfer', from: [OTHER], store: 'google' });
  assert.deepEqual(stored('MAC_APP_STORE'), { kind: 'transfer', from: [OTHER], store: 'apple' });
  assert.deepEqual(stored(null), { kind: 'transfer', from: [OTHER], store: null }, 'no store named: every purchase of the account');
});

test('a transfer only knows our accounts: anonymous ids and aliases are skipped', () => {
  assert.deepEqual(
    entitlementAction(transfer(['$RCAnonymousID:old', OTHER.toUpperCase()], ['$RCAnonymousID:new', ACCOUNT])),
    { kind: 'transfer', from: [OTHER], store: null },
  );
  assert.deepEqual(rcEventAccountIds(transfer([OTHER], ['$RCAnonymousID:new', ACCOUNT])), [ACCOUNT]);
});

test('a transfer from or to no account of ours changes nothing', () => {
  assert.deepEqual(entitlementAction(transfer([], [ACCOUNT])), { kind: 'none' });
  assert.deepEqual(entitlementAction(transfer([OTHER], [])), { kind: 'none' });
  assert.deepEqual(entitlementAction(transfer([OTHER], ['$RCAnonymousID:new'])), { kind: 'none' });
  assert.deepEqual(entitlementAction(transfer(['$RCAnonymousID:old'], [ACCOUNT])), { kind: 'none' });
  assert.deepEqual(entitlementAction(transfer('x', undefined)), { kind: 'none' });
  assert.deepEqual(entitlementAction(transfer([ACCOUNT], [ACCOUNT])), { kind: 'none' }, 'to itself');
});

test('without a transaction id nothing can be set or ended', () => {
  const noTx = { original_transaction_id: undefined, transaction_id: undefined };
  assert.deepEqual(entitlementAction(of('INITIAL_PURCHASE', noTx)), { kind: 'none' });
  assert.deepEqual(entitlementAction(of('EXPIRATION', noTx)), { kind: 'none' });
});
