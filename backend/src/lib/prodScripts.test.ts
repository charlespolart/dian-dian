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

/** What is wrong with a production script; empty when nothing is. */
function problems(script: string): string[] {
  const found: string[] = [];
  const all = statements(script);
  const guard = all.indexOf('SET default_transaction_read_only = on');
  if (guard === -1) return ['no "SET default_transaction_read_only = on;"'];
  // A read-only session refuses CREATE TEMP TABLE, so that alone may come
  // first: it reads, and what it makes is private to the session.
  for (const before of all.slice(0, guard)) {
    if (!/^CREATE TEMP TABLE /.test(before)) found.push(`before the guard: ${before.slice(0, 60)}`);
  }
  for (const after of all.slice(guard + 1)) {
    if (!/^(SELECT|WITH)\s/.test(after)) found.push(`after the guard, not a read: ${after.slice(0, 60)}`);
    // A SELECT can turn the guard off (set_config), and so can a second SET.
    if (/set_config|default_transaction_read_only/i.test(after)) found.push(`after the guard, touches the guard: ${after.slice(0, 60)}`);
  }
  // psql's own commands are not SQL and the guard does not see them: a new
  // connection (\c) starts a session without it, \i runs another file, \!
  // a shell. Only the ones that print and format, and "stop on error".
  for (const line of script.split('\n')) {
    if (/^\s*\\/.test(line) && !/^\s*\\(echo\b|pset\b|set ON_ERROR_STOP on\s*$)/.test(line)) found.push(`psql command: ${line.trim().slice(0, 60)}`);
  }
  return found;
}

test('the production scripts are found', () => {
  assert.ok(scripts.includes('prod-stats.sql') && scripts.includes('prod-purchases.sql'), `found: ${scripts.join(', ')}`);
});

const GUARD = 'SET default_transaction_read_only = on;';
const ok = `\\pset format aligned\n${GUARD}\n\\echo === Titre ===\nSELECT 1;\n`;

test('a script that sets the guard and then reads has no problem', () => {
  assert.deepEqual(problems(ok), []);
  assert.deepEqual(problems(`\\set ON_ERROR_STOP on\nCREATE TEMP TABLE u AS\nSELECT 1;\n${GUARD}\nWITH a AS (SELECT 1) SELECT * FROM a;\n`), [], 'a temporary table may come first');
});

test('what gets a script refused', () => {
  const refused = (script: string, what: string) => assert.notDeepEqual(problems(script), [], what);
  refused('SELECT 1;\n', 'no guard');
  refused(`SELECT 1;\n${GUARD}\nSELECT 2;\n`, 'a read before the guard');
  refused(`${ok}UPDATE users SET vip = true;\n`, 'a statement that writes');
  refused(`${ok}\\c other_database\nSELECT 1;\n`, 'a new connection: the guard is gone with the session');
  refused(`${ok}\\i other.sql\n`, 'another file, unchecked');
  refused(`${ok}\\! rm -rf /tmp/x\n`, 'a shell command');
  refused(`${ok}SELECT set_config('default_transaction_read_only', 'off', false);\n`, 'the guard turned off by a SELECT');
  refused(`${ok}SET default_transaction_read_only = off;\n`, 'the guard turned off');
  refused(`${ok}WITH x AS (SELECT set_config('default_transaction_read_only', 'off', false)) SELECT * FROM x;\n`, 'the same, inside a WITH');
});

for (const name of scripts) {
  test(`${name} makes its session read-only, then only reads`, () => {
    assert.deepEqual(problems(readFileSync(new URL(name, dir), 'utf8')), []);
  });
}
