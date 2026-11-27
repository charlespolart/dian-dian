import assert from 'node:assert/strict';
import { test } from 'node:test';
import { accountKind } from './accountKind.js';

const none = { email: null, passwordHash: null };

test('an account with no identity is invisible (chantier 9, principle 5)', () => {
  assert.deepEqual(accountKind(none, []), { kind: 'invisible', methods: [] });
});

test('any identity attaches it, and the methods say which', () => {
  assert.deepEqual(accountKind({ email: 'a@b.fr', passwordHash: 'h' }, []), { kind: 'attached', methods: ['email', 'password'] });
  assert.deepEqual(accountKind({ email: 'a@b.fr', passwordHash: null }, ['apple']), { kind: 'attached', methods: ['email', 'apple'] });
  assert.deepEqual(accountKind(none, ['google', 'apple']), { kind: 'attached', methods: ['apple', 'google'] });
});
