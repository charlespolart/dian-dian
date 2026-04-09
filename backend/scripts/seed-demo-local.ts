/**
 * Seed a demo account with beautiful, realistic trackers for screenshots.
 * Run: cd backend && npx tsx scripts/seed-demo-local.ts
 */
import 'dotenv/config';
import * as argon2 from 'argon2';
import { db } from '../src/db/index.js';
import { users, pages, legends, cells } from '../src/db/schema.js';
import { eq } from 'drizzle-orm';

const EMAIL = 'demo@diandian.app';
const PASSWORD = 'password';

function daysInMonth(m: number, year: number): number {
  if (m === 2) return (year % 4 === 0 && year % 100 !== 0) || year % 400 === 0 ? 29 : 28;
  return [4, 6, 9, 11].includes(m) ? 30 : 31;
}

// Seeded random for reproducible results
let seed = 42;
function rand(): number {
  seed = (seed * 1664525 + 1013904223) & 0x7fffffff;
  return seed / 0x7fffffff;
}

function pick<T>(arr: T[]): T {
  return arr[Math.floor(rand() * arr.length)];
}

function weightedPick(colors: string[], weights: number[]): string {
  const total = weights.reduce((a, b) => a + b, 0);
  let r = rand() * total;
  for (let i = 0; i < colors.length; i++) {
    r -= weights[i];
    if (r <= 0) return colors[i];
  }
  return colors[colors.length - 1];
}

async function main() {
  console.log('Creating demo account for screenshots...');

  const passwordHash = await argon2.hash(PASSWORD, { type: argon2.argon2id });

  // Clean up existing
  const [existing] = await db.select({ id: users.id }).from(users).where(eq(users.email, EMAIL)).limit(1);
  if (existing) {
    await db.delete(users).where(eq(users.id, existing.id));
    console.log('  Cleaned up existing demo account');
  }

  const [user] = await db.insert(users).values({ email: EMAIL, passwordHash }).returning({ id: users.id });
  console.log(`  Created: ${EMAIL} / ${PASSWORD} (${user.id})`);

  // ═══════════════════════════════════════════
  // 2025 TRACKERS (complete year - visually full)
  // ═══════════════════════════════════════════

  // ── 1. Mood 2025 (warm palette, every day filled) ──
  await createTracker(user.id, 'Mood', 2025, 0, [
    { color: '#FFEC99', label: 'Amazing' },
    { color: '#FFD43B', label: 'Great' },
    { color: '#8CE99A', label: 'Good' },
    { color: '#74C0FC', label: 'Okay' },
    { color: '#E599F7', label: 'Meh' },
  ], (m, d, _year) => {
    // Mostly positive mood with seasonal variation
    const dayOfYear = (m - 1) * 30 + d;
    // Summer (jun-aug) happier, winter (dec-feb) more meh
    const isSummer = m >= 5 && m <= 9;
    const isWeekend = (dayOfYear % 7) <= 1;

    if (isSummer) {
      return weightedPick(
        ['#FFEC99', '#FFD43B', '#8CE99A', '#74C0FC', '#E599F7'],
        isWeekend ? [35, 30, 25, 8, 2] : [15, 30, 35, 15, 5]
      );
    } else {
      return weightedPick(
        ['#FFEC99', '#FFD43B', '#8CE99A', '#74C0FC', '#E599F7'],
        isWeekend ? [20, 25, 30, 18, 7] : [10, 20, 30, 28, 12]
      );
    }
  });

  // ── 2. Reading 2025 (pink gradient, ~85% fill) ──
  await createTracker(user.id, 'Reading', 2025, 1, [
    { color: '#FFC9C9', label: '1-10 pages' },
    { color: '#FFA8A8', label: '11-30 pages' },
    { color: '#FF8787', label: '31-60 pages' },
    { color: '#FA5252', label: '60+ pages' },
  ], (m, d, _year) => {
    if (rand() < 0.15) return null; // 15% rest days
    // Weekends: read more
    const dayOfYear = (m - 1) * 30 + d;
    const isWeekend = (dayOfYear % 7) <= 1;
    if (isWeekend) {
      return weightedPick(['#FFC9C9', '#FFA8A8', '#FF8787', '#FA5252'], [5, 15, 40, 40]);
    }
    return weightedPick(['#FFC9C9', '#FFA8A8', '#FF8787', '#FA5252'], [25, 40, 25, 10]);
  });

  // ── 3. Exercise 2025 (vibrant, ~55% fill) ──
  await createTracker(user.id, 'Exercise', 2025, 2, [
    { color: '#51CF66', label: 'Running' },
    { color: '#339AF0', label: 'Swimming' },
    { color: '#FF922B', label: 'Gym' },
    { color: '#CC5DE8', label: 'Yoga' },
    { color: '#20C997', label: 'Cycling' },
  ], (m, d, _year) => {
    const dayOfYear = (m - 1) * 30 + d;
    const dayOfWeek = dayOfYear % 7;
    // Mon, Wed, Fri, Sat = workout days (some skips)
    if (![0, 2, 4, 5].includes(dayOfWeek)) return null;
    if (rand() < 0.12) return null; // 12% skip
    // Vary exercise by day
    const exercises = ['#51CF66', '#339AF0', '#FF922B', '#CC5DE8', '#20C997'];
    const dayPreference = [
      [40, 10, 30, 15, 5],  // Mon: running/gym
      [10, 30, 30, 20, 10], // Wed: swimming/gym
      [20, 10, 40, 10, 20], // Fri: gym/cycling
      [15, 15, 10, 40, 20], // Sat: yoga/cycling
    ];
    const prefIdx = [0, 2, 4, 5].indexOf(dayOfWeek);
    return weightedPick(exercises, dayPreference[prefIdx]);
  });

  // ── 4. Sleep 2025 (blues, every day) ──
  await createTracker(user.id, 'Sleep', 2025, 3, [
    { color: '#1864AB', label: '8h+ deep' },
    { color: '#1C7ED6', label: '7-8h good' },
    { color: '#4DABF7', label: '6-7h okay' },
    { color: '#A5D8FF', label: '5-6h light' },
    { color: '#D0EBFF', label: '<5h poor' },
  ], (m, d, _year) => {
    const dayOfYear = (m - 1) * 30 + d;
    const isWeekend = (dayOfYear % 7) <= 1;
    // Better sleep on weekends
    if (isWeekend) {
      return weightedPick(
        ['#1864AB', '#1C7ED6', '#4DABF7', '#A5D8FF', '#D0EBFF'],
        [30, 40, 20, 8, 2]
      );
    }
    return weightedPick(
      ['#1864AB', '#1C7ED6', '#4DABF7', '#A5D8FF', '#D0EBFF'],
      [10, 25, 35, 22, 8]
    );
  });

  // ═══════════════════════════════════════════
  // 2026 TRACKERS (in progress - Jan to Apr 6)
  // ═══════════════════════════════════════════

  const maxMonth2026 = 4;
  const maxDay2026 = 6;

  // ── 5. Mood 2026 ──
  await createTracker(user.id, 'Mood', 2026, 0, [
    { color: '#FFEC99', label: 'Amazing' },
    { color: '#FFD43B', label: 'Great' },
    { color: '#8CE99A', label: 'Good' },
    { color: '#74C0FC', label: 'Okay' },
    { color: '#E599F7', label: 'Meh' },
  ], (m, d, _year) => {
    if (m > maxMonth2026 || (m === maxMonth2026 && d > maxDay2026)) return null;
    const dayOfYear = (m - 1) * 30 + d;
    const isWeekend = (dayOfYear % 7) <= 1;
    return weightedPick(
      ['#FFEC99', '#FFD43B', '#8CE99A', '#74C0FC', '#E599F7'],
      isWeekend ? [25, 30, 28, 12, 5] : [12, 22, 35, 22, 9]
    );
  });

  // ── 6. Reading 2026 ──
  await createTracker(user.id, 'Reading', 2026, 1, [
    { color: '#FFC9C9', label: '1-10 pages' },
    { color: '#FFA8A8', label: '11-30 pages' },
    { color: '#FF8787', label: '31-60 pages' },
    { color: '#FA5252', label: '60+ pages' },
  ], (m, d, _year) => {
    if (m > maxMonth2026 || (m === maxMonth2026 && d > maxDay2026)) return null;
    if (rand() < 0.15) return null;
    const dayOfYear = (m - 1) * 30 + d;
    const isWeekend = (dayOfYear % 7) <= 1;
    if (isWeekend) {
      return weightedPick(['#FFC9C9', '#FFA8A8', '#FF8787', '#FA5252'], [5, 15, 40, 40]);
    }
    return weightedPick(['#FFC9C9', '#FFA8A8', '#FF8787', '#FA5252'], [25, 40, 25, 10]);
  });

  // ── 7. Exercise 2026 ──
  await createTracker(user.id, 'Exercise', 2026, 2, [
    { color: '#51CF66', label: 'Running' },
    { color: '#339AF0', label: 'Swimming' },
    { color: '#FF922B', label: 'Gym' },
    { color: '#CC5DE8', label: 'Yoga' },
    { color: '#20C997', label: 'Cycling' },
  ], (m, d, _year) => {
    if (m > maxMonth2026 || (m === maxMonth2026 && d > maxDay2026)) return null;
    const dayOfYear = (m - 1) * 30 + d;
    const dayOfWeek = dayOfYear % 7;
    if (![0, 2, 4, 5].includes(dayOfWeek)) return null;
    if (rand() < 0.12) return null;
    return pick(['#51CF66', '#339AF0', '#FF922B', '#CC5DE8', '#20C997']);
  });

  // ── 8. Period 2026 ──
  await createTracker(user.id, 'Period', 2026, 3, [
    { color: '#FF6B6B', label: 'Heavy' },
    { color: '#FFA8A8', label: 'Medium' },
    { color: '#FFD8D8', label: 'Light' },
    { color: '#D0BFFF', label: 'PMS' },
    { color: '#E599F7', label: 'Cramps' },
  ], (m, d, _year) => {
    if (m > maxMonth2026 || (m === maxMonth2026 && d > maxDay2026)) return null;
    const dayOfYear = (m - 1) * 30 + d;
    const cycleDay = ((dayOfYear + 5) % 28); // offset to look natural
    if (cycleDay >= 25) return weightedPick(['#D0BFFF', '#E599F7'], [60, 40]); // PMS
    if (cycleDay <= 1) return '#FF6B6B'; // Heavy
    if (cycleDay <= 3) return '#FFA8A8'; // Medium
    if (cycleDay <= 4) return weightedPick(['#FFD8D8', '#E599F7'], [70, 30]); // Light/cramps
    return null;
  });

  // ── 9. Sleep 2026 ──
  await createTracker(user.id, 'Sleep', 2026, 4, [
    { color: '#1864AB', label: '8h+ deep' },
    { color: '#1C7ED6', label: '7-8h good' },
    { color: '#4DABF7', label: '6-7h okay' },
    { color: '#A5D8FF', label: '5-6h light' },
    { color: '#D0EBFF', label: '<5h poor' },
  ], (m, d, _year) => {
    if (m > maxMonth2026 || (m === maxMonth2026 && d > maxDay2026)) return null;
    const dayOfYear = (m - 1) * 30 + d;
    const isWeekend = (dayOfYear % 7) <= 1;
    if (isWeekend) {
      return weightedPick(['#1864AB', '#1C7ED6', '#4DABF7', '#A5D8FF', '#D0EBFF'], [30, 40, 20, 8, 2]);
    }
    return weightedPick(['#1864AB', '#1C7ED6', '#4DABF7', '#A5D8FF', '#D0EBFF'], [10, 25, 35, 22, 8]);
  });

  console.log(`\nDone! Login: ${EMAIL} / ${PASSWORD}`);
  console.log('Trackers: 4x 2025 (full year) + 5x 2026 (in progress)');
}

async function createTracker(
  userId: string,
  title: string,
  year: number,
  position: number,
  legendDefs: { color: string; label: string }[],
  cellFn: (month: number, day: number, year: number) => string | null,
) {
  const [page] = await db.insert(pages).values({
    userId, title, year, position,
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
    const maxDay = daysInMonth(m, year);
    for (let d = 1; d <= maxDay; d++) {
      const color = cellFn(m, d, year);
      if (color) cellRows.push({ pageId: page.id, month: m, day: d, color });
    }
  }

  if (cellRows.length > 0) {
    await db.insert(cells).values(cellRows);
  }

  console.log(`  ${title} ${year}: ${cellRows.length} cells, ${legendDefs.length} legends`);
}

main().then(() => process.exit(0)).catch((err) => {
  console.error(err);
  process.exit(1);
});
