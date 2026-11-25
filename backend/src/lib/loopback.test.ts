import assert from 'node:assert/strict';
import { test } from 'node:test';
import { isLoopbackDatabase, isLoopbackUrl } from './loopback.js';

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

test('a database is judged by the hosts its client will connect to', () => {
  assert.equal(isLoopbackDatabase('postgres://postgres:password@localhost:5432/dian_dian_test'), true, 'the database of the release checks');
  assert.equal(isLoopbackDatabase('postgresql://user:secret@127.0.0.1:5433/dian_dian'), true);
  assert.equal(isLoopbackDatabase('postgres://user:secret@db.internal:5432/dian_dian'), false);
  // The URL parser reads the last `@`, the client the first: it would connect to db.example.com.
  assert.equal(isLoopbackDatabase('postgres://x@db.example.com,y@localhost/dian_dian'), false, 'several hosts, the first one elsewhere');
  assert.equal(isLoopbackDatabase('postgres://x@localhost,y@db.example.com/dian_dian'), false, 'several hosts, one of them elsewhere');
  assert.equal(isLoopbackDatabase(undefined), false, 'no address given: the client would fall back on its environment');
  assert.equal(isLoopbackDatabase(''), false);
});
