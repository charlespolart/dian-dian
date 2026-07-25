import type { Request, Response, NextFunction } from 'express';
import { verifyAccessToken } from '../lib/jwt.js';

declare global {
  namespace Express {
    interface Request {
      userId?: string;
    }
  }
}

export async function requireAuth(req: Request, res: Response, next: NextFunction) {
  const header = req.headers.authorization;
  if (!header?.startsWith('Bearer ')) {
    res.status(401).json({ error: 'Missing token' });
    return;
  }

  try {
    req.userId = await verifyAccessToken(header.slice(7));
    next();
  } catch (err) {
    // Routine expiry is normal token lifecycle (the app refreshes) — stay quiet.
    // Log everything else: a malformed/tampered token is worth seeing.
    const code = (err as { code?: string } | null)?.code;
    if (code !== 'ERR_JWT_EXPIRED') {
      console.warn('auth: rejected token', { ip: req.ip, code });
    }
    res.status(401).json({ error: 'Invalid or expired token' });
  }
}
