import assert from 'node:assert/strict';
import { test } from 'node:test';
import { gzipSync } from 'node:zlib';
import { countryDatabaseUrl, createCountries } from './country.js';

const NOV = 'https://download.db-ip.com/free/dbip-country-lite-2026-11.mmdb.gz';
const OCT = 'https://download.db-ip.com/free/dbip-country-lite-2026-10.mmdb.gz';
const DEC = 'https://download.db-ip.com/free/dbip-country-lite-2026-12.mmdb.gz';

// A stand-in for the database file: the test's "database" is a JSON map from
// address to record, read by a stand-in opener. What the real reader makes of
// the real file is checked once by hand (see the plan, task 7).
const file = (records: Record<string, unknown>) => gzipSync(Buffer.from(JSON.stringify(records)));
const open = (database: Buffer) => {
  const records = JSON.parse(database.toString('utf8')) as Record<string, unknown>;
  return { get: (ip: string) => records[ip] ?? null };
};
const FRANCE = file({ '203.0.113.7': { country: { iso_code: 'FR' } }, '2001:db8::1': { country: { iso_code: 'DE' } } });

function setup(answers: Record<string, () => Response>, start = '2026-11-25T10:00:00Z') {
  let now = new Date(start);
  const asked: string[] = [];
  const warnings: string[] = [];
  const fetcher = (async (url: string | URL | Request) => {
    asked.push(String(url));
    const answer = answers[String(url)];
    return answer ? answer() : new Response('not found', { status: 404 });
  }) as typeof fetch;
  const countries = createCountries({ fetch: fetcher, now: () => now, open, warn: (message) => warnings.push(message), maxBytes: 1_000_000 });
  return { countries, asked, warnings, at: (iso: string) => { now = new Date(iso); } };
}
const ok = (body: Buffer) => () => new Response(new Uint8Array(body), { status: 200 });

test('the database of a month has its address', () => {
  assert.equal(countryDatabaseUrl(new Date('2026-11-25T10:00:00Z')), NOV);
  assert.equal(countryDatabaseUrl(new Date('2027-01-01T00:00:00Z')), 'https://download.db-ip.com/free/dbip-country-lite-2027-01.mmdb.gz');
  assert.equal(countryDatabaseUrl(new Date('2026-12-31T23:59:59Z')), DEC);
});

test('before the database is loaded, every country is unknown', () => {
  const { countries } = setup({});
  assert.equal(countries.countryOf('203.0.113.7'), '');
});

test('once loaded, an address gives its country', async () => {
  const { countries, asked } = setup({ [NOV]: ok(FRANCE) });
  await countries.refresh();
  assert.deepEqual(asked, [NOV]);
  assert.equal(countries.countryOf('203.0.113.7'), 'FR');
  assert.equal(countries.countryOf('2001:db8::1'), 'DE');
  assert.equal(countries.countryOf('::ffff:203.0.113.7'), 'FR', 'an IPv4 address written as IPv6');
  assert.equal(countries.countryOf('198.51.100.1'), '', 'an address the database does not know');
});

test('what is not an address has no country, and never throws', async () => {
  const { countries } = setup({ [NOV]: ok(FRANCE) });
  await countries.refresh();
  assert.equal(countries.countryOf(undefined), '');
  assert.equal(countries.countryOf(''), '');
  assert.equal(countries.countryOf('abc'), '');
  assert.equal(countries.countryOf('203.0.113.7:443'), '');
});

test('a record of an unexpected shape gives no country', async () => {
  const { countries } = setup({ [NOV]: ok(file({
    '192.0.2.1': { country: { iso_code: 42 } }, '192.0.2.2': { country: null }, '192.0.2.3': 'FR',
    '192.0.2.4': { country: { iso_code: 'FRA' } }, '192.0.2.5': { country: { iso_code: 'fr' } }, '192.0.2.6': { country: { iso_code: '<b' } },
  })) });
  await countries.refresh();
  for (const ip of ['192.0.2.1', '192.0.2.2', '192.0.2.3', '192.0.2.4', '192.0.2.6']) assert.equal(countries.countryOf(ip), '', ip);
  assert.equal(countries.countryOf('192.0.2.5'), 'FR', 'two letters, in capitals');
});

test('on the first of the month the new file may not be out yet: last month\'s is used', async () => {
  const { countries, asked } = setup({ [OCT]: ok(FRANCE) });
  await countries.refresh();
  assert.deepEqual(asked, [NOV, OCT]);
  assert.equal(countries.countryOf('203.0.113.7'), 'FR');
});

test('a file already loaded is not downloaded again; a new month is', async () => {
  const december = file({ '203.0.113.7': { country: { iso_code: 'BE' } } });
  const { countries, asked, at } = setup({ [NOV]: ok(FRANCE), [DEC]: ok(december) });
  await countries.refresh();
  await countries.refresh();
  assert.deepEqual(asked, [NOV], 'once');
  at('2026-12-02T10:00:00Z');
  await countries.refresh();
  assert.deepEqual(asked, [NOV, DEC]);
  assert.equal(countries.countryOf('203.0.113.7'), 'BE', 'the new file answers');
});

test('a month whose file is missing keeps the one loaded, and asks again the next day', async () => {
  const { countries, asked, at } = setup({ [NOV]: ok(FRANCE) });
  await countries.refresh();
  at('2026-12-01T10:00:00Z');
  await countries.refresh();
  assert.deepEqual(asked, [NOV, DEC], 'last month\'s is the one already loaded: not asked for again');
  assert.equal(countries.countryOf('203.0.113.7'), 'FR');
  await countries.refresh();
  assert.deepEqual(asked, [NOV, DEC, DEC]);
});

for (const [what, body] of [
  ['is cut short', FRANCE.subarray(0, FRANCE.length - 12)],
  ['is not compressed', Buffer.from(JSON.stringify({ '203.0.113.7': { country: { iso_code: 'XX' } } }))],
  ['is not a database once unpacked', gzipSync(Buffer.from('not a database'))],
  ['unpacks to more than the limit', gzipSync(Buffer.alloc(1_000_001, 0x20))],
  ['is larger than the limit as sent', Buffer.alloc(1_000_001, 1)],
] as Array<[string, Buffer]>) {
  test(`a file that ${what} is refused: no exception, the database loaded before stays`, async () => {
    const { countries, warnings, at } = setup({ [NOV]: ok(FRANCE), [DEC]: ok(body) });
    await countries.refresh();
    at('2026-12-02T10:00:00Z');
    await countries.refresh();
    assert.equal(countries.countryOf('203.0.113.7'), 'FR');
    assert.equal(warnings.length, 1, 'said once');
  });
}

test('with nothing loaded and nothing to load, countries stay unknown', async () => {
  const { countries, asked, warnings } = setup({});
  await countries.refresh();
  assert.deepEqual(asked, [NOV, OCT]);
  assert.equal(countries.countryOf('203.0.113.7'), '');
  assert.equal(warnings.length, 1);
});
