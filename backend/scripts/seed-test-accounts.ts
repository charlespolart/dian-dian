/**
 * Seed test accounts with example trackers.
 * Run from backend dir: npx tsx scripts/seed-test-accounts.ts
 */
import 'dotenv/config';
import * as argon2 from 'argon2';
import { db } from '../src/db/index.js';
import { users, pages, legends, cells, subscriptions } from '../src/db/schema.js';
import { eq } from 'drizzle-orm';

const PREMIUM_EMAIL = 'premium@overridedev.com';
const FREE_EMAIL = 'free@overridedev.com';
const PASSWORD = 'TestTest123!';

async function main() {
  console.log('Seeding test accounts...');

  const passwordHash = await argon2.hash(PASSWORD, { type: argon2.argon2id });

  // ── Clean up existing test accounts ──
  for (const email of [PREMIUM_EMAIL, FREE_EMAIL]) {
    const [existing] = await db.select({ id: users.id }).from(users).where(eq(users.email, email)).limit(1);
    if (existing) {
      await db.delete(users).where(eq(users.id, existing.id)); // cascade deletes pages/cells/legends/subscriptions
      console.log(`  Deleted existing account: ${email}`);
    }
  }

  // ── Create premium account ──
  const [premiumUser] = await db.insert(users).values({ email: PREMIUM_EMAIL, passwordHash }).returning({ id: users.id });
  console.log(`  Created premium account: ${PREMIUM_EMAIL} (${premiumUser.id})`);

  // Set premium subscription
  await db.insert(subscriptions).values({
    userId: premiumUser.id,
    store: 'apple',
    productId: 'dian_dian_premium_yearly',
    originalTransactionId: `test_seed_${Date.now()}`,
    active: true,
  });

  // ── Create free account ──
  const [freeUser] = await db.insert(users).values({ email: FREE_EMAIL, passwordHash }).returning({ id: users.id });
  console.log(`  Created free account: ${FREE_EMAIL} (${freeUser.id})`);

  // ── Premium trackers ──
  await createTracker(premiumUser.id, 'Reading', 0, [
    { color: '#FFB3C1', label: '1-20 pages' },
    { color: '#FF8FA3', label: '21-50 pages' },
    { color: '#FF758F', label: '51-100 pages' },
    { color: '#C9184A', label: '100+ pages' },
  ], (m, d) => {
    if (m > 4 || (m === 4 && d > 5)) return null;
    if (m === 2 && d > 28) return null;
    if (d % 3 === 0) return null; // skip some days
    const colors = ['#FFB3C1', '#FF8FA3', '#FF758F', '#C9184A'];
    return colors[(m * 7 + d * 3) % colors.length];
  });

  await createTracker(premiumUser.id, 'Mood', 1, [
    { color: '#FFE066', label: 'Great' },
    { color: '#8CE99A', label: 'Good' },
    { color: '#74C0FC', label: 'Okay' },
    { color: '#DA77F2', label: 'Meh' },
    { color: '#FF6B6B', label: 'Bad' },
  ], (m, d) => {
    if (m > 4 || (m === 4 && d > 5)) return null;
    if (m === 2 && d > 28) return null;
    const colors = ['#FFE066', '#8CE99A', '#8CE99A', '#74C0FC', '#FFE066', '#8CE99A', '#DA77F2', '#8CE99A', '#FFE066', '#74C0FC', '#FF6B6B', '#8CE99A', '#FFE066'];
    return colors[(m * 31 + d) % colors.length];
  });

  await createTracker(premiumUser.id, 'Exercise', 2, [
    { color: '#69DB7C', label: 'Running' },
    { color: '#4DABF7', label: 'Swimming' },
    { color: '#FFA94D', label: 'Gym' },
    { color: '#E599F7', label: 'Yoga' },
  ], (m, d) => {
    if (m > 4 || (m === 4 && d > 5)) return null;
    if (m === 2 && d > 28) return null;
    if (d % 2 === 0 && d % 7 !== 0) return null; // ~3-4x per week
    const colors = ['#69DB7C', '#4DABF7', '#FFA94D', '#E599F7'];
    return colors[(m * 7 + d) % colors.length];
  });

  await createTracker(premiumUser.id, 'Period', 3, [
    { color: '#FF6B6B', label: 'Heavy' },
    { color: '#FFA8A8', label: 'Medium' },
    { color: '#FFD8D8', label: 'Light' },
    { color: '#E599F7', label: 'PMS' },
  ], (m, d) => {
    if (m > 4 || (m === 4 && d > 5)) return null;
    if (m === 2 && d > 28) return null;
    // ~28 day cycles
    const dayOfYear = (m - 1) * 30 + d;
    const cycleDay = dayOfYear % 28;
    if (cycleDay >= 26 || cycleDay <= 0) return '#E599F7'; // PMS
    if (cycleDay >= 1 && cycleDay <= 2) return '#FF6B6B'; // Heavy
    if (cycleDay >= 3 && cycleDay <= 4) return '#FFA8A8'; // Medium
    if (cycleDay === 5) return '#FFD8D8'; // Light
    return null;
  });

  await createTracker(premiumUser.id, 'Sleep Quality', 4, [
    { color: '#364FC7', label: 'Deep sleep' },
    { color: '#5C7CFA', label: 'Good sleep' },
    { color: '#91A7FF', label: 'Light sleep' },
    { color: '#DBE4FF', label: 'Poor sleep' },
  ], (m, d) => {
    if (m > 4 || (m === 4 && d > 5)) return null;
    if (m === 2 && d > 28) return null;
    const colors = ['#364FC7', '#5C7CFA', '#5C7CFA', '#91A7FF', '#364FC7', '#5C7CFA', '#DBE4FF', '#5C7CFA', '#364FC7', '#91A7FF'];
    return colors[(m * 13 + d * 7) % colors.length];
  });

  // ── Free trackers ──
  await createTracker(freeUser.id, 'Mood', 0, [
    { color: '#FFE066', label: 'Great' },
    { color: '#8CE99A', label: 'Good' },
    { color: '#74C0FC', label: 'Okay' },
  ], (m, d) => {
    if (m > 4 || (m === 4 && d > 5)) return null;
    if (m === 2 && d > 28) return null;
    const colors = ['#FFE066', '#8CE99A', '#74C0FC', '#8CE99A', '#FFE066', '#74C0FC', '#8CE99A'];
    return colors[(m * 5 + d * 3) % colors.length];
  });

  await createTracker(freeUser.id, 'Exercise', 1, [
    { color: '#69DB7C', label: 'Running' },
    { color: '#4DABF7', label: 'Swimming' },
    { color: '#FFA94D', label: 'Gym' },
  ], (m, d) => {
    if (m > 4 || (m === 4 && d > 5)) return null;
    if (m === 2 && d > 28) return null;
    if (d % 3 !== 0 && d % 7 !== 1) return null;
    const colors = ['#69DB7C', '#4DABF7', '#FFA94D'];
    return colors[(m + d) % colors.length];
  });

  console.log('\nDone! Test accounts:');
  console.log(`  Premium: ${PREMIUM_EMAIL} / ${PASSWORD}`);
  console.log(`  Free:    ${FREE_EMAIL} / ${PASSWORD}`);
}

async function createTracker(
  userId: string,
  title: string,
  position: number,
  legendDefs: { color: string; label: string }[],
  cellFn: (month: number, day: number) => string | null,
) {
  const [page] = await db.insert(pages).values({
    userId,
    title,
    year: 2026,
    position,
  }).returning({ id: pages.id });

  for (let i = 0; i < legendDefs.length; i++) {
    await db.insert(legends).values({
      pageId: page.id,
      color: legendDefs[i].color,
      label: legendDefs[i].label,
      position: i,
    });
  }

  const cellRows: { pageId: string; month: number; day: number; color: string }[] = [];
  for (let m = 1; m <= 12; m++) {
    const maxDay = m === 2 ? 28 : [4, 6, 9, 11].includes(m) ? 30 : 31;
    for (let d = 1; d <= maxDay; d++) {
      const color = cellFn(m, d);
      if (color) {
        cellRows.push({ pageId: page.id, month: m, day: d, color });
      }
    }
  }

  if (cellRows.length > 0) {
    await db.insert(cells).values(cellRows);
  }

  console.log(`  Tracker "${title}": ${cellRows.length} cells`);
}

main().then(() => process.exit(0)).catch((err) => {
  console.error(err);
  process.exit(1);
});
