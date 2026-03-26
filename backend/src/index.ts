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
  message: { error: 'Trop de tentatives, réessayez dans 15 minutes' },
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

// WebSocket
setupWebSocket(server);

// Serve frontend static files in production
const frontendDist = path.resolve(__dirname, '../../frontend/dist');
app.use(express.static(frontendDist));

// SPA fallback — inject apple-touch-icon meta tags
import { readFileSync } from 'fs';
let indexHtml = '';
try {
  indexHtml = readFileSync(path.join(frontendDist, 'index.html'), 'utf-8');
  if (!indexHtml.includes('apple-touch-icon')) {
    indexHtml = indexHtml.replace(
      '</head>',
      '  <link rel="apple-touch-icon" sizes="180x180" href="/apple-touch-icon.png" />\n' +
      '  <meta name="apple-mobile-web-app-capable" content="yes" />\n' +
      '  <meta name="apple-mobile-web-app-status-bar-style" content="default" />\n' +
      '  <meta name="apple-mobile-web-app-title" content="Dian Dian" />\n' +
      '  <meta name="theme-color" content="#f5f0d0" />\n' +
      '</head>'
    );
  }
} catch { /* dist not built yet */ }

app.get('*', (_req, res) => {
  if (indexHtml) {
    res.type('html').send(indexHtml);
  } else {
    res.sendFile(path.join(frontendDist, 'index.html'));
  }
});

server.listen(env.PORT, () => {
  console.log(`Server running on http://localhost:${env.PORT}`);
});
