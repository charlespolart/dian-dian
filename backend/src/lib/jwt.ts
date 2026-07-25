import { SignJWT, jwtVerify } from 'jose';
import { randomBytes, createHash } from 'crypto';
import { env } from './env.js';

const secret = new TextEncoder().encode(env.JWT_SECRET);

export async function signAccessToken(userId: string): Promise<string> {
  return new SignJWT({ sub: userId })
    .setProtectedHeader({ alg: 'HS256' })
    .setIssuedAt()
    .setExpirationTime('15m')
    .sign(secret);
}

export async function verifyAccessToken(token: string): Promise<string> {
  // Pin the algorithm at verification: never trust the token header's `alg`.
  const { payload } = await jwtVerify(token, secret, { algorithms: ['HS256'] });
  if (!payload.sub) throw new Error('Invalid token');
  return payload.sub;
}

export function generateRefreshToken(): string {
  return randomBytes(48).toString('base64url');
}

export function hashToken(token: string): string {
  return createHash('sha256').update(token).digest('hex');
}
