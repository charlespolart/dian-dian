import assert from 'node:assert/strict';
import { test } from 'node:test';
import { keptSince, runRetentionPurge } from './retention.js';

const at = (iso: string) => keptSince(new Date(iso), 13).toISOString();

test('13 months kept: the current month and the 12 before it', () => {
  assert.equal(at('2026-11-26T10:00:00Z'), '2025-11-01T00:00:00.000Z');
  assert.equal(at('2026-11-30T23:59:59Z'), '2025-11-01T00:00:00.000Z', 'the last second of a month');
  assert.equal(at('2026-12-01T00:00:00Z'), '2025-12-01T00:00:00.000Z', 'the first instant of the next one');
  assert.equal(at('2027-01-31T12:00:00Z'), '2026-01-01T00:00:00.000Z', 'across a year, from a 31st');
});

test('the month is the UTC one, wherever the server runs', () => {
  // 23:30 on 31 March in New York is already 1 April in UTC.
  assert.equal(at('2026-03-31T23:30:00-05:00'), '2025-04-01T00:00:00.000Z');
});

test('on any day, at least twelve months are kept and nothing kept is older than thirteen', () => {
  const DAY = 24 * 60 * 60 * 1000;
  for (let now = Date.UTC(2026, 0, 1, 12); now <= Date.UTC(2029, 11, 31, 12); now += DAY) {
    const days = (now - keptSince(new Date(now), 13).getTime()) / DAY;
    assert.ok(days >= 365 && days < 398, `${new Date(now).toISOString()}: the limit is ${days} days back`);
  }
});

test('a purge that fails is logged and never thrown', async () => {
  const logged: unknown[][] = [];
  const said: unknown[][] = [];
  const down = { delete() { throw new Error('down'); } } as unknown as Parameters<typeof runRetentionPurge>[0];
  await runRetentionPurge(down, new Date('2026-11-26T10:00:00Z'), { log: (...args) => { said.push(args); }, error: (...args) => { logged.push(args); } });
  assert.equal(logged.length, 1);
  assert.match(String(logged[0][0]), /^Retention purge failed:/);
  assert.equal(said.length, 0, 'nothing else is said');
});
