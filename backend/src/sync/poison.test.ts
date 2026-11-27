/**
 * One change the server cannot apply must not hold the phone's queue back
 * forever (review, minor 8): it is refused, the next ones go. A failure of
 * the moment is not a refusal: the phone sends the batch again.
 */
import assert from 'node:assert/strict';
import { test } from 'node:test';
import { refusedForGood } from './poison.js';

const pg = (code: string) => Object.assign(new Error('db'), { cause: { code } });

test('the database refusing what it was asked to write: refused for good', () => {
  assert.equal(refusedForGood(pg('22001')), true, 'value too long');
  assert.equal(refusedForGood(pg('23503')), true, 'a reference to a row deleted since');
});

test('a bug in the code (a type error) is refused too, and logged by the caller', () => {
  assert.equal(refusedForGood(new TypeError("Cannot read properties of undefined (reading 'id')")), true);
  assert.equal(refusedForGood(new RangeError('Invalid time value')), true);
});

test('a failure of the moment is not: the batch is answered 500 and sent again', () => {
  assert.equal(refusedForGood(pg('40001')), false, 'serialization');
  assert.equal(refusedForGood(pg('08006')), false, 'connection');
  assert.equal(refusedForGood(Object.assign(new Error('read ECONNRESET'), { code: 'ECONNRESET' })), false);
});
