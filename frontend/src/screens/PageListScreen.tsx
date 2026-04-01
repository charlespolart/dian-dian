import React, { useState, useMemo } from 'react';
import { View, Text, TouchableOpacity, ScrollView, StyleSheet, useWindowDimensions, Platform } from 'react-native';
import { SafeAreaView } from 'react-native-safe-area-context';
import { COLORS, FONTS } from '../lib/theme';
import { useLanguage } from '../contexts/LanguageContext';
import { useConfirm } from '../hooks/useConfirm';
import PageCard from '../components/PageCard';
import type { Page } from '../hooks/usePages';

const SafeContainer = Platform.OS === 'web'
  ? ({ children, ...props }: any) => <View style={props.style}>{children}</View>
  : SafeAreaView;

interface Props {
  pages: Page[];
  onSelectPage: (id: string) => void;
  onCreatePage: () => void;
  onDeletePage: (id: string) => void;
  onOpenSettings: () => void;
}

export default function PageListScreen({ pages, onSelectPage, onCreatePage, onDeletePage, onOpenSettings }: Props) {
  const { t } = useLanguage();
  const confirm = useConfirm();
  const { width } = useWindowDimensions();

  const currentYear = new Date().getFullYear();

  const years = useMemo(() => {
    const set = new Set(pages.map(p => p.year ?? currentYear));
    set.add(currentYear);
    return [...set].sort((a, b) => b - a);
  }, [pages, currentYear]);

  const [selectedYear, setSelectedYear] = useState(currentYear);

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
        {filteredPages.map(page => (
          <PageCard
            key={page.id}
            page={page}
            cardWidth={cardWidth}
            onPress={() => onSelectPage(page.id)}
            onLongPress={() => handleDelete(page.id)}
          />
        ))}

        {/* Add page button */}
        <TouchableOpacity
          style={[styles.addCard, { width: cardWidth }]}
          onPress={() => onCreatePage()}
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
  addCard: {
    backgroundColor: '#faf5ea',
    borderRadius: 12,
    borderWidth: 1,
    borderStyle: 'dashed',
    borderColor: COLORS.tabBorder,
    justifyContent: 'center',
    alignItems: 'center',
    padding: 12,
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
