import { Router, Response } from 'express';
import { z } from 'zod';
import * as argon2 from 'argon2';
import { db } from '../db/index.js';
import { users, refreshTokens, passwordResetTokens, subscriptions, oauthAccounts, endedSessions } from '../db/schema.js';
import { and } from 'drizzle-orm';
import { signAccessToken, generateRefreshToken, hashToken } from '../lib/jwt.js';
import { validate } from '../middleware/validate.js';
import { requireAuth } from '../middleware/auth.js';
import { sendPasswordResetEmail, sendAccountDeletedEmail } from '../lib/email.js';
import { verifyAppleIdentityToken, verifyGoogleIdToken } from '../lib/oauth.js';
import { env } from '../lib/env.js';
import { hasActiveSubscription } from '../lib/premium.js';
import { nextRev } from '../lib/revs.js';
import { eq } from 'drizzle-orm';
import crypto from 'crypto';

const router = Router();

type ProfileUser = {
  id: string; email: string; vip: boolean; theme: string;
  language: string | null; cursorId: string; cursorEnabled: boolean;
};

/** The user fields the app needs at startup (settings, vip, premium). */
async function profileOf(user: ProfileUser) {
  return {
    userId: user.id,
    email: user.email,
    vip: user.vip,
    premium: await hasActiveSubscription(user.id),
    theme: user.theme,
    language: user.language,
    cursorId: user.cursorId,
    cursorEnabled: user.cursorEnabled,
  };
}

/**
 * How long a session lasts without being used: 18 months, longer than the 12
 * months after which the account document erases an untouched account, so
 * that a phone left offline for weeks is never logged out (offline sync,
 * chantier 10). Each renewal starts the period again.
 */
export const SESSION_DAYS = 548;
const sessionMs = SESSION_DAYS * 24 * 60 * 60 * 1000;

function setRefreshCookie(res: Response, refreshToken: string) {
  res.cookie('refreshToken', refreshToken, {
    httpOnly: true,
    secure: process.env.NODE_ENV === 'production',
    sameSite: 'strict',
    maxAge: sessionMs,
    path: '/api/auth',
  });
}

/** A new refresh token for [userId], stored by its hash; returns it and its row id. */
async function newRefreshToken(userId: string): Promise<{ token: string; id: string }> {
  const token = generateRefreshToken();
  const [row] = await db.insert(refreshTokens)
    .values({ userId, tokenHash: hashToken(token), expiresAt: new Date(Date.now() + sessionMs) })
    .returning({ id: refreshTokens.id });
  return { token, id: row.id };
}

/** Issues access + refresh tokens, sets the cookie, and returns the response body. */
async function issueSession(res: Response, user: ProfileUser) {
  const accessToken = await signAccessToken(user.id);
  const { token: refreshToken } = await newRefreshToken(user.id);
  setRefreshCookie(res, refreshToken);
  return { accessToken, refreshToken, ...(await profileOf(user)) };
}

/** A refused renewal, with why: the app only erases its copy for `account_deleted`. */
type EndCode = 'invalid' | 'session_expired' | 'session_revoked' | 'account_deleted';
const refuse = (res: Response, code: EndCode) => res.status(401).json({ error: 'Invalid or expired refresh token', code });

const registerSchema = z.object({
  email: z.string().email('Invalid email').max(255),
  password: z.string().min(8, 'Password must be at least 8 characters').max(128),
});

const loginSchema = registerSchema;

// Register
router.post('/register', validate(registerSchema), async (req, res) => {
  try {
    const { email, password } = req.body;

    const existing = await db.select({ id: users.id }).from(users).where(eq(users.email, email)).limit(1);
    if (existing.length > 0) {
      res.status(409).json({ error: 'An account already exists with this email' });
      return;
    }

    const passwordHash = await argon2.hash(password, { type: argon2.argon2id });

    const [user] = await db.insert(users).values({ email, passwordHash }).returning();
    // No default page since 1.2.0: the app's first-tracker flow creates it.

    res.status(201).json(await issueSession(res, user));
  } catch (err) {
    console.error('Register error:', err);
    res.status(500).json({ error: 'Server error' });
  }
});

// Login
router.post('/login', validate(loginSchema), async (req, res) => {
  try {
    const { email, password } = req.body;

    const [user] = await db.select().from(users).where(eq(users.email, email)).limit(1);
    if (!user || !user.passwordHash) {
      // OAuth-only users have no password — generic message keeps providers private.
      // Log IP only (no email → no PII in logs) so a brute-force is visible live.
      console.warn('auth: failed login', { ip: req.ip });
      res.status(401).json({ error: 'Invalid email or password' });
      return;
    }

    const valid = await argon2.verify(user.passwordHash, password);
    if (!valid) {
      console.warn('auth: failed login', { ip: req.ip });
      res.status(401).json({ error: 'Invalid email or password' });
      return;
    }

    res.json(await issueSession(res, user));
  } catch (err) {
    console.error('Login error:', err);
    res.status(500).json({ error: 'Server error' });
  }
});

// OAuth sign-in (Apple / Google) — verifies the provider's identity token,
// then either signs in an existing linked user, links the provider to a user
// matched by email, or creates a fresh user.
const oauthSchema = z.object({
  provider: z.enum(['apple', 'google']),
  identityToken: z.string().min(10),
});

router.post('/oauth', validate(oauthSchema), async (req, res) => {
  try {
    const { provider, identityToken } = req.body as { provider: 'apple' | 'google'; identityToken: string };

    let claims;
    try {
      if (provider === 'apple') {
        if (env.APPLE_BUNDLE_IDS.length === 0) throw new Error('APPLE_BUNDLE_IDS not configured');
        claims = await verifyAppleIdentityToken(identityToken, env.APPLE_BUNDLE_IDS);
      } else {
        if (env.GOOGLE_CLIENT_IDS.length === 0) throw new Error('GOOGLE_CLIENT_IDS not configured');
        claims = await verifyGoogleIdToken(identityToken, env.GOOGLE_CLIENT_IDS);
      }
    } catch (err) {
      console.error(`${provider} token verification failed:`, err);
      res.status(401).json({ error: 'Invalid identity token' });
      return;
    }

    // 1) Already linked? Sign that user in.
    const [linked] = await db.select({ userId: oauthAccounts.userId })
      .from(oauthAccounts)
      .where(and(eq(oauthAccounts.provider, provider), eq(oauthAccounts.subject, claims.subject)))
      .limit(1);

    if (linked) {
      const [user] = await db.select().from(users).where(eq(users.id, linked.userId)).limit(1);
      if (!user) {
        res.status(500).json({ error: 'Account inconsistency' });
        return;
      }
      res.json(await issueSession(res, user));
      return;
    }

    // 2) Email matches an existing user? Link the provider to that user.
    if (claims.email) {
      const [existing] = await db.select().from(users).where(eq(users.email, claims.email)).limit(1);
      if (existing) {
        await db.insert(oauthAccounts).values({ provider, subject: claims.subject, userId: existing.id });
        res.json(await issueSession(res, existing));
        return;
      }
    }

    // 3) Brand-new account — create user (no password) + link. No default page
    //    since 1.2.0: the app's first-tracker flow creates it.
    if (!claims.email) {
      res.status(400).json({ error: 'Provider did not return an email' });
      return;
    }

    const [created] = await db.insert(users).values({
      email: claims.email,
      passwordHash: null,
      emailVerified: claims.emailVerified === true,
    }).returning();
    await db.insert(oauthAccounts).values({ provider, subject: claims.subject, userId: created.id });

    res.status(201).json(await issueSession(res, created));
  } catch (err) {
    console.error('OAuth error:', err);
    res.status(500).json({ error: 'Server error' });
  }
});

function generateOtpCode(): string {
  // 6-digit numeric code, zero-padded.
  return crypto.randomInt(0, 1_000_000).toString().padStart(6, '0');
}

// Forgot password — issues a 6-digit OTP delivered by email.
router.post('/forgot-password', validate(z.object({ email: z.string().email() })), async (req, res) => {
  try {
    const { email } = req.body;
    const [user] = await db.select({ id: users.id }).from(users).where(eq(users.email, email)).limit(1);

    // Always return success to prevent email enumeration.
    if (!user) {
      res.json({ ok: true });
      return;
    }

    // One active code per user — overwrite any previous one.
    await db.delete(passwordResetTokens).where(eq(passwordResetTokens.userId, user.id));

    const code = generateOtpCode();
    await db.insert(passwordResetTokens).values({
      userId: user.id,
      tokenHash: hashToken(code),
      expiresAt: new Date(Date.now() + 10 * 60 * 1000), // 10 min
    });

    await sendPasswordResetEmail(email, code);
    res.json({ ok: true });
  } catch (err) {
    console.error('Forgot password error:', err);
    res.status(500).json({ error: 'Server error' });
  }
});

// Reset password — consumes the OTP. Caps wrong guesses at 5 to block brute-force.
router.post('/reset-password', validate(z.object({
  email: z.string().email(),
  code: z.string().regex(/^\d{6}$/),
  password: z.string().min(8).max(128),
})), async (req, res) => {
  try {
    const { email, code, password } = req.body;
    const [user] = await db.select({ id: users.id }).from(users).where(eq(users.email, email)).limit(1);
    if (!user) {
      res.status(400).json({ error: 'Invalid or expired code' });
      return;
    }

    const [stored] = await db.select().from(passwordResetTokens)
      .where(eq(passwordResetTokens.userId, user.id)).limit(1);
    if (!stored || stored.expiresAt < new Date()) {
      res.status(400).json({ error: 'Invalid or expired code' });
      return;
    }

    if (stored.attempts >= 5) {
      await db.delete(passwordResetTokens).where(eq(passwordResetTokens.userId, user.id));
      res.status(400).json({ error: 'Too many attempts, request a new code' });
      return;
    }

    if (stored.tokenHash !== hashToken(code)) {
      await db.update(passwordResetTokens)
        .set({ attempts: stored.attempts + 1 })
        .where(eq(passwordResetTokens.userId, user.id));
      res.status(400).json({ error: 'Invalid or expired code' });
      return;
    }

    const passwordHash = await argon2.hash(password, { type: argon2.argon2id });
    await db.update(users).set({ passwordHash }).where(eq(users.id, user.id));
    await db.delete(passwordResetTokens).where(eq(passwordResetTokens.userId, user.id));

    res.json({ ok: true });
  } catch (err) {
    console.error('Reset password error:', err);
    res.status(500).json({ error: 'Server error' });
  }
});

// Delete account
router.delete('/account', requireAuth, async (req, res) => {
  try {
    const [user] = await db.select({ email: users.email }).from(users).where(eq(users.id, req.userId!)).limit(1);

    // Cascade delete handles pages, cells, legends, tokens. Its sessions are
    // remembered as ended by a deletion: another phone of the account learns
    // it at its next renewal and erases its copy (H24).
    await db.transaction(async (tx) => {
      const sessions = await tx.select({ tokenHash: refreshTokens.tokenHash }).from(refreshTokens).where(eq(refreshTokens.userId, req.userId!));
      if (sessions.length > 0) {
        await tx.insert(endedSessions).values(sessions.map((t) => ({ tokenHash: t.tokenHash, reason: 'account_deleted' })))
          .onConflictDoNothing();
      }
      await tx.delete(users).where(eq(users.id, req.userId!));
    });

    res.clearCookie('refreshToken', { path: '/api/auth' });

    if (user) {
      sendAccountDeletedEmail(user.email).catch(err => console.error('Email send error:', err));
    }

    res.json({ ok: true });
  } catch (err) {
    console.error('Delete account error:', err);
    res.status(500).json({ error: 'Server error' });
  }
});

// Refresh
// Renew a session. The token presented is replaced; it stays good while
// its successor has never been used, so a renewal whose answer was lost on
// the way can be made again (the unused successor is dropped). Once the
// successor has served, the old token is refused, saying why.
router.post('/refresh', async (req, res) => {
  try {
    const token = req.body?.refreshToken || req.cookies?.refreshToken;
    if (!token) { refuse(res, 'invalid'); return; }

    const tokenH = hashToken(token);
    const [stored] = await db.select().from(refreshTokens).where(eq(refreshTokens.tokenHash, tokenH)).limit(1);
    if (!stored) {
      const [ended] = await db.select({ reason: endedSessions.reason }).from(endedSessions).where(eq(endedSessions.tokenHash, tokenH)).limit(1);
      refuse(res, (ended?.reason as EndCode | undefined) ?? 'invalid');
      return;
    }
    if (stored.expiresAt < new Date()) { refuse(res, 'session_expired'); return; }

    // The profile rides along with the new token pair so the app can skip
    // the /me round-trip on cold start.
    const [user] = await db.select().from(users).where(eq(users.id, stored.userId)).limit(1);
    if (!user) { refuse(res, 'account_deleted'); return; }

    if (stored.replacedById) {
      const [successor] = await db.select({ id: refreshTokens.id, replacedById: refreshTokens.replacedById })
        .from(refreshTokens).where(eq(refreshTokens.id, stored.replacedById)).limit(1);
      // The successor has served (it was renewed in turn): this token is spent.
      if (successor?.replacedById) { refuse(res, 'session_revoked'); return; }
      // Never used: its answer was lost. Drop it and issue another.
      if (successor) await db.delete(refreshTokens).where(eq(refreshTokens.id, successor.id));
    }

    const next = await newRefreshToken(stored.userId);
    await db.update(refreshTokens).set({ replacedById: next.id }).where(eq(refreshTokens.id, stored.id));
    // The token before this one is no longer needed: its successor (this
    // one) has now served.
    await db.delete(refreshTokens).where(eq(refreshTokens.replacedById, stored.id));

    const accessToken = await signAccessToken(stored.userId);
    setRefreshCookie(res, next.token);
    res.json({ accessToken, refreshToken: next.token, ...(await profileOf(user)) });
  } catch (err) {
    console.error('Refresh error:', err);
    res.status(500).json({ error: 'Server error' });
  }
});

// Get current user info (vip status, settings, etc.)
router.get('/me', requireAuth, async (req, res) => {
  try {
    const [user] = await db.select({
      id: users.id,
      email: users.email,
      vip: users.vip,
      theme: users.theme,
      language: users.language,
      cursorId: users.cursorId,
      cursorEnabled: users.cursorEnabled,
    })
      .from(users)
      .where(eq(users.id, req.userId!))
      .limit(1);
    if (!user) { res.status(404).json({ error: 'User not found' }); return; }
    const premium = await hasActiveSubscription(user.id);
    res.json({ ...user, premium });
  } catch (err) {
    console.error('Get me error:', err);
    res.status(500).json({ error: 'Server error' });
  }
});

// Update user settings
const settingsSchema = z.object({
  theme: z.string().max(50).optional(),
  language: z.string().max(10).nullable().optional(),
  cursorId: z.string().max(50).optional(),
  cursorEnabled: z.boolean().optional(),
}).strict();

router.patch('/settings', requireAuth, validate(settingsSchema), async (req, res) => {
  try {
    const updates: Record<string, unknown> = {};
    if (req.body.theme !== undefined) updates.theme = req.body.theme;
    if (req.body.language !== undefined) updates.language = req.body.language;
    if (req.body.cursorId !== undefined) updates.cursorId = req.body.cursorId;
    if (req.body.cursorEnabled !== undefined) updates.cursorEnabled = req.body.cursorEnabled;

    if (Object.keys(updates).length === 0) {
      res.json({ ok: true });
      return;
    }

    // Each setting is an element of its own for the offline rule: theme,
    // language, cursor (its id and whether it is on go together).
    await db.transaction(async (tx) => {
      const rev = await nextRev(tx, req.userId!);
      await tx.update(users).set({
        ...updates,
        ...(updates.theme !== undefined ? { themeRev: rev } : {}),
        ...(updates.language !== undefined ? { languageRev: rev } : {}),
        ...(updates.cursorId !== undefined || updates.cursorEnabled !== undefined ? { cursorRev: rev } : {}),
      }).where(eq(users.id, req.userId!));
    });
    res.json({ ok: true });
  } catch (err) {
    console.error('Update settings error:', err);
    res.status(500).json({ error: 'Server error' });
  }
});

// Logout
router.post('/logout', requireAuth, async (req, res) => {
  try {
    const token = req.body?.refreshToken || req.cookies?.refreshToken;
    if (token) {
      await db.delete(refreshTokens).where(eq(refreshTokens.tokenHash, hashToken(token)));
    }

    res.clearCookie('refreshToken', { path: '/api/auth' });
    res.json({ ok: true });
  } catch (err) {
    console.error('Logout error:', err);
    res.status(500).json({ error: 'Server error' });
  }
});

export default router;
