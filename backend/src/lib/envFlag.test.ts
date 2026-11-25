import assert from 'node:assert/strict';
import { test } from 'node:test';
import { envFlag } from './envFlag.js';

test('a setting says on or off in the usual ways', () => {
  for (const value of ['on', 'ON', 'true', '1', 'yes', ' on ']) assert.equal(envFlag(value, false), true, value);
  for (const value of ['off', 'OFF', 'false', '0', 'no', ' off ']) assert.equal(envFlag(value, true), false, value);
});

test('a setting that is absent, empty or unreadable keeps its default', () => {
  for (const value of [undefined, '', '  ', 'maybe', 'production']) {
    assert.equal(envFlag(value, true), true, String(value));
    assert.equal(envFlag(value, false), false, String(value));
  }
});
