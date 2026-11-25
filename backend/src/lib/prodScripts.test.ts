/**
 * The scripts run by hand against the production database
 * (backend/scripts/prod-*.sql) only read it, and say so to the database
 * itself: a statement that writes, added by mistake, is refused there
 * instead of being run.
 */
import assert from 'node:assert/strict';
import { readdirSync, readFileSync } from 'node:fs';
import { test } from 'node:test';

const dir = new URL('../../scripts/', import.meta.url);
const scripts = readdirSync(dir).filter((name) => /^prod-.*\.sql$/.test(name)).sort();

/** The SQL statements of a psql script: no comment line, no `\` command. */
function statements(script: string): string[] {
  return script.split('\n')
    .filter((line) => !/^\s*(--|\\)/.test(line))
    .join('\n')
    .split(';')
    .map((statement) => statement.trim())
    .filter((statement) => statement !== '');
}

test('the production scripts are found', () => {
  assert.ok(scripts.includes('prod-stats.sql') && scripts.includes('prod-purchases.sql'), `found: ${scripts.join(', ')}`);
});

for (const name of scripts) {
  test(`${name} makes its session read-only, then only reads`, () => {
    const all = statements(readFileSync(new URL(name, dir), 'utf8'));
    const guard = all.indexOf('SET default_transaction_read_only = on');
    assert.notEqual(guard, -1, 'no "SET default_transaction_read_only = on;"');
    // A read-only session refuses CREATE TEMP TABLE, so that alone may come
    // first: it reads, and what it makes is private to the session.
    for (const before of all.slice(0, guard)) assert.match(before, /^CREATE TEMP TABLE /, 'only a temporary table may come before the guard');
    for (const after of all.slice(guard + 1)) assert.match(after, /^(SELECT|WITH)\s/, 'after the guard a script only reads');
  });
}
