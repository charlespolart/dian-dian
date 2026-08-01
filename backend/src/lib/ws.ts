import { WebSocketServer, WebSocket } from 'ws';
import type { Server } from 'http';
import { verifyAccessToken } from './jwt.js';

// Map userId -> Set of connected WebSockets
const clients = new Map<string, Set<WebSocket>>();

// How long a connection may sit unauthenticated before we drop it.
const AUTH_TIMEOUT_MS = 10_000;

export function setupWebSocket(server: Server) {
  const wss = new WebSocketServer({ server, path: '/ws' });

  wss.on('connection', async (ws, req) => {
    const url = new URL(req.url || '', `http://${req.headers.host}`);
    const legacyToken = url.searchParams.get('token');

    const attach = (userId: string) => {
      if (!clients.has(userId)) clients.set(userId, new Set());
      clients.get(userId)!.add(ws);

      ws.on('close', () => {
        clients.get(userId)?.delete(ws);
        if (clients.get(userId)?.size === 0) clients.delete(userId);
      });
    };

    if (legacyToken) {
      // LEGACY path — apps shipped before 2026-08 pass ?token= in the URL.
      // Kept for backward compatibility while the installed fleet migrates;
      // remove once first-message auth has been out for a few months.
      try {
        attach(await verifyAccessToken(legacyToken));
      } catch {
        ws.close(4003, 'Invalid token');
      }
      return;
    }

    // NEW path — the client authenticates with its first message:
    //   {"type":"auth","token":"<jwt>"}
    // Keeps the token out of URLs (query strings end up in proxy/access
    // logs). The server acks with an `auth:ok` event; until then the socket
    // receives no broadcasts (attach() runs only after verification).
    const timer = setTimeout(() => ws.close(4001, 'Auth timeout'), AUTH_TIMEOUT_MS);

    ws.once('message', async (raw) => {
      clearTimeout(timer);
      try {
        const msg = JSON.parse(String(raw)) as { type?: string; token?: string };
        if (msg?.type !== 'auth' || typeof msg.token !== 'string') {
          ws.close(4001, 'Expected auth message');
          return;
        }
        attach(await verifyAccessToken(msg.token));
        ws.send(JSON.stringify({ event: 'auth:ok' }));
      } catch {
        ws.close(4003, 'Invalid token');
      }
    });
  });
}

export function broadcast(userId: string, event: string, data: unknown, excludeWs?: WebSocket) {
  const userClients = clients.get(userId);
  if (!userClients) return;
  const message = JSON.stringify({ event, data });
  for (const ws of userClients) {
    if (ws !== excludeWs && ws.readyState === WebSocket.OPEN) {
      ws.send(message);
    }
  }
}
