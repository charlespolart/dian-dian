import React, { useMemo } from 'react';
import { View, Text, StyleSheet } from 'react-native';
import { COLORS, FONTS } from '../lib/theme';
import { useLanguage } from '../contexts/LanguageContext';
import type { Cell } from '../hooks/useCells';

function getDaysInMonth(month: number, year: number): number {
  return new Date(year, month + 1, 0).getDate();
}

interface Props {
  cells: Cell[];
  year?: number;
}

export default function Stats({ cells, year = new Date().getFullYear() }: Props) {
  const { t } = useLanguage();
  const { filled, streak, percent } = useMemo(() => {
    const filledCount = cells.length;
    const totalDays = Array.from({ length: 12 }, (_, m) => getDaysInMonth(m, year)).reduce((a, b) => a + b, 0);
    const pct = Math.round((filledCount / totalDays) * 100);

    // Streak
    const filledSet = new Set(cells.map(c => `${c.month}-${c.day}`));
    let best = 0, cur = 0;
    for (let m = 0; m < 12; m++) {
      const days = getDaysInMonth(m, year);
      for (let d = 1; d <= days; d++) {
        if (filledSet.has(`${m}-${d}`)) {
          cur++;
          if (cur > best) best = cur;
        } else {
          cur = 0;
        }
      }
    }

    return { filled: filledCount, streak: best, percent: pct + '%' };
  }, [cells, year]);

  return (
    <View style={styles.container}>
      <StatItem value={String(filled)} label={t('tracker.statDays')} />
      <StatItem value={String(streak)} label={t('tracker.statStreak')} />
      <StatItem value={percent} label={t('tracker.statYear')} />
    </View>
  );
}

function StatItem({ value, label }: { value: string; label: string }) {
  return (
    <View style={styles.stat}>
      <Text style={styles.value}>{value}</Text>
      <Text style={styles.label}>{label}</Text>
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    flexDirection: 'row',
    justifyContent: 'center',
    gap: 12,
  },
  stat: {
    alignItems: 'center',
    gap: 1,
  },
  value: {
    fontFamily: FONTS.pixel,
    fontSize: 16,
    color: COLORS.textLabel,
  },
  label: {
    fontFamily: FONTS.dot,
    fontSize: 11,
    color: COLORS.textMuted,
    letterSpacing: 1,
  },
});
