import assert from 'node:assert/strict';
import { test } from 'node:test';
import { refusesTheRow, sqlState } from './pgError.js';

// The shapes seen in the logs: drizzle wraps the driver's error in `cause`.
const wrapped = (code: string) => Object.assign(new Error('Failed query'), { cause: Object.assign(new Error('db'), { code }) });

test('sqlState reads the code of a database error, through drizzle\'s wrapper', () => {
  assert.equal(sqlState(wrapped('22021')), '22021');
  assert.equal(sqlState(Object.assign(new Error('db'), { code: '23505' })), '23505');
});

test('sqlState is null for what is not the database\'s answer', () => {
  assert.equal(sqlState(wrapped('CONNECTION_CLOSED')), null, 'the driver lost its connection');
  assert.equal(sqlState(wrapped('ECONNRESET')), null);
  assert.equal(sqlState(new RangeError('Invalid time value')), null);
  assert.equal(sqlState(wrapped('2202')), null);
  assert.equal(sqlState('boom'), null);
  assert.equal(sqlState(null), null);
  assert.equal(sqlState(undefined), null);
});

test('a row the database refuses for what it holds would be refused again', () => {
  assert.equal(refusesTheRow(wrapped('22021')), true, 'a character the encoding refuses');
  assert.equal(refusesTheRow(wrapped('22P05')), true, 'a character jsonb refuses');
  assert.equal(refusesTheRow(wrapped('22001')), true, 'a value too long');
  assert.equal(refusesTheRow(wrapped('23503')), true, 'the account deleted a moment ago');
  assert.equal(refusesTheRow(wrapped('42P01')), true, 'the table missing after a rollback: the purchase still counts');
  assert.equal(refusesTheRow(wrapped('42703')), true, 'a column missing after a rollback');
});

test('a failure that may not happen again is not about the row', () => {
  assert.equal(refusesTheRow(wrapped('08006')), false, 'connection failure');
  assert.equal(refusesTheRow(wrapped('40001')), false, 'serialization failure');
  assert.equal(refusesTheRow(wrapped('40P01')), false, 'deadlock');
  assert.equal(refusesTheRow(wrapped('53300')), false, 'too many connections');
  assert.equal(refusesTheRow(wrapped('57014')), false, 'query cancelled');
  assert.equal(refusesTheRow(wrapped('57P01')), false, 'the database is shutting down');
  assert.equal(refusesTheRow(wrapped('55P03')), false, 'lock not available');
  assert.equal(refusesTheRow(wrapped('CONNECTION_CLOSED')), false, 'no answer from the database at all');
  assert.equal(refusesTheRow(new Error('boom')), false);
});
