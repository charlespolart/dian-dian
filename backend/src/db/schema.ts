import { pgTable, uuid, text, smallint, integer, boolean, timestamp, primaryKey } from 'drizzle-orm/pg-core';

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
});

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
});

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
});

export const pages = pgTable('pages', {
  id: uuid('id').defaultRandom().primaryKey(),
  userId: uuid('user_id').notNull().references(() => users.id, { onDelete: 'cascade' }),
  title: text('title').notNull().default('New Tracker'),
  position: integer('position').notNull().default(0),
  palette: text('palette'),
  createdAt: timestamp('created_at', { withTimezone: true }).defaultNow().notNull(),
});

export const cells = pgTable('cells', {
  pageId: uuid('page_id').notNull().references(() => pages.id, { onDelete: 'cascade' }),
  year: smallint('year').notNull(),
  month: smallint('month').notNull(),
  day: smallint('day').notNull(),
  color: text('color').notNull(),
  comment: text('comment'),
  updatedAt: timestamp('updated_at', { withTimezone: true }).defaultNow().notNull(),
}, (t) => [
  primaryKey({ columns: [t.pageId, t.year, t.month, t.day] }),
]);

export const legends = pgTable('legends', {
  id: uuid('id').defaultRandom().primaryKey(),
  pageId: uuid('page_id').notNull().references(() => pages.id, { onDelete: 'cascade' }),
  color: text('color').notNull(),
  label: text('label').notNull(),
  position: integer('position').notNull().default(0),
  createdAt: timestamp('created_at', { withTimezone: true }).defaultNow().notNull(),
});
