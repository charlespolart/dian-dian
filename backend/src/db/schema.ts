import { pgTable, uuid, text, smallint, integer, bigint, boolean, timestamp, doublePrecision, jsonb, primaryKey, index, uniqueIndex } from 'drizzle-orm/pg-core';

/**
 * A version number taken from the account's counter (`users.rev`, see
 * lib/revs.ts). 0 for what predates the counter: a full copy sends it anyway.
 */
const revColumn = (name: string) => bigint(name, { mode: 'number' }).notNull().default(0);

export const users = pgTable('users', {
  id: uuid('id').defaultRandom().primaryKey(),
  email: text('email').notNull().unique(),
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
  createdAt: timestamp('created_at', { withTimezone: true }).defaultNow().notNull(),
});

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

export const refreshTokens = pgTable('refresh_tokens', {
  id: uuid('id').defaultRandom().primaryKey(),
  userId: uuid('user_id').notNull().references(() => users.id, { onDelete: 'cascade' }),
  tokenHash: text('token_hash').notNull(),
  expiresAt: timestamp('expires_at', { withTimezone: true }).notNull(),
  createdAt: timestamp('created_at', { withTimezone: true }).defaultNow().notNull(),
}, (t) => [
  index('refresh_tokens_token_hash_idx').on(t.tokenHash),
  index('refresh_tokens_expires_at_idx').on(t.expiresAt),
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
