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
      {/* Grid + legend dots side by side */}
      <View style={styles.gridRow}>
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

        {legends.length > 0 && (
          <View style={styles.legendDots}>
            {legends.slice(0, 8).map((l, i) => (
              <View key={i} style={[styles.legendDot, { backgroundColor: l.color }]} />
            ))}
          </View>
        )}
      </View>

      {/* Title */}
      <Text style={styles.cardTitle} numberOfLines={1}>{page.title}</Text>
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
  gridRow: {
    flexDirection: 'row',
    gap: 6,
    alignItems: 'center',
  },
  miniGrid: {
    flexDirection: 'row',
    gap: 1,
    flex: 1,
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
  legendDots: {
    gap: 3,
    alignItems: 'center',
  },
  legendDot: {
    width: 7,
    height: 7,
    borderRadius: 4,
    borderWidth: 0.5,
    borderColor: 'rgba(0,0,0,0.06)',
  },
});
