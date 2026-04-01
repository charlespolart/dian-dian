import React, { useState, useMemo } from 'react';
import { View, Text, TouchableOpacity, ScrollView, StyleSheet, useWindowDimensions, Platform } from 'react-native';
import { SafeAreaView } from 'react-native-safe-area-context';
import { COLORS, FONTS, DEFAULT_PALETTE } from '../lib/theme';
import { useLanguage } from '../contexts/LanguageContext';
import { useConfirm } from '../hooks/useConfirm';
import type { Page } from '../hooks/usePages';

const SafeContainer = Platform.OS === 'web'
  ? ({ children, ...props }: any) => <View style={props.style}>{children}</View>
  : SafeAreaView;

interface Props {
  pages: Page[];
  onSelectPage: (id: string) => void;
  onCreatePage: (year?: number) => void;
  onDeletePage: (id: string) => void;
  onOpenSettings: () => void;
}

export default function PageListScreen({ pages, onSelectPage, onCreatePage, onDeletePage, onOpenSettings }: Props) {
  const { t } = useLanguage();
  const confirm = useConfirm();
  const { width } = useWindowDimensions();

  // Get available years
  const years = useMemo(() => {
    const set = new Set(pages.map(p => p.year ?? new Date().getFullYear()));
    return [...set].sort((a, b) => b - a);
  }, [pages]);

  const [selectedYear, setSelectedYear] = useState(() => {
    const current = new Date().getFullYear();
    return years.includes(current) ? current : years[0] ?? current;
  });

  const filteredPages = useMemo(
    () => pages.filter(p => (p.year ?? new Date().getFullYear()) === selectedYear),
    [pages, selectedYear]
  );

  const isMobile = width < 768;
  const cardWidth = isMobile ? (width - 48) / 2 : 200;

  const handleDelete = async (id: string) => {
    if (pages.length <= 1) return;
    const ok = await confirm({
      title: t('common.delete'),
      message: t('tracker.deletePageConfirm'),
      confirmText: t('common.delete'),
      cancelText: t('common.cancel'),
      destructive: true,
    });
    if (ok) onDeletePage(id);
  };

  return (
    <SafeContainer style={styles.safeArea} edges={['top', 'bottom']}>
      {/* Header */}
      <View style={styles.header}>
        <Text style={styles.titleChinese}>点点</Text>
        <Text style={styles.titleEnglish}>Dian Dian</Text>
        <TouchableOpacity style={styles.settingsBtn} onPress={onOpenSettings}>
          <Text style={styles.settingsBtnText}>☰</Text>
        </TouchableOpacity>
      </View>

      {/* Year navigation */}
      <View style={styles.yearNav}>
        <TouchableOpacity onPress={() => setSelectedYear(y => y - 1)}>
          <Text style={styles.yearArrow}>‹</Text>
        </TouchableOpacity>
        <Text style={styles.yearText}>{selectedYear}</Text>
        <TouchableOpacity onPress={() => setSelectedYear(y => y + 1)}>
          <Text style={styles.yearArrow}>›</Text>
        </TouchableOpacity>
      </View>

      {/* Page grid */}
      <ScrollView style={styles.scrollArea} contentContainerStyle={styles.grid}>
        {filteredPages.map(page => {
          const palette = page.palette ?? DEFAULT_PALETTE;
          const colors = palette.flat().slice(0, 12);
          return (
            <TouchableOpacity
              key={page.id}
              style={[styles.card, { width: cardWidth }]}
              onPress={() => onSelectPage(page.id)}
              onLongPress={() => handleDelete(page.id)}
              activeOpacity={0.8}
            >
              {/* Mini grid preview */}
              <View style={styles.miniGrid}>
                {Array.from({ length: 12 }, (_, m) => (
                  <View key={m} style={styles.miniCol}>
                    {Array.from({ length: 6 }, (_, d) => (
                      <View key={d} style={[styles.miniDot, { backgroundColor: COLORS.dotEmpty }]} />
                    ))}
                  </View>
                ))}
              </View>

              {/* Title */}
              <Text style={styles.cardTitle} numberOfLines={1}>{page.title}</Text>

              {/* Legend colors */}
              <View style={styles.legendColors}>
                {colors.slice(0, 8).map((c, i) => (
                  <View key={i} style={[styles.legendMiniDot, { backgroundColor: c }]} />
                ))}
              </View>
            </TouchableOpacity>
          );
        })}

        {/* Add page button */}
        <TouchableOpacity
          style={[styles.card, styles.addCard, { width: cardWidth }]}
          onPress={() => onCreatePage(selectedYear)}
        >
          <Text style={styles.addIcon}>+</Text>
          <Text style={styles.addText}>{t('common.add').replace('+ ', '')}</Text>
        </TouchableOpacity>
      </ScrollView>
    </SafeContainer>
  );
}

const styles = StyleSheet.create({
  safeArea: {
    flex: 1,
  },
  header: {
    alignItems: 'center',
    paddingTop: 16,
    paddingBottom: 4,
  },
  titleChinese: {
    fontSize: 36,
    color: COLORS.title,
    textAlign: 'center',
  },
  titleEnglish: {
    fontFamily: FONTS.pixel,
    fontSize: 12,
    color: COLORS.subtitle,
    textAlign: 'center',
    letterSpacing: 3,
  },
  settingsBtn: {
    position: 'absolute',
    right: 16,
    top: 16,
    padding: 8,
  },
  settingsBtnText: {
    fontSize: 22,
    color: COLORS.accent,
  },
  yearNav: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
    gap: 20,
    paddingVertical: 12,
  },
  yearArrow: {
    fontSize: 28,
    color: COLORS.accent,
    paddingHorizontal: 8,
  },
  yearText: {
    fontFamily: FONTS.pixel,
    fontSize: 18,
    color: COLORS.title,
    letterSpacing: 3,
  },
  scrollArea: {
    flex: 1,
  },
  grid: {
    flexDirection: 'row',
    flexWrap: 'wrap',
    justifyContent: 'center',
    gap: 12,
    padding: 16,
    paddingBottom: 40,
  },
  card: {
    backgroundColor: '#faf5ea',
    borderRadius: 12,
    borderWidth: 1,
    borderColor: COLORS.shellBorder,
    padding: 12,
    gap: 8,
    alignItems: 'center',
  },
  miniGrid: {
    flexDirection: 'row',
    gap: 2,
    justifyContent: 'center',
  },
  miniCol: {
    gap: 2,
  },
  miniDot: {
    width: 4,
    height: 4,
    borderRadius: 2,
  },
  cardTitle: {
    fontFamily: FONTS.pixel,
    fontSize: 10,
    color: COLORS.title,
    letterSpacing: 1,
    textAlign: 'center',
  },
  legendColors: {
    flexDirection: 'row',
    gap: 3,
    justifyContent: 'center',
  },
  legendMiniDot: {
    width: 8,
    height: 8,
    borderRadius: 4,
    borderWidth: 1,
    borderColor: 'rgba(0,0,0,0.06)',
  },
  addCard: {
    borderStyle: 'dashed',
    borderColor: COLORS.tabBorder,
    justifyContent: 'center',
    minHeight: 100,
  },
  addIcon: {
    fontSize: 28,
    color: COLORS.subtitle,
  },
  addText: {
    fontFamily: FONTS.pixel,
    fontSize: 9,
    color: COLORS.subtitle,
    letterSpacing: 1,
    textTransform: 'uppercase',
  },
});
