import { SignJWT, jwtVerify } from 'jose';
import { randomBytes, createHash } from 'crypto';
import { env } from './env.js';

const secret = new TextEncoder().encode(env.JWT_SECRET);

/** An access token for [userId], naming its session (`sid`, chantier 9). */
export async function signAccessToken(userId: string, sessionId: string): Promise<string> {
  return new SignJWT({ sub: userId, sid: sessionId })
    .setProtectedHeader({ alg: 'HS256' })
    .setIssuedAt()
    .setExpirationTime('15m')
    .sign(secret);
}

/**
 * Who the token is for, and its session. A token issued before sessions had
 * ids (before the update; 15 minutes at most) has none: `sessionId` null.
 */
export async function verifyAccessToken(token: string): Promise<{ userId: string; sessionId: string | null }> {
  // Pin the algorithm at verification: never trust the token header's `alg`.
  const { payload } = await jwtVerify(token, secret, { algorithms: ['HS256'] });
  if (!payload.sub) throw new Error('Invalid token');
  return { userId: payload.sub, sessionId: typeof payload.sid === 'string' ? payload.sid : null };
}

export function generateRefreshToken(): string {
  return randomBytes(48).toString('base64url');
}

export function hashToken(token: string): string {
  return createHash('sha256').update(token).digest('hex');
}
