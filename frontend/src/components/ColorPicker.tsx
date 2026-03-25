import React from 'react';
import { View, TouchableOpacity, Text, StyleSheet } from 'react-native';
import { PALETTE, COLORS, FONTS } from '../lib/theme';

interface Props {
  selectedColor: string | null;
  onSelect: (color: string | null) => void;
}

export default function ColorPicker({ selectedColor, onSelect }: Props) {
  return (
    <View style={styles.container}>
      {/* Eraser */}
      <View style={styles.eraserRow}>
        <TouchableOpacity
          style={[styles.swatch, styles.eraser, selectedColor === null && styles.selected]}
          onPress={() => onSelect(null)}
        >
          <Text style={styles.eraserText}>x</Text>
        </TouchableOpacity>
      </View>

      {/* Palette grid: 5 per row */}
      <View style={styles.grid}>
        {Array.from({ length: Math.ceil(PALETTE.length / 5) }, (_, row) => (
          <View key={row} style={styles.gridRow}>
            {PALETTE.slice(row * 5, row * 5 + 5).map(color => (
              <TouchableOpacity
                key={color}
                style={[
                  styles.swatch,
                  { backgroundColor: color },
                  selectedColor === color && styles.selected,
                ]}
                onPress={() => onSelect(color)}
              />
            ))}
          </View>
        ))}
      </View>
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    gap: 4,
  },
  eraserRow: {
    alignItems: 'center',
    marginBottom: 2,
  },
  grid: {
    gap: 4,
    alignItems: 'center',
  },
  gridRow: {
    flexDirection: 'row',
    gap: 4,
  },
  swatch: {
    width: 24,
    height: 24,
    borderRadius: 12,
    borderWidth: 2,
    borderColor: COLORS.tabBorder,
  },
  selected: {
    borderColor: '#8880a8',
    boxShadow: '0px 0px 4px rgba(136,128,168,0.3)',
    transform: [{ scale: 1.15 }],
  },
  eraser: {
    backgroundColor: COLORS.bg,
    borderStyle: 'dashed',
    borderColor: COLORS.tabBorder,
    alignItems: 'center',
    justifyContent: 'center',
  },
  eraserText: {
    fontFamily: FONTS.pixel,
    fontSize: 11,
    color: COLORS.textWarm,
  },
});
