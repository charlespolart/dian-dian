/**
 * The counter: adds up in memory, writes counts to the database every few
 * seconds, away from the path of the response.
 *
 * `add` does no I/O and never throws: a visit costs the page nothing. What
 * waits in memory is written by `flush` in one go; a write that fails is
 * kept for the next, and dropped after ten failures in a row (said once) so
 * that an outage of the database cannot fill the memory. A restart of the
 * server loses at most the seconds since the last write.
 *
 * Bounded on purpose. The site of origin and the name of a robot are written
 * by whoever sends the request: past a number of new ones in a day, the next
 * are filed under 'other'. And past a number of rows in a day, whatever is
 * new falls into one row per kind — nobody can fill the table, and a busy
 * day keeps its detail far longer than an attack needs to be cut off.
 */
import { lt, sql } from 'drizzle-orm';
import type { db as database } from '../db/index.js';
import { audienceCounts, audienceTotals } from './schema.js';

type Db = typeof database;

/** One thing seen: a page view or a tap on a store button, with what is known of it. */
export type Hit = {
  kind: 'visit' | 'store_tap';
  store: '' | 'apple' | 'play';
  origin: string;
  originFrom: 'referer' | 'tag' | '';
  tagged: boolean;
  device: string;
  browser: string;
  inApp: string;
  lang: string;
  country: string;
  /** '' for a person. */
  botFamily: string;
  botName: string;
  botCheck: string;
};

type Total = { day: string; visits: number; visitors: number; tapsApple: number; tapsPlay: number };
export type Batch = { counts: Array<Hit & { day: string; count: number }>; totals: Total[] };

const FIELDS = ['kind', 'store', 'origin', 'originFrom', 'tagged', 'device', 'browser', 'inApp', 'lang', 'country', 'botFamily', 'botName', 'botCheck'] as const;
const keyOf = (day: string, hit: Hit) => `${day}\u0001${FIELDS.map((field) => String(hit[field])).join('\u0001')}`;

export function createCounter(deps: {
  write: (batch: Batch) => Promise<void>;
  now: () => Date;
  warn?: (message: string) => void;
  /** New sites of origin a day may bring before the next are 'other'. */
  maxOrigins?: number;
  /** The same for names of robots. */
  maxBotNames?: number;
  /** New rows a day may bring before the next fall into one row per kind. */
  maxRows?: number;
}): {
  /** Counts one hit. `newVisitor`: the first visit of the day for this person. Never throws, no I/O. */
  add(hit: Hit, newVisitor: boolean): void;
  /** Writes what waits. A failure keeps it for the next call. Never throws. */
  flush(): Promise<void>;
} {
  const warn = deps.warn ?? ((message: string) => console.error(message));
  const maxOrigins = deps.maxOrigins ?? 100;
  const maxBotNames = deps.maxBotNames ?? 200;
  const maxRows = deps.maxRows ?? 2000;

  let pending = new Map<string, Hit & { day: string; count: number }>();
  let totals = new Map<string, Total>();
  // What the current day has brought so far, to hold it to its limits.
  let day = '';
  let origins = new Set<string>();
  let botNames = new Set<string>();
  let rowsOfDay = new Set<string>();
  let writing = false;
  let failures = 0;

  /** The hit as it will be counted: itself, or folded when the day is past a limit. */
  function bounded(today: string, hit: Hit): Hit {
    let kept = hit;
    if (kept.botFamily === '') {
      if (kept.origin !== '' && kept.origin !== 'other' && !origins.has(kept.origin)) {
        if (origins.size < maxOrigins) origins.add(kept.origin);
        else kept = { ...kept, origin: 'other' };
      }
    } else if (kept.botName !== 'other' && !botNames.has(kept.botName)) {
      if (botNames.size < maxBotNames) botNames.add(kept.botName);
      else kept = { ...kept, botName: 'other' };
    }
    const key = keyOf(today, kept);
    if (rowsOfDay.has(key)) return kept;
    if (rowsOfDay.size < maxRows) {
      rowsOfDay.add(key);
      return kept;
    }
    // Past the limit of the day: one row per kind, store and, for a robot, family.
    const blank = { origin: '', originFrom: '', tagged: false, device: '', browser: '', inApp: '', lang: '', country: '', botCheck: '' } as const;
    return kept.botFamily === ''
      ? { ...blank, kind: kept.kind, store: kept.store, origin: 'other', device: 'other', browser: 'other', botFamily: '', botName: '' }
      : { ...blank, kind: kept.kind, store: kept.store, botFamily: kept.botFamily, botName: 'other' };
  }

  return {
    add(hit, newVisitor) {
      try {
        const today = deps.now().toISOString().slice(0, 10);
        if (today !== day) {
          day = today;
          origins = new Set();
          botNames = new Set();
          rowsOfDay = new Set();
        }
        const kept = bounded(today, hit);
        const key = keyOf(today, kept);
        const row = pending.get(key);
        if (row) row.count++;
        else pending.set(key, { ...kept, day: today, count: 1 });

        if (kept.botFamily !== '') return; // the totals of a day are its people
        const total = totals.get(today) ?? { day: today, visits: 0, visitors: 0, tapsApple: 0, tapsPlay: 0 };
        if (kept.kind === 'visit') {
          total.visits++;
          if (newVisitor) total.visitors++;
        } else if (kept.store === 'apple') total.tapsApple++;
        else if (kept.store === 'play') total.tapsPlay++;
        totals.set(today, total);
      } catch {
        // Counting must never cost a page: a hit that cannot be counted is not.
      }
    },

    async flush() {
      if (writing || (pending.size === 0 && totals.size === 0)) return;
      writing = true;
      const batch: Batch = { counts: [...pending.values()], totals: [...totals.values()] };
      pending = new Map();
      totals = new Map();
      try {
        await deps.write(batch);
        failures = 0;
      } catch (err) {
        failures++;
        if (failures >= 10) {
          const lost = batch.counts.reduce((sum, row) => sum + row.count, 0);
          warn(`Audience: ${lost} visits and taps dropped after ${failures} failed writes: ${err instanceof Error ? err.message : String(err)}`);
          failures = 0;
        } else {
          // Back in the queue, under what was counted while the write was tried.
          for (const row of batch.counts) {
            const key = keyOf(row.day, row);
            const later = pending.get(key);
            if (later) later.count += row.count;
            else pending.set(key, row);
          }
          for (const total of batch.totals) {
            const later = totals.get(total.day);
            if (later) {
              later.visits += total.visits;
              later.visitors += total.visitors;
              later.tapsApple += total.tapsApple;
              later.tapsPlay += total.tapsPlay;
            } else totals.set(total.day, total);
          }
        }
      } finally {
        writing = false;
      }
    },
  };
}

/** How many rows one INSERT carries: 15 values each, far under PostgreSQL's 65 535 parameters. */
const CHUNK = 500;

/** Writes a batch: each count is added to the row of its day, in one transaction. */
export function writeBatch(db: Db): (batch: Batch) => Promise<void> {
  return async (batch) => {
    await db.transaction(async (tx) => {
      for (let i = 0; i < batch.counts.length; i += CHUNK) {
        await tx.insert(audienceCounts)
          .values(batch.counts.slice(i, i + CHUNK))
          .onConflictDoUpdate({
            target: [
              audienceCounts.day, audienceCounts.kind, audienceCounts.store, audienceCounts.origin, audienceCounts.originFrom, audienceCounts.tagged, audienceCounts.device,
              audienceCounts.browser, audienceCounts.inApp, audienceCounts.lang, audienceCounts.country, audienceCounts.botFamily, audienceCounts.botName, audienceCounts.botCheck,
            ],
            set: { count: sql`${audienceCounts.count} + excluded.count` },
          });
      }
      if (batch.totals.length > 0) {
        await tx.insert(audienceTotals)
          .values(batch.totals)
          .onConflictDoUpdate({
            target: audienceTotals.day,
            set: {
              visits: sql`${audienceTotals.visits} + excluded.visits`,
              visitors: sql`${audienceTotals.visitors} + excluded.visitors`,
              tapsApple: sql`${audienceTotals.tapsApple} + excluded.taps_apple`,
              tapsPlay: sql`${audienceTotals.tapsPlay} + excluded.taps_play`,
            },
          });
      }
    });
  };
}

/** The first day of the month 25 months before the month of `now` (UTC): days before it are rolled up. */
export function rollUpBefore(now: Date): string {
  return new Date(Date.UTC(now.getUTCFullYear(), now.getUTCMonth() - 25, 1)).toISOString().slice(0, 10);
}

/**
 * Daily rows are kept 25 months. Older days become one total per month
 * (visits and taps of people, hits of robots) and are deleted, in one
 * transaction. The visitors of a day cannot be added across days: they are
 * not carried over.
 */
export async function rollUpOldDays(db: Db, now: Date): Promise<void> {
  const before = rollUpBefore(now);
  await db.transaction(async (tx) => {
    await tx.execute(sql`
      INSERT INTO audience_months (month, visits, taps_apple, taps_play, bot_hits)
      SELECT month, sum(visits)::int, sum(taps_apple)::int, sum(taps_play)::int, sum(bot_hits)::int
      FROM (
        SELECT date_trunc('month', day)::date AS month, visits, taps_apple, taps_play, 0 AS bot_hits
        FROM audience_totals WHERE day < ${before}::date
        UNION ALL
        SELECT date_trunc('month', day)::date, 0, 0, 0, count
        FROM audience_counts WHERE day < ${before}::date AND bot_family <> ''
      ) old
      GROUP BY month
      ON CONFLICT (month) DO UPDATE SET
        visits = audience_months.visits + excluded.visits,
        taps_apple = audience_months.taps_apple + excluded.taps_apple,
        taps_play = audience_months.taps_play + excluded.taps_play,
        bot_hits = audience_months.bot_hits + excluded.bot_hits`);
    await tx.delete(audienceCounts).where(lt(audienceCounts.day, before));
    await tx.delete(audienceTotals).where(lt(audienceTotals.day, before));
  });
}
