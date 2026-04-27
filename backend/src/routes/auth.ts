import { Router, Response } from 'express';
import { z } from 'zod';
import * as argon2 from 'argon2';
import { db } from '../db/index.js';
import { users, refreshTokens, pages, passwordResetTokens, subscriptions, oauthAccounts } from '../db/schema.js';
import { and } from 'drizzle-orm';
import { signAccessToken, generateRefreshToken, hashToken } from '../lib/jwt.js';
import { validate } from '../middleware/validate.js';
import { requireAuth } from '../middleware/auth.js';
import { sendPasswordResetEmail, sendAccountDeletedEmail } from '../lib/email.js';
import { verifyAppleIdentityToken, verifyGoogleIdToken } from '../lib/oauth.js';
import { env } from '../lib/env.js';
import { eq } from 'drizzle-orm';
import crypto from 'crypto';

const router = Router();

async function hasActiveSubscription(userId: string): Promise<boolean> {
  const [sub] = await db.select()
    .from(subscriptions)
    .where(and(eq(subscriptions.userId, userId), eq(subscriptions.active, true)))
    .limit(1);
  if (!sub) return false;
  if (sub.expiresAt && sub.expiresAt < new Date()) return false;
  return true;
}

/** Issues access + refresh tokens, sets the cookie, and returns the response body. */
async function issueSession(
  res: Response,
  user: { id: string; vip: boolean; theme: string; language: string | null; cursorId: string; cursorEnabled: boolean },
) {
  const accessToken = await signAccessToken(user.id);
  const refreshToken = generateRefreshToken();
  const expiresAt = new Date(Date.now() + 7 * 24 * 60 * 60 * 1000);
  await db.insert(refreshTokens).values({
    userId: user.id,
    tokenHash: hashToken(refreshToken),
    expiresAt,
  });
  res.cookie('refreshToken', refreshToken, {
    httpOnly: true,
    secure: process.env.NODE_ENV === 'production',
    sameSite: 'strict',
    maxAge: 7 * 24 * 60 * 60 * 1000,
    path: '/api/auth',
  });
  const premium = await hasActiveSubscription(user.id);
  return {
    accessToken, refreshToken, userId: user.id, vip: user.vip, premium,
    theme: user.theme, language: user.language,
    cursorId: user.cursorId, cursorEnabled: user.cursorEnabled,
  };
}

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

    // Create default page
    await db.insert(pages).values({ userId: user.id, title: 'My Tracker', position: 0 });

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
      res.status(401).json({ error: 'Invalid email or password' });
      return;
    }

    const valid = await argon2.verify(user.passwordHash, password);
    if (!valid) {
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

    // 3) Brand-new account — create user (no password) + link, plus default page.
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
    await db.insert(pages).values({ userId: created.id, title: 'My Tracker', position: 0 });

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

    // Cascade delete handles pages, cells, legends, tokens
    await db.delete(users).where(eq(users.id, req.userId!));

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
router.post('/refresh', async (req, res) => {
  try {
    const token = req.body?.refreshToken || req.cookies?.refreshToken;
    if (!token) {
      res.status(401).json({ error: 'Missing refresh token' });
      return;
    }

    const tokenH = hashToken(token);
    const [stored] = await db.select().from(refreshTokens).where(eq(refreshTokens.tokenHash, tokenH)).limit(1);

    if (!stored || stored.expiresAt < new Date()) {
      res.status(401).json({ error: 'Invalid or expired refresh token' });
      return;
    }

    // Rotation: delete old, issue new
    await db.delete(refreshTokens).where(eq(refreshTokens.id, stored.id));

    const accessToken = await signAccessToken(stored.userId);
    const newRefreshToken = generateRefreshToken();
    const expiresAt = new Date(Date.now() + 7 * 24 * 60 * 60 * 1000);

    await db.insert(refreshTokens).values({
      userId: stored.userId,
      tokenHash: hashToken(newRefreshToken),
      expiresAt,
    });

    res.cookie('refreshToken', newRefreshToken, {
      httpOnly: true,
      secure: process.env.NODE_ENV === 'production',
      sameSite: 'strict',
      maxAge: 7 * 24 * 60 * 60 * 1000,
      path: '/api/auth',
    });

    res.json({ accessToken, refreshToken: newRefreshToken });
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

    await db.update(users).set(updates).where(eq(users.id, req.userId!));
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
