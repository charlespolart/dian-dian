import { Router } from 'express';
import { z } from 'zod';
import { eq } from 'drizzle-orm';
import { db } from '../db/index.js';
import { events, users } from '../db/schema.js';
import { requireAuth } from '../middleware/auth.js';
import { validate } from '../middleware/validate.js';

const router = Router();
router.use(requireAuth);

// Product events the app reports (roadmap #2: how often the free limit is
// hit). A name is a lower-case dotted slug, e.g. `paywall.tracker_limit`.
// With it, where the event comes from — the platform and the app's version —
// so the iOS and Android funnels can be compared; apps ≤ 1.4.0 send the name
// alone. Nothing else is stored, and nothing at all for an account that
// objected (`users.events_opt_out`).
//
// The origin is a detail of the count: a value this server does not know
// (another platform, a pre-release version) is dropped, never a 400 that
// would lose the event.
const eventSchema = z.object({
  name: z.string().min(1).max(64).regex(/^[a-z0-9_]+(\.[a-z0-9_]+)*$/),
  platform: z.enum(['ios', 'android', 'web']).optional().catch(undefined),
  appVersion: z.string().regex(/^\d{1,3}\.\d{1,3}\.\d{1,3}$/).optional().catch(undefined),
});
type EventBody = z.infer<typeof eventSchema>;

router.post('/', validate(eventSchema), async (req, res) => {
  try {
    const { name, platform, appVersion } = req.body as EventBody;
    // Someone who objected to these events (docs/REGISTRE.md, fiche 7) is
    // answered like anyone else — the app must not see an error and try
    // again — and nothing is written. So is an account deleted while its
    // access token still runs (15 minutes): there is no one to count.
    const [account] = await db.select({ objected: users.eventsOptOut }).from(users).where(eq(users.id, req.userId!)).limit(1);
    if (!account || account.objected) {
      res.status(204).end();
      return;
    }
    await db.insert(events).values({ userId: req.userId!, name, platform: platform ?? null, appVersion: appVersion ?? null });
    res.status(204).end();
  } catch (err) {
    console.error('Event error:', err);
    res.status(500).json({ error: 'Server error' });
  }
});

export default router;
