import { eq, notExists } from 'drizzle-orm';
import { db } from '../db/index.js';
import { endedSessions, refreshTokens, sessions } from '../db/schema.js';

/**
 * Why a session is over, as a refused request says it (chantier 9). The app
 * ends the session without trying to renew it for the first three; `invalid`
 * (expired, signed out, never known) goes through a renewal first.
 */
export type EndReason = 'account_deleted' | 'password_changed' | 'session_revoked' | 'invalid';

/** Whether a session still exists, or why it does not. One indexed read, no cache. */
export async function sessionStatus(sessionId: string): Promise<'alive' | EndReason> {
  const [alive] = await db.select({ id: sessions.id }).from(sessions).where(eq(sessions.id, sessionId)).limit(1);
  if (alive) return 'alive';
  const [ended] = await db.select({ reason: endedSessions.reason }).from(endedSessions)
    .where(eq(endedSessions.sessionId, sessionId)).limit(1);
  return (ended?.reason as EndReason | undefined) ?? 'invalid';
}

/** A new session of [userId]: a sign-in, a sign-up, an account created. */
export async function newSession(userId: string): Promise<string> {
  const [row] = await db.insert(sessions).values({ userId }).returning({ id: sessions.id });
  return row.id;
}

/** Sessions whose every token has expired or gone: nothing can renew them. */
export async function purgeEmptySessions(): Promise<void> {
  await db.delete(sessions).where(notExists(
    db.select({ id: refreshTokens.id }).from(refreshTokens).where(eq(refreshTokens.sessionId, sessions.id)),
  ));
}
