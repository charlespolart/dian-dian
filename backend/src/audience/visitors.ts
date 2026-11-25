/**
 * The visitors of the day, counted without knowing any of them.
 *
 * A visitor is a fingerprint: SHA-256(salt ‖ domain ‖ IP ‖ User-Agent). The
 * salt is drawn at random on the first visit of each UTC day and lives in
 * memory only — never written, never derived from a secret or from the date,
 * so that once the day is over nothing can recompute its fingerprints. The
 * fingerprints live in memory too; the database only ever receives a count.
 *
 * An indicator, not a truth: people behind one mobile address merge into
 * one visitor, a visitor who moves from Pinterest's browser to Safari counts
 * twice, and a restart of the server starts the day's count again.
 */
import { createHash } from 'node:crypto';

export function createVisitors(deps: {
  now: () => Date;
  randomBytes: (n: number) => Buffer;
  /** How many fingerprints a day may hold: past it, nobody is new (memory stays bounded). */
  max?: number;
}): {
  /** True the first time of the UTC day for this domain, this address and this User-Agent. */
  isNew(domain: string, ip: string, userAgent: string): boolean;
} {
  const max = deps.max ?? 200_000;
  let day = '';
  let salt = Buffer.alloc(0);
  let seen = new Set<string>();

  return {
    isNew(domain, ip, userAgent) {
      const today = deps.now().toISOString().slice(0, 10);
      if (today !== day) {
        day = today;
        salt = deps.randomBytes(32);
        seen = new Set();
      }
      // The parts are separated, so that `a` + `bc` is not `ab` + `c`. Half
      // the digest is plenty to tell a day's visitors apart, and half the memory.
      const print = createHash('sha256')
        .update(salt).update('\0').update(domain).update('\0').update(ip).update('\0').update(userAgent)
        .digest('base64')
        .slice(0, 22);
      if (seen.has(print) || seen.size >= max) return false;
      seen.add(print);
      return true;
    },
  };
}
