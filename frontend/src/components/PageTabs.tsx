import React from 'react';
import { View, Text, TouchableOpacity, StyleSheet, ScrollView } from 'react-native';
import { COLORS, FONTS } from '../lib/theme';
import type { Page } from '../hooks/usePages';

interface Props {
  pages: Page[];
  activePageId: string | null;
  onSelect: (id: string) => void;
  onAdd: () => void;
  onDelete: (id: string) => void;
}

export default function PageTabs({ pages, activePageId, onSelect, onAdd, onDelete }: Props) {
  return (
    <View style={styles.container}>
      <ScrollView
        horizontal
        showsHorizontalScrollIndicator={false}
        contentContainerStyle={styles.tabsRow}
        style={styles.scrollArea}
      >
        {pages.map(page => (
          <TouchableOpacity
            key={page.id}
            style={[styles.tab, page.id === activePageId && styles.activeTab]}
            onPress={() => onSelect(page.id)}
            onLongPress={() => {
              if (pages.length > 1) onDelete(page.id);
            }}
          >
            <Text
              style={[styles.tabText, page.id === activePageId && styles.activeTabText]}
              numberOfLines={1}
            >
              {page.title}
            </Text>
            {pages.length > 1 && (
              <TouchableOpacity onPress={() => onDelete(page.id)} hitSlop={{ top: 6, bottom: 6, left: 6, right: 6 }}>
                <Text style={styles.closeText}>x</Text>
              </TouchableOpacity>
            )}
          </TouchableOpacity>
        ))}
      </ScrollView>
      <TouchableOpacity style={styles.addTab} onPress={onAdd}>
        <Text style={styles.addTabText}>+</Text>
      </TouchableOpacity>
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    flexDirection: 'row',
    alignItems: 'flex-end',
    gap: 6,
  },
  scrollArea: {
    flex: 1,
  },
  tabsRow: {
    flexDirection: 'row',
    gap: 6,
    alignItems: 'flex-end',
    paddingHorizontal: 4,
  },
  tab: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 6,
    paddingHorizontal: 16,
    paddingVertical: 8,
    borderTopLeftRadius: 10,
    borderTopRightRadius: 10,
    borderWidth: 2,
    borderBottomWidth: 0,
    borderColor: COLORS.tabBorder,
    backgroundColor: COLORS.tab,
    maxWidth: 150,
  },
  activeTab: {
    backgroundColor: COLORS.tabActive,
    borderColor: COLORS.tabActiveBorder,
  },
  tabText: {
    fontFamily: FONTS.pixel,
    fontSize: 10,
    letterSpacing: 1,
    color: COLORS.textMuted,
  },
  activeTabText: {
    color: COLORS.accent,
  },
  closeText: {
    fontSize: 12,
    opacity: 0.4,
    color: COLORS.textMuted,
  },
  addTab: {
    paddingHorizontal: 14,
    paddingVertical: 7,
    borderTopLeftRadius: 10,
    borderTopRightRadius: 10,
    borderWidth: 2,
    borderBottomWidth: 0,
    borderColor: COLORS.tabBorder,
    borderStyle: 'dashed',
    backgroundColor: 'transparent',
  },
  addTabText: {
    fontFamily: FONTS.pixel,
    fontSize: 13,
    color: COLORS.subtitle,
  },
});
