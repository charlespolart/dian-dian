/**
 * The durations the privacy policy and docs/REGISTRE.md state for what lives
 * outside the database are the ones the server is configured with: backups
 * 30 days (pgBackRest), logs 6 months at most (journald, which the
 * containers write to).
 */
import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';
import { test } from 'node:test';

const ops = (path: string) => readFileSync(new URL(`../../../ops/${path}`, import.meta.url), 'utf8');
const DAY = 24 * 60 * 60;

/** A journald time span (`178d`, `1day`, `6month`) in seconds; months as journald counts them (30.44 days). */
function seconds(span: string): number {
  const match = /^(\d+)\s*(s|min|h|d|day|days|w|week|weeks|month|months)$/.exec(span.trim());
  assert.ok(match, `a time span journald reads: ${span}`);
  const unit: Record<string, number> = { s: 1, min: 60, h: 3600, d: DAY, day: DAY, days: DAY, w: 7 * DAY, week: 7 * DAY, weeks: 7 * DAY, month: 2_629_800, months: 2_629_800 };
  return Number(match[1]) * unit[match[2]];
}

test('backups: 30 daily full backups are kept, so a deleted row leaves them after 30 days', () => {
  assert.match(ops('pgbackrest/pgbackrest.conf'), /^repo1-retention-full=30$/m);
});

test('logs: journald drops an entry within 6 months (180 days), whatever file it sits in', () => {
  const conf = ops('journald/dian-dian.conf');
  const value = (key: string) => new RegExp(`^${key}=(.+)$`, 'm').exec(conf)?.[1] ?? '';
  // An entry goes when the whole file it is in is older than the retention: at worst one file's span later.
  const worst = seconds(value('MaxRetentionSec')) + seconds(value('MaxFileSec'));
  assert.ok(worst <= 180 * DAY, `an entry can live ${worst / DAY} days`);
});

test('logs: every production container writes to journald, not to a file of its own', () => {
  const compose = ops('docker-compose.prod.yml');
  const services = compose.split(/^services:\n/m)[1].split(/^(?=  [a-z][a-z0-9_-]*:\s*$)/m).filter((block) => /^  [a-z]/.test(block));
  assert.deepEqual(services.map((block) => block.trim().split(':')[0]), ['postgres', 'backend', 'caddy']);
  for (const block of services) {
    assert.match(block, /^    logging:\n      driver: journald$/m, `${block.trim().split(':')[0]} logs to journald`);
  }
});
