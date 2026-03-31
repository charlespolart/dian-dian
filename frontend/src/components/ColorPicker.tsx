import React from 'react';
import { View, TouchableOpacity, Text, StyleSheet } from 'react-native';
import { COLORS, FONTS } from '../lib/theme';
import { useLanguage } from '../contexts/LanguageContext';

interface Props {
  palette: string[][];
  selectedColor: string | null;
  onSelect: (color: string | null) => void;
  onOpenPaletteConfig: () => void;
}

export default function ColorPicker({ palette, selectedColor, onSelect, onOpenPaletteConfig }: Props) {
  const { t } = useLanguage();

  return (
    <View style={styles.container}>
      {/* Palette grid: 6 per row */}
      <View style={styles.grid}>
        {palette.map((row, rowIdx) => (
          <View key={rowIdx} style={styles.gridRow}>
            {row.map(color => (
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

      {/* Edit palette button */}
      <TouchableOpacity style={styles.editBtn} onPress={onOpenPaletteConfig}>
        <Text style={styles.editBtnText}>{t('palette.edit')}</Text>
      </TouchableOpacity>
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
  editBtn: {
    alignSelf: 'center',
    marginTop: 4,
    paddingHorizontal: 10,
    paddingVertical: 4,
    borderWidth: 1,
    borderColor: COLORS.tabBorder,
    borderRadius: 8,
    borderStyle: 'dashed',
  },
  editBtnText: {
    fontFamily: FONTS.pixel,
    fontSize: 8,
    letterSpacing: 1,
    color: COLORS.textMuted,
    textTransform: 'uppercase',
  },
});
