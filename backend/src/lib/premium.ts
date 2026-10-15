import { and, eq } from 'drizzle-orm';
import { db } from '../db/index.js';
import { subscriptions, users } from '../db/schema.js';

/** Free accounts own at most this many trackers (the app shows the same number). */
export const maxFreeTrackers = 3;

export async function hasActiveSubscription(userId: string): Promise<boolean> {
  const [sub] = await db.select()
    .from(subscriptions)
    .where(and(eq(subscriptions.userId, userId), eq(subscriptions.active, true)))
    .limit(1);
  if (!sub) return false;
  if (sub.expiresAt && sub.expiresAt < new Date()) return false;
  return true;
}

/** VIP (manual flag, never counted as a customer) or an active subscription: no free-tier limits. */
export async function isUnlimited(userId: string): Promise<boolean> {
  const [u] = await db.select({ vip: users.vip }).from(users).where(eq(users.id, userId)).limit(1);
  if (u?.vip) return true;
  return hasActiveSubscription(userId);
}
