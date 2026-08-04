import express from 'express';
import helmet from 'helmet';
import cors from 'cors';
import cookieParser from 'cookie-parser';
import rateLimit from 'express-rate-limit';
import { createServer } from 'http';
import path from 'path';
import { fileURLToPath } from 'url';
import { sql } from 'drizzle-orm';
import { env } from './lib/env.js';
import { db } from './db/index.js';
import { setupWebSocket } from './lib/ws.js';
import authRoutes from './routes/auth.js';
import pagesRoutes from './routes/pages.js';
import cellsRoutes from './routes/cells.js';
import legendsRoutes from './routes/legends.js';
import legalRoutes from './routes/legal.js';
import landingRoutes from './routes/landing.js';
import purchaseRoutes from './routes/purchase.js';

const __dirname = path.dirname(fileURLToPath(import.meta.url));

const app = express();
const server = createServer(app);

// Trust proxy (behind nginx)
app.set('trust proxy', 1);

// Security. CSP is tuned for the server-rendered landing + legal pages, which
// use inline <style>, inline <script>, inline event handlers and Google Fonts.
// No user-controlled HTML is rendered (the ?lang param is allow-listed), so
// 'unsafe-inline' here carries no real XSS risk. The mobile app hits /api/*
// (JSON) — CSP is a browser directive and does not affect it.
app.use(helmet({
  contentSecurityPolicy: {
    useDefaults: true,
    directives: {
      defaultSrc: ["'self'"],
      imgSrc: ["'self'", 'data:', 'https:'],
      styleSrc: ["'self'", "'unsafe-inline'", 'https://fonts.googleapis.com'],
      fontSrc: ["'self'", 'https://fonts.gstatic.com'],
      scriptSrc: ["'self'", "'unsafe-inline'"],
      scriptSrcAttr: ["'unsafe-inline'"],
      connectSrc: ["'self'"],
      frameAncestors: ["'none'"],
      baseUri: ["'self'"],
      formAction: ["'self'"],
      objectSrc: ["'none'"],
    },
  },
}));
app.use(cors({ origin: env.CORS_ORIGIN, credentials: true }));
app.use(express.json({ limit: '1mb' }));
app.use(cookieParser());

// Rate limiting. IP-keyed (trust proxy is set → real client IP via Caddy's
// X-Forwarded-For). Login/register brute-force, plus password-reset and OAuth
// which either send email (spam/cost) or run JWKS verification (cost).
const authLimiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 min
  max: 30,
  message: { error: 'Too many attempts, try again in 15 minutes' },
});
// Stricter budget for the email-sending path — forgot-password is rare per
// user, so a low cap barely touches legit traffic but stops inbox spam.
const forgotLimiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 min
  max: 5,
  message: { error: 'Too many attempts, try again in 15 minutes' },
});

// Routes
app.use('/api/auth/login', authLimiter);
app.use('/api/auth/register', authLimiter);
app.use('/api/auth/forgot-password', forgotLimiter);
app.use('/api/auth/oauth', authLimiter);
app.use('/api/auth', authRoutes);
app.use('/api/pages', pagesRoutes);
app.use('/api/cells', cellsRoutes);
app.use('/api/legends', legendsRoutes);
app.use('/api/purchase', purchaseRoutes);

// Liveness — deliberately cheap and DB-free. This is what the container
// healthcheck polls: if it depended on Postgres, every DB blip would mark the
// backend unhealthy and stall `compose up --wait` during a deploy.
app.get('/api/health', (_req, res) => res.json({ ok: true }));

// Readiness — actually proves the DB is reachable. /api/health returning 200
// says nothing about Postgres, so a green healthcheck can hide a dead DB
// (seen during the pgBackRest rollout). Use this one for monitoring.
app.get('/api/ready', async (_req, res) => {
  try {
    await db.execute(sql`SELECT 1`);
    res.json({ ok: true, db: 'up' });
  } catch (err) {
    console.error('Readiness check failed:', err);
    res.status(503).json({ ok: false, db: 'down' });
  }
});

// Contact form
import { sendEmail } from './lib/email.js';
function escapeHtml(s: string): string {
  return s.replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;').replace(/"/g, '&quot;');
}
const contactLimiter = rateLimit({ windowMs: 15 * 60 * 1000, max: 5, message: { error: 'Too many messages, try again later' } });
app.post('/api/contact', contactLimiter, async (req, res) => {
  const { name, email, message } = req.body;
  if (!name?.trim() || !email?.trim() || !message?.trim()) {
    res.status(400).json({ error: 'All fields are required' });
    return;
  }
  const safeName = escapeHtml(name.trim());
  const safeEmail = escapeHtml(email.trim());
  const safeMessage = escapeHtml(message.trim()).replace(/\n/g, '<br/>');
  try {
    await sendEmail({
      to: 'diandian@overridedev.com',
      fromName: 'Dian Dian Contact',
      replyTo: email.trim(),
      subject: `[Dian Dian] Message from ${safeName}`,
      html: `<p><strong>From:</strong> ${safeName} (${safeEmail})</p><hr/><p>${safeMessage}</p>`,
    });
    res.json({ ok: true });
  } catch (err) {
    console.error('Contact form error:', err);
    res.status(500).json({ error: 'Failed to send message' });
  }
});

// WebSocket
setupWebSocket(server);

// Landing (root) + legal pages, served before the static assets and the
// SPA catch-all so their routes take priority.
app.use(landingRoutes);
app.use(legalRoutes);

// Static assets for the landing + legal pages (screenshots, icons).
// `.png`/`.jpg` under /shots get a short revalidated cache via Caddy.
app.use(express.static(path.join(__dirname, '../public'), { maxAge: '1d', index: false }));

// AdMob app-ads.txt — verifies our domain authorizes this AdMob publisher.
app.get('/app-ads.txt', (_req, res) => {
  res
    .type('text/plain')
    .send('google.com, pub-7932342939488027, DIRECT, f08c47fec0942fa0\n');
});

// Web is intentionally limited to the server-rendered landing + legal pages.
// All app interaction (login, tracker, password reset OTP) lives in the
// iOS/Android app — no Flutter web build is served.
app.get('*', (_req, res) => {
  res.redirect(302, '/');
});

server.listen(env.PORT, () => {
  console.log(`Server running on http://localhost:${env.PORT}`);
});
