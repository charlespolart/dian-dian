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

// SPA fallback
app.get('*', (_req, res) => {
  res.sendFile(path.join(frontendDist, 'index.html'));
});

server.listen(env.PORT, () => {
  console.log(`Server running on http://localhost:${env.PORT}`);
});
