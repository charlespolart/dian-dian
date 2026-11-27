import { pgTable, uuid, text, smallint, integer, bigint, boolean, timestamp, date, doublePrecision, jsonb, primaryKey, index, uniqueIndex } from 'drizzle-orm/pg-core';

/**
 * A version number taken from the account's counter (`users.rev`, see
 * lib/revs.ts). 0 for what predates the counter: a full copy sends it anyway.
 */
const revColumn = (name: string) => bigint(name, { mode: 'number' }).notNull().default(0);

export const users = pgTable('users', {
  id: uuid('id').defaultRandom().primaryKey(),
  // Null for an invisible account (chantier 9): no identity yet. Unique all
  // the same (PostgreSQL admits several NULLs).
  email: text('email').unique(),
  // Null for users who only sign in via OAuth — their identity comes from oauth_accounts.
  passwordHash: text('password_hash'),
  emailVerified: boolean('email_verified').notNull().default(false),
  vip: boolean('vip').notNull().default(false),
  theme: text('theme').notNull().default('defaultTheme'),
  language: text('language'),
  cursorId: text('cursor_id').notNull().default('cat'),
  cursorEnabled: boolean('cursor_enabled').notNull().default(false),
  // The person objected to product events (docs/REGISTRE.md, fiche 7): the
  // server writes none for this account. Set by hand, on request; no route
  // shows it or changes it.
  eventsOptOut: boolean('events_opt_out').notNull().default(false),
  // The account's version counter, raised by every write of its data (one
  // transaction at a time: the update locks the row). Elements without a row
  // of their own keep their number here: the order of the trackers, the
  // choice of the open ones, and each setting (offline sync, chantier 10).
  rev: revColumn('rev'),
  pagesOrderRev: revColumn('pages_order_rev'),
  keepFreeRev: revColumn('keep_free_rev'),
  themeRev: revColumn('theme_rev'),
  languageRev: revColumn('language_rev'),
  cursorRev: revColumn('cursor_rev'),
  // The highest number among the deletion traces purged after 24 months: a
  // phone whose last sync is older gets the full copy (it may have missed one).
  syncFloorRev: revColumn('sync_floor_rev'),
  // The last time the app spoke to the server for this account (renewal,
  // key, sync read; at most hourly): the automatic erasures of invisible
  // accounts count from it (chantier 9, cases 61 and 62).
  lastSeenAt: timestamp('last_seen_at', { withTimezone: true }).defaultNow().notNull(),
  createdAt: timestamp('created_at', { withTimezone: true }).defaultNow().notNull(),
});

// The key of an invisible account (chantier 9): a 32-byte secret made by
// the phone, which reopens the account's session. Only its SHA-256 is kept;
// it goes when the account gets an identity or is deleted.
export const accountKeys = pgTable('account_keys', {
  userId: uuid('user_id').primaryKey().references(() => users.id, { onDelete: 'cascade' }),
  keyHash: text('key_hash').notNull(),
  createdAt: timestamp('created_at', { withTimezone: true }).defaultNow().notNull(),
});

// What the server remembers of an account that is gone (chantier 9): its id
// and why, nothing else, 24 months — a key or a phone's copy that comes back
// is told the account was deleted instead of bringing it back to life.
// 'deleted' (asked for); later lots add 'merged' and 'purged'.
export const deletedAccounts = pgTable('deleted_accounts', {
  userId: uuid('user_id').primaryKey(),
  reason: text('reason').notNull(),
  at: timestamp('at', { withTimezone: true }).defaultNow().notNull(),
}, (t) => [
  index('deleted_accounts_at_idx').on(t.at),
]);

// Links a user to an OAuth provider's stable user id ("subject"). A single user
// row can have multiple oauth_accounts rows (e.g. both Apple and Google linked).
export const oauthAccounts = pgTable('oauth_accounts', {
  provider: text('provider').notNull(), // 'apple' | 'google'
  subject: text('subject').notNull(),
  userId: uuid('user_id').notNull().references(() => users.id, { onDelete: 'cascade' }),
  createdAt: timestamp('created_at', { withTimezone: true }).defaultNow().notNull(),
}, (t) => [
  primaryKey({ columns: [t.provider, t.subject] }),
  index('oauth_accounts_user_id_idx').on(t.userId),
]);

// Stores a hashed 6-digit OTP code for password reset (not a link token).
// `attempts` caps brute-force guessing — code is invalidated after 5 wrong tries.
export const passwordResetTokens = pgTable('password_reset_tokens', {
  id: uuid('id').defaultRandom().primaryKey(),
  userId: uuid('user_id').notNull().references(() => users.id, { onDelete: 'cascade' }),
  tokenHash: text('token_hash').notNull(),
  attempts: integer('attempts').notNull().default(0),
  expiresAt: timestamp('expires_at', { withTimezone: true }).notNull(),
  createdAt: timestamp('created_at', { withTimezone: true }).defaultNow().notNull(),
}, (t) => [
  index('password_reset_tokens_user_id_idx').on(t.userId),
]);

export const emailVerificationTokens = pgTable('email_verification_tokens', {
  id: uuid('id').defaultRandom().primaryKey(),
  userId: uuid('user_id').notNull().references(() => users.id, { onDelete: 'cascade' }),
  tokenHash: text('token_hash').notNull(),
  expiresAt: timestamp('expires_at', { withTimezone: true }).notNull(),
  createdAt: timestamp('created_at', { withTimezone: true }).defaultNow().notNull(),
});

// A session: one phone signed in to an account, from its sign-in to its
// sign-out (chantier 9). Its refresh tokens follow one another under it;
// its access tokens name it (`sid`), and every request checks it still
// exists. Closing it deletes it, with its tokens.
export const sessions = pgTable('sessions', {
  id: uuid('id').defaultRandom().primaryKey(),
  userId: uuid('user_id').notNull().references(() => users.id, { onDelete: 'cascade' }),
  createdAt: timestamp('created_at', { withTimezone: true }).defaultNow().notNull(),
}, (t) => [
  index('sessions_user_id_idx').on(t.userId),
]);

export const refreshTokens = pgTable('refresh_tokens', {
  id: uuid('id').defaultRandom().primaryKey(),
  userId: uuid('user_id').notNull().references(() => users.id, { onDelete: 'cascade' }),
  sessionId: uuid('session_id').notNull().references(() => sessions.id, { onDelete: 'cascade' }),
  tokenHash: text('token_hash').notNull(),
  expiresAt: timestamp('expires_at', { withTimezone: true }).notNull(),
  // The token that replaced this one at its last renewal. This one stays
  // good while its successor has never been used: a renewal whose answer was
  // lost can be made again (offline sync, chantier 10).
  replacedById: uuid('replaced_by_id'),
  createdAt: timestamp('created_at', { withTimezone: true }).defaultNow().notNull(),
}, (t) => [
  index('refresh_tokens_token_hash_idx').on(t.tokenHash),
  index('refresh_tokens_expires_at_idx').on(t.expiresAt),
  index('refresh_tokens_session_id_idx').on(t.sessionId),
]);

export const subscriptions = pgTable('subscriptions', {
  id: uuid('id').defaultRandom().primaryKey(),
  userId: uuid('user_id').notNull().references(() => users.id, { onDelete: 'cascade' }),
  store: text('store').notNull(), // 'apple' or 'google'
  productId: text('product_id').notNull(),
  originalTransactionId: text('original_transaction_id').notNull().unique(),
  expiresAt: timestamp('expires_at', { withTimezone: true }),
  active: boolean('active').notNull().default(true),
  createdAt: timestamp('created_at', { withTimezone: true }).defaultNow().notNull(),
  updatedAt: timestamp('updated_at', { withTimezone: true }).defaultNow().notNull(),
}, (t) => [
  index('subscriptions_user_id_idx').on(t.userId),
]);

export const pages = pgTable('pages', {
  id: uuid('id').defaultRandom().primaryKey(),
  userId: uuid('user_id').notNull().references(() => users.id, { onDelete: 'cascade' }),
  title: text('title').notNull().default('New Tracker'),
  // Legacy: pre-multi-year clients (≤ 1.1.0) read this to filter the page
  // list and pick which year of cells to fetch. New clients (≥ 1.2.0) ignore
  // it and rely on cells.year. Drop after 1.1.0 adoption is negligible.
  year: integer('year').notNull().default(new Date().getFullYear()),
  position: integer('position').notNull().default(0),
  palette: text('palette'),
  // Free tier: the user's choice of which trackers stay open once the
  // account is over the free limit (1.2.0). None chosen = the app keeps
  // the most active ones.
  keepFree: boolean('keep_free').notNull().default(false),
  // Idempotency key the app sets when creating its first tracker (1.4.0):
  // a retry after a lost response finds the page instead of making a twin.
  clientId: text('client_id'),
  // rev: last change of the row, whatever the cause (what sync sends).
  // editRev: last direct edit of the tracker itself (its name, its palette),
  // what the offline rule compares. contentRev: last change of anything in
  // it (days, legends, their order, its name): a deletion that waited is
  // compared with it. legendsOrderRev: the order of its legends.
  rev: revColumn('rev'),
  editRev: revColumn('edit_rev'),
  contentRev: revColumn('content_rev'),
  legendsOrderRev: revColumn('legends_order_rev'),
  createdAt: timestamp('created_at', { withTimezone: true }).defaultNow().notNull(),
}, (t) => [
  index('pages_user_id_idx').on(t.userId),
  uniqueIndex('pages_user_client_id_idx').on(t.userId, t.clientId),
]);

export const cells = pgTable('cells', {
  pageId: uuid('page_id').notNull().references(() => pages.id, { onDelete: 'cascade' }),
  year: smallint('year').notNull(),
  month: smallint('month').notNull(),
  day: smallint('day').notNull(),
  color: text('color').notNull(),
  comment: text('comment'),
  // Set once at the first write (1.2.0, backfilled from updated_at);
  // the upsert never touches it. Activation stats read it.
  createdAt: timestamp('created_at', { withTimezone: true }).defaultNow().notNull(),
  updatedAt: timestamp('updated_at', { withTimezone: true }).defaultNow().notNull(),
  // rev: last change (a legend recoloured elsewhere changes it); editRev:
  // last direct edit of the day, what the offline rule compares.
  rev: revColumn('rev'),
  editRev: revColumn('edit_rev'),
}, (t) => [
  primaryKey({ columns: [t.pageId, t.year, t.month, t.day] }),
  // What changed in a tracker since a number (GET /api/sync?since=N).
  index('cells_page_rev_idx').on(t.pageId, t.rev),
]);

export const legends = pgTable('legends', {
  id: uuid('id').defaultRandom().primaryKey(),
  pageId: uuid('page_id').notNull().references(() => pages.id, { onDelete: 'cascade' }),
  color: text('color').notNull(),
  label: text('label').notNull(),
  position: integer('position').notNull().default(0),
  rev: revColumn('rev'),
  editRev: revColumn('edit_rev'),
  createdAt: timestamp('created_at', { withTimezone: true }).defaultNow().notNull(),
}, (t) => [
  index('legends_page_id_idx').on(t.pageId),
]);

// What was deleted, and under which number: a phone that comes back learns
// it (sync), and a change that waited for something deleted since is set
// aside ("the server wins"). Kept 24 months (lib/retention.ts), as long as
// the account document keeps the memory of deleted accounts. `key`: the id
// of a tracker or a legend, `pageId:yyyy-mm-dd` for a day (lib/revs.ts).
export const deletions = pgTable('deletions', {
  id: uuid('id').defaultRandom().primaryKey(),
  userId: uuid('user_id').notNull().references(() => users.id, { onDelete: 'cascade' }),
  kind: text('kind').notNull(), // 'page' | 'legend' | 'cell'
  key: text('key').notNull(),
  pageId: uuid('page_id'),
  rev: revColumn('rev'),
  deletedAt: timestamp('deleted_at', { withTimezone: true }).defaultNow().notNull(),
}, (t) => [
  index('deletions_user_rev_idx').on(t.userId, t.rev),
  index('deletions_user_kind_key_idx').on(t.userId, t.kind, t.key),
]);

// Product events reported by the app (roadmap #2): one row per paywall gate
// shown, e.g. `paywall.tracker_limit`. A counter, not analytics: name +
// account + time, no payload. Read by scripts/prod-events.sql.
export const events = pgTable('events', {
  id: uuid('id').defaultRandom().primaryKey(),
  userId: uuid('user_id').notNull().references(() => users.id, { onDelete: 'cascade' }),
  name: text('name').notNull(),
  // Where the event comes from, so the iOS and Android funnels can be told
  // apart: `ios` | `android` | `web`, and the app's `X.Y.Z`. Null for apps
  // ≤ 1.4.0, which send the name alone.
  platform: text('platform'),
  appVersion: text('app_version'),
  createdAt: timestamp('created_at', { withTimezone: true }).defaultNow().notNull(),
}, (t) => [
  index('events_name_created_at_idx').on(t.name, t.createdAt),
]);

// Every RevenueCat webhook event as it arrived, next to `subscriptions`
// (the current state). What the state alone cannot tell: whether a period
// was a trial, what was paid and in which currency, why and when a
// subscription was cancelled, and whether the purchase was a sandbox one.
// The columns are the fields scripts/prod-purchases.sql reads; `payload` is
// the rest of the event for whatever else is needed later, without any field
// that says who it is about (see lib/rcEvent.ts). `user_id` is null when the event names no account we know (an
// anonymous RevenueCat id, a deleted account, a test event).
export const subscriptionEvents = pgTable('subscription_events', {
  id: uuid('id').defaultRandom().primaryKey(),
  // RevenueCat's own event id: a retried delivery reuses it.
  rcEventId: text('rc_event_id').notNull().unique(),
  userId: uuid('user_id').references(() => users.id, { onDelete: 'cascade' }),
  type: text('type').notNull(),
  environment: text('environment'), // 'PRODUCTION' | 'SANDBOX'
  store: text('store'),
  productId: text('product_id'),
  periodType: text('period_type'), // 'TRIAL' | 'INTRO' | 'NORMAL' | …
  priceUsd: doublePrecision('price_usd'),
  priceLocal: doublePrecision('price_local'),
  currency: text('currency'),
  countryCode: text('country_code'),
  cancelReason: text('cancel_reason'),
  expirationReason: text('expiration_reason'),
  isTrialConversion: boolean('is_trial_conversion'),
  originalTransactionId: text('original_transaction_id'),
  eventAt: timestamp('event_at', { withTimezone: true }).notNull(),
  purchasedAt: timestamp('purchased_at', { withTimezone: true }),
  expiresAt: timestamp('expires_at', { withTimezone: true }),
  payload: jsonb('payload').notNull(),
  receivedAt: timestamp('received_at', { withTimezone: true }).defaultNow().notNull(),
}, (t) => [
  index('subscription_events_user_id_idx').on(t.userId),
  index('subscription_events_type_event_at_idx').on(t.type, t.eventAt),
]);

export type NewSubscriptionEvent = typeof subscriptionEvents.$inferInsert;

// The changes a phone sent (offline sync) and what was answered, by the id
// the phone gave them: a change sent again — its answer lost on the way —
// gets the same answer and is never applied twice. Kept 90 days
// (lib/retention.ts); a change sent later than that is judged like any other
// that waited. No content beyond the answer.
export const syncMutations = pgTable('sync_mutations', {
  id: uuid('id').notNull(),
  userId: uuid('user_id').notNull().references(() => users.id, { onDelete: 'cascade' }),
  result: jsonb('result').notNull(),
  createdAt: timestamp('created_at', { withTimezone: true }).defaultNow().notNull(),
}, (t) => [
  // Per account: an id another account happens to use is not this one's.
  primaryKey({ columns: [t.userId, t.id] }),
  index('sync_mutations_created_at_idx').on(t.createdAt),
]);

// What offline sync is like, per week (spec, "Mesure"): syncs that sent
// changes which waited, how many such changes, how many were set aside and
// why. Counts only: no account, no device. Read by scripts/prod-sync.sql.
export const syncStats = pgTable('sync_stats', {
  week: date('week').notNull(),
  kind: text('kind').notNull(),
  count: integer('count').notNull().default(0),
}, (t) => [
  primaryKey({ columns: [t.week, t.kind] }),
]);

// Sessions ended by the server, by the hash of their refresh token, and why:
// a phone that presents one is told the reason instead of a bare refusal
// ("account_deleted" makes it erase its copy, H24; anything else keeps it).
// Kept as long as a session lasts (548 days, lib/retention.ts); only a hash,
// linked to no account.
export const endedSessions = pgTable('ended_sessions', {
  tokenHash: text('token_hash').primaryKey(),
  // 'account_deleted' | 'password_changed' | 'session_revoked'
  reason: text('reason').notNull(),
  // The session the token belonged to: a request with its access token
  // learns why it is refused (chantier 9). Null for rows written before.
  sessionId: uuid('session_id'),
  endedAt: timestamp('ended_at', { withTimezone: true }).defaultNow().notNull(),
}, (t) => [
  index('ended_sessions_ended_at_idx').on(t.endedAt),
  index('ended_sessions_session_id_idx').on(t.sessionId),
]);
