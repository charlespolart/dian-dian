/**
 * End-to-end smoke test against a RUNNING backend (default http://localhost:3001).
 * Registers a throwaway user, exercises the data routes (including the new
 * bootstrap / stats / reorder endpoints and the month validation fix), then
 * deletes the account. Exits non-zero on the first failed assertion.
 *
 * Run: cd backend && npx tsx scripts/smoke.ts
 *      SMOKE_BASE=https://diandian.overridedev.com npx tsx scripts/smoke.ts
 */
import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';

const BASE = process.env.SMOKE_BASE ?? 'http://localhost:3001';
// The version this checkout would run; only compared against the server when
// the server IS this checkout (local dev, CI) — not when SMOKE_BASE points at prod.
const localVersion = (JSON.parse(readFileSync(new URL('../package.json', import.meta.url), 'utf8')) as { version: string }).version;
const email = `smoke-${Date.now()}@example.com`;
const password = 'smoke-password-123';
let access = '';
let refresh = '';

// eslint-disable-next-line @typescript-eslint/no-explicit-any
type Json = any;

async function call(method: string, path: string, body?: unknown, auth = true): Promise<{ status: number; json: Json }> {
  const res = await fetch(`${BASE}${path}`, {
    method,
    headers: {
      'Content-Type': 'application/json',
      ...(auth && access ? { Authorization: `Bearer ${access}` } : {}),
    },
    body: body === undefined ? undefined : JSON.stringify(body),
  });
  const text = await res.text();
  let json: Json = null;
  try { json = JSON.parse(text); } catch { /* non-JSON body */ }
  return { status: res.status, json };
}

async function main() {
  // --- health reports the running version (deploy-prod.sh waits on it) ----
  let r = await call('GET', '/api/health', undefined, false);
  assert.equal(r.status, 200);
  assert.equal(r.json.ok, true);
  assert.equal(typeof r.json.version, 'string', 'health reports a version');
  if (!process.env.SMOKE_BASE) assert.equal(r.json.version, localVersion, 'health version matches package.json');

  // --- register -----------------------------------------------------------
  r = await call('POST', '/api/auth/register', { email, password }, false);
  assert.equal(r.status, 201, `register: ${JSON.stringify(r.json)}`);
  access = r.json.accessToken; refresh = r.json.refreshToken;
  const userId: string = r.json.userId;
  assert.ok(userId, 'register returns userId');

  // --- refresh returns the profile (new) and still the tokens (legacy) ----
  r = await call('POST', '/api/auth/refresh', { refreshToken: refresh }, false);
  assert.equal(r.status, 200, `refresh: ${JSON.stringify(r.json)}`);
  assert.ok(r.json.accessToken && r.json.refreshToken, 'refresh returns a token pair');
  assert.equal(r.json.userId, userId, 'refresh returns userId');
  assert.equal(typeof r.json.premium, 'boolean', 'refresh returns premium');
  assert.equal(typeof r.json.vip, 'boolean', 'refresh returns vip');
  assert.equal(r.json.email, email, 'refresh returns email');
  access = r.json.accessToken; refresh = r.json.refreshToken;

  // --- no default page since 1.2.0: the app creates the first tracker -------
  r = await call('GET', '/api/pages');
  assert.equal(r.status, 200);
  assert.deepEqual(r.json, [], 'no default page at register');
  r = await call('GET', '/api/bootstrap');
  assert.equal(r.json.activated, false, 'activated: no cell yet');
  r = await call('POST', '/api/pages', { title: 'First', position: 0 });
  assert.equal(r.status, 201);
  const pageId: string = r.json.id;

  // --- second page + single-request reorder --------------------------------
  r = await call('POST', '/api/pages', { title: 'Second', position: 1 });
  assert.equal(r.status, 201);
  const page2: string = r.json.id;
  r = await call('PUT', '/api/pages/reorder', { ids: [page2, pageId] });
  assert.equal(r.status, 200, `reorder: ${JSON.stringify(r.json)}`);
  r = await call('GET', '/api/pages');
  assert.deepEqual(r.json.map((p: Json) => p.id), [page2, pageId], 'reorder applied');

  // --- December is saveable; invalid dates are rejected --------------------
  r = await call('PUT', `/api/cells/${pageId}`, { year: 2026, month: 12, day: 31, color: '#FF0000' });
  assert.equal(r.status, 200, `december: ${JSON.stringify(r.json)}`);
  assert.equal(typeof r.json.createdAt, 'string', 'cells carry createdAt (backend 1.2.0)');
  r = await call('PUT', `/api/cells/${pageId}`, { year: 2026, month: 2, day: 30, color: '#FF0000' });
  assert.equal(r.status, 400, 'feb 30 rejected');
  r = await call('PUT', `/api/cells/${pageId}`, { year: 2024, month: 2, day: 29, color: '#00FF00', comment: 'leap' });
  assert.equal(r.status, 200, 'leap day 2024 accepted');
  r = await call('PUT', `/api/cells/${pageId}`, { year: 2025, month: 2, day: 29, color: '#00FF00' });
  assert.equal(r.status, 400, 'feb 29 2025 rejected');
  r = await call('PUT', `/api/cells/${pageId}`, { year: 2026, month: 13, day: 1, color: '#FF0000' });
  assert.equal(r.status, 400, 'month 13 rejected');
  r = await call('PUT', `/api/cells/${pageId}`, { year: 2026, month: 0, day: 1, color: '#FF0000' });
  assert.equal(r.status, 400, 'month 0 rejected');
  r = await call('DELETE', `/api/cells/${pageId}`, { year: 2026, month: 12, day: 30 });
  assert.equal(r.status, 200, 'delete december (no-op) accepted');

  // --- legend ---------------------------------------------------------------
  r = await call('POST', `/api/legends/${pageId}`, { color: '#FF0000', label: 'Red', position: 0 });
  assert.equal(r.status, 201);

  // --- bootstrap --------------------------------------------------------------
  r = await call('GET', '/api/bootstrap?year=2026');
  assert.equal(r.status, 200, `bootstrap: ${JSON.stringify(r.json)}`);
  assert.equal(r.json.year, 2026);
  assert.equal(r.json.activated, true, 'activated once a cell exists');
  assert.deepEqual(r.json.pages.map((p: Json) => p.id), [page2, pageId], 'bootstrap pages in position order');
  assert.equal(r.json.pages[1].palette, null, 'palette parsed (null)');
  assert.deepEqual(r.json.cells[pageId], [[12, 31, '#FF0000']], 'compact cells for 2026');
  assert.deepEqual(r.json.cells[page2], [], 'empty page present in cells');
  assert.equal(r.json.legends[pageId].length, 1, 'legends grouped by page');
  assert.equal(r.json.legends[pageId][0].label, 'Red');
  assert.deepEqual(r.json.legends[page2], [], 'empty page present in legends');
  r = await call('GET', '/api/bootstrap?year=2024');
  assert.deepEqual(r.json.cells[pageId], [[2, 29, '#00FF00', 'leap']], 'comment as 4th element');
  r = await call('GET', '/api/bootstrap');
  assert.equal(r.json.year, new Date().getFullYear(), 'bootstrap defaults to the current year');
  r = await call('GET', '/api/bootstrap?year=abc');
  assert.equal(r.json.year, new Date().getFullYear(), 'bootstrap ignores a garbage year');

  // --- stats/days ---------------------------------------------------------
  r = await call('GET', '/api/stats/days');
  assert.equal(r.status, 200, `stats/days: ${JSON.stringify(r.json)}`);
  assert.deepEqual(
    [...r.json[pageId]].sort((a: number[], b: number[]) => a[0] - b[0]),
    [[2024, 2, 29], [2026, 12, 31]],
    'all-time dates per page',
  );

  // --- legacy endpoints unchanged ---------------------------------------
  r = await call('GET', `/api/cells/${pageId}?year=2026`);
  assert.equal(r.status, 200);
  assert.equal(r.json.length, 1);
  assert.equal(r.json[0].month, 12);
  assert.equal(r.json[0].pageId, pageId, 'legacy cell payload keeps pageId');
  r = await call('GET', `/api/legends/${pageId}`);
  assert.equal(r.json.length, 1);

  // --- landing forwards a campaign to the store links (Pinterest attribution) ---
  {
    const res = await fetch(`${BASE}/?utm_source=pinterest&utm_campaign=mood-en`);
    assert.equal(res.status, 200);
    const html = await res.text();
    assert.ok(html.includes('referrer=utm_source%3Dpinterest%26utm_campaign%3Dmood-en'), 'Play link carries the campaign referrer');
    const plain = await (await fetch(`${BASE}/`)).text();
    assert.ok(!plain.includes('referrer='), 'no referrer without a campaign');
  }

  // --- first tracker (app 1.4.0): page + legends in one transaction ---------
  // The account is free and already has 'First' and 'Second'.
  {
    r = await call('POST', '/api/pages', {
      title: 'Humeur',
      legends: [
        { color: '#FFEC99', label: 'Génial' }, { color: '#FFD43B', label: 'Super' },
        { color: '#8CE99A', label: 'Bien' }, { color: '#74C0FC', label: 'Bof' }, { color: '#E599F7', label: 'Mou' },
      ],
    });
    assert.equal(r.status, 201, `create with legends: ${JSON.stringify(r.json)}`);
    const mood: string = r.json.id;
    assert.equal(r.json.position, 0, 'position defaults to 0 when omitted');
    assert.deepEqual(
      r.json.legends.map((l: Json) => [l.label, l.position]),
      [['Génial', 0], ['Super', 1], ['Bien', 2], ['Bof', 3], ['Mou', 4]],
      'legends created in order',
    );
    assert.equal(r.json.replaced, null, 'nothing replaced');
    r = await call('GET', `/api/legends/${mood}`);
    assert.equal(r.json.length, 5, 'legends persisted');

    // --- free limit (backend 1.2.0): the server refuses a 4th tracker ------
    r = await call('POST', '/api/pages', { title: 'Fourth' });
    assert.equal(r.status, 403, `free limit: ${JSON.stringify(r.json)}`);

    // Replacing an empty page keeps the count, so it is allowed at the limit.
    r = await call('POST', '/api/pages', {
      title: 'Sommeil', replaces: page2, legends: [{ color: '#1864AB', label: '8 h+' }],
    });
    assert.equal(r.status, 201, `replace: ${JSON.stringify(r.json)}`);
    const sleep: string = r.json.id;
    assert.equal(r.json.replaced, page2, 'reports the replaced page');
    assert.equal(r.json.position, 0, 'takes the position of the replaced page');
    r = await call('GET', '/api/pages');
    const ids: string[] = r.json.map((p: Json) => p.id);
    assert.ok(!ids.includes(page2) && ids.includes(sleep), 'replaced page is gone, new one is there');
    assert.equal(ids.length, 3, 'still 3 trackers');

    r = await call('POST', '/api/pages', { title: 'Nope', replaces: mood });
    assert.equal(r.status, 409, 'a page with legends cannot be replaced');
    r = await call('POST', '/api/pages', { title: 'Nope', replaces: '00000000-0000-4000-8000-000000000000' });
    assert.equal(r.status, 404, 'an unknown page cannot be replaced');
    r = await call('POST', '/api/pages', {
      title: 'Nope', replaces: sleep, legends: Array.from({ length: 13 }, (_, i) => ({ color: '#000000', label: `L${i}` })),
    });
    assert.equal(r.status, 400, '13 legends rejected');
    r = await call('GET', '/api/pages');
    assert.equal(r.json.length, 3, 'refused creations wrote nothing');

    // --- which trackers stay open on a free account: the user's choice ------
    r = await call('PUT', '/api/pages/keep', { ids: [mood, sleep] });
    assert.equal(r.status, 200, `keep: ${JSON.stringify(r.json)}`);
    r = await call('GET', '/api/bootstrap?year=2026');
    const byId: Record<string, Json> = Object.fromEntries(r.json.pages.map((p: Json) => [p.id, p]));
    assert.equal(byId[mood].keepFree, true, 'kept');
    assert.equal(byId[sleep].keepFree, true, 'kept');
    assert.equal(byId[pageId].keepFree, false, 'not kept');
    assert.equal(byId[pageId].recentCells, 2, 'activity: cells touched in the last 90 days');
    assert.equal(typeof byId[pageId].lastCellAt, 'string', 'activity: last cell date');
    assert.equal(byId[mood].recentCells, 0, 'no cell → 0');
    assert.equal(byId[mood].lastCellAt, null, 'no cell → null');
    r = await call('PUT', '/api/pages/keep', { ids: [mood, sleep, pageId, '00000000-0000-4000-8000-000000000000'] });
    assert.equal(r.status, 400, 'at most 3 kept');
  }

  // --- events (roadmap #2: count the paywall gates) ------------------------
  r = await call('POST', '/api/events', { name: 'paywall.tracker_limit' });
  assert.equal(r.status, 204, `event: ${JSON.stringify(r.json)}`);
  r = await call('POST', '/api/events', { name: 'Bad Name!' });
  assert.equal(r.status, 400, 'event names are lower-case slugs');
  r = await call('POST', '/api/events', { name: 'paywall.tracker_limit' }, false);
  assert.equal(r.status, 401, 'events need a session');

  // --- cleanup --------------------------------------------------------------
  r = await call('DELETE', '/api/auth/account');
  assert.equal(r.status, 200);
  console.log('smoke: OK');
}

main().catch((err) => {
  console.error('smoke: FAILED');
  console.error(err);
  process.exit(1);
});
