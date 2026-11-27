import assert from 'node:assert/strict';
import { test } from 'node:test';
import { syncBatchCounts, weekOf } from './syncStats.js';

test('a week starts on Monday, UTC', () => {
  assert.equal(weekOf(new Date('2026-11-27T10:00:00Z')), '2026-11-23'); // a Friday
  assert.equal(weekOf(new Date('2026-11-23T00:00:00Z')), '2026-11-23'); // the Monday itself
  assert.equal(weekOf(new Date('2026-11-22T23:59:59Z')), '2026-11-16'); // the Sunday before
});

test('what a batch adds to the week: syncs with changes that waited, how many, and what was set aside and why', () => {
  assert.deepEqual(syncBatchCounts(2, [
    { id: 'a', status: 'applied', revs: {} },
    { id: 'b', status: 'changed', current: null },
    { id: 'c', status: 'deleted' },
    { id: 'd', status: 'rejected', reason: 'legend_limit' },
  ]), { syncs_with_waited: 1, mutations_waited: 2, set_aside_changed: 1, set_aside_deleted: 1, rejected_legend_limit: 1 });
  assert.deepEqual(syncBatchCounts(0, [{ id: 'a', status: 'applied', revs: {} }]), {}, 'a batch made online counts nothing');
});
