/**
 * End-to-end smoke test against a RUNNING backend (default http://localhost:3001).
 * Registers a throwaway user, exercises the data routes (including the new
 * bootstrap / stats / reorder endpoints and the month validation fix), then
 * deletes the account. Exits non-zero on the first failed assertion.
 *
 * Run: cd backend && npx tsx scripts/smoke.ts
 *      SMOKE_BASE=https://diandian.overridedev.com npx tsx scripts/smoke.ts
 *
 * The RevenueCat webhook checks post made-up purchase events, and read and
 * write the database directly. They only run when the server under test AND
 * the database of DATABASE_URL are on this machine (localhost), and after
 * checking that this database is the server's; against anything else they
 * are skipped. They need the server's REVENUECAT_WEBHOOK_SECRET in this
 * process too:
 *      REVENUECAT_WEBHOOK_SECRET=local-smoke npm run dev
 *      REVENUECAT_WEBHOOK_SECRET=local-smoke npx tsx scripts/smoke.ts
 */
import 'dotenv/config';
import assert from 'node:assert/strict';
import { createHash, randomBytes, randomUUID } from 'node:crypto';
import { readFileSync } from 'node:fs';
import postgres from 'postgres';
import WebSocket from 'ws';
import { envFlag } from '../src/lib/envFlag.js';
import { isLoopbackDatabase, isLoopbackUrl } from '../src/lib/loopback.js';

const BASE = process.env.SMOKE_BASE ?? 'http://localhost:3001';
// What no route shows (the raw purchase events, the columns of a product
// event) is read straight from the database, and made-up purchases are
// posted to the webhook: only when the server and the database are both on
// this machine. Decided from where they are, not from which variables are
// set: a production address in SMOKE_BASE or in DATABASE_URL turns it off.
const local = isLoopbackUrl(BASE) && isLoopbackDatabase(process.env.DATABASE_URL);
const sql = local ? postgres(process.env.DATABASE_URL!, { max: 1 }) : null;
const webhookSecret = local ? process.env.REVENUECAT_WEBHOOK_SECRET : undefined;
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

/** Posts one RevenueCat event to the webhook; `authorization: null` sends none. */
async function webhook(event: Record<string, unknown>, authorization: string | null = webhookSecret ?? null): Promise<number> {
  const res = await fetch(`${BASE}/api/purchase/webhook`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json', ...(authorization ? { Authorization: authorization } : {}) },
    body: JSON.stringify({ api_version: '1.0', event }),
  });
  return res.status;
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
  if (sql) {
    // The database read below must be the one the server writes to.
    const [registered] = await sql`select 1 from users where id = ${userId}`;
    assert.ok(registered, 'DATABASE_URL is not the database of the server under test: the account just registered is not in it');
  }

  // --- refresh returns the profile (new) and still the tokens (legacy) ----
  r = await call('POST', '/api/auth/refresh', { refreshToken: refresh }, false);
  assert.equal(r.status, 200, `refresh: ${JSON.stringify(r.json)}`);
  assert.ok(r.json.accessToken && r.json.refreshToken, 'refresh returns a token pair');
  assert.equal(r.json.userId, userId, 'refresh returns userId');
  assert.equal(typeof r.json.premium, 'boolean', 'refresh returns premium');
  assert.equal(typeof r.json.vip, 'boolean', 'refresh returns vip');
  assert.equal(r.json.email, email, 'refresh returns email');
  access = r.json.accessToken; refresh = r.json.refreshToken;

  // --- a session lasts (chantier 10): 18 months, renewed at each use; a ---
  // --- renewal survives a lost answer; a refusal says why -------------------
  {
    const renew = (token: string) => call('POST', '/api/auth/refresh', { refreshToken: token }, false);
    if (sql) {
      const [t] = await sql`select extract(epoch from expires_at - now())::int as left from refresh_tokens where user_id = ${userId} order by created_at desc limit 1`;
      assert.ok(Math.abs(t.left - 548 * 24 * 3600) < 120, `a session lasts 548 days (${t.left} s left)`);
    }
    const r1 = refresh;
    const lost = await renew(r1); // its answer is lost on the way
    assert.equal(lost.status, 200);
    const again = await renew(r1); // the phone tries again with the token it still has
    assert.equal(again.status, 200, `a renewal whose answer was lost can be made again: ${JSON.stringify(again.json)}`);
    assert.notEqual(again.json.refreshToken, lost.json.refreshToken, 'with a new token');
    const unused = await renew(lost.json.refreshToken);
    assert.equal(unused.status, 401, 'the token that never arrived no longer works');
    const r3 = again.json.refreshToken;
    const used = await renew(r3);
    assert.equal(used.status, 200, 'the new one works');
    const stale = await renew(r1);
    assert.equal(stale.status, 401, 'once its successor has served, the old token is refused');
    assert.equal(stale.json.code, 'invalid', '"invalid", never "session_revoked", which means logged out from another device');
    const garbage = await renew('not-a-token');
    assert.equal(garbage.json.code, 'invalid');
    access = used.json.accessToken; refresh = used.json.refreshToken;
  }

  // --- a session has an id, carried by its access tokens and checked at ----
  // --- every request (chantier 9, lot 1) -------------------------------------
  {
    const sidOf = (jwt: string) => JSON.parse(Buffer.from(jwt.split('.')[1], 'base64url').toString()).sid as string | undefined;
    const sid = sidOf(access);
    assert.match(sid ?? '', /^[0-9a-f-]{36}$/, 'the access token names its session');
    const renewed = await call('POST', '/api/auth/refresh', { refreshToken: refresh }, false);
    assert.equal(sidOf(renewed.json.accessToken), sid, 'a renewal keeps the session');
    access = renewed.json.accessToken; refresh = renewed.json.refreshToken;
    if (sql) {
      const [{ n }] = await sql`select count(*)::int as n from sessions where id = ${sid}`;
      assert.equal(n, 1, 'one row per session');
    }

    // Logging out closes the whole session: a token left before it (its
    // successor never served) no longer renews anything.
    const other = await call('POST', '/api/auth/login', { email, password }, false);
    const before = other.json.refreshToken as string;
    const after = await call('POST', '/api/auth/refresh', { refreshToken: before }, false);
    const out = await fetch(`${BASE}/api/auth/logout`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json', Authorization: `Bearer ${after.json.accessToken}` },
      body: JSON.stringify({ refreshToken: after.json.refreshToken }),
    });
    assert.equal(out.status, 200);
    const left = await call('POST', '/api/auth/refresh', { refreshToken: before }, false);
    assert.equal(left.status, 401, 'the token before the logout renews nothing');
    const gone = await fetch(`${BASE}/api/auth/me`, { headers: { Authorization: `Bearer ${after.json.accessToken}` } });
    assert.equal(gone.status, 401, 'and its access token no longer opens anything, though it has not expired');

    if (sql && process.env.JWT_SECRET) {
      // An access token without a session id (issued before the update) is
      // still accepted until it expires (15 minutes).
      const { SignJWT } = await import('jose');
      const legacy = await new SignJWT({ sub: userId }).setProtectedHeader({ alg: 'HS256' }).setIssuedAt().setExpirationTime('15m')
        .sign(new TextEncoder().encode(process.env.JWT_SECRET));
      const me = await fetch(`${BASE}/api/auth/me`, { headers: { Authorization: `Bearer ${legacy}` } });
      assert.equal(me.status, 200, 'a token without a session id still works');
    }
  }

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

  // --- version numbers (chantier 10): every write of today's routes takes a ---
  // --- number from the account's counter; every deletion leaves a trace -----
  // Today's routes are what apps 1.4.0 use: their writes must count as
  // changes for the offline rule ("the server wins").
  if (sql) {
    const userRev = async () => (await sql`select rev::int as rev from users where id = ${userId}`)[0].rev as number;
    const userCols = async () => (await sql`
      select rev::int, pages_order_rev::int, keep_free_rev::int, theme_rev::int, language_rev::int, cursor_rev::int
      from users where id = ${userId}`)[0];
    const pageCols = async (id: string) => (await sql`
      select rev::int, edit_rev::int, content_rev::int, legends_order_rev::int from pages where id = ${id}`)[0];
    const cellCols = async (id: string, y: number, m: number, d: number) => (await sql`
      select rev::int, edit_rev::int from cells where page_id = ${id} and year = ${y} and month = ${m} and day = ${d}`)[0];
    const legendCols = async (id: string) => (await sql`select rev::int, edit_rev::int from legends where id = ${id}`)[0];
    const trace = async (kind: string, key: string) => (await sql`
      select page_id, rev::int from deletions where user_id = ${userId} and kind = ${kind} and key = ${key}`)[0];

    // A tracker of its own, removed at the end: the rest of the suite keeps its two.
    let before = await userRev();
    r = await call('POST', '/api/pages', { title: 'Revs', position: 2, legends: [{ color: '#123456', label: 'L0' }] });
    assert.equal(r.status, 201, `revs page: ${JSON.stringify(r.json)}`);
    const revPage: string = r.json.id;
    const firstLegend: string = r.json.legends[0].id;
    let now = await userRev();
    assert.equal(now, before + 1, 'creating a tracker takes one number');
    assert.deepEqual(await pageCols(revPage), { rev: now, edit_rev: now, content_rev: now, legends_order_rev: 0 }, 'a new tracker carries its number');
    assert.deepEqual(await legendCols(firstLegend), { rev: now, edit_rev: now }, 'and so do the legends created with it');

    before = now;
    r = await call('PUT', `/api/cells/${revPage}`, { year: 2026, month: 3, day: 1, color: '#123456', comment: 'x' });
    assert.equal(r.status, 200);
    now = await userRev();
    assert.equal(now, before + 1, 'colouring a day takes one number');
    assert.deepEqual(await cellCols(revPage, 2026, 3, 1), { rev: now, edit_rev: now }, 'the day carries it');
    assert.equal((await pageCols(revPage)).content_rev, now, 'and so does the content of its tracker');
    assert.equal((await pageCols(revPage)).rev, now, 'the tracker row changed (its content number)');
    assert.equal((await pageCols(revPage)).edit_rev, before, 'but its own edit number did not');

    r = await call('DELETE', `/api/cells/${revPage}`, { year: 2026, month: 3, day: 1 });
    now = await userRev();
    assert.deepEqual(await trace('cell', `${revPage}:2026-03-01`), { page_id: revPage, rev: now }, 'clearing a day leaves a trace');
    assert.equal((await pageCols(revPage)).content_rev, now);

    r = await call('PUT', `/api/cells/${revPage}`, { year: 2026, month: 3, day: 2, color: '#123456' });
    r = await call('PUT', `/api/cells/${revPage}`, { year: 2025, month: 1, day: 1, color: '#123456' });
    r = await call('PATCH', `/api/cells/${revPage}/recolor`, { colorMap: { '#123456': '#654321' } });
    now = await userRev();
    assert.deepEqual(await cellCols(revPage, 2026, 3, 2), { rev: now, edit_rev: now }, 'an old app\'s mass recolour counts as an edit of each day');
    assert.deepEqual(await cellCols(revPage, 2025, 1, 1), { rev: now, edit_rev: now }, 'in every year');

    r = await call('DELETE', `/api/cells/${revPage}/all`, { year: 2025 });
    now = await userRev();
    assert.deepEqual(await trace('cell', `${revPage}:2025-01-01`), { page_id: revPage, rev: now }, 'resetting a year leaves a trace per day');

    r = await call('POST', `/api/legends/${revPage}`, { color: '#ABCDEF', label: 'L1', position: 1 });
    const secondLegend: string = r.json.id;
    now = await userRev();
    assert.deepEqual(await legendCols(secondLegend), { rev: now, edit_rev: now }, 'a new legend carries its number');
    assert.equal((await pageCols(revPage)).content_rev, now);
    r = await call('PATCH', `/api/legends/${secondLegend}`, { label: 'L1b' });
    now = await userRev();
    assert.deepEqual(await legendCols(secondLegend), { rev: now, edit_rev: now }, 'renaming a legend is an edit');
    r = await call('PUT', `/api/legends/${revPage}/reorder`, { ids: [secondLegend, firstLegend] });
    now = await userRev();
    assert.equal((await pageCols(revPage)).legends_order_rev, now, 'reordering the legends numbers their order');
    assert.equal((await pageCols(revPage)).content_rev, now);
    r = await call('PATCH', `/api/legends/${revPage}/recolor`, { colorMap: { '#ABCDEF': '#FEDCBA' } });
    now = await userRev();
    assert.deepEqual(await legendCols(secondLegend), { rev: now, edit_rev: now }, 'an old app\'s legend recolour is an edit');
    r = await call('DELETE', `/api/legends/${secondLegend}`);
    now = await userRev();
    assert.deepEqual(await trace('legend', secondLegend), { page_id: revPage, rev: now }, 'deleting a legend leaves a trace');
    assert.equal((await pageCols(revPage)).content_rev, now);

    r = await call('PATCH', `/api/pages/${revPage}`, { title: 'Revs 2' });
    now = await userRev();
    assert.deepEqual(await pageCols(revPage), { rev: now, edit_rev: now, content_rev: now, legends_order_rev: (await pageCols(revPage)).legends_order_rev }, 'renaming a tracker is an edit of it and of its content');
    r = await call('PATCH', `/api/pages/${revPage}`, { position: 2 });
    now = await userRev();
    assert.equal((await userCols()).pages_order_rev, now, 'a position sent by an app before 1.3.0 numbers the order');
    r = await call('PUT', '/api/pages/reorder', { ids: [page2, pageId, revPage] });
    now = await userRev();
    assert.equal((await userCols()).pages_order_rev, now, 'reordering the trackers numbers their order');
    r = await call('PUT', '/api/pages/keep', { ids: [] });
    now = await userRev();
    assert.equal((await userCols()).keep_free_rev, now, 'choosing the open trackers numbers that choice');
    r = await call('PATCH', '/api/auth/settings', { theme: 'defaultTheme' });
    now = await userRev();
    assert.equal((await userCols()).theme_rev, now, 'each setting has its number: theme');
    r = await call('PATCH', '/api/auth/settings', { language: null });
    now = await userRev();
    assert.equal((await userCols()).language_rev, now, 'language');
    r = await call('PATCH', '/api/auth/settings', { cursorEnabled: false });
    now = await userRev();
    assert.equal((await userCols()).cursor_rev, now, 'cursor');

    r = await call('DELETE', `/api/pages/${revPage}`);
    assert.equal(r.status, 200);
    now = await userRev();
    assert.deepEqual(await trace('page', revPage), { page_id: revPage, rev: now }, 'deleting a tracker leaves a trace');
    await sql`delete from deletions where user_id = ${userId}`;
  }

  // --- offline sync (chantier 10): changes sent by a phone, judged one by ---
  // --- one, never applied twice; what changed since a number -----------------
  {
    const uuid = () => randomUUID();
    const send = async (mutations: Json[]) => {
      const res = await call('POST', '/api/sync/mutations', { mutations });
      assert.equal(res.status, 200, `sync/mutations: ${JSON.stringify(res.json)}`);
      return res.json as { results: Json[]; rev: number };
    };
    const mut = (kind: string, data: Json, more: Json = {}) => ({ id: uuid(), kind, waited: false, base: null, data, ...more });
    const pull = async (since: number) => {
      const res = await call('GET', `/api/sync?since=${since}`);
      assert.equal(res.status, 200, `sync: ${JSON.stringify(res.json)}`);
      return res.json;
    };

    // The full copy: every tracker, legend and day of every year.
    const full = await pull(0);
    assert.equal(full.full, true, 'since=0 is the full copy');
    assert.ok(full.pages.some((p: Json) => p.id === pageId), 'with the trackers');
    assert.ok(Array.isArray(full.cells[pageId]) && full.cells[pageId].some((c: Json[]) => c[0] === 2024), 'and the days of every year');
    assert.equal(typeof full.rev, 'number');
    assert.deepEqual(full.pagesOrder?.ids?.slice(0, 2), [page2, pageId], 'the order of the trackers');

    // One change, sent twice (its answer lost): applied once.
    const day = mut('cell.set', { pageId, year: 2026, month: 4, day: 1, color: '#2B8A3E', comment: 'run' }, { base: 0 });
    const first = await send([day]);
    assert.equal(first.results[0].status, 'applied');
    const dayRev: number = first.results[0].revs.element;
    const again = await send([day]);
    assert.deepEqual(again.results, first.results, 'sent again, the same answer');
    assert.equal(again.rev, first.rev, 'and nothing applied twice');

    // What changed since a number: that day alone.
    const delta = await pull(dayRev - 1);
    assert.equal(delta.full, false);
    assert.deepEqual(delta.cells[pageId].map((c: Json[]) => c.slice(0, 7)), [[2026, 4, 1, '#2B8A3E', 'run', dayRev, dayRev]], 'the day, with its numbers');
    assert.ok(Math.abs(delta.cells[pageId][0][7] - Date.now()) < 60_000, 'and when it last changed (ms)');
    assert.deepEqual((await pull(dayRev)).cells, {}, 'nothing after it');
    assert.equal((await pull(dayRev + 1_000_000)).full, true, 'a phone ahead of the server (a restored database) takes the full copy');

    // The offline rule: a change that waited loses to one made elsewhere meanwhile (H17).
    const stale = await send([mut('cell.set', { pageId, year: 2026, month: 4, day: 1, color: '#C92A2A', comment: null }, { waited: true, base: 0 })]);
    assert.equal(stale.results[0].status, 'changed', 'set aside');
    assert.deepEqual(stale.results[0].current, { color: '#2B8A3E', comment: 'run' }, 'with what the server keeps');
    const fresh = await send([mut('cell.set', { pageId, year: 2026, month: 4, day: 1, color: '#C92A2A', comment: null }, { waited: true, base: dayRev })]);
    assert.equal(fresh.results[0].status, 'applied', 'a change that knew the latest version is applied');
    const online = await send([mut('cell.set', { pageId, year: 2026, month: 4, day: 1, color: '#1864AB', comment: null }, { base: 1 })]);
    // A day coloured then cleared elsewhere is empty again: a phone that never
    // saw it (no number) colours it offline without a conflict.
    await send([mut('cell.set', { pageId, year: 2026, month: 4, day: 9, color: '#000000' }), mut('cell.clear', { pageId, year: 2026, month: 4, day: 9 })]);
    const neverSeen = await send([mut('cell.set', { pageId, year: 2026, month: 4, day: 9, color: '#2B8A3E' }, { waited: true, base: null })]);
    assert.equal(neverSeen.results[0].status, 'applied', 'never seen, empty now: no conflict');
    await send([mut('cell.clear', { pageId, year: 2026, month: 4, day: 9 })]);
    if (sql) {
      // A day written before the numbers (edit number 0), cleared elsewhere
      // since: a phone that saw it with 0 and changed it offline is set aside (I2).
      await sql`insert into cells (page_id, year, month, day, color, rev, edit_rev) values (${pageId}, 2026, 4, 20, '#000000', 0, 0)`;
      await send([mut('cell.clear', { pageId, year: 2026, month: 4, day: 20 })]);
      const sawZero = await send([mut('cell.set', { pageId, year: 2026, month: 4, day: 20, color: '#2B8A3E' }, { waited: true, base: 0 })]);
      assert.equal(sawZero.results[0].status, 'changed', 'the clear made elsewhere is not undone');
    }
    assert.equal(online.results[0].status, 'applied', 'a change that did not wait: the last writer wins (H27)');

    // A tracker created by the phone, with its legend and a day; a recolour
    // of the legend leaves its days unedited (H29).
    const trackerId = uuid();
    const legendId = uuid();
    const created = await send([
      mut('page.create', { id: trackerId, title: 'Offline', legends: [{ id: legendId, color: '#495057', label: 'Done' }] }, { waited: true }),
      mut('cell.set', { pageId: trackerId, year: 2026, month: 5, day: 2, color: '#495057' }, { waited: true, base: 0 }),
    ]);
    assert.deepEqual(created.results.map((x: Json) => x.status), ['applied', 'applied'], 'a tracker created offline, then a day in it');
    const legendBase: number = created.results[0].revs.element;
    const dayInIt: number = created.results[1].revs.element;
    const recolour = await send([mut('legend.update', { id: legendId, color: '#F08C00' }, { waited: true, base: legendBase })]);
    assert.equal(recolour.results[0].status, 'applied');
    if (sql) {
      const [c] = await sql`select color, rev::int, edit_rev::int from cells where page_id = ${trackerId} and year = 2026 and month = 5 and day = 2`;
      assert.deepEqual(c, { color: '#F08C00', rev: recolour.rev, edit_rev: dayInIt }, 'the day took the colour without being edited');
    }
    const commentAfter = await send([mut('cell.set', { pageId: trackerId, year: 2026, month: 5, day: 2, color: '#F08C00', comment: 'kept' }, { waited: true, base: dayInIt })]);
    assert.equal(commentAfter.results[0].status, 'applied', 'a change made offline on that day is kept (H29)');

    // A deletion that waited compares the whole tracker (H21).
    const [contentBefore] = [created.results[0].revs.content as number];
    const staleDelete = await send([mut('page.delete', { id: trackerId }, { waited: true, base: contentBefore })]);
    assert.equal(staleDelete.results[0].status, 'changed', 'not deleted: something in it changed since');
    const now = (await pull(0)).pages.find((x: Json) => x.id === trackerId);
    const deleted = await send([mut('page.delete', { id: trackerId }, { waited: true, base: now.contentRev })]);
    assert.equal(deleted.results[0].status, 'applied');
    const afterDelete = await send([
      mut('cell.set', { pageId: trackerId, year: 2026, month: 5, day: 3, color: '#F08C00' }, { waited: true, base: 0 }),
      mut('page.create', { id: trackerId, title: 'Back' }, { waited: true }),
    ]);
    assert.deepEqual(afterDelete.results.map((x: Json) => x.status), ['deleted', 'deleted'], 'nothing is written into a deleted tracker, and it does not come back (H20)');
    // Deleting what is already gone, or clearing a day already cleared
    // elsewhere, is what was asked: applied, nothing to tell (minor 7).
    const again2 = await send([mut('page.delete', { id: trackerId }, { waited: true, base: 1 })]);
    assert.equal(again2.results[0].status, 'applied', 'a tracker already deleted');
    await send([mut('cell.set', { pageId, year: 2026, month: 4, day: 21, color: '#000000' })]);
    const seenAt = (await pull(0)).cells[pageId].find((c: Json[]) => c[0] === 2026 && c[1] === 4 && c[2] === 21)[6];
    await send([mut('cell.clear', { pageId, year: 2026, month: 4, day: 21 })]);
    const clearAgain = await send([mut('cell.clear', { pageId, year: 2026, month: 4, day: 21 }, { waited: true, base: seenAt })]);
    assert.equal(clearAgain.results[0].status, 'applied', 'a day already cleared elsewhere');
    const traces = await pull(deleted.rev - 1);
    assert.ok(traces.deletions.some((t: Json) => t.kind === 'page' && t.key === trackerId), 'the deletion reaches the other phones');

    // A 13th legend is refused (H12); an order keeps what it does not list; a setting.
    const legendsTracker = uuid();
    await send([mut('page.create', { id: legendsTracker, title: 'Legends' }, { waited: true })]);
    const twelve = await send(Array.from({ length: 13 }, (_, i) => mut('legend.create', { id: uuid(), pageId: legendsTracker, color: '#000000', label: `L${i}` }, { waited: true })));
    assert.equal(twelve.results.filter((x: Json) => x.status === 'applied').length, 12);
    assert.deepEqual(twelve.results[12], { id: twelve.results[12].id, status: 'rejected', reason: 'legend_limit' }, 'the 13th legend is refused');
    const order = await send([mut('pages.reorder', { ids: [legendsTracker] })]);
    assert.equal(order.results[0].status, 'applied');
    const ids = (await pull(0)).pagesOrder.ids;
    assert.equal(ids[0], legendsTracker, 'the listed tracker first');
    assert.ok(ids.includes(pageId) && ids.includes(page2), 'the others kept');
    const theme = await send([mut('setting.set', { key: 'theme', value: 'defaultTheme' }, { waited: true, base: 0 })]);
    assert.equal(theme.results[0].status, 'changed', 'a setting changed since (the revs block set the theme) wins over one that waited');
    assert.equal((await send([{ id: 'nope', kind: 'cell.set', waited: false, base: 0, data: {} }])).results[0].status, 'rejected', 'a change that cannot be read is refused');
    await send([mut('page.delete', { id: legendsTracker })]);
    // The rest of the suite expects this order, and no extra day on the first tracker.
    await send([mut('pages.reorder', { ids: [page2, pageId] }), mut('cell.clear', { pageId, year: 2026, month: 4, day: 1 })]);
  }

  // --- the invisible account (chantier 9, lot 1, task 3) ---------------------
  {
    // Its own address for the creation limit, so that reruns of this suite
    // against one dev server do not meet it (trust proxy reads X-Forwarded-For).
    const net = `10.${Math.floor(Math.random() * 250)}.${Math.floor(Math.random() * 250)}.${Math.floor(Math.random() * 250)}`;
    const post = (path: string, body: unknown, from = net) => fetch(`${BASE}${path}`, {
      method: 'POST', headers: { 'Content-Type': 'application/json', 'X-Forwarded-For': from }, body: JSON.stringify(body),
    }).then(async (res) => ({ status: res.status, json: await res.json() as Json }));
    const id = randomUUID();
    const key = randomBytes(32).toString('base64url');
    const made = await post('/api/auth/invisible', { id, key });
    assert.equal(made.status, 201, `invisible: ${JSON.stringify(made.json)}`);
    assert.equal(made.json.userId, id, 'under the id the phone chose');
    assert.deepEqual([made.json.kind, made.json.methods, made.json.email], ['invisible', [], null], 'the server says what it is');
    const replay = await post('/api/auth/invisible', { id, key });
    assert.equal(replay.status, 200, 'the same request again (its answer lost): a session, no second account');
    assert.equal((await post('/api/auth/invisible', { id, key: randomBytes(32).toString('base64url') })).json.code, 'taken', 'another key on that id: refused');
    assert.equal((await post('/api/auth/invisible', { id: randomUUID(), key: 'short' })).status, 400, 'a key that is not 32 bytes');
    const reopened = await post('/api/auth/key', { id, key });
    assert.equal(reopened.status, 200, 'the key reopens a session');
    assert.equal(reopened.json.kind, 'invisible');
    assert.equal((await post('/api/auth/key', { id, key: randomBytes(32).toString('base64url') })).json.code, 'invalid');
    assert.equal((await post('/api/auth/key', { id: randomUUID(), key })).json.code, 'unknown', 'an id the server never had: the phone keeps its copy');
    const as = (token: string, method: string, path: string, body?: unknown) => fetch(`${BASE}${path}`, {
      method, headers: { 'Content-Type': 'application/json', Authorization: `Bearer ${token}` }, body: body === undefined ? undefined : JSON.stringify(body),
    });
    const tracker = randomUUID();
    const sent = await as(reopened.json.accessToken, 'POST', '/api/sync/mutations', {
      mutations: [{ id: randomUUID(), kind: 'page.create', waited: true, base: null, data: { id: tracker, title: 'Sans compte' } }],
    });
    assert.equal(sent.status, 200, 'it syncs like any account');
    const me = await (await as(reopened.json.accessToken, 'GET', '/api/auth/me')).json();
    assert.deepEqual([me.kind, me.methods, me.email], ['invisible', [], null]);
    if (sql) {
      const [u] = await sql`select extract(epoch from now() - last_seen_at)::int as ago from users where id = ${id}`;
      assert.ok(u.ago < 60, 'its last contact is known');
    }
    assert.equal((await as(reopened.json.accessToken, 'DELETE', '/api/auth/account')).status, 200, '« Supprimer mes données »');
    assert.equal((await post('/api/auth/key', { id, key })).json.code, 'account_deleted', 'the key no longer opens anything, and says why');
    assert.equal((await post('/api/auth/invisible', { id, key })).json.code, 'account_deleted', 'nor brings the account back');

    // Too many accounts from one network: refused (the app keeps writing on the phone and tries later, case 6).
    const crowd = `10.251.${Math.floor(Math.random() * 250)}.${Math.floor(Math.random() * 250)}`;
    const limit = Number(process.env.INVISIBLE_PER_HOUR ?? 30);
    const madeHere: { id: string; key: string; token: string }[] = [];
    for (let i = 0; i < limit; i++) {
      const one = { id: randomUUID(), key: randomBytes(32).toString('base64url') };
      const r = await post('/api/auth/invisible', one, crowd);
      assert.equal(r.status, 201);
      madeHere.push({ ...one, token: r.json.accessToken });
    }
    assert.equal((await post('/api/auth/invisible', { id: randomUUID(), key: randomBytes(32).toString('base64url') }, crowd)).status, 429);
    for (const one of madeHere) await as(one.token, 'DELETE', '/api/auth/account');
  }

  // --- closing sessions, and saying why (chantier 9, lot 1, task 2) --------
  {
    const mail = `smoke-sessions-${Date.now()}@example.com`;
    const a = (await call('POST', '/api/auth/register', { email: mail, password }, false)).json;
    const b = (await call('POST', '/api/auth/login', { email: mail, password }, false)).json;
    const c = (await call('POST', '/api/auth/login', { email: mail, password }, false)).json;
    const as = (token: string, method: string, path: string, body?: unknown) => fetch(`${BASE}${path}`, {
      method, headers: { 'Content-Type': 'application/json', Authorization: `Bearer ${token}` }, body: body === undefined ? undefined : JSON.stringify(body),
    });
    const socket = new WebSocket(`${BASE.replace(/^http/, 'ws')}/ws`);
    const heard: { event: string; data: Json }[] = [];
    let socketClosed = false;
    await new Promise<void>((resolve, reject) => {
      socket.on('open', () => socket.send(JSON.stringify({ type: 'auth', token: b.accessToken })));
      socket.on('message', (raw) => {
        const m = JSON.parse(String(raw)) as { event: string; data: Json };
        heard.push(m);
        if (m.event === 'auth:ok') resolve();
      });
      socket.on('close', () => { socketClosed = true; });
      socket.on('error', reject);
    });

    const closed = await as(a.accessToken, 'POST', '/api/auth/sessions/close-others');
    assert.equal(closed.status, 200, '« Déconnecter mes autres appareils »');
    assert.equal((await closed.json()).closed, 2);
    const meB = await as(b.accessToken, 'GET', '/api/auth/me');
    assert.equal(meB.status, 401, 'the other phone stops at its next request');
    assert.equal((await meB.json()).code, 'session_revoked');
    const renewB = await call('POST', '/api/auth/refresh', { refreshToken: b.refreshToken }, false);
    assert.equal(renewB.json.code, 'session_revoked', 'and its renewal says the same');
    for (let i = 0; i < 40 && !socketClosed; i++) await new Promise((r) => setTimeout(r, 25));
    assert.deepEqual(heard.find((m) => m.event === 'session:ended')?.data, { code: 'session_revoked' }, 'its live channel is told');
    assert.ok(socketClosed, 'then closed');
    assert.equal((await as(a.accessToken, 'GET', '/api/auth/me')).status, 200, 'the phone that asked stays signed in');
    // A live channel opened afterwards with the closed session's token is
    // told why too, instead of being closed without a word (the app would
    // otherwise reconnect every 3 seconds).
    const late = await new Promise<{ event: string; data: Json } | null>((resolve) => {
      const ws = new WebSocket(`${BASE.replace(/^http/, 'ws')}/ws`);
      ws.on('open', () => ws.send(JSON.stringify({ type: 'auth', token: b.accessToken })));
      ws.on('message', (raw) => resolve(JSON.parse(String(raw))));
      ws.on('close', () => resolve(null));
    });
    assert.deepEqual(late, { event: 'session:ended', data: { code: 'session_revoked' } });
    assert.equal((await as(c.accessToken, 'GET', '/api/auth/me')).status, 401);

    if (sql) {
      // A password changed by « mot de passe oublié » closes every session (case 51).
      const [{ id }] = await sql`select id from users where email = ${mail}`;
      await sql`insert into password_reset_tokens (user_id, token_hash, expires_at) values (${id}, ${createHash('sha256').update('123456').digest('hex')}, ${new Date(Date.now() + 600_000)})`;
      const reset = await call('POST', '/api/auth/reset-password', { email: mail, code: '123456', password }, false);
      assert.equal(reset.status, 200, `reset: ${JSON.stringify(reset.json)}`);
      const meA = await as(a.accessToken, 'GET', '/api/auth/me');
      assert.equal((await meA.json()).code, 'password_changed', 'every session ends, saying the password changed');
      const renewA = await call('POST', '/api/auth/refresh', { refreshToken: a.refreshToken }, false);
      assert.equal(renewA.json.code, 'password_changed');
    }
    const again = (await call('POST', '/api/auth/login', { email: mail, password }, false)).json;
    assert.equal((await as(again.accessToken, 'DELETE', '/api/auth/account')).status, 200);
  }

  // --- every change tells the account's other phones: `sync` (I1) ---------
  {
    const socket = new WebSocket(`${BASE.replace(/^http/, 'ws')}/ws`);
    const received: string[] = [];
    await new Promise<void>((resolve, reject) => {
      socket.on('open', () => socket.send(JSON.stringify({ type: 'auth', token: access })));
      socket.on('message', (raw) => {
        const { event } = JSON.parse(String(raw)) as { event: string };
        if (event === 'auth:ok') resolve();
        received.push(event);
      });
      socket.on('error', reject);
    });
    const syncAfter = async (what: string, write: () => Promise<unknown>) => {
      received.length = 0;
      await write();
      for (let i = 0; i < 40 && !received.includes('sync'); i++) await new Promise((r) => setTimeout(r, 25));
      assert.ok(received.includes('sync'), `${what} tells the other phones (sync)`);
    };
    await syncAfter('a day written by app 1.4.0', () => call('PUT', `/api/cells/${pageId}`, { year: 2026, month: 6, day: 6, color: '#123456' }));
    await syncAfter('a day erased by app 1.4.0', () => call('DELETE', `/api/cells/${pageId}`, { year: 2026, month: 6, day: 6 }));
    await syncAfter('a tracker renamed by app 1.4.0', () => call('PATCH', `/api/pages/${pageId}`, { title: 'Renamed' }));
    await syncAfter('a setting changed by app 1.4.0', () => call('PATCH', '/api/auth/settings', { theme: 'defaultTheme' }));
    await syncAfter('a setting sent by a phone', () => call('POST', '/api/sync/mutations', {
      mutations: [{ id: randomUUID(), kind: 'setting.set', waited: false, base: null, data: { key: 'language', value: 'en' } }],
    }));
    socket.close();
  }

  // --- the site: store buttons go through /go/*, unknown paths are 404 -------
  {
    const IPHONE = 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_6 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/18.6 Mobile/15E148 Safari/604.1';
    const ANDROID = 'Mozilla/5.0 (Linux; Android 15; Pixel 8) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/138.0.0.0 Mobile Safari/537.36';
    // The suite is not a visitor: `DNT: 1` keeps these requests out of the
    // audience counter, on the production site too.
    const site = (path: string, headers: Record<string, string> = {}) => fetch(`${BASE}${path}`, { redirect: 'manual', headers: { dnt: '1', ...headers } });

    const res = await site('/?utm_source=pinterest&utm_campaign=mood-en');
    assert.equal(res.status, 200);
    assert.equal(res.headers.get('referrer-policy'), 'no-referrer', 'a link followed from the page does not say which page the visitor was on');
    const html = await res.text();
    assert.ok(html.includes('href="/go/play?lang=en&amp;utm_source=pinterest&amp;utm_campaign=mood-en"'), 'the Play button carries the page language and the campaign');
    assert.ok(html.includes('href="/go/apple?lang=en&amp;utm_source=pinterest&amp;utm_campaign=mood-en"'), 'the App Store button carries the page language and the campaign');
    assert.ok(!html.includes('apps.apple.com') && !html.includes('play.google.com'), 'the page links to the stores through the site only');
    const plain = await (await site('/')).text();
    assert.ok(plain.includes('href="/go/apple?lang=en"') && plain.includes('href="/go/play?lang=en"'), 'an unknown device sees both stores, without a campaign');
    const buttons = plain.match(/<a class="btn-store"[^>]*>/g) ?? [];
    assert.ok(buttons.length >= 2 && buttons.every((a) => a.includes('referrerpolicy="strict-origin-when-cross-origin"')), 'only the store buttons tell the store where the visitor comes from');
    assert.ok(buttons.every((a) => !a.includes('target=')), 'a store button opens in place: a new tab that only redirects would stay behind, empty');
    assert.ok((await (await site('/?lang=fr')).text()).includes('href="/go/apple?lang=fr"'), 'the button carries the language of the page');
    // A parameter written with brackets is not a string: it is ignored, not a 500.
    assert.equal((await site('/?lang[toString]=x&utm_source[toString]=y')).status, 200, 'a parameter of the wrong shape does not break the page');
    assert.equal((await site('/go/apple?lang[toString]=x&utm_source[toString]=y&utm_campaign[toString]=z')).status, 302, 'nor a store button');
    assert.equal((await site('/privacy?lang[toString]=x')).status, 200, 'nor a legal page');
    assert.equal((await site('/nope?lang[toString]=x')).status, 404, 'nor the 404 page');
    // One store per platform; both when the device can't be told.
    const iphone = await (await site('/', { 'user-agent': IPHONE })).text();
    assert.ok(iphone.includes('/go/apple') && !iphone.includes('/go/play'), 'an iPhone sees the App Store only');
    const android = await (await site('/', { 'user-agent': ANDROID })).text();
    assert.ok(android.includes('/go/play') && !android.includes('/go/apple'), 'an Android device sees Google Play only');

    // The buttons redirect to the store, with the campaign.
    let go = await site('/go/play?utm_source=pinterest&utm_campaign=mood-en');
    assert.equal(go.status, 302, 'the Play button redirects');
    assert.equal(go.headers.get('location'), 'https://play.google.com/store/apps/details?id=app.mydiandian&referrer=utm_source%3Dpinterest%26utm_campaign%3Dmood-en');
    assert.equal(go.headers.get('cache-control'), 'no-store', 'every tap reaches the server');
    assert.equal(go.headers.get('referrer-policy'), 'strict-origin-when-cross-origin');
    go = await site('/go/play');
    assert.equal(go.headers.get('location'), 'https://play.google.com/store/apps/details?id=app.mydiandian');
    go = await site('/go/apple?utm_source=pinterest&utm_campaign=mood-en');
    assert.equal(go.status, 302, 'the App Store button redirects');
    const apple = go.headers.get('location') ?? '';
    assert.ok(apple.startsWith('https://apps.apple.com/app/id6761432329'), apple);
    // With a provider token on the server, the campaign is the source alone (one name per source).
    if (apple.includes('ct=')) assert.ok(apple.includes('ct=pinterest&') && !apple.includes('mood'), apple);
    assert.equal((await site('/go/amazon')).status, 404, 'there are two stores');

    // Unknown paths are not the home page any more: scanners would count as visits.
    const lost = await site('/wp-login.php');
    assert.equal(lost.status, 404, 'an unknown path is a 404');
    assert.ok((await lost.text()).includes('href="/"'), 'with a way back to the site');
    const lostApi = await site('/api/nope');
    assert.equal(lostApi.status, 404);
    assert.deepEqual(await lostApi.json(), { error: 'Not found' }, 'an unknown API path answers JSON');
    for (const path of ['/privacy', '/terms', '/legal', '/contact', '/about', '/delete-account', '/app-ads.txt', '/favicon.png', '/robots.txt']) {
      assert.equal((await site(path)).status, 200, `${path} is still there`);
    }
    assert.equal((await site('/privacy')).headers.get('referrer-policy'), 'no-referrer', 'the other pages keep the strict policy');
    assert.ok((await (await site('/robots.txt')).text()).includes('Disallow: /go/'), 'polite robots do not follow the store buttons');

    // Nothing on the site is loaded from a third party: its fonts are served
    // from here (docs/REGISTRE.md). Fetched from Google, they gave it the
    // address of every visitor.
    for (const path of ['/', '/privacy', '/terms', '/legal', '/contact', '/about', '/delete-account', '/privacy/audience', '/no-such-page']) {
      const page = await site(path);
      const body = await page.text();
      assert.ok(!/googleapis|gstatic/.test(body), `${path} loads nothing from Google`);
      assert.ok(!/googleapis|gstatic/.test(page.headers.get('content-security-policy') ?? ''), `${path}: the content security policy allows no font host but this one`);
      assert.ok(body.includes('href="/fonts/fonts.css"'), `${path} loads the site's own fonts`);
    }
    const fontsCss = await site('/fonts/fonts.css');
    assert.equal(fontsCss.status, 200, 'the font stylesheet is served');
    assert.match(fontsCss.headers.get('content-type') ?? '', /^text\/css/);
    const css = await fontsCss.text();
    assert.ok(css.includes('@font-face') && !css.includes('https://'), 'the font stylesheet names files of this site only');
    const fontFiles = [...new Set([...css.matchAll(/url\((\/fonts\/[^)]+)\)/g)].map((match) => match[1]))];
    assert.ok(fontFiles.length >= 3, `the stylesheet names its font files (${fontFiles.length})`);
    for (const file of fontFiles) {
      const font = await site(file);
      assert.equal(font.status, 200, `${file} is served`);
      assert.equal(font.headers.get('content-type'), 'font/woff2', `${file} is a woff2 font`);
      await font.arrayBuffer();
    }
    // The website's contact page is a real form posting to /api/contact.
    const contact = await (await site('/contact?lang=fr')).text();
    assert.ok(contact.includes('id="contact-form"') && contact.includes('/api/contact'), 'contact page has the form');

    // The privacy policy says what the site counts and where to object, in its four languages.
    for (const [lang, title, tag, updated] of [
      ['en', 'Website Audience Measurement', 'campaign tag', 'November 27, 2026'], ['fr', "Mesure d'audience du site", 'marquage de campagne', '27 novembre 2026'],
      ['zh-CN', '网站访问统计', '推广标记', '2026年11月27日'], ['zh-TW', '網站流量統計', '推廣標記', '2026年11月27日'],
    ]) {
      const policy = await (await site(`/privacy?lang=${lang}`)).text();
      assert.ok(policy.includes(title), `the ${lang} policy has its audience section`);
      assert.ok(policy.includes(tag), `the ${lang} policy says a tagged link is noted`);
      assert.ok(policy.includes(updated), `the ${lang} policy carries the date of its last change, written in its language`);
      assert.ok(policy.includes(`href="/privacy/audience?lang=${lang}"`), `the ${lang} policy links to the opt-out page`);
      assert.ok(policy.includes('dd_noaudience'), `the ${lang} policy names the opt-out cookie`);
      assert.ok(policy.includes('IP Geolocation by DB-IP'), `the ${lang} policy credits the country database`);
    }
    const frPolicy = await (await site('/privacy?lang=fr')).text();
    assert.ok(frPolicy.includes("aucun outil d'analyse tiers") && !frPolicy.includes("outil d'analyse ou script"), 'the policy no longer says there is no analytics tool at all, only no third-party one');
    assert.ok(!frPolicy.includes("uniquement pour l'authentification") && !(await (await site('/privacy?lang=en')).text()).includes('solely for authentication'), 'the policy no longer says cookies serve authentication alone');
    assert.ok(plain.includes('href="https://db-ip.com"') && plain.includes('IP Geolocation by DB-IP'), 'the site credits the country database (its licence asks for the link)');
    assert.ok(plain.includes('href="/privacy/audience?lang=en"'), 'the site\'s footer leads to the opt-out page');

    // The policy says what the register does (docs/REGISTRE.md), the same in
    // its four languages: who receives the data, the product events and
    // their 13 months, and where to complain.
    const sections = (page: string) => (page.match(/<h2/g) ?? []).length;
    const policySections: Record<string, number> = {};
    for (const [lang, oldClaim] of [
      ['en', 'No personal data is shared with or sold to third parties'], ['fr', "Aucune donnée personnelle n'est partagée ou vendue à des tiers"],
      ['zh-CN', '不会与第三方共享或出售个人数据'], ['zh-TW', '不會與第三方分享或出售個人資料'],
    ]) {
      const policy = await (await site(`/privacy?lang=${lang}`)).text();
      policySections[lang] = sections(policy);
      for (const name of ['Vultr', 'Cloudflare', 'Resend', 'RevenueCat', 'Microsoft', 'AdMob', 'Apple', 'Google']) {
        assert.ok(policy.includes(name), `the ${lang} policy names ${name}`);
      }
      assert.ok(!policy.includes(oldClaim), `the ${lang} policy no longer says nothing is shared with anyone`);
      const events = policy.split('id="events"')[1]?.split('<h2')[0] ?? '';
      assert.ok(events.includes('13'), `the ${lang} policy has its section on product events, with their 13 months`);
      assert.ok(/href="https:\/\/www\.cnil\.fr\/[^"]+"/.test(policy), `the ${lang} policy says where to complain`);
    }
    // What each version must say, found by the review of 2026-11-26: the
    // policy says no less than the code and the register.
    const policySays: Record<string, Record<string, string>> = {
      'sign-in with Apple or Google keeps the address and an identifier only': { en: 'we keep only your email address', fr: 'nous ne gardons que votre adresse e-mail', 'zh-CN': '我们只保存您的电子邮箱', 'zh-TW': '我們只儲存您的電子郵件' },
      'what a purchase record holds': { en: "the store's transaction identifier", fr: "l'identifiant de la transaction chez le store", 'zh-CN': '商店的交易标识符', 'zh-TW': '商店的交易識別碼' },
      'a refused session token is logged too': { en: 'a sign-in or a session token is refused', fr: 'une connexion ou un jeton de session est refusé', 'zh-CN': '登录或会话令牌被拒绝', 'zh-TW': '登入或工作階段權杖被拒絕' },
      'RevenueCat receives device information': { en: 'technical information about your device', fr: 'des informations techniques sur votre appareil', 'zh-CN': '您设备的技术信息', 'zh-TW': '您裝置的技術資訊' },
      'the full copy of the account kept on the phone (offline sync)': { en: 'a full copy of your account', fr: 'une copie complète de votre compte', 'zh-CN': '您账户的完整副本', 'zh-TW': '您帳戶的完整副本' },
      'the changes made offline wait on the phone': { en: 'the changes you made offline', fr: 'les modifications faites hors ligne', 'zh-CN': '离线时所做', 'zh-TW': '離線時所做' },
      'a closed session leaves the copy hidden on the phone': { en: 'stays on the phone, hidden', fr: 'reste sur le téléphone, cachée', 'zh-CN': '隐藏保留在手机上', 'zh-TW': '隱藏保留在手機上' },
      'every change a phone sends is kept 90 days with its answer': { en: 'the changes a phone sends, with our answer, 90 days', fr: "les modifications qu'un téléphone envoie, avec notre réponse, 90 jours", 'zh-CN': '手机发送的更改及我们的答复保留 90 天', 'zh-TW': '手機傳送的變更及我們的答覆保留 90 天' },
      'purchase events after a deletion': { en: 'linked to no account', fr: 'sans lien avec un compte', 'zh-CN': '不与任何账户关联', 'zh-TW': '不與任何帳戶關聯' },
      'backups are kept 30 days': { en: 'kept 30 days', fr: 'gardées 30 jours', 'zh-CN': '保留 30 天', 'zh-TW': '保留 30 天' },
      'logs are kept 6 months at most': { en: '6 months at most', fr: '6 mois au plus', 'zh-CN': '最多保留 6 个月', 'zh-TW': '最多保留 6 個月' },
    };
    for (const lang of ['en', 'fr', 'zh-CN', 'zh-TW']) {
      const policy = await (await site(`/privacy?lang=${lang}`)).text();
      for (const [what, phrase] of Object.entries(policySays)) {
        assert.ok(policy.includes(phrase[lang]), `the ${lang} policy says ${what}`);
      }
      const events = policy.split('id="events"')[1]?.split('<h2')[0] ?? '';
      if (lang.startsWith('zh')) assert.ok(events.includes('接收方') && !events.includes('使用者：'), `the ${lang} events section says who receives them, not "users"`);
    }
    for (const lang of ['en', 'fr', 'zh-CN', 'zh-TW']) {
      for (const path of ['/privacy', '/delete-account']) {
        const page = await (await site(`${path}?lang=${lang}`)).text();
        assert.ok(!/next updated|prochaine mise à jour|下一次更新|7 days|7 jours| 7 天/.test(page), `${path} in ${lang} no longer gives the old durations (logs until an update, backups 7 days)`);
      }
    }
    assert.ok(!(await (await site('/privacy?lang=zh-TW')).text()).includes('使用者分析'), 'zh-TW: profiling is not called "user analysis", which the usage statistics would contradict');
    assert.equal(policySections.en, 13, 'the policy has its thirteen sections');
    assert.deepEqual(policySections, { en: 13, fr: 13, 'zh-CN': 13, 'zh-TW': 13 }, 'the same sections in the four languages');

    // Deleting an account: the page says what stays for a while, and where.
    const deleteSections: Record<string, number> = {};
    for (const [lang, oldClaim] of [['en', 'no personal data'], ['fr', 'aucune donnée personnelle'], ['zh-CN', '不保留任何个人数据'], ['zh-TW', '不保留任何個人資料']]) {
      const page = await (await site(`/delete-account?lang=${lang}`)).text();
      deleteSections[lang] = sections(page);
      assert.ok(page.includes('RevenueCat'), `the ${lang} deletion page names RevenueCat`);
      const backups = { en: 'kept 30 days', fr: 'gardées 30 jours', 'zh-CN': '保留 30 天', 'zh-TW': '保留 30 天' }[lang]!;
      assert.ok(page.includes(backups), `the ${lang} deletion page says the backups last 30 days`);
      const cancel = { en: 'does not cancel a subscription', fr: "n'annule pas un abonnement", 'zh-CN': '删除账户不会取消订阅', 'zh-TW': '刪除帳戶不會取消訂閱' }[lang]!;
      assert.ok(page.includes(cancel), `the ${lang} deletion page says a store subscription keeps renewing`);
      const after = { en: 'linked to no account', fr: 'sans lien avec un compte', 'zh-CN': '不与任何账户关联', 'zh-TW': '不與任何帳戶關聯' }[lang]!;
      assert.ok(page.includes(after), `the ${lang} deletion page says what becomes of the purchase events that come after`);
      const token = { en: 'sign-in or session token', fr: "d'une connexion ou d'un jeton de session", 'zh-CN': '登录或会话令牌', 'zh-TW': '登入或工作階段權杖' }[lang]!;
      assert.ok(page.includes(token), `the ${lang} deletion page says which log lines hold an address`);
      const logs = { en: '6 months at most', fr: '6 mois au plus', 'zh-CN': '最多 6 个月', 'zh-TW': '最多 6 個月' }[lang]!;
      assert.ok(page.includes(logs), `the ${lang} deletion page says how long the log keeps it`);
      assert.ok(!page.toLowerCase().includes(oldClaim), `the ${lang} deletion page no longer says nothing at all is kept`);
    }
    assert.deepEqual(deleteSections, { en: 5, fr: 5, 'zh-CN': 5, 'zh-TW': 5 }, 'the deletion page keeps its five sections in the four languages');

    // Each page's <title> is in the language of the page (zh-TW had Simplified ones).
    for (const [path, title] of [
      ['/privacy', '隱私權政策'], ['/terms', '使用條款'], ['/about', '關於'], ['/contact', '聯絡我們'], ['/legal', '法律聲明'], ['/delete-account', '刪除帳戶'],
    ]) {
      const page = await (await site(`${path}?lang=zh-TW`)).text();
      assert.equal(page.match(/<title>([^<]*?) — Dian Dian<\/title>/)?.[1], title, `${path} in zh-TW has a Traditional title`);
    }
    // The browser holds the site to what the policy says: nothing from a third party, images included.
    const imgSrc = /img-src ([^;]*)/.exec((await site('/')).headers.get('content-security-policy') ?? '')?.[1] ?? '';
    assert.ok(imgSrc !== '' && !imgSrc.includes('https:'), `images come from the site only (img-src ${imgSrc})`);

    // The opt-out page: a button sets a cookie, and the counter leaves its bearer out.
    const optOutPage = (headers: Record<string, string> = {}) => fetch(`${BASE}/privacy/audience?lang=fr`, { headers });
    const choose = (choice: string, headers: Record<string, string> = {}) => fetch(`${BASE}/privacy/audience?lang=fr`, {
      method: 'POST', redirect: 'manual',
      headers: { 'content-type': 'application/x-www-form-urlencoded', origin: new URL(BASE).origin, ...headers },
      body: `choice=${choice}`,
    });
    let optOut = await optOutPage();
    assert.equal(optOut.status, 200, 'the opt-out page');
    // Under `no-referrer` a browser sends `Origin: null` with the form, and
    // the page could not tell its own button from another site's.
    assert.equal(optOut.headers.get('referrer-policy'), 'same-origin', 'the page lets its own form say where it comes from');
    let optOutHtml = await optOut.text();
    assert.ok(optOutHtml.includes('Ne plus compter mes visites') && !optOutHtml.includes('Compter à nouveau mes visites'), 'someone who is counted is offered to stop');
    optOut = await choose('out');
    assert.equal(optOut.status, 303, 'the choice is recorded, then the page is shown again');
    assert.equal(optOut.headers.get('location'), '/privacy/audience?lang=fr');
    const cookie = optOut.headers.get('set-cookie') ?? '';
    assert.ok(cookie.startsWith('dd_noaudience=1;'), cookie);
    assert.ok(/Max-Age=34128000/.test(cookie) && /HttpOnly/i.test(cookie) && /SameSite=Lax/i.test(cookie) && /Path=\//.test(cookie), `13 months, not readable by scripts, sent on a link from another site: ${cookie}`);
    optOutHtml = await (await optOutPage({ cookie: 'dd_noaudience=1' })).text();
    assert.ok(optOutHtml.includes('Compter à nouveau mes visites') && !optOutHtml.includes('Ne plus compter mes visites'), 'someone who opted out is offered to come back');
    optOutHtml = await (await optOutPage({ 'sec-gpc': '1' })).text();
    assert.ok(!optOutHtml.includes('Ne plus compter mes visites') && !optOutHtml.includes('Compter à nouveau mes visites'), 'a browser that already objects has nothing to do');
    optOut = await choose('in', { cookie: 'dd_noaudience=1' });
    assert.equal(optOut.status, 303);
    assert.ok(/^dd_noaudience=;/.test(optOut.headers.get('set-cookie') ?? ''), 'coming back removes the cookie');
    // What browsers really send. Chrome, Safari and Firefox say where a
    // request comes from in Sec-Fetch-Site; that is what is believed.
    optOut = await choose('out', { origin: 'null', 'sec-fetch-site': 'same-origin' });
    assert.equal(optOut.status, 303, 'the site\'s own form is accepted even when the browser hides its Origin');
    optOut = await choose('out', { 'sec-fetch-site': 'cross-site' });
    assert.equal(optOut.status, 403, 'a form on another site is refused, whatever Origin it shows');
    assert.equal(optOut.headers.get('set-cookie'), null);
    optOut = await choose('in', { 'sec-fetch-site': 'same-site' });
    assert.equal(optOut.status, 403, 'a sibling domain is another site');
    // A browser too old for Sec-Fetch-Site: its Origin is compared.
    optOut = await choose('out', { origin: 'https://elsewhere.example' });
    assert.equal(optOut.status, 403, 'another site cannot make the choice for a visitor');
    assert.equal(optOut.headers.get('set-cookie'), null);
    assert.equal((await choose('out', { origin: 'null' })).status, 403, 'an Origin that says nothing is not this site');
    assert.equal((await choose('maybe')).status, 400, 'a choice is out or in');

    // The audience counter, read in the database: local only.
    if (sql) {
      const run = `smoke-${Date.now()}`;
      const origin = `${run}.example`;
      const CHATGPT = 'Mozilla/5.0 AppleWebKit/537.36 (KHTML, like Gecko); compatible; ChatGPT-User/1.0; +https://openai.com/bot';
      const today = new Date().toISOString().slice(0, 10);
      const visit = (headers: Record<string, string>) => fetch(`${BASE}/`, { headers });
      const person = { 'user-agent': IPHONE, referer: `https://www.${origin}/a/page?x=1`, 'accept-language': 'fr-FR,fr;q=0.9' };
      const count = async (where: postgres.PendingQuery<postgres.Row[]>) => {
        const [row] = await sql`select coalesce(sum(count), 0)::int as n from audience_counts where day = ${today} and ${where}`;
        return row.n as number;
      };
      const robots = sql`bot_family = 'ai_user' and bot_name = 'ChatGPT-User' and bot_check = 'unverified'`;
      const taps = sql`kind = 'store_tap' and store = 'apple' and device = 'iphone' and bot_family = '' and lang = 'zh-TW'`;
      const totals = async () => {
        const [row] = await sql`select visits, visitors, taps_apple from audience_totals where day = ${today}`;
        return { visits: (row?.visits ?? 0) as number, visitors: (row?.visitors ?? 0) as number, tapsApple: (row?.taps_apple ?? 0) as number };
      };
      /** Waits for the counter's next write (every 5 seconds) to show `n` visits from this run's origin. */
      const written = async (n: number) => {
        for (let i = 0; i < 40; i++) {
          if (await count(sql`origin = ${origin}`) === n) return;
          await new Promise((resolve) => setTimeout(resolve, 250));
        }
        assert.fail(`the counter did not write ${n} visit(s) from ${origin} within 10 seconds`);
      };
      const before = { robots: await count(robots), taps: await count(taps), ...(await totals()) };

      await visit(person);
      await visit({ 'user-agent': CHATGPT });
      await fetch(`${BASE}/go/apple?lang=zh-TW`, { redirect: 'manual', headers: { 'user-agent': IPHONE, 'accept-language': 'fr-FR,fr;q=0.9' } });
      await visit({ ...person, dnt: '1' });
      await visit({ ...person, 'sec-gpc': '1' });
      await visit({ ...person, cookie: 'dd_noaudience=1' });
      await fetch(`${BASE}/`, { method: 'HEAD', headers: person });
      await written(1);
      const [row] = await sql`
        select kind, origin_from, tagged, device, browser, in_app, lang, bot_family, count
        from audience_counts where origin = ${origin}`;
      assert.deepEqual(
        { ...row },
        { kind: 'visit', origin_from: 'referer', tagged: false, device: 'iphone', browser: 'safari', in_app: '', lang: 'fr', bot_family: '', count: 1 },
        'a visit is one row: its origin as a bare domain, and classes of what was seen',
      );
      assert.equal(await count(robots) - before.robots, 1, 'a robot is counted by name, unverified when its address is not its operator\'s');
      assert.equal(await count(taps) - before.taps, 1, 'a tap on a store button is counted, in the language of the page it was on');
      const after = await totals();
      assert.deepEqual({ visits: after.visits - before.visits, tapsApple: after.tapsApple - before.tapsApple }, { visits: 1, tapsApple: 1 }, 'the totals of the day count the person, not the robot, not who objects');

      // A later write adds to the row instead of replacing it (as after a restart).
      await visit(person);
      await written(2);

      // Nothing that identifies anyone is in the table.
      const columns = await sql`select column_name from information_schema.columns where table_name = 'audience_counts'`;
      assert.deepEqual(
        columns.map((c) => c.column_name).sort(),
        ['bot_check', 'bot_family', 'bot_name', 'browser', 'count', 'country', 'day', 'device', 'in_app', 'kind', 'lang', 'origin', 'origin_from', 'store', 'tagged'],
      );
      // With the real downloads on — the release checks set AUDIENCE_DOWNLOADS=on
      // for the server and for this suite — the server holds DB-IP's real
      // database: a visit forwarded from a well-known American address must be
      // counted in the United States. It is the one automated check that the
      // reader still reads the real file, and that the server sees the
      // visitor's address behind a proxy.
      const probe = `${run}-country.example`;
      if (envFlag(process.env.AUDIENCE_DOWNLOADS, false)) {
        let country = '';
        for (let i = 0; i < 20 && country !== 'US'; i++) {
          await visit({ 'user-agent': IPHONE, referer: `https://${probe}/`, 'x-forwarded-for': '8.8.8.8' });
          await new Promise((resolve) => setTimeout(resolve, 3000));
          const [seen] = await sql`select country from audience_counts where origin = ${probe} and country <> ''`;
          country = (seen?.country ?? '') as string;
        }
        assert.equal(country, 'US', 'with its downloads on, the server finds the country of an address (waited a minute for the database)');
      } else {
        console.log('smoke: country check skipped (AUDIENCE_DOWNLOADS is not on for this suite and its server)');
      }

      // The suite leaves the database as it found it: its rows, and what it added to the day's totals.
      const end = await totals();
      await sql`delete from audience_counts where origin in ${sql([origin, probe])}`;
      await sql`update audience_counts set count = count - 1 where day = ${today} and ((${robots}) or (${taps}))`;
      await sql`delete from audience_counts where day = ${today} and count <= 0`;
      await sql`
        update audience_totals
        set visits = visits - ${end.visits - before.visits}, visitors = visitors - ${end.visitors - before.visitors}, taps_apple = taps_apple - ${end.tapsApple - before.tapsApple}
        where day = ${today}`;
      await sql`delete from audience_totals where day = ${today} and visits <= 0 and visitors <= 0 and taps_apple <= 0 and taps_play <= 0`;

      // Days older than 25 months become one total per month.
      const { db } = await import('../src/db/index.js');
      const { rollUpOldDays } = await import('../src/audience/counter.js');
      const month = async () => {
        const [m] = await sql`select visits, taps_apple, taps_play, bot_hits from audience_months where month = '2020-03-01'`;
        return { visits: (m?.visits ?? 0) as number, tapsApple: (m?.taps_apple ?? 0) as number, tapsPlay: (m?.taps_play ?? 0) as number, botHits: (m?.bot_hits ?? 0) as number, there: m !== undefined };
      };
      const monthBefore = await month();
      await sql`insert into audience_counts (day, kind, origin, device, count) values ('2020-03-15', 'visit', ${origin}, 'iphone', 3)`;
      await sql`insert into audience_counts (day, kind, bot_family, bot_name, bot_check, count) values ('2020-03-16', 'visit', 'other', ${run}, 'unverifiable', 4)`;
      await sql`insert into audience_totals (day, visits, visitors, taps_apple, taps_play) values ('2020-03-15', 3, 2, 1, 0)`;
      await rollUpOldDays(db, new Date());
      const monthAfter = await month();
      assert.deepEqual(
        { visits: monthAfter.visits - monthBefore.visits, tapsApple: monthAfter.tapsApple - monthBefore.tapsApple, tapsPlay: monthAfter.tapsPlay - monthBefore.tapsPlay, botHits: monthAfter.botHits - monthBefore.botHits },
        { visits: 3, tapsApple: 1, tapsPlay: 0, botHits: 4 },
        'the old days are added to their month',
      );
      const [{ left }] = await sql`
        select (select count(*) from audience_counts where day < '2020-04-01') + (select count(*) from audience_totals where day < '2020-04-01') as left`;
      assert.equal(Number(left), 0, 'and deleted');
      await rollUpOldDays(db, new Date());
      assert.deepEqual(await month(), monthAfter, 'rolling up again changes nothing');
      if (monthBefore.there) {
        await sql`update audience_months set visits = visits - 3, taps_apple = taps_apple - 1, bot_hits = bot_hits - 4 where month = '2020-03-01'`;
      } else {
        await sql`delete from audience_months where month = '2020-03-01'`;
      }
    }
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
    if (sql) {
      const [t] = await sql`select page_id from deletions where user_id = ${userId} and kind = 'page' and key = ${page2}`;
      assert.equal(t?.page_id, page2, 'the empty tracker it replaces leaves a deletion trace');
    }
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

    // --- idempotent creation: the same clientId never makes a twin ---------
    // (the app retries with the key it generated when the response was lost)
    const clientId = '11111111-1111-4111-8111-111111111111';
    r = await call('DELETE', `/api/pages/${sleep}`);
    assert.equal(r.status, 200, 'free a slot');
    r = await call('POST', '/api/pages', { title: 'Twin', clientId, legends: [{ color: '#111111', label: 'One' }] });
    assert.equal(r.status, 201, `create with clientId: ${JSON.stringify(r.json)}`);
    const twin: string = r.json.id;
    r = await call('POST', '/api/pages', { title: 'Twin', clientId, legends: [{ color: '#111111', label: 'One' }] });
    assert.equal(r.status, 200, `replay: ${JSON.stringify(r.json)}`);
    assert.equal(r.json.id, twin, 'the replay returns the page already created');
    assert.equal(r.json.legends.length, 1, 'with its legends');
    r = await call('GET', '/api/pages');
    assert.equal(r.json.length, 3, 'no twin');
  }

  // --- events (roadmap #2: count the paywall gates) ------------------------
  r = await call('POST', '/api/events', { name: 'paywall.tracker_limit' });
  assert.equal(r.status, 204, `event: ${JSON.stringify(r.json)}`);
  r = await call('POST', '/api/events', { name: 'Bad Name!' });
  assert.equal(r.status, 400, 'event names are lower-case slugs');
  r = await call('POST', '/api/events', { name: 'paywall.tracker_limit' }, false);
  assert.equal(r.status, 401, 'events need a session');
  // Where an event comes from: kept when it is a platform and a version this
  // server knows, dropped (never refused) otherwise — the count comes first.
  r = await call('POST', '/api/events', { name: 'paywall.stats', platform: 'ios', appVersion: '1.5.0' });
  assert.equal(r.status, 204, `event with its origin: ${JSON.stringify(r.json)}`);
  r = await call('POST', '/api/events', { name: 'paywall.export', platform: 'macos', appVersion: '1.5.0-beta' });
  assert.equal(r.status, 204, 'an origin this server does not know never refuses the event');
  if (sql) {
    const origin = async (name: string) => {
      const [row] = await sql`select platform, app_version from events where user_id = ${userId} and name = ${name}`;
      return { platform: row.platform, appVersion: row.app_version };
    };
    assert.deepEqual(await origin('paywall.stats'), { platform: 'ios', appVersion: '1.5.0' }, 'platform and version are kept');
    assert.deepEqual(await origin('paywall.export'), { platform: null, appVersion: null }, 'an unknown origin is left empty');
    assert.deepEqual(await origin('paywall.tracker_limit'), { platform: null, appVersion: null }, 'an app that sends the name alone (≤ 1.4.0) still counts');

    // An account that objected to product events (docs/REGISTRE.md, fiche 7):
    // the app is answered as usual and nothing is written.
    const written = async (name: string) => (await sql`select count(*)::int as n from events where user_id = ${userId} and name = ${name}`)[0].n as number;
    await sql`update users set events_opt_out = true where id = ${userId}`;
    r = await call('POST', '/api/events', { name: 'paywall.themes' });
    assert.equal(r.status, 204, 'an account that objected is answered like any other');
    assert.equal(await written('paywall.themes'), 0, 'and nothing is written for it');
    r = await call('POST', '/api/events', { name: 'Bad Name!' });
    assert.equal(r.status, 400, 'a bad name is refused as before');
    await sql`update users set events_opt_out = false where id = ${userId}`;
    r = await call('POST', '/api/events', { name: 'paywall.themes' });
    assert.equal(r.status, 204);
    assert.equal(await written('paywall.themes'), 1, 'once the objection is lifted, events are written again');
  }

  // --- retention: 13 months for product events, and for purchase events ----
  // --- that name no account (docs/REGISTRE.md) ------------------------------
  if (sql) {
    const { db } = await import('../src/db/index.js');
    const { keptSince, purgeOldRows } = await import('../src/lib/retention.js');
    const run = `smoke-${Date.now()}`;
    const now = new Date();
    const limit = keptSince(now, 13);
    const justBefore = new Date(limit.getTime() - 1);
    const threeYearsAgo = new Date(Date.UTC(now.getUTCFullYear() - 3, now.getUTCMonth(), 1));
    await sql`
      insert into events (user_id, name, created_at)
      values (${userId}, 'smoke.old', ${justBefore}), (${userId}, 'smoke.edge', ${limit}), (${userId}, 'smoke.recent', ${now})`;
    const purchaseEvent = (id: string, account: string | null, receivedAt: Date) => sql`
      insert into subscription_events (rc_event_id, user_id, type, event_at, payload, received_at)
      values (${`${run}-${id}`}, ${account}, 'TEST', ${receivedAt}, '{}'::jsonb, ${receivedAt})`;
    await purchaseEvent('orphan-old', null, justBefore);
    await purchaseEvent('orphan-edge', null, limit);
    await purchaseEvent('owned-old', userId, threeYearsAgo);
    const left = async () => ({
      events: (await sql`select name from events where user_id = ${userId} and name like 'smoke.%' order by name`).map((row) => row.name as string),
      purchaseEvents: (await sql`select rc_event_id from subscription_events where rc_event_id like ${`${run}-%`} order by rc_event_id`).map((row) => row.rc_event_id as string),
    });
    try {
      const purged = await purgeOldRows(db, now);
      assert.ok(purged.events >= 1 && purged.purchaseEvents >= 1, `the purge says what it deleted: ${JSON.stringify(purged)}`);
      const kept = {
        events: ['smoke.edge', 'smoke.recent'],
        purchaseEvents: [`${run}-orphan-edge`, `${run}-owned-old`],
      };
      assert.deepEqual(await left(), kept, 'older than the limit is deleted; the limit itself, and the purchase events of an account whatever their age, are kept');
      await purgeOldRows(db, now);
      assert.deepEqual(await left(), kept, 'purging again deletes nothing more');
      // Offline sync: answers to changes kept 90 days; deletion traces 24
      // months, after which the account's floor makes a late phone take the
      // full copy (it may have missed a deletion).
      const syncLimit = new Date(now.getTime() - 90 * 24 * 60 * 60 * 1000);
      const oldAnswer = randomUUID();
      const newAnswer = randomUUID();
      await sql`insert into sync_mutations (id, user_id, result, created_at) values
        (${oldAnswer}, ${userId}, '{}'::jsonb, ${new Date(syncLimit.getTime() - 1000)}),
        (${newAnswer}, ${userId}, '{}'::jsonb, ${new Date(syncLimit.getTime() + 60_000)})`;
      const traceLimit = keptSince(now, 24);
      const [{ rev: accountRev }] = await sql`select rev::int from users where id = ${userId}`;
      await sql`insert into deletions (user_id, kind, key, rev, deleted_at) values
        (${userId}, 'legend', ${`${run}-old-trace`}, ${accountRev}, ${new Date(traceLimit.getTime() - 1000)}),
        (${userId}, 'legend', ${`${run}-new-trace`}, ${accountRev}, ${traceLimit})`;
      const purgedSync = await purgeOldRows(db, now);
      assert.ok(purgedSync.syncMutations >= 1 && purgedSync.deletions >= 1, `the purge says it: ${JSON.stringify(purgedSync)}`);
      const answers = (await sql`select id from sync_mutations where id in ${sql([oldAnswer, newAnswer])}`).map((row) => row.id);
      assert.deepEqual(answers, [newAnswer], 'answers older than 90 days are deleted');
      const keptTraces = (await sql`select key from deletions where user_id = ${userId} and key like ${`${run}-%`}`).map((row) => row.key);
      assert.deepEqual(keptTraces, [`${run}-new-trace`], 'traces older than 24 months are deleted');
      const [{ floor }] = await sql`select sync_floor_rev::int as floor from users where id = ${userId}`;
      assert.equal(floor, accountRev, 'and the account remembers the highest number it forgot');
      const late = await call('GET', `/api/sync?since=${accountRev - 1}`);
      assert.equal(late.json.full, true, 'a phone older than that takes the full copy');
      const oldEnd = `${run}-old-end`;
      const newEnd = `${run}-new-end`;
      await sql`insert into ended_sessions (token_hash, reason, ended_at) values
        (${oldEnd}, 'account_deleted', ${new Date(now.getTime() - 548 * 24 * 60 * 60 * 1000 - 1000)}),
        (${newEnd}, 'account_deleted', ${new Date(now.getTime() - 547 * 24 * 60 * 60 * 1000)})`;
      await purgeOldRows(db, now);
      const ends = (await sql`select token_hash from ended_sessions where token_hash in ${sql([oldEnd, newEnd])}`).map((row) => row.token_hash);
      assert.deepEqual(ends, [newEnd], 'ended sessions are remembered as long as a session lasts, then forgotten');
      await sql`delete from ended_sessions where token_hash = ${newEnd}`;
    } finally {
      await sql`delete from events where user_id = ${userId} and name like 'smoke.%'`;
      await sql`delete from deletions where user_id = ${userId} and key like ${`${run}-%`}`;
      await sql`update users set sync_floor_rev = 0 where id = ${userId}`;
      await sql`delete from subscription_events where rc_event_id like ${`${run}-%`}`;
    }
  }

  // --- RevenueCat webhook: every event is kept, the entitlement follows -----
  if (process.env.CI && !process.env.SMOKE_BASE) {
    assert.ok(webhookSecret && sql, 'CI runs the webhook checks: REVENUECAT_WEBHOOK_SECRET and a local DATABASE_URL must be set');
  }
  if (!webhookSecret || !sql) {
    console.log('smoke: webhook checks skipped (the server or the database is not on this machine, or REVENUECAT_WEBHOOK_SECRET is missing)');
  } else {
    const run = `smoke-${Date.now()}`;
    const now = Date.now();
    const week = 7 * 24 * 60 * 60 * 1000;
    const premium = async (token = access) => {
      const res = await fetch(`${BASE}/api/purchase/status`, { headers: { Authorization: `Bearer ${token}` } });
      return ((await res.json()) as { premium: boolean }).premium;
    };
    // What the session routes and the tracker limit read (`hasActiveSubscription`).
    const premiumInSession = async (token = access) => {
      const res = await fetch(`${BASE}/api/auth/me`, { headers: { Authorization: `Bearer ${token}` } });
      return ((await res.json()) as { premium: boolean }).premium;
    };
    // Everything is a sandbox event of this throwaway account.
    const mine = {
      app_user_id: userId, environment: 'SANDBOX', store: 'APP_STORE', product_id: 'premium_yearly',
      original_transaction_id: `${run}-tx`, transaction_id: `${run}-tx`, currency: 'EUR', country_code: 'FR',
      event_timestamp_ms: now,
    };
    const trialStart = {
      ...mine, type: 'INITIAL_PURCHASE', id: `${run}-purchase`, period_type: 'TRIAL',
      price: 0, price_in_purchased_currency: 0, purchased_at_ms: now, expiration_at_ms: now + week,
    };

    assert.equal(await webhook(trialStart, null), 401, 'the webhook needs its secret');
    assert.equal(await premium(), false, 'an unauthenticated event changes nothing');
    assert.equal(await webhook(trialStart), 200, 'trial start');
    assert.equal(await premium(), true, 'a trial start makes the account premium');
    assert.equal(await webhook(trialStart), 200, 'a retried delivery is accepted');
    assert.equal(await webhook({
      ...mine, type: 'CANCELLATION', id: `${run}-cancel`, period_type: 'TRIAL', cancel_reason: 'UNSUBSCRIBE', expiration_at_ms: now + week,
    }), 200, 'cancellation');
    assert.equal(await premium(), true, 'a cancelled trial runs to its end');

    // Events that name no account of ours: accepted, kept, and nothing else.
    const transferId = `${run}-transfer`;
    assert.equal(await webhook({
      type: 'TRANSFER', id: transferId, event_timestamp_ms: now, environment: 'SANDBOX', store: 'APP_STORE',
      transferred_from: [randomUUID()], transferred_to: [randomUUID()],
    }), 200, 'an event without app_user_id (a transfer) is accepted');
    const strangerId = `${run}-stranger`;
    assert.equal(await webhook({
      ...trialStart, id: strangerId, app_user_id: randomUUID(), original_transaction_id: `${run}-tx2`, transaction_id: `${run}-tx2`,
    }), 200, 'a purchase for an account we do not know is accepted');
    assert.equal(await webhook({ ...mine, type: 'REFUND_REVERSED', id: `${run}-unknown` }), 200, 'a type this server does not know is accepted');
    assert.equal(await premium(), true, 'none of them touched the subscription');

    // A payment fails at the end of the period: with a grace period, premium
    // holds until its end instead of stopping at once.
    const hour = 60 * 60 * 1000;
    assert.equal(await webhook({
      ...mine, type: 'RENEWAL', id: `${run}-renewal`, period_type: 'NORMAL', price: 14.99, price_in_purchased_currency: 14.99,
      is_trial_conversion: true, expiration_at_ms: now - hour,
    }), 200, 'renewal');
    assert.equal(await premium(), false, 'a period that is over is over');
    assert.equal(await webhook({
      ...mine, type: 'BILLING_ISSUE', id: `${run}-billing`, period_type: 'NORMAL', expiration_at_ms: now - hour,
      grace_period_expiration_at_ms: now + 3 * 24 * hour,
    }), 200, 'billing issue');
    assert.equal(await premium(), true, 'a billing issue keeps premium through the grace period');
    assert.equal(await webhook({ ...mine, type: 'SUBSCRIPTION_PAUSED', id: `${run}-pause`, period_type: 'NORMAL' }), 200, 'pause');
    assert.equal(await premium(), true, 'a pause does not end premium: the expiration does');

    // The purchase is restored on a second account: it follows.
    const second = await call('POST', '/api/auth/register', { email: `smoke-second-${Date.now()}@example.com`, password }, false);
    assert.equal(second.status, 201, `second account: ${JSON.stringify(second.json)}`);
    const secondId: string = second.json.userId;
    const secondToken: string = second.json.accessToken;
    assert.equal(await webhook({
      type: 'TRANSFER', id: `${run}-moved`, event_timestamp_ms: now, environment: 'SANDBOX', store: 'APP_STORE',
      transferred_from: [userId], transferred_to: ['$RCAnonymousID:smoke', secondId],
    }), 200, 'transfer to the second account');
    assert.equal(await premium(secondToken), true, 'the account the purchase was restored on is premium');
    assert.equal(await premium(), false, 'the account it left is not any more');

    assert.equal(await webhook({
      ...mine, app_user_id: secondId, type: 'EXPIRATION', id: `${run}-expire`, period_type: 'NORMAL', expiration_reason: 'BILLING_ERROR', expiration_at_ms: now,
    }), 200, 'expiration');
    assert.equal(await premium(secondToken), false, 'the expiration ends premium');
    assert.equal(await webhook({
      ...mine, app_user_id: secondId, type: 'BILLING_ISSUE', id: `${run}-late-billing`, period_type: 'NORMAL', expiration_at_ms: now,
      grace_period_expiration_at_ms: now + 4 * 24 * hour,
    }), 200, 'billing issue after the expiration');
    assert.equal(await premium(secondToken), false, 'a failed payment reported after the expiration does not reopen the subscription');

    // A subscription whose events now come for another account belongs to
    // it: a transfer this server never received (lost, or from before it
    // handled them) is caught up at the next purchase event.
    const moving = { ...mine, original_transaction_id: `${run}-tx3`, transaction_id: `${run}-tx3`, period_type: 'NORMAL', price: 14.99, price_in_purchased_currency: 14.99 };
    assert.equal(await webhook({ ...moving, type: 'INITIAL_PURCHASE', id: `${run}-tx3-start`, expiration_at_ms: now + week }), 200, 'purchase');
    assert.equal(await premium(), true, 'the buyer is premium');
    assert.equal(await webhook({ ...moving, app_user_id: secondId, type: 'RENEWAL', id: `${run}-tx3-renewal`, expiration_at_ms: now + 2 * week }), 200, 'renewal for another account');
    assert.equal(await premium(secondToken), true, 'the account the renewal names is premium');
    assert.equal(await premium(), false, 'the account it used to belong to is not any more');

    // A period that ran out but was never closed (its EXPIRATION is yet to
    // come) must not hide a purchase that is valid: here a lifetime.
    const lapsed = { ...mine, original_transaction_id: `${run}-tx4`, transaction_id: `${run}-tx4`, period_type: 'NORMAL', price: 2.99, price_in_purchased_currency: 2.99 };
    assert.equal(await webhook({ ...lapsed, type: 'RENEWAL', id: `${run}-tx4-renewal`, product_id: 'premium_monthly', expiration_at_ms: now - hour }), 200, 'a period already over');
    assert.equal(await premiumInSession(), false, 'a period that is over gives nothing');
    assert.equal(await webhook({
      ...mine, type: 'NON_RENEWING_PURCHASE', id: `${run}-life`, product_id: 'premium_lifetime', period_type: 'NORMAL',
      original_transaction_id: `${run}-tx5`, transaction_id: `${run}-tx5`, price: 29.99, price_in_purchased_currency: 29.99, expiration_at_ms: null,
    }), 200, 'lifetime purchase');
    assert.equal(await premiumInSession(), true, 'the session sees the lifetime, not the period that ran out');
    assert.equal(await premium(), true, 'and so does the purchase status');
    assert.equal(await premium(), true, 'asked twice, the same answer');

    const subscription = async (tx: string) => {
      const [row] = await sql`select user_id, active, expires_at from subscriptions where original_transaction_id = ${`${run}-${tx}`}`;
      return row as { user_id: string; active: boolean; expires_at: Date | null } | undefined;
    };
    assert.equal(await webhook({
      ...mine, type: 'BILLING_ISSUE', id: `${run}-life-billing`, product_id: 'premium_lifetime', period_type: 'NORMAL',
      original_transaction_id: `${run}-tx5`, transaction_id: `${run}-tx5`, expiration_at_ms: null, grace_period_expiration_at_ms: now + 3 * 24 * hour,
    }), 200, 'billing issue on a lifetime');
    assert.equal((await subscription('tx5'))?.expires_at, null, 'a lifetime never gets an end date');

    // Transfers. To an account we do not know: nothing moves.
    const nowhereId = `${run}-nowhere`;
    assert.equal(await webhook({
      type: 'TRANSFER', id: nowhereId, event_timestamp_ms: now, environment: 'SANDBOX', store: 'APP_STORE',
      transferred_from: [userId], transferred_to: [randomUUID()],
    }), 200, 'transfer to an account we do not know');
    assert.equal((await subscription('tx5'))?.user_id, userId, 'a transfer to an account we do not know moves nothing');

    // The account also buys on Android, and restores that purchase on the
    // second account. The transfer lists an account deleted since before the
    // one that exists, and names its store: the Play purchase follows, what
    // was bought on the App Store stays.
    const play = {
      ...mine, store: 'PLAY_STORE', product_id: 'premium_monthly', original_transaction_id: `${run}-tx6`, transaction_id: `${run}-tx6`,
      period_type: 'NORMAL', price: 2.99, price_in_purchased_currency: 2.99,
    };
    const playStart = { ...play, type: 'INITIAL_PURCHASE', id: `${run}-tx6-start`, expiration_at_ms: now + week };
    assert.equal(await webhook(playStart), 200, 'a purchase in the other store');
    const toSecond = {
      type: 'TRANSFER', id: `${run}-play-moved`, event_timestamp_ms: now, environment: 'SANDBOX', store: 'PLAY_STORE',
      transferred_from: [userId], transferred_to: [randomUUID(), secondId],
    };
    assert.equal(await webhook(toSecond), 200, 'transfer of the Play purchase');
    assert.equal((await subscription('tx6'))?.user_id, secondId, 'a transfer reaches the first account of its list that exists');
    assert.equal((await subscription('tx5'))?.user_id, userId, 'what was bought in the other store stays where it is');

    // Restored back, then the first transfer is delivered a second time
    // (RevenueCat retries when our answer got lost): an event already applied
    // is not applied again, or the purchase would leave once more.
    assert.equal(await webhook({ ...toSecond, id: `${run}-play-back`, transferred_from: [secondId], transferred_to: [userId] }), 200, 'restored back');
    assert.equal((await subscription('tx6'))?.user_id, userId, 'the Play purchase is back');
    assert.equal((await subscription('tx3'))?.user_id, secondId, 'and the App Store subscription of the second account did not come with it');
    assert.equal(await webhook(toSecond), 200, 'the first transfer delivered again');
    assert.equal((await subscription('tx6'))?.user_id, userId, 'a transfer already applied is not applied again');
    assert.equal(await webhook({ ...play, type: 'EXPIRATION', id: `${run}-tx6-expire`, expiration_reason: 'UNSUBSCRIBE', expiration_at_ms: now }), 200, 'expiration');
    assert.equal(await webhook(playStart), 200, 'its purchase delivered again');
    assert.equal((await subscription('tx6'))?.active, false, 'a purchase delivered again does not reopen what has expired since');

    // An event that cannot be kept (its id holds a character the database
    // refuses) still gives what was paid for: only the record is missing.
    assert.equal(await webhook({
      ...play, type: 'INITIAL_PURCHASE', id: `${run}-nul\u0000`, original_transaction_id: `${run}-tx7`, transaction_id: `${run}-tx7`, expiration_at_ms: now + week,
    }), 200, 'an event the database cannot keep');
    assert.equal((await subscription('tx7'))?.user_id, userId, 'the purchase is applied all the same');
    const [{ unkept }] = await sql`select count(*)::int as unkept from subscription_events where original_transaction_id = ${`${run}-tx7`}`;
    assert.equal(unkept, 0, 'and it is the record that is missing');

    // A date no calendar holds in a field that is only measurement: the
    // purchase goes through, the field is left empty.
    assert.equal(await webhook({
      ...play, type: 'RENEWAL', id: `${run}-odd-date`, original_transaction_id: `${run}-tx8`, transaction_id: `${run}-tx8`,
      purchased_at_ms: 1e20, expiration_at_ms: now + week,
    }), 200, 'a purchase date that cannot be read');
    assert.equal((await subscription('tx8'))?.active, true, 'the purchase is applied');
    const [oddDate] = await sql`select purchased_at from subscription_events where rc_event_id = ${`${run}-odd-date`}`;
    assert.equal(oddDate?.purchased_at, null, 'and kept, without the date');

    // The end of the period cannot be read: nothing can be given safely, so
    // nothing is applied AND nothing is kept, and RevenueCat is told to send
    // it again. The same event sent again, readable this time, does both.
    const badEnd = { ...play, type: 'RENEWAL', id: `${run}-bad-end`, original_transaction_id: `${run}-tx9`, transaction_id: `${run}-tx9` };
    assert.equal(await webhook({ ...badEnd, expiration_at_ms: 1e20 }), 500, 'an event that cannot be applied is refused');
    assert.equal(await subscription('tx9'), undefined, 'nothing is applied');
    const [{ refused }] = await sql`select count(*)::int as refused from subscription_events where rc_event_id = ${`${run}-bad-end`}`;
    assert.equal(refused, 0, 'and nothing is kept, or its next delivery would be taken for one already applied');
    assert.equal(await webhook({ ...badEnd, expiration_at_ms: now + week }), 200, 'delivered again');
    assert.equal((await subscription('tx9'))?.active, true, 'the delivery that can be applied is');

    // A transfer that names no store moves everything the account bought.
    assert.equal(await webhook({
      type: 'TRANSFER', id: `${run}-all-moved`, event_timestamp_ms: now, environment: 'SANDBOX',
      transferred_from: [userId], transferred_to: [secondId],
    }), 200, 'transfer without a store');
    assert.equal((await subscription('tx5'))?.user_id, secondId, 'the App Store lifetime follows');
    assert.equal((await subscription('tx9'))?.user_id, secondId, 'and so does the Play subscription');

    const kept = await sql`
      select rc_event_id, type, period_type, environment, price_usd, currency, cancel_reason, expiration_reason
      from subscription_events where user_id = ${userId}`;
    assert.deepEqual(
      kept.map((e) => e.type).sort(),
      [
        'BILLING_ISSUE', 'BILLING_ISSUE', 'CANCELLATION', 'EXPIRATION', 'INITIAL_PURCHASE', 'INITIAL_PURCHASE', 'INITIAL_PURCHASE',
        'NON_RENEWING_PURCHASE', 'REFUND_REVERSED', 'RENEWAL', 'RENEWAL', 'RENEWAL', 'RENEWAL', 'SUBSCRIPTION_PAUSED', 'TRANSFER',
      ],
      'one row per event of the account: an event delivered twice is one row',
    );
    const keptBySecond = await sql`select type from subscription_events where user_id = ${secondId}`;
    assert.deepEqual(
      keptBySecond.map((e) => e.type).sort(),
      ['BILLING_ISSUE', 'EXPIRATION', 'RENEWAL', 'TRANSFER', 'TRANSFER', 'TRANSFER'],
      'a transfer is kept with the account it reaches',
    );
    const start = kept.find((e) => e.rc_event_id === `${run}-purchase`)!;
    assert.deepEqual(
      { period: start.period_type, env: start.environment, price: start.price_usd, currency: start.currency },
      { period: 'TRIAL', env: 'SANDBOX', price: 0, currency: 'EUR' },
      'the trial start keeps its period, environment and price',
    );
    assert.equal(kept.find((e) => e.type === 'CANCELLATION')!.cancel_reason, 'UNSUBSCRIBE');
    const orphans = await sql`
      select rc_event_id, payload from subscription_events
      where user_id is null and rc_event_id in ${sql([transferId, strangerId, nowhereId])}`;
    assert.equal(orphans.length, 3, 'events for unknown accounts are kept without an account');
    for (const orphan of orphans) {
      const fields = Object.keys(orphan.payload as Record<string, unknown>);
      for (const who of ['app_user_id', 'aliases', 'transferred_from', 'transferred_to']) {
        assert.ok(!fields.includes(who), `${orphan.rc_event_id} keeps no ${who}`);
      }
    }
    await sql`delete from subscription_events where rc_event_id in ${sql([transferId, strangerId, nowhereId])}`;
    const gone = await fetch(`${BASE}/api/auth/account`, { method: 'DELETE', headers: { Authorization: `Bearer ${secondToken}` } });
    assert.equal(gone.status, 200, 'second account deleted');
    const late = await fetch(`${BASE}/api/events`, {
      method: 'POST', headers: { Authorization: `Bearer ${secondToken}`, 'Content-Type': 'application/json' }, body: JSON.stringify({ name: 'paywall.themes' }),
    });
    assert.equal(late.status, 401, 'an event sent by an account just deleted (its access token still valid) is refused, not a 500');
    assert.equal((await late.json()).code, 'account_deleted', 'with why: its session is over (chantier 9)');
  }

  // --- cleanup --------------------------------------------------------------
  // --- after a database restore, every phone takes the full copy ----------
  // (ops/scripts/restore.sh runs this very statement; review, minor 9)
  if (sql) {
    const seen = (await call('GET', '/api/sync?since=0')).json.rev as number;
    await sql`update users set rev = rev + 1000000, sync_floor_rev = rev + 1000000 where id = ${userId}`;
    const after = await call('GET', `/api/sync?since=${seen}`);
    assert.equal(after.json.full, true, 'a phone that knew the old numbers gets the full copy');
    assert.equal((await call('GET', `/api/sync?since=${after.json.rev}`)).json.full, false, 'then deltas again');
  }

  r = await call('DELETE', '/api/auth/account');
  assert.equal(r.status, 200);
  // The access token still has minutes to run: the session check says why it is refused.
  r = await call('GET', '/api/sync?since=0');
  assert.equal(r.status, 401, 'a deleted account reads nothing, not an empty list');
  assert.equal(r.json.code, 'account_deleted');
  r = await call('POST', '/api/auth/refresh', { refreshToken: refresh }, false);
  assert.equal(r.status, 401);
  assert.equal(r.json.code, 'account_deleted', 'a session of a deleted account says so (H24)');
  if (sql) {
    const [{ n }] = await sql`select count(*)::int as n from subscription_events where user_id = ${userId}`;
    assert.equal(n, 0, 'deleting the account deletes its purchase events');
    await (await import('../src/db/index.js')).db.$client.end();
    await sql.end();
  }
  console.log('smoke: OK');
}

main().catch((err) => {
  console.error('smoke: FAILED');
  console.error(err);
  process.exit(1);
});
