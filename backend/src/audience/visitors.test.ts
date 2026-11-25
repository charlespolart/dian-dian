import assert from 'node:assert/strict';
import { test } from 'node:test';
import { createVisitors } from './visitors.js';

const UA = 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_6 like Mac OS X) Safari/604.1';
const SITE = 'diandian.overridedev.com';

function setup(max?: number) {
  let now = new Date('2026-11-25T10:00:00Z');
  let salts = 0;
  const visitors = createVisitors({
    now: () => now,
    // A different salt each time it is asked for one.
    randomBytes: (n) => Buffer.alloc(n, ++salts),
    max,
  });
  return { visitors, at: (iso: string) => { now = new Date(iso); }, salts: () => salts };
}

test('the same visitor is new once a day', () => {
  const { visitors } = setup();
  assert.equal(visitors.isNew(SITE, '203.0.113.7', UA), true);
  assert.equal(visitors.isNew(SITE, '203.0.113.7', UA), false);
  assert.equal(visitors.isNew(SITE, '203.0.113.7', UA), false);
});

test('another address, another browser or another site is another visitor', () => {
  const { visitors } = setup();
  assert.equal(visitors.isNew(SITE, '203.0.113.7', UA), true);
  assert.equal(visitors.isNew(SITE, '203.0.113.8', UA), true);
  assert.equal(visitors.isNew(SITE, '203.0.113.7', `${UA} x`), true);
  assert.equal(visitors.isNew('other.example', '203.0.113.7', UA), true);
});

test('the three parts are kept apart: moving a character from one to the next changes the visitor', () => {
  const { visitors } = setup();
  assert.equal(visitors.isNew('a', 'bc', 'd'), true);
  assert.equal(visitors.isNew('ab', 'c', 'd'), true);
  assert.equal(visitors.isNew('a', 'b', 'cd'), true);
});

test('at midnight UTC the salt is drawn again and everyone is new', () => {
  const { visitors, at, salts } = setup();
  at('2026-11-25T23:59:59Z');
  assert.equal(visitors.isNew(SITE, '203.0.113.7', UA), true);
  assert.equal(salts(), 1);
  at('2026-11-26T00:00:01Z');
  assert.equal(visitors.isNew(SITE, '203.0.113.7', UA), true, 'a new day');
  assert.equal(salts(), 2, 'a new salt');
  assert.equal(visitors.isNew(SITE, '203.0.113.7', UA), false);
  assert.equal(salts(), 2, 'one salt per day');
});

test('the fingerprint depends on the salt: yesterday\'s cannot be recomputed', () => {
  // With the same salt, a visitor seen is seen. Here the salt changes with the day.
  const { visitors, at } = setup();
  visitors.isNew(SITE, '203.0.113.7', UA);
  at('2026-11-26T10:00:00Z');
  visitors.isNew(SITE, '203.0.113.9', UA); // the day turns: yesterday's fingerprints are gone
  at('2026-11-25T10:00:00Z');
  assert.equal(visitors.isNew(SITE, '203.0.113.7', UA), true, 'back on the first day with a third salt: not recognised');
});

test('memory is bounded: past the limit nobody is new any more', () => {
  const { visitors } = setup(3);
  assert.equal(visitors.isNew(SITE, '1', UA), true);
  assert.equal(visitors.isNew(SITE, '2', UA), true);
  assert.equal(visitors.isNew(SITE, '3', UA), true);
  assert.equal(visitors.isNew(SITE, '4', UA), false, 'the fourth is not counted');
  assert.equal(visitors.isNew(SITE, '1', UA), false, 'and those seen are still seen');
});
