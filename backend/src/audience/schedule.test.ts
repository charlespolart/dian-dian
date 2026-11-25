import assert from 'node:assert/strict';
import { test } from 'node:test';
import { keepFresh } from './schedule.js';

/** Timers by hand: `delays` is every delay asked for, `fire` runs the pending one. */
function clock() {
  const delays: number[] = [];
  let pending: (() => void) | null = null;
  return {
    delays,
    setTimer: (run: () => void, ms: number) => { delays.push(ms); pending = run; },
    fire: async () => { const run = pending; pending = null; run?.(); await new Promise((resolve) => setImmediate(resolve)); },
  };
}
const TIMES = { first: 3_000, every: 86_400_000, retry: 900_000 };

test('the first run waits a moment, then a success is refreshed a day later', async () => {
  const { delays, setTimer, fire } = clock();
  let runs = 0;
  keepFresh(async () => { runs++; return true; }, { ...TIMES, setTimer });
  assert.equal(runs, 0, 'nothing runs at once: a server that restarts in a loop does not hammer the source');
  assert.deepEqual(delays, [3_000]);
  await fire();
  assert.equal(runs, 1);
  assert.deepEqual(delays, [3_000, 86_400_000]);
});

test('a failure is tried again soon, and again, until it works', async () => {
  const { delays, setTimer, fire } = clock();
  const results = [false, false, true];
  keepFresh(async () => results.shift() ?? true, { ...TIMES, setTimer });
  await fire();
  await fire();
  await fire();
  assert.deepEqual(delays, [3_000, 900_000, 900_000, 86_400_000]);
});

test('a task that throws counts as a failure and never stops the schedule', async () => {
  const { delays, setTimer, fire } = clock();
  keepFresh(async () => { throw new Error('boom'); }, { ...TIMES, setTimer });
  await fire();
  await fire();
  assert.deepEqual(delays, [3_000, 900_000, 900_000]);
});
