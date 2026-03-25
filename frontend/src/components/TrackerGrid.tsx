import React, { useMemo } from 'react';
import { View, Text, TouchableOpacity, StyleSheet } from 'react-native';
import { COLORS, FONTS } from '../lib/theme';

const MONTHS = ['J', 'F', 'M', 'A', 'M', 'J', 'J', 'A', 'S', 'O', 'N', 'D'];

function getDaysInMonth(month: number, year: number): number {
  return new Date(year, month + 1, 0).getDate();
}

interface Props {
  year?: number;
  getCellColor: (month: number, day: number) => string | null;
  selectedColor: string | null;
  onCellPress: (month: number, day: number) => void;
  dotSize?: number;
}

export default function TrackerGrid({ year = new Date().getFullYear(), getCellColor, selectedColor, onCellPress, dotSize: forcedDotSize }: Props) {
  const dotSize = forcedDotSize || 18;
  const spacingH = 3;
  const spacingV = 2;
  const labelW = 24;
  const labelSize = dotSize < 14 ? 7 : dotSize < 20 ? 9 : 11;

  const daysPerMonth = useMemo(() =>
    Array.from({ length: 12 }, (_, m) => getDaysInMonth(m, year)),
    [year],
  );

  return (
    <View>
      {/* Header row */}
      <View style={[styles.row, { marginBottom: spacingV }]}>
        <View style={{ width: labelW }} />
        {MONTHS.map((m, i) => (
          <View key={i} style={{ width: dotSize + spacingH, alignItems: 'center' }}>
            <Text style={[styles.headerText, { fontSize: labelSize, fontFamily: FONTS.pixel }]}>{m}</Text>
          </View>
        ))}
      </View>

      {/* Day rows */}
      {Array.from({ length: 31 }, (_, i) => i + 1).map(day => (
        <View key={day} style={[styles.row, { marginBottom: spacingV }]}>
          <View style={{ width: labelW, alignItems: 'flex-end', paddingRight: 6 }}>
            <Text style={[styles.dayLabel, { fontSize: labelSize, fontFamily: FONTS.pixel }]}>{day}</Text>
          </View>
          {Array.from({ length: 12 }, (_, month) => {
            const exists = day <= daysPerMonth[month];
            const color = exists ? getCellColor(month, day) : null;
            return (
              <View key={month} style={{ width: dotSize + spacingH, alignItems: 'center' }}>
                {exists && (
                  <TouchableOpacity
                    onPress={() => onCellPress(month, day)}
                    style={{
                      width: dotSize,
                      height: dotSize,
                      borderRadius: dotSize / 2,
                      backgroundColor: color || COLORS.dotEmpty,
                      borderWidth: 2,
                      borderColor: color ? 'rgba(0,0,0,0.08)' : COLORS.dotBorder,
                    }}
                    activeOpacity={0.7}
                  />
                )}
              </View>
            );
          })}
        </View>
      ))}
    </View>
  );
}

const styles = StyleSheet.create({
  row: {
    flexDirection: 'row',
    alignItems: 'center',
  },
  headerText: {
    color: COLORS.textMuted,
    letterSpacing: 1,
  },
  dayLabel: {
    color: COLORS.textWarm,
  },
});
