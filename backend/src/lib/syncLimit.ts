import type { Request } from 'express';
import rateLimit from 'express-rate-limit';

/**
 * The budget of the sync routes (offline sync, chantier 10): a phone back
 * after weeks sends its queue in batches of 100 and reads what changed after
 * each; two phones of one account read again on every `sync` message.
 * Counted per account, after authentication — never per address: many
 * phones share one address behind a mobile carrier's NAT, and a limit per
 * address would make all of them look offline once a few were busy.
 */
export function syncLimiter(max = 1200) {
  return rateLimit({
    windowMs: 15 * 60 * 1000, // 15 min
    max,
    keyGenerator: (req: Request) => `user:${req.userId}`,
    message: { error: 'Too many sync requests' },
  });
}
