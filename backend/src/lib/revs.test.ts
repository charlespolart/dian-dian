import assert from 'node:assert/strict';
import { test } from 'node:test';
import { cellKey } from './revs.js';

test('a day is keyed by its tracker and its date, zero-padded', () => {
  assert.equal(cellKey('0b7f6c1e-1111-4222-8333-944455556666', 2026, 3, 1), '0b7f6c1e-1111-4222-8333-944455556666:2026-03-01');
  assert.equal(cellKey('p', 2025, 12, 31), 'p:2025-12-31');
});
