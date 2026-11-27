import assert from 'node:assert/strict';
import { test } from 'node:test';
import { judge, mergeOrder, parseMutation, type Mutation } from './mutations.js';

const m = (over: Partial<Mutation> = {}): Mutation => ({
  id: '0b7f6c1e-1111-4222-8333-944455556666', kind: 'cell.set', waited: true, base: 4,
  data: { pageId: '1b7f6c1e-1111-4222-8333-944455556666', year: 2026, month: 3, day: 1, color: '#123456', comment: null },
  ...over,
});
const here = (editRev: number) => ({ exists: true, editRev, tombstoned: false, parentGone: false });

test('a change that did not wait is applied whatever changed: the last writer wins (H27)', () => {
  assert.equal(judge(m({ waited: false, base: 1 }), here(9)), 'apply');
});

test('a change that waited is applied when its element is as the phone knew it', () => {
  assert.equal(judge(m({ base: 4 }), here(4)), 'apply');
});

test('a change that waited is set aside when its element changed elsewhere (H17, H22)', () => {
  assert.equal(judge(m({ base: 4 }), here(5)), 'changed');
});

test('a day that did not exist for the phone (base 0) and still does not exist is applied', () => {
  assert.equal(judge(m({ base: 0 }), { exists: false, editRev: 0, tombstoned: false, parentGone: false }), 'apply');
});

test('a day cleared elsewhere since the phone saw it is a change of that day', () => {
  assert.equal(judge(m({ base: 4 }), { exists: false, editRev: 0, tombstoned: true, parentGone: false }), 'changed');
});

test('anything in a tracker deleted elsewhere is set aside as deleted (H20)', () => {
  assert.equal(judge(m({ base: 4 }), { exists: false, editRev: 0, tombstoned: false, parentGone: true }), 'deleted');
  assert.equal(judge(m({ waited: false }), { exists: false, editRev: 0, tombstoned: false, parentGone: true }), 'deleted');
});

test('an edit of an element deleted elsewhere is set aside as deleted', () => {
  const rename = m({ kind: 'page.update', base: 3, data: { id: '1b7f6c1e-1111-4222-8333-944455556666', title: 'X' } });
  assert.equal(judge(rename, { exists: false, editRev: 0, tombstoned: true, parentGone: false }), 'deleted');
});

test('a creation is never in conflict, but never brings back what was deleted since', () => {
  const create = m({ kind: 'page.create', base: null, data: { id: '1b7f6c1e-1111-4222-8333-944455556666', title: 'Sport' } });
  assert.equal(judge(create, { exists: false, editRev: 0, tombstoned: false, parentGone: false }), 'apply');
  assert.equal(judge(create, { exists: false, editRev: 0, tombstoned: true, parentGone: false }), 'deleted');
});

test('a creation sent again after a lost answer finds its element already there, and is applied (idempotent upstream)', () => {
  const create = m({ kind: 'page.create', base: null, data: { id: '1b7f6c1e-1111-4222-8333-944455556666', title: 'Sport' } });
  assert.equal(judge(create, here(7)), 'apply');
});

test('a mutation is read defensively: an unknown kind or a missing id is no mutation', () => {
  assert.equal(parseMutation({ id: 'x', kind: 'cell.set', waited: true, base: 1, data: {} }), null, 'id must be a uuid');
  assert.equal(parseMutation({ ...m(), kind: 'nope' }), null);
  assert.deepEqual(parseMutation(m()), m());
  assert.equal(parseMutation({ ...m(), data: { ...m().data, color: 'red' } }), null, 'a day colour is #RRGGBB');
});

test('an order sent by a phone puts the ids it lists first, then the others in their order (a tracker created elsewhere is kept)', () => {
  assert.deepEqual(mergeOrder(['c', 'a'], ['a', 'b', 'c', 'd']), ['c', 'a', 'b', 'd']);
  assert.deepEqual(mergeOrder(['x', 'b'], ['a', 'b']), ['b', 'a'], 'an id the server does not have is dropped');
  assert.deepEqual(mergeOrder([], ['a', 'b']), ['a', 'b']);
});
