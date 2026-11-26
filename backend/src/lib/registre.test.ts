/**
 * The register of processing activities (docs/REGISTRE.md) names every table
 * of the database. A table added without saying there what it holds, why and
 * for how long fails here.
 */
import assert from 'node:assert/strict';
import { readdirSync, readFileSync } from 'node:fs';
import { test } from 'node:test';

const read = (path: string) => readFileSync(new URL(path, import.meta.url), 'utf8');

/** The tables a drizzle snapshot describes, without their schema prefix (`public.`). */
function tablesOfSnapshot(snapshot: { tables: Record<string, unknown> }): string[] {
  return Object.keys(snapshot.tables).map((name) => name.slice(name.indexOf('.') + 1));
}

// The tables as the migrations leave the database: the newest snapshot, which
// sees every schema file and every table a migration creates.
const snapshots = readdirSync(new URL('../../drizzle/meta/', import.meta.url)).filter((name) => /^\d{4}_snapshot\.json$/.test(name)).sort();
const tables = tablesOfSnapshot(JSON.parse(read(`../../drizzle/meta/${snapshots[snapshots.length - 1]}`)));
const register = read('../../../docs/REGISTRE.md');

test('the tables are read from a migration snapshot, without their schema prefix', () => {
  assert.deepEqual(tablesOfSnapshot({ tables: { 'public.users': {}, 'public.new_table': {} } }), ['users', 'new_table']);
});

test('the tables of the schema are found', () => {
  assert.ok(tables.includes('users') && tables.includes('audience_counts'), `found: ${tables.join(', ')}`);
});

for (const table of tables) {
  test(`the register names the table ${table}`, () => {
    assert.ok(register.includes(`\`${table}\``), `docs/REGISTRE.md does not mention \`${table}\`: add it to the sheet of the processing it belongs to`);
  });
}
