import assert from 'node:assert/strict';
import { test } from 'node:test';
import { isLoopbackUrl } from './loopback.js';

test('a server or a database on this machine is loopback', () => {
  assert.equal(isLoopbackUrl('http://localhost:3001'), true);
  assert.equal(isLoopbackUrl('http://127.0.0.1:3001'), true);
  assert.equal(isLoopbackUrl('http://[::1]:3001'), true);
  assert.equal(isLoopbackUrl('http://LOCALHOST:3001/api'), true);
  assert.equal(isLoopbackUrl('postgres://postgres:password@localhost:5432/dian_dian_test'), true, 'the database of the release checks');
  assert.equal(isLoopbackUrl('postgresql://user:secret@Localhost:5433/dian_dian'), true);
  assert.equal(isLoopbackUrl('postgres://user@127.0.0.1/dian_dian'), true);
});

test('anything else is not', () => {
  assert.equal(isLoopbackUrl('https://diandian.overridedev.com'), false);
  assert.equal(isLoopbackUrl('http://45.76.44.34:3001'), false);
  assert.equal(isLoopbackUrl('http://localhost.example.com'), false, 'a name that only starts like localhost');
  assert.equal(isLoopbackUrl('http://127.0.0.1.example.com'), false);
  assert.equal(isLoopbackUrl('postgres://user:secret@db.internal:5432/dian_dian'), false);
});

test('what cannot be read is not loopback: the doubt goes to the safe side', () => {
  assert.equal(isLoopbackUrl(undefined), false);
  assert.equal(isLoopbackUrl(''), false);
  assert.equal(isLoopbackUrl('localhost:3001'), false, 'no scheme: the host cannot be read');
  assert.equal(isLoopbackUrl('not a url'), false);
  assert.equal(isLoopbackUrl('postgres:///dian_dian?host=/tmp'), false, 'a socket path names no host');
});
