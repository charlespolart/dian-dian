import { and, eq, inArray, ne } from 'drizzle-orm';
import type { Tx } from './revs.js';
import { endedSessions, refreshTokens, sessions } from '../db/schema.js';
import type { EndReason } from './sessions.js';
import { closeSessionSockets } from './ws.js';

/**
 * Closes the sessions of [userId] (chantier 9): all of them, or all but
 * [except]. Each token of each session is remembered as ended with
 * [reason], so that the phone's next request and its next renewal both say
 * why. The sessions are locked first: a renewal of one of them waits for
 * the closing, so that no token escapes the memory. Returns the sessions
 * closed; [afterCommit] then closes their live channels — call it once the
 * transaction is committed.
 */
export async function closeSessions(
  tx: Tx,
  userId: string,
  { except, reason }: { except?: string | null; reason: Exclude<EndReason, 'invalid'> },
): Promise<{ closed: string[]; afterCommit: () => void }> {
  const where = and(eq(sessions.userId, userId), except ? ne(sessions.id, except) : undefined);
  const closing = (await tx.select({ id: sessions.id }).from(sessions).where(where).for('update')).map((s) => s.id);
  if (closing.length === 0) return { closed: [], afterCommit: () => {} };
  {
    const tokens = await tx.select({ tokenHash: refreshTokens.tokenHash, sessionId: refreshTokens.sessionId })
      .from(refreshTokens).where(inArray(refreshTokens.sessionId, closing));
    if (tokens.length > 0) {
      await tx.insert(endedSessions).values(tokens.map((t) => ({ tokenHash: t.tokenHash, sessionId: t.sessionId, reason })))
        .onConflictDoNothing();
    }
  }
  await tx.delete(sessions).where(inArray(sessions.id, closing));
  return { closed: closing, afterCommit: () => closeSessionSockets(closing, reason) };
}
