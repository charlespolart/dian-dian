import { Router, Response } from 'express';
import { z } from 'zod';
import * as argon2 from 'argon2';
import { db } from '../db/index.js';
import { users, refreshTokens, passwordResetTokens, subscriptions, oauthAccounts, endedSessions, sessions, accountKeys, deletedAccounts } from '../db/schema.js';
import { accountKind } from '../lib/accountKind.js';
import { sqlState } from '../lib/pgError.js';
import { newSession, touchLastSeen, type EndReason } from '../lib/sessions.js';
import { closeSessions } from '../lib/closeSessions.js';
import type { Tx } from '../lib/revs.js';
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
import { notifySync } from '../lib/ws.js';

const router = Router();

type ProfileUser = {
  id: string; email: string | null; passwordHash: string | null; vip: boolean; theme: string;
  language: string | null; cursorId: string; cursorEnabled: boolean;
};

/**
 * The user fields the app needs at startup (settings, vip, premium), and
 * what the account is: invisible or attached, and by which methods
 * (chantier 9, principle 5 — the app never guesses it).
 */
async function profileOf(user: ProfileUser) {
  const providers = (await db.select({ provider: oauthAccounts.provider }).from(oauthAccounts)
    .where(eq(oauthAccounts.userId, user.id))).map((row) => row.provider);
  return {
    userId: user.id,
    email: user.email,
    ...accountKind(user, providers),
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

/** A new refresh token of [sessionId], stored by its hash; returns it and its row id. */
async function newRefreshToken(userId: string, sessionId: string, tx: Tx | typeof db = db): Promise<{ token: string; id: string }> {
  const token = generateRefreshToken();
  const [row] = await tx.insert(refreshTokens)
    .values({ userId, sessionId, tokenHash: hashToken(token), expiresAt: new Date(Date.now() + sessionMs) })
    .returning({ id: refreshTokens.id });
  return { token, id: row.id };
}

/** Opens a session: access + refresh tokens, the cookie, and the response body. */
async function issueSession(res: Response, user: ProfileUser) {
  // The session and its first token in one step: the hourly purge of
  // sessions without a token never sees one between the two (review, minor 11).
  const { sessionId, refreshToken } = await db.transaction(async (tx) => {
    const id = await newSession(user.id, tx);
    const { token } = await newRefreshToken(user.id, id, tx);
    return { sessionId: id, refreshToken: token };
  });
  const accessToken = await signAccessToken(user.id, sessionId);
  setRefreshCookie(res, refreshToken);
  return { accessToken, refreshToken, ...(await profileOf(user)) };
}

/**
 * A refused renewal, with why: the app only erases its copy for
 * `account_deleted`. An expired or spent token is `invalid`;
 * `session_revoked` means only "signed out from another device" (chantier 9).
 */
type EndCode = EndReason;
const refuse = (res: Response, code: EndCode) => res.status(401).json({ error: 'Invalid or expired refresh token', code });

// --- The invisible account (chantier 9) --------------------------------------
// The phone chooses its id (UUID v4) and its key (32 random bytes,
// base64url): offline at first launch it already writes under the account's
// final id, and the account is born at the first network (case 5).
const keySchema = z.object({
  id: z.string().uuid(),
  key: z.string().regex(/^[A-Za-z0-9_-]{43}$/, 'A key is 32 bytes in base64url'),
});

/** Whether [key] is the one whose hash is [stored], in constant time. */
function sameKey(stored: string, key: string): boolean {
  const a = Buffer.from(stored, 'hex');
  const b = Buffer.from(hashToken(key), 'hex');
  return a.length === b.length && crypto.timingSafeEqual(a, b);
}

/** Whether the account is remembered as deleted. */
async function wasDeleted(userId: string): Promise<boolean> {
  const [gone] = await db.select({ userId: deletedAccounts.userId }).from(deletedAccounts).where(eq(deletedAccounts.userId, userId)).limit(1);
  return !!gone;
}

// Create an invisible account, or answer again a creation whose answer was
// lost (same id, same key: a session, no second account).
router.post('/invisible', validate(keySchema), async (req, res) => {
  try {
    const { id, key } = req.body as z.infer<typeof keySchema>;
    if (await wasDeleted(id)) { refuse(res, 'account_deleted'); return; }
    const [existing] = await db.select().from(users).where(eq(users.id, id)).limit(1);
    if (existing) {
      const [held] = await db.select({ keyHash: accountKeys.keyHash }).from(accountKeys).where(eq(accountKeys.userId, id)).limit(1);
      if (held && sameKey(held.keyHash, key)) {
        await touchLastSeen(id);
        res.json(await issueSession(res, existing));
        return;
      }
      res.status(409).json({ error: 'This id is taken', code: 'taken' });
      return;
    }
    let created;
    try {
      created = await db.transaction(async (tx) => {
        const [user] = await tx.insert(users).values({ id, email: null }).returning();
        await tx.insert(accountKeys).values({ userId: id, keyHash: hashToken(key) });
        return user;
      });
    } catch (err) {
      if (sqlState(err) === '23505') { res.status(409).json({ error: 'This id is taken', code: 'taken' }); return; } // a twin request won the race
      throw err;
    }
    res.status(201).json(await issueSession(res, created));
  } catch (err) {
    console.error('Invisible account error:', err);
    res.status(500).json({ error: 'Server error' });
  }
});

// Reopen an invisible account's session with its key: the phone's way back
// when its refresh token is refused, lost, or absent (principle 4).
router.post('/key', validate(keySchema), async (req, res) => {
  try {
    const { id, key } = req.body as z.infer<typeof keySchema>;
    if (await wasDeleted(id)) { refuse(res, 'account_deleted'); return; }
    const [user] = await db.select().from(users).where(eq(users.id, id)).limit(1);
    // Never known here (a database restored to before it): the phone keeps
    // its copy and stays in; bringing the account back is a later lot.
    if (!user) { res.status(401).json({ error: 'Unknown account', code: 'unknown' }); return; }
    const [held] = await db.select({ keyHash: accountKeys.keyHash }).from(accountKeys).where(eq(accountKeys.userId, id)).limit(1);
    if (!held || !sameKey(held.keyHash, key)) { refuse(res, 'invalid'); return; }
    await touchLastSeen(id);
    res.json(await issueSession(res, user));
  } catch (err) {
    console.error('Key session error:', err);
    res.status(500).json({ error: 'Server error' });
  }
});

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
    // A changed password closes every session of the account, in the same
    // step: whoever had the old one is out (case 51).
    const closing = await db.transaction(async (tx) => {
      await tx.update(users).set({ passwordHash }).where(eq(users.id, user.id));
      await tx.delete(passwordResetTokens).where(eq(passwordResetTokens.userId, user.id));
      return closeSessions(tx, user.id, { reason: 'password_changed' });
    });
    closing.afterCommit();

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
    // it at its next request or renewal and erases its copy (H24, case 50).
    const closing = await db.transaction(async (tx) => {
      const ended = await closeSessions(tx, req.userId!, { reason: 'account_deleted' });
      await tx.delete(users).where(eq(users.id, req.userId!));
      // Remembered 24 months, by its id only: its key, or a copy of its data
      // restored on a phone, never brings it back (chantier 9).
      await tx.insert(deletedAccounts).values({ userId: req.userId!, reason: 'deleted' }).onConflictDoNothing();
      return ended;
    });
    closing.afterCommit();

    res.clearCookie('refreshToken', { path: '/api/auth' });

    if (user?.email) {
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
    if (stored.expiresAt < new Date()) { refuse(res, 'invalid'); return; }

    // The profile rides along with the new token pair so the app can skip
    // the /me round-trip on cold start.
    const [user] = await db.select().from(users).where(eq(users.id, stored.userId)).limit(1);
    if (!user) { refuse(res, 'account_deleted'); return; }

    if (stored.replacedById) {
      const [successor] = await db.select({ id: refreshTokens.id, replacedById: refreshTokens.replacedById })
        .from(refreshTokens).where(eq(refreshTokens.id, stored.replacedById)).limit(1);
      // The successor has served (it was renewed in turn): this token is spent.
      if (successor?.replacedById) { refuse(res, 'invalid'); return; }
      // Never used: its answer was lost. Drop it and issue another.
      if (successor) await db.delete(refreshTokens).where(eq(refreshTokens.id, successor.id));
    }

    const next = await newRefreshToken(stored.userId, stored.sessionId);
    await touchLastSeen(stored.userId);
    await db.update(refreshTokens).set({ replacedById: next.id }).where(eq(refreshTokens.id, stored.id));
    // The token before this one is no longer needed: its successor (this
    // one) has now served.
    await db.delete(refreshTokens).where(eq(refreshTokens.replacedById, stored.id));

    const accessToken = await signAccessToken(stored.userId, stored.sessionId);
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
    const [user] = await db.select().from(users).where(eq(users.id, req.userId!)).limit(1);
    if (!user) { res.status(404).json({ error: 'User not found' }); return; }
    // `id` as before; the profile adds `kind` and `methods` (chantier 9).
    res.json({ id: user.id, ...(await profileOf(user)) });
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
    notifySync(req.userId!); // the account's other phones take the setting live
    res.json({ ok: true });
  } catch (err) {
    console.error('Update settings error:', err);
    res.status(500).json({ error: 'Server error' });
  }
});

// « Déconnecter mes autres appareils » (case 52): every session of the
// account but this one ends, saying so. A token issued before sessions had
// ids cannot say which one is "this one": 401, the app renews and asks again.
router.post('/sessions/close-others', requireAuth, async (req, res) => {
  try {
    if (!req.sessionId) { res.status(401).json({ error: 'Renew the session first' }); return; }
    const closing = await db.transaction((tx) => closeSessions(tx, req.userId!, { except: req.sessionId, reason: 'session_revoked' }));
    closing.afterCommit();
    res.json({ closed: closing.closed.length });
  } catch (err) {
    console.error('Close other sessions error:', err);
    res.status(500).json({ error: 'Server error' });
  }
});

// Logout
router.post('/logout', requireAuth, async (req, res) => {
  try {
    // The whole session closes: every token of its chain goes with it (a
    // token left before the last renewal would otherwise still renew it).
    const token = req.body?.refreshToken || req.cookies?.refreshToken;
    const [owned] = token
      ? await db.select({ sessionId: refreshTokens.sessionId }).from(refreshTokens)
        .where(and(eq(refreshTokens.tokenHash, hashToken(token)), eq(refreshTokens.userId, req.userId!))).limit(1)
      : [];
    const sessionId = owned?.sessionId ?? req.sessionId;
    if (sessionId) await db.delete(sessions).where(and(eq(sessions.id, sessionId), eq(sessions.userId, req.userId!)));

    res.clearCookie('refreshToken', { path: '/api/auth' });
    res.json({ ok: true });
  } catch (err) {
    console.error('Logout error:', err);
    res.status(500).json({ error: 'Server error' });
  }
});

export default router;
