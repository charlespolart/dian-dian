import assert from 'node:assert/strict';
import { test } from 'node:test';
import { lockedPageIdsFor, type LockablePage } from './trackerLock.js';

const page = (id: string, p: Partial<LockablePage> = {}): LockablePage => ({
  id, createdAt: new Date('2026-01-01'), keepFree: false, recentCells: 0, lastCellAt: null, ...p,
});

test('nothing locked at or under the limit', () => {
  assert.deepEqual(lockedPageIdsFor([page('a'), page('b'), page('c')], 3), new Set());
});

test('without a choice the most active stay open (recent cells, then last cell, then age)', () => {
  const pages = [
    page('a', { recentCells: 1, lastCellAt: new Date('2026-09-01') }),
    page('b'),
    page('c', { recentCells: 30, lastCellAt: new Date('2026-10-15') }),
    page('d', { recentCells: 2, lastCellAt: new Date('2026-10-01') }),
    page('e', { createdAt: new Date('2025-01-01') }),
  ];
  assert.deepEqual(lockedPageIdsFor(pages, 3), new Set(['b', 'e']));
});

test('kept pages win over activity, completed by activity when fewer than the limit', () => {
  const pages = [
    page('a', { recentCells: 99, lastCellAt: new Date('2026-10-15') }),
    page('b', { keepFree: true }),
    page('c', { recentCells: 1 }),
    page('d'),
  ];
  assert.deepEqual(lockedPageIdsFor(pages, 3), new Set(['d']));
});

test('more kept than the limit: the oldest kept stay', () => {
  const pages = [
    page('a', { createdAt: new Date('2026-03-01'), keepFree: true }),
    page('b', { createdAt: new Date('2026-01-01'), keepFree: true }),
    page('c', { createdAt: new Date('2026-02-01'), keepFree: true }),
    page('d', { createdAt: new Date('2026-04-01'), keepFree: true }),
    page('e'),
  ];
  assert.deepEqual(lockedPageIdsFor(pages, 3), new Set(['d', 'e']));
});
