import React, { useEffect, useState } from 'react';
import { View, Text, TouchableOpacity, StyleSheet } from 'react-native';
import { COLORS, FONTS } from '../lib/theme';
import { apiFetch } from '../lib/api';
import type { Page } from '../hooks/usePages';
import type { Cell } from '../hooks/useCells';

interface Props {
  page: Page;
  cardWidth: number;
  onPress: () => void;
  onLongPress: () => void;
}

interface LegendSummary {
  color: string;
  label: string;
}

function getDaysInMonth(month: number, year: number): number {
  return new Date(year, month + 1, 0).getDate();
}

export default function PageCard({ page, cardWidth, onPress, onLongPress }: Props) {
  const [cells, setCells] = useState<Cell[]>([]);
  const [legends, setLegends] = useState<LegendSummary[]>([]);

  useEffect(() => {
    apiFetch(`/cells/${page.id}`).then(r => r.ok ? r.json() : []).then(setCells).catch(() => {});
    apiFetch(`/legends/${page.id}`).then(r => r.ok ? r.json() : []).then(setLegends).catch(() => {});
  }, [page.id]);

  const year = page.year ?? new Date().getFullYear();
  const cellMap = new Map(cells.map(c => [`${c.month}-${c.day}`, c.color]));
  const dotSize = Math.max(2, Math.min(4, (cardWidth - 40) / 14));

  return (
    <TouchableOpacity
      style={[styles.card, { width: cardWidth }]}
      onPress={onPress}
      onLongPress={onLongPress}
      activeOpacity={0.8}
    >
      {/* Mini grid with real colors */}
      <View style={styles.miniGrid}>
        {Array.from({ length: 12 }, (_, m) => (
          <View key={m} style={styles.miniCol}>
            {Array.from({ length: getDaysInMonth(m, year) }, (_, d) => {
              const color = cellMap.get(`${m}-${d + 1}`);
              return (
                <View
                  key={d}
                  style={[
                    styles.miniDot,
                    { width: dotSize, height: dotSize, borderRadius: dotSize / 2 },
                    { backgroundColor: color || COLORS.dotEmpty },
                  ]}
                />
              );
            })}
          </View>
        ))}
      </View>

      {/* Title */}
      <Text style={styles.cardTitle} numberOfLines={1}>{page.title}</Text>

      {/* Legend colors — vertical */}
      {legends.length > 0 && (
        <View style={styles.legendList}>
          {legends.slice(0, 6).map((l, i) => (
            <View key={i} style={styles.legendRow}>
              <View style={[styles.legendDot, { backgroundColor: l.color }]} />
              <Text style={styles.legendLabel} numberOfLines={1}>{l.label}</Text>
            </View>
          ))}
          {legends.length > 6 && (
            <Text style={styles.legendMore}>+{legends.length - 6}</Text>
          )}
        </View>
      )}
    </TouchableOpacity>
  );
}

const styles = StyleSheet.create({
  card: {
    backgroundColor: '#faf5ea',
    borderRadius: 12,
    borderWidth: 1,
    borderColor: COLORS.shellBorder,
    padding: 10,
    gap: 6,
  },
  miniGrid: {
    flexDirection: 'row',
    gap: 1,
    justifyContent: 'center',
    alignSelf: 'center',
  },
  miniCol: {
    gap: 1,
  },
  miniDot: {
    borderWidth: 0.5,
    borderColor: 'rgba(0,0,0,0.04)',
  },
  cardTitle: {
    fontFamily: FONTS.pixel,
    fontSize: 10,
    color: COLORS.title,
    letterSpacing: 1,
    textAlign: 'center',
  },
  legendList: {
    gap: 2,
  },
  legendRow: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 4,
  },
  legendDot: {
    width: 6,
    height: 6,
    borderRadius: 3,
    borderWidth: 0.5,
    borderColor: 'rgba(0,0,0,0.06)',
  },
  legendLabel: {
    fontFamily: FONTS.dot,
    fontSize: 8,
    color: COLORS.textMuted,
    flex: 1,
  },
  legendMore: {
    fontFamily: FONTS.dot,
    fontSize: 8,
    color: COLORS.textMuted,
    textAlign: 'center',
  },
});
