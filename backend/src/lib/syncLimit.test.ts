/**
 * The sync routes are limited per account, not per address: many phones
 * share one address behind a mobile carrier's NAT, and a limit per address
 * would make all of them look offline once a few were busy.
 */
import assert from 'node:assert/strict';
import type { AddressInfo } from 'node:net';
import { test } from 'node:test';
import express from 'express';
import { syncLimiter } from './syncLimit.js';

test('one account over its budget is refused; another account from the same address is not', async () => {
  const app = express();
  app.use((req, _res, next) => { req.userId = req.header('x-user') ?? undefined; next(); }); // stands for requireAuth
  app.use(syncLimiter(3));
  app.get('/', (_req, res) => { res.json({ ok: true }); });
  const server = app.listen(0);
  try {
    const port = (server.address() as AddressInfo).port;
    const get = (user: string) => fetch(`http://127.0.0.1:${port}/`, { headers: { 'x-user': user } }).then((r) => r.status);
    assert.deepEqual([await get('u1'), await get('u1'), await get('u1')], [200, 200, 200]);
    assert.equal(await get('u1'), 429, 'the fourth of u1');
    assert.equal(await get('u2'), 200, 'u2, same address, has its own budget');
  } finally {
    server.close();
  }
});
