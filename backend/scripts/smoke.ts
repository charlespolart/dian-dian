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
import { randomUUID } from 'node:crypto';
import { readFileSync } from 'node:fs';
import postgres from 'postgres';
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

  // --- the site: store buttons go through /go/*, unknown paths are 404 -------
  {
    const IPHONE = 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_6 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/18.6 Mobile/15E148 Safari/604.1';
    const ANDROID = 'Mozilla/5.0 (Linux; Android 15; Pixel 8) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/138.0.0.0 Mobile Safari/537.36';
    // The suite is not a visitor: `DNT: 1` keeps these requests out of the
    // audience counter, on the production site too.
    const site = (path: string, headers: Record<string, string> = {}) => fetch(`${BASE}${path}`, { redirect: 'manual', headers: { dnt: '1', ...headers } });

    const res = await site('/?utm_source=pinterest&utm_campaign=mood-en');
    assert.equal(res.status, 200);
    assert.equal(res.headers.get('referrer-policy'), 'strict-origin-when-cross-origin', 'the stores are told the visitor comes from the site');
    const html = await res.text();
    assert.ok(html.includes('href="/go/play?utm_source=pinterest&amp;utm_campaign=mood-en"'), 'the Play button carries the campaign');
    assert.ok(html.includes('href="/go/apple?utm_source=pinterest&amp;utm_campaign=mood-en"'), 'the App Store button carries the campaign');
    assert.ok(!html.includes('apps.apple.com') && !html.includes('play.google.com'), 'the page links to the stores through the site only');
    const plain = await (await site('/')).text();
    assert.ok(plain.includes('href="/go/apple"') && plain.includes('href="/go/play"'), 'an unknown device sees both stores, without a campaign');
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
    // The website's contact page is a real form posting to /api/contact.
    const contact = await (await site('/contact?lang=fr')).text();
    assert.ok(contact.includes('id="contact-form"') && contact.includes('/api/contact'), 'contact page has the form');

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
      const taps = sql`kind = 'store_tap' and store = 'apple' and device = 'iphone' and bot_family = ''`;
      const totals = async () => {
        const [row] = await sql`select visits, taps_apple from audience_totals where day = ${today}`;
        return { visits: (row?.visits ?? 0) as number, tapsApple: (row?.taps_apple ?? 0) as number };
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
      await fetch(`${BASE}/go/apple`, { redirect: 'manual', headers: { 'user-agent': IPHONE } });
      await visit({ ...person, dnt: '1' });
      await visit({ ...person, 'sec-gpc': '1' });
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
      assert.equal(await count(taps) - before.taps, 1, 'a tap on a store button is counted');
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
      await sql`delete from audience_counts where origin = ${origin}`;

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
      await db.$client.end();
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
  }

  // --- cleanup --------------------------------------------------------------
  r = await call('DELETE', '/api/auth/account');
  assert.equal(r.status, 200);
  if (sql) {
    const [{ n }] = await sql`select count(*)::int as n from subscription_events where user_id = ${userId}`;
    assert.equal(n, 0, 'deleting the account deletes its purchase events');
    await sql.end();
  }
  console.log('smoke: OK');
}

main().catch((err) => {
  console.error('smoke: FAILED');
  console.error(err);
  process.exit(1);
});
