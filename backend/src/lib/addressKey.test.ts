import assert from 'node:assert/strict';
import { test } from 'node:test';
import { addressKey } from './addressKey.js';

test('an IPv4 address counts alone', () => {
  assert.equal(addressKey('203.0.113.7'), '203.0.113.7');
  assert.equal(addressKey('::ffff:203.0.113.7'), '203.0.113.7', 'IPv4 mapped into IPv6 is the same address');
});

test('IPv6 counts by /56: one customer\'s whole prefix is one address (case 63)', () => {
  assert.equal(addressKey('2001:db8:abcd:1234::1'), '2001:db8:abcd:1200::/56');
  assert.equal(addressKey('2001:db8:abcd:12ff:ffff:ffff:ffff:ffff'), '2001:db8:abcd:1200::/56');
  assert.equal(addressKey('2001:DB8:ABCD:12A0::9'), '2001:db8:abcd:1200::/56');
  assert.notEqual(addressKey('2001:db8:abcd:1300::1'), addressKey('2001:db8:abcd:1200::1'));
  assert.equal(addressKey('::1'), '0:0:0:0::/56');
  assert.equal(addressKey('fe80::1%en0'), 'fe80:0:0:0::/56', 'a zone is dropped');
  assert.equal(addressKey('64:ff9b::192.0.2.33'), '64:ff9b:0:0::/56', 'an embedded IPv4 tail is read as two groups');
});

test('no address at all is one bucket, never a crash', () => {
  assert.equal(addressKey(undefined), 'unknown');
  assert.equal(addressKey(''), 'unknown');
});
