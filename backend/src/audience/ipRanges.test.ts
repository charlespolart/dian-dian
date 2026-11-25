import assert from 'node:assert/strict';
import { test } from 'node:test';
import { BOT_RANGES } from './bots.js';
import { RANGE_SOURCES, createIpRanges } from './ipRanges.js';

const LIST = { creationTime: '2026-11-06T00:00:00', prefixes: [{ ipv4Prefix: '203.0.113.0/24' }, { ipv6Prefix: '2001:db8:1234::/48' }] };
const json = (body: unknown, status = 200) => new Response(JSON.stringify(body), { status, headers: { 'content-type': 'application/json' } });
const SOURCES = { one: 'https://example.com/one.json', two: 'https://example.com/two.json' };

/** A fetch that answers each URL with what `answers` holds (a Response, or an error to throw). */
function fakeFetch(answers: Record<string, () => Response | Promise<Response>>) {
  const calls: Array<{ url: string; signal: AbortSignal | null | undefined }> = [];
  const fetcher = (async (url: string | URL | Request, init?: RequestInit) => {
    calls.push({ url: String(url), signal: init?.signal });
    const answer = answers[String(url)];
    if (!answer) throw new Error(`unexpected fetch of ${String(url)}`);
    return answer();
  }) as typeof fetch;
  return { fetcher, calls };
}

async function loaded(one: () => Response | Promise<Response> = () => json(LIST)) {
  const { fetcher, calls } = fakeFetch({ [SOURCES.one]: one, [SOURCES.two]: () => json({ prefixes: [{ ipv4Prefix: '198.51.100.0/24' }] }) });
  const warnings: string[] = [];
  const ranges = createIpRanges({ fetch: fetcher, sources: SOURCES, warn: (message) => warnings.push(message) });
  await ranges.refresh();
  return { ranges, calls, warnings };
}

test('every list a robot of the table names has a source', () => {
  for (const name of BOT_RANGES) assert.ok(Object.hasOwn(RANGE_SOURCES, name), name);
  assert.equal(Object.keys(RANGE_SOURCES).length, 14);
  for (const url of Object.values(RANGE_SOURCES)) assert.match(url, /^https:\/\//);
});

test('an address inside the operator\'s ranges is verified, outside it is not', async () => {
  const { ranges } = await loaded();
  assert.equal(ranges.check('one', '203.0.113.7'), 'verified');
  assert.equal(ranges.check('one', '203.0.114.7'), 'unverified');
  assert.equal(ranges.check('one', '2001:db8:1234:5678::1'), 'verified');
  assert.equal(ranges.check('one', '2001:db8:9999::1'), 'unverified');
  assert.equal(ranges.check('two', '203.0.113.7'), 'unverified', 'each list is its own');
  assert.equal(ranges.check('two', '198.51.100.20'), 'verified');
});

test('an IPv4 address written as IPv6 is read as IPv4', async () => {
  const { ranges } = await loaded();
  assert.equal(ranges.check('one', '::ffff:203.0.113.7'), 'verified');
  assert.equal(ranges.check('one', '::FFFF:203.0.114.7'), 'unverified');
});

test('a robot whose operator publishes no ranges is unverifiable, whatever its address', async () => {
  const { ranges } = await loaded();
  assert.equal(ranges.check(null, '203.0.113.7'), 'unverifiable');
  assert.equal(ranges.check(null, undefined), 'unverifiable');
});

test('what cannot be checked is unverified, never an exception', async () => {
  const fresh = createIpRanges({ fetch: fakeFetch({}).fetcher, sources: SOURCES });
  assert.equal(fresh.check('one', '203.0.113.7'), 'unverified', 'before the lists are loaded');
  const { ranges } = await loaded();
  assert.equal(ranges.check('one', undefined), 'unverified');
  assert.equal(ranges.check('one', ''), 'unverified');
  assert.equal(ranges.check('one', 'abc'), 'unverified');
  assert.equal(ranges.check('one', '203.0.113.7:443'), 'unverified');
  assert.equal(ranges.check('nope', '203.0.113.7'), 'unverified', 'a list that does not exist');
});

test('each download has a time limit', async () => {
  const { calls } = await loaded();
  assert.equal(calls.length, 2);
  for (const call of calls) assert.ok(call.signal instanceof AbortSignal, call.url);
});

for (const [what, answer] of [
  ['the network fails', () => { throw new Error('ENOTFOUND'); }],
  ['the server answers 500', () => json(LIST, 500)],
  ['the answer is a web page', () => new Response('<!doctype html><html><body>blocked</body></html>', { status: 200 })],
  ['the JSON has no prefixes', () => json({ creationTime: 'x' })],
  ['the JSON is a list of nothing usable', () => json({ prefixes: [{ ipv4Prefix: 'not-an-address/24' }, { other: 1 }, 'x', null] })],
  ['the answer is larger than 2 MB', () => new Response(JSON.stringify({ prefixes: [{ ipv4Prefix: '203.0.113.0/24' }], padding: 'x'.repeat(2_100_000) }), { status: 200 })],
] as Array<[string, () => Response]>) {
  test(`${what}: no exception, and the list loaded before stays in service`, async () => {
    let fail = false;
    const { ranges, warnings } = await loaded(() => (fail ? answer() : json(LIST)));
    assert.deepEqual(warnings, []);
    fail = true;
    await ranges.refresh();
    assert.deepEqual(warnings, ['Audience: IP ranges not loaded: one'], 'the failure is said, once, with the name of the list');
    assert.equal(ranges.check('one', '203.0.113.7'), 'verified', 'the earlier list still answers');
    assert.equal(ranges.check('two', '198.51.100.20'), 'verified', 'and the other list was refreshed all the same');
  });
}

test('a file with a bad prefix among good ones gives the good ones', async () => {
  const { ranges } = await loaded(() => json({ prefixes: [{ ipv4Prefix: '203.0.113.0/24' }, { ipv4Prefix: '999.1.1.1/24' }, { ipv4Prefix: '10.0.0.0/99' }, { ipv6Prefix: 'zz::/32' }, { ipv4Prefix: '192.0.2.0/24' }] }));
  assert.equal(ranges.check('one', '203.0.113.7'), 'verified');
  assert.equal(ranges.check('one', '192.0.2.9'), 'verified');
  assert.equal(ranges.check('one', '10.0.0.1'), 'unverified');
});

test('a refreshed list replaces the one before it', async () => {
  let second = false;
  const { ranges } = await loaded(() => json(second ? { prefixes: [{ ipv4Prefix: '192.0.2.0/24' }] } : LIST));
  second = true;
  await ranges.refresh();
  assert.equal(ranges.check('one', '192.0.2.9'), 'verified');
  assert.equal(ranges.check('one', '203.0.113.7'), 'unverified', 'a range the operator dropped no longer verifies');
});
