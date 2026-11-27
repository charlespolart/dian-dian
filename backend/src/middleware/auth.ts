import type { Request, Response, NextFunction } from 'express';
import { verifyAccessToken } from '../lib/jwt.js';
import { sessionStatus } from '../lib/sessions.js';

declare global {
  namespace Express {
    interface Request {
      userId?: string;
      /** The session of the access token; null for a token issued before sessions had ids. */
      sessionId?: string | null;
    }
  }
}

export async function requireAuth(req: Request, res: Response, next: NextFunction) {
  const header = req.headers.authorization;
  if (!header?.startsWith('Bearer ')) {
    res.status(401).json({ error: 'Missing token' });
    return;
  }

  let claims: { userId: string; sessionId: string | null };
  try {
    claims = await verifyAccessToken(header.slice(7));
  } catch (err) {
    // Routine expiry is normal token lifecycle (the app refreshes) — stay quiet.
    // Log everything else: a malformed/tampered token is worth seeing.
    const code = (err as { code?: string } | null)?.code;
    if (code !== 'ERR_JWT_EXPIRED') {
      console.warn('auth: rejected token', { ip: req.ip, code });
    }
    // No reason: the app renews its tokens (and app 1.4.0 behaves as today).
    res.status(401).json({ error: 'Invalid or expired token' });
    return;
  }
  // A valid token whose session is over is refused at once, with why: a
  // signed-out or deleted account no longer reads nor writes for the rest of
  // the token's 15 minutes (chantier 9).
  if (claims.sessionId) {
    let status;
    try {
      status = await sessionStatus(claims.sessionId);
    } catch (err) {
      next(err);
      return;
    }
    if (status !== 'alive') {
      res.status(401).json({ error: 'Session ended', code: status });
      return;
    }
  }
  req.userId = claims.userId;
  req.sessionId = claims.sessionId;
  next();
}
