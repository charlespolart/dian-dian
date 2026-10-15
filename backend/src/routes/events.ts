import { Router } from 'express';
import { z } from 'zod';
import { db } from '../db/index.js';
import { events } from '../db/schema.js';
import { requireAuth } from '../middleware/auth.js';
import { validate } from '../middleware/validate.js';

const router = Router();
router.use(requireAuth);

// Product events the app reports (roadmap #2: how often the free limit is
// hit). A name is a lower-case dotted slug, e.g. `paywall.tracker_limit`;
// nothing else is stored.
const eventSchema = z.object({
  name: z.string().min(1).max(64).regex(/^[a-z0-9_]+(\.[a-z0-9_]+)*$/),
});

router.post('/', validate(eventSchema), async (req, res) => {
  try {
    await db.insert(events).values({ userId: req.userId!, name: req.body.name });
    res.status(204).end();
  } catch (err) {
    console.error('Event error:', err);
    res.status(500).json({ error: 'Server error' });
  }
});

export default router;
