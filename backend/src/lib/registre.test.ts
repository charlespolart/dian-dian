/**
 * The register of processing activities (docs/REGISTRE.md) names every table
 * of the database. A table added without saying there what it holds, why and
 * for how long fails here.
 */
import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';
import { test } from 'node:test';

const read = (path: string) => readFileSync(new URL(path, import.meta.url), 'utf8');
const tables = ['../db/schema.ts', '../audience/schema.ts']
  .flatMap((file) => [...read(file).matchAll(/pgTable\('([a-z_]+)'/g)].map((match) => match[1]));
const register = read('../../../docs/REGISTRE.md');

test('the tables of the schema are found', () => {
  assert.ok(tables.includes('users') && tables.includes('audience_counts'), `found: ${tables.join(', ')}`);
});

for (const table of tables) {
  test(`the register names the table ${table}`, () => {
    assert.ok(register.includes(`\`${table}\``), `docs/REGISTRE.md does not mention \`${table}\`: add it to the sheet of the processing it belongs to`);
  });
}
