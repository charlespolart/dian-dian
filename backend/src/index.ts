import express from 'express';
import helmet from 'helmet';
import cors from 'cors';
import cookieParser from 'cookie-parser';
import rateLimit from 'express-rate-limit';
import { createServer } from 'http';
import path from 'path';
import { fileURLToPath } from 'url';
import { env } from './lib/env.js';
import { setupWebSocket } from './lib/ws.js';
import authRoutes from './routes/auth.js';
import pagesRoutes from './routes/pages.js';
import cellsRoutes from './routes/cells.js';
import legendsRoutes from './routes/legends.js';
import legalRoutes from './routes/legal.js';

const __dirname = path.dirname(fileURLToPath(import.meta.url));

const app = express();
const server = createServer(app);

// Security
app.use(helmet({ contentSecurityPolicy: false }));
app.use(cors({ origin: env.CORS_ORIGIN, credentials: true }));
app.use(express.json({ limit: '1mb' }));
app.use(cookieParser());

// Rate limiting on login/register only
const authLimiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 min
  max: 30,
  message: { error: 'Too many attempts, try again in 15 minutes' },
});

// Routes
app.use('/api/auth/login', authLimiter);
app.use('/api/auth/register', authLimiter);
app.use('/api/auth', authRoutes);
app.use('/api/pages', pagesRoutes);
app.use('/api/cells', cellsRoutes);
app.use('/api/legends', legendsRoutes);

// Health check
app.get('/api/health', (_req, res) => res.json({ ok: true }));

// Contact form
import { Resend } from 'resend';
const resend = new Resend(env.RESEND_API_KEY);
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
    await resend.emails.send({
      from: 'Dian Dian Contact <noreply@mydiandian.app>',
      to: 'contact@mydiandian.app',
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

// Legal pages (served before static files so routes take priority)
app.use(legalRoutes);

// Serve Flutter web static files in production
const webDist = path.resolve(__dirname, '../../flutter_app/build/web');
app.use(express.static(webDist));

// SPA fallback
app.get('*', (_req, res) => {
  res.sendFile(path.join(webDist, 'index.html'));
});

server.listen(env.PORT, () => {
  console.log(`Server running on http://localhost:${env.PORT}`);
});
