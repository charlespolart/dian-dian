import { Router } from 'express';
import { z } from 'zod';
import * as argon2 from 'argon2';
import { db } from '../db/index.js';
import { users, refreshTokens, pages, passwordResetTokens } from '../db/schema.js';
import { signAccessToken, generateRefreshToken, hashToken } from '../lib/jwt.js';
import { validate } from '../middleware/validate.js';
import { requireAuth } from '../middleware/auth.js';
import { sendPasswordResetEmail, sendAccountDeletedEmail } from '../lib/email.js';
import { eq } from 'drizzle-orm';
import crypto from 'crypto';

const router = Router();

const registerSchema = z.object({
  email: z.string().email('Invalid email').max(255),
  password: z.string().min(8, 'Password must be at least 8 characters').max(128),
});

const loginSchema = registerSchema;

function generateToken(): string {
  return crypto.randomBytes(32).toString('hex');
}

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

    const [user] = await db.insert(users).values({ email, passwordHash }).returning({ id: users.id });

    // Create default page
    await db.insert(pages).values({ userId: user.id, title: 'My Tracker', position: 0 });

    // Generate auth tokens
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

    res.status(201).json({ accessToken, refreshToken, userId: user.id });
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
    if (!user) {
      res.status(401).json({ error: 'Invalid email or password' });
      return;
    }

    const valid = await argon2.verify(user.passwordHash, password);
    if (!valid) {
      res.status(401).json({ error: 'Invalid email or password' });
      return;
    }

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

    res.json({ accessToken, refreshToken, userId: user.id, vip: user.vip });
  } catch (err) {
    console.error('Login error:', err);
    res.status(500).json({ error: 'Server error' });
  }
});

// Forgot password
router.post('/forgot-password', validate(z.object({ email: z.string().email() })), async (req, res) => {
  try {
    const { email } = req.body;
    const [user] = await db.select({ id: users.id }).from(users).where(eq(users.email, email)).limit(1);

    // Always return success to prevent email enumeration
    if (!user) {
      res.json({ ok: true });
      return;
    }

    // Delete old tokens
    await db.delete(passwordResetTokens).where(eq(passwordResetTokens.userId, user.id));

    const token = generateToken();
    await db.insert(passwordResetTokens).values({
      userId: user.id,
      tokenHash: hashToken(token),
      expiresAt: new Date(Date.now() + 60 * 60 * 1000), // 1h
    });

    await sendPasswordResetEmail(email, token);
    res.json({ ok: true });
  } catch (err) {
    console.error('Forgot password error:', err);
    res.status(500).json({ error: 'Server error' });
  }
});

// Reset password
router.post('/reset-password', validate(z.object({
  token: z.string().min(1),
  password: z.string().min(8).max(128),
})), async (req, res) => {
  try {
    const { token, password } = req.body;
    const tokenH = hashToken(token);

    const [stored] = await db.select().from(passwordResetTokens).where(eq(passwordResetTokens.tokenHash, tokenH)).limit(1);
    if (!stored || stored.expiresAt < new Date()) {
      res.status(400).json({ error: 'Invalid or expired reset link' });
      return;
    }

    const passwordHash = await argon2.hash(password, { type: argon2.argon2id });
    await db.update(users).set({ passwordHash }).where(eq(users.id, stored.userId));

    // Delete used token
    await db.delete(passwordResetTokens).where(eq(passwordResetTokens.userId, stored.userId));

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

// Get current user info (vip status, etc.)
router.get('/me', requireAuth, async (req, res) => {
  try {
    const [user] = await db.select({ id: users.id, email: users.email, vip: users.vip })
      .from(users)
      .where(eq(users.id, req.userId!))
      .limit(1);
    if (!user) { res.status(404).json({ error: 'User not found' }); return; }
    res.json(user);
  } catch (err) {
    console.error('Get me error:', err);
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
