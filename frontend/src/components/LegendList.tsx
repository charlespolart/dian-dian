import React from 'react';
import { View, Text, TouchableOpacity, StyleSheet, useWindowDimensions } from 'react-native';
import { COLORS, FONTS } from '../lib/theme';
import { useLanguage } from '../contexts/LanguageContext';
import type { Legend } from '../hooks/useLegends';

interface Props {
  legends: Legend[];
  brushColor: string | null;
  onSelectLegend: (color: string) => void;
}

export default function LegendList({ legends, brushColor, onSelectLegend }: Props) {
  const { t } = useLanguage();
  const { width } = useWindowDimensions();
  const isMobile = width < 768;

  return (
    <View style={styles.wrapper}>
      {/* Eraser — always on top, centered on mobile */}
      <TouchableOpacity
        style={[styles.legendItem, isMobile && styles.legendItemEraserMobile, brushColor === null && styles.legendItemSelected]}
        onPress={() => onSelectLegend('__eraser__')}
        activeOpacity={0.7}
      >
        <View style={[styles.legendDot, styles.eraserDot, brushColor === null && styles.legendDotSelected]} />
        <Text style={[styles.legendLabel, brushColor === null && styles.legendLabelSelected]}>{t('tracker.eraser')}</Text>
      </TouchableOpacity>

      {/* Legends — 2 columns on mobile */}
      <View style={styles.container}>
        {legends.map(legend => {
          const isSelected = brushColor?.toUpperCase() === legend.color.toUpperCase();
          return (
            <TouchableOpacity
              key={legend.id}
              style={[styles.legendItem, isMobile && styles.legendItemHalf, isSelected && styles.legendItemSelected]}
              onPress={() => onSelectLegend(legend.color)}
              activeOpacity={0.7}
            >
              <View style={[styles.legendDot, { backgroundColor: legend.color }, isSelected && styles.legendDotSelected]} />
              <Text style={[styles.legendLabel, isSelected && styles.legendLabelSelected]} numberOfLines={1}>{legend.label}</Text>
            </TouchableOpacity>
          );
        })}
      </View>
    </View>
  );
}

const styles = StyleSheet.create({
  wrapper: {
    gap: 3,
  },
  container: {
    gap: 3,
    flexDirection: 'row',
    flexWrap: 'wrap',
  },
  legendItem: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 6,
    paddingVertical: 5,
    paddingHorizontal: 7,
    borderRadius: 8,
    borderWidth: 2,
    borderColor: 'transparent',
    width: '100%',
  },
  legendItemEraserMobile: {
    alignSelf: 'center',
  },
  legendItemHalf: {
    width: '48%',
  },
  legendItemSelected: {
    backgroundColor: COLORS.tabActive,
    borderColor: COLORS.tabActiveBorder,
  },
  legendDot: {
    width: 14,
    height: 14,
    borderRadius: 7,
    borderWidth: 2,
    borderColor: 'rgba(0,0,0,0.08)',
  },
  legendDotSelected: {
    borderColor: '#8880a8',
    transform: [{ scale: 1.15 }],
  },
  eraserDot: {
    backgroundColor: COLORS.bg,
    borderStyle: 'dashed',
    borderColor: COLORS.tabBorder,
  },
  legendLabel: {
    flex: 1,
    fontFamily: FONTS.dot,
    fontSize: 12,
    color: COLORS.textLabel,
  },
  legendLabelSelected: {
    color: COLORS.accent,
  },
});
