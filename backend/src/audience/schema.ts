/**
 * The audience counter's tables: counts only, never who. No IP address, no
 * User-Agent, no `utm_*` value and no full referring URL is ever written.
 */
import { pgTable, text, integer, boolean, date, primaryKey } from 'drizzle-orm/pg-core';

// One row per day (UTC) and per combination of what was seen, incremented.
// Every dimension is NOT NULL with '' for "does not apply": a primary key
// does not compare NULLs, and each combination must be one row.
export const audienceCounts = pgTable('audience_counts', {
  day: date('day').notNull(),
  kind: text('kind').notNull(), // 'visit' | 'store_tap'
  store: text('store').notNull().default(''), // 'apple' | 'play' | ''
  // The site the visitor came from: a domain name, 'other', or ''.
  origin: text('origin').notNull().default(''),
  // Where `origin` was read: 'referer' (the header) | 'tag' (a known utm_source) | ''.
  originFrom: text('origin_from').notNull().default(''),
  // A utm_source was present. Its value is not kept.
  tagged: boolean('tagged').notNull().default(false),
  device: text('device').notNull().default(''), // iphone | ipad | android | desktop | other | '' (a robot)
  browser: text('browser').notNull().default(''), // a family, never a version
  inApp: text('in_app').notNull().default(''), // pinterest | instagram | facebook | tiktok | ''
  lang: text('lang').notNull().default(''),
  country: text('country').notNull().default(''), // ISO 3166-1 alpha-2, '' when unknown
  // '' is a person. ai_user | ai_search | ai_training | search | preview | other | fake
  botFamily: text('bot_family').notNull().default(''),
  botName: text('bot_name').notNull().default(''),
  botCheck: text('bot_check').notNull().default(''), // verified | unverified | unverifiable | ''
  count: integer('count').notNull(),
}, (t) => [
  // Named: the default name, made of every column, is longer than
  // PostgreSQL's 63 characters. It starts with `day`, which is what the
  // reading script and the purge filter on.
  primaryKey({
    name: 'audience_counts_pk',
    columns: [t.day, t.kind, t.store, t.origin, t.originFrom, t.tagged, t.device, t.browser, t.inApp, t.lang, t.country, t.botFamily, t.botName, t.botCheck],
  }),
]);

// One row per day, people only. `visitors` is the number of distinct
// fingerprints of the day: it cannot be added across rows or across days.
export const audienceTotals = pgTable('audience_totals', {
  day: date('day').primaryKey(),
  visits: integer('visits').notNull().default(0),
  visitors: integer('visitors').notNull().default(0),
  tapsApple: integer('taps_apple').notNull().default(0),
  tapsPlay: integer('taps_play').notNull().default(0),
});

// What is left of the days older than 25 months: one row per month.
export const audienceMonths = pgTable('audience_months', {
  month: date('month').primaryKey(), // the first day of the month
  visits: integer('visits').notNull().default(0),
  tapsApple: integer('taps_apple').notNull().default(0),
  tapsPlay: integer('taps_play').notNull().default(0),
  botHits: integer('bot_hits').notNull().default(0),
});
