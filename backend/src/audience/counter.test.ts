import assert from 'node:assert/strict';
import { test } from 'node:test';
import { createCounter, rollUpBefore, type Batch, type Hit } from './counter.js';

const person: Hit = {
  kind: 'visit', store: '', origin: 'pinterest.com', originFrom: 'referer', tagged: false,
  device: 'iphone', browser: 'safari', inApp: '', lang: 'fr', country: 'FR', botFamily: '', botName: '', botCheck: '',
};
const robot: Hit = {
  kind: 'visit', store: '', origin: '', originFrom: '', tagged: false,
  device: '', browser: '', inApp: '', lang: '', country: '', botFamily: 'ai_user', botName: 'ChatGPT-User', botCheck: 'verified',
};
const tap = (store: 'apple' | 'play', more: Partial<Hit> = {}): Hit => ({ ...person, kind: 'store_tap', store, origin: '', originFrom: '', ...more });

function setup(limits: { maxOrigins?: number; maxBotNames?: number; maxRows?: number } = {}) {
  let now = new Date('2026-11-25T10:00:00Z');
  const written: Batch[] = [];
  const warnings: string[] = [];
  let failing = false;
  const counter = createCounter({
    write: async (batch) => {
      if (failing) throw new Error('database down');
      written.push(batch);
    },
    now: () => now,
    warn: (message) => warnings.push(message),
    ...limits,
  });
  return { counter, written, warnings, at: (iso: string) => { now = new Date(iso); }, fail: (on: boolean) => { failing = on; } };
}
const rows = (batch: Batch) => batch.counts.map((row) => `${row.day} ${row.kind} ${row.origin || row.botName} ${row.count}`).sort();

test('identical visits are one row with their number; a different one is another row', async () => {
  const { counter, written } = setup();
  counter.add(person, true);
  counter.add(person, false);
  counter.add(person, false);
  counter.add({ ...person, country: 'BE' }, true);
  await counter.flush();
  assert.equal(written.length, 1);
  assert.deepEqual(written[0].counts.map((row) => [row.day, row.country, row.count]).sort(), [['2026-11-25', 'BE', 1], ['2026-11-25', 'FR', 3]]);
  assert.deepEqual(written[0].counts[0], { ...person, day: '2026-11-25', count: 3 }, 'a row is the hit, its day and its number');
});

test('the totals of the day count people only', async () => {
  const { counter, written } = setup();
  counter.add(person, true);
  counter.add(person, false);
  counter.add(robot, false);
  counter.add(tap('apple'), false);
  counter.add(tap('play'), false);
  counter.add(tap('play'), false);
  counter.add(tap('apple', { botFamily: 'other', botName: 'curl', botCheck: 'unverifiable', device: '', browser: '', lang: '', country: '' }), false);
  await counter.flush();
  assert.deepEqual(written[0].totals, [{ day: '2026-11-25', visits: 2, visitors: 1, tapsApple: 1, tapsPlay: 2 }]);
  assert.equal(written[0].counts.length, 5, 'the robots are in the rows, not in the totals');
});

test('a robot never counts as a new visitor, whatever the caller says', async () => {
  const { counter, written } = setup();
  counter.add(robot, true);
  await counter.flush();
  assert.deepEqual(written[0].totals, [], 'a day with robots only has no total');
});

test('each visit falls in its own day (UTC)', async () => {
  const { counter, written, at } = setup();
  at('2026-11-25T23:59:59Z');
  counter.add(person, true);
  at('2026-11-26T00:00:01Z');
  counter.add(person, true);
  await counter.flush();
  assert.deepEqual(rows(written[0]), ['2026-11-25 visit pinterest.com 1', '2026-11-26 visit pinterest.com 1']);
  assert.deepEqual(written[0].totals.map((t) => [t.day, t.visits, t.visitors]).sort(), [['2026-11-25', 1, 1], ['2026-11-26', 1, 1]]);
});

test('nothing waiting, nothing written', async () => {
  const { counter, written } = setup();
  await counter.flush();
  counter.add(person, true);
  await counter.flush();
  await counter.flush();
  assert.equal(written.length, 1);
});

test('a write that fails loses nothing: the next one carries it all', async () => {
  const { counter, written, fail, warnings } = setup();
  counter.add(person, true);
  fail(true);
  await counter.flush();
  counter.add(person, false);
  counter.add(robot, false);
  await counter.flush();
  assert.equal(written.length, 0);
  fail(false);
  await counter.flush();
  assert.deepEqual(rows(written[0]), ['2026-11-25 visit ChatGPT-User 1', '2026-11-25 visit pinterest.com 2']);
  assert.deepEqual(written[0].totals, [{ day: '2026-11-25', visits: 2, visitors: 1, tapsApple: 0, tapsPlay: 0 }]);
  assert.deepEqual(warnings, []);
});

test('after ten failed writes in a row, what waits is dropped and said once: memory stays bounded', async () => {
  const { counter, written, fail, warnings } = setup();
  fail(true);
  for (let i = 0; i < 10; i++) {
    counter.add(person, false);
    await counter.flush();
  }
  assert.equal(warnings.length, 1);
  assert.match(warnings[0], /10 visits/);
  fail(false);
  await counter.flush();
  assert.equal(written.length, 0, 'nothing is left to write');
  counter.add(person, false);
  await counter.flush();
  assert.deepEqual(rows(written[0]), ['2026-11-25 visit pinterest.com 1'], 'and counting goes on');
});

test('a flush that starts while another is writing waits its turn: nothing is written twice', async () => {
  let release: () => void = () => {};
  const written: Batch[] = [];
  const counter = createCounter({
    write: (batch) => new Promise((resolve) => { written.push(batch); release = resolve; }),
    now: () => new Date('2026-11-25T10:00:00Z'),
  });
  counter.add(person, true);
  const first = counter.flush();
  counter.add(person, false);
  await counter.flush();
  assert.equal(written.length, 1, 'the second flush returns at once: a write is in flight');
  release();
  await first;
  const third = counter.flush();
  release();
  await third;
  assert.deepEqual(written.map((batch) => batch.counts.map((row) => row.count)), [[1], [1]], 'the visit added meanwhile goes with the next write');
});

test('the sites of origin of a day are bounded: past the limit a new one is "other", the rest of the visit is kept', async () => {
  const { counter, written } = setup({ maxOrigins: 3 });
  for (const site of ['a.com', 'b.com', 'c.com', 'd.com', 'e.com', 'a.com']) counter.add({ ...person, origin: site }, false);
  await counter.flush();
  assert.deepEqual(rows(written[0]), ['2026-11-25 visit a.com 2', '2026-11-25 visit b.com 1', '2026-11-25 visit c.com 1', '2026-11-25 visit other 2']);
  const other = written[0].counts.find((row) => row.origin === 'other')!;
  assert.deepEqual([other.device, other.browser, other.country, other.lang], ['iphone', 'safari', 'FR', 'fr']);
});

test('the names of robots of a day are bounded the same way', async () => {
  const { counter, written } = setup({ maxBotNames: 2 });
  for (const name of ['One', 'Two', 'Three', 'Four', 'One']) counter.add({ ...robot, botFamily: 'other', botName: name, botCheck: 'unverifiable' }, false);
  await counter.flush();
  assert.deepEqual(rows(written[0]), ['2026-11-25 visit One 2', '2026-11-25 visit Two 1', '2026-11-25 visit other 2']);
});

test('the rows of a day are bounded: past the limit everything new falls in one row per kind', async () => {
  const { counter, written } = setup({ maxRows: 3 });
  for (const country of ['FR', 'BE', 'CH', 'CA', 'LU', 'FR']) counter.add({ ...person, country }, false);
  counter.add(tap('apple', { country: 'CA' }), false);
  counter.add(robot, false);
  await counter.flush();
  const kept = written[0].counts.filter((row) => row.origin === 'pinterest.com').map((row) => `${row.country} ${row.count}`).sort();
  assert.deepEqual(kept, ['BE 1', 'CH 1', 'FR 2']);
  const rest = written[0].counts.filter((row) => row.origin !== 'pinterest.com');
  const blank = { origin: 'other', originFrom: '', tagged: false, device: 'other', browser: 'other', inApp: '', lang: '', country: '', botFamily: '', botName: '', botCheck: '' };
  assert.deepEqual(rest.find((row) => row.kind === 'visit' && row.botFamily === ''), { ...blank, kind: 'visit', store: '', day: '2026-11-25', count: 2 }, 'the people past the limit');
  assert.deepEqual(rest.find((row) => row.kind === 'store_tap'), { ...blank, kind: 'store_tap', store: 'apple', day: '2026-11-25', count: 1 }, 'a tap keeps its store');
  assert.deepEqual(rest.find((row) => row.botFamily !== ''), { ...robot, botName: 'other', botCheck: '', day: '2026-11-25', count: 1 }, 'a robot keeps its family');
  assert.equal(rest.length, 3);
  assert.deepEqual(written[0].totals, [{ day: '2026-11-25', visits: 6, visitors: 0, tapsApple: 1, tapsPlay: 0 }], 'the totals still count everyone');
});

test('the limits start again with the day', async () => {
  const { counter, written, at } = setup({ maxOrigins: 1 });
  counter.add({ ...person, origin: 'a.com' }, false);
  counter.add({ ...person, origin: 'b.com' }, false);
  at('2026-11-26T08:00:00Z');
  counter.add({ ...person, origin: 'b.com' }, false);
  await counter.flush();
  assert.deepEqual(rows(written[0]), ['2026-11-25 visit a.com 1', '2026-11-25 visit other 1', '2026-11-26 visit b.com 1']);
});

test('add never throws, whatever it is given', () => {
  const { counter } = setup();
  assert.doesNotThrow(() => counter.add(null as unknown as Hit, true));
  assert.doesNotThrow(() => counter.add({} as Hit, true));
});

test('daily rows are kept 25 full months: the days before that month are rolled up', () => {
  assert.equal(rollUpBefore(new Date('2026-11-25T10:00:00Z')), '2024-10-01');
  assert.equal(rollUpBefore(new Date('2026-11-01T00:00:00Z')), '2024-10-01');
  assert.equal(rollUpBefore(new Date('2026-11-30T23:59:59Z')), '2024-10-01');
  assert.equal(rollUpBefore(new Date('2027-01-15T10:00:00Z')), '2024-12-01');
  assert.equal(rollUpBefore(new Date('2027-02-01T00:00:00Z')), '2025-01-01');
});
