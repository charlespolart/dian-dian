import React, { useEffect, useRef } from 'react';
import { View, Text, TouchableOpacity, ScrollView, StyleSheet, Animated, Pressable, useWindowDimensions } from 'react-native';
import { COLORS, FONTS } from '../lib/theme';
import SettingsIcon from '../../assets/settings.svg';
import { useLanguage } from '../contexts/LanguageContext';
import type { Page } from '../hooks/usePages';

interface Props {
  visible: boolean;
  onClose: () => void;
  pages: Page[];
  activePageId: string | null;
  onSelectPage: (id: string) => void;
  onAddPage: () => void;
  onDeletePage: (id: string) => void;
  onOpenSettings: () => void;
}

const MENU_WIDTH = 260;

export default function SideMenu({
  visible, onClose, pages, activePageId,
  onSelectPage, onAddPage, onDeletePage, onOpenSettings,
}: Props) {
  const { t } = useLanguage();
  const { width } = useWindowDimensions();
  const slideAnim = useRef(new Animated.Value(-MENU_WIDTH)).current;
  const fadeAnim = useRef(new Animated.Value(0)).current;

  useEffect(() => {
    if (visible) {
      Animated.parallel([
        Animated.timing(slideAnim, { toValue: 0, duration: 220, useNativeDriver: false }),
        Animated.timing(fadeAnim, { toValue: 1, duration: 220, useNativeDriver: false }),
      ]).start();
    } else {
      Animated.parallel([
        Animated.timing(slideAnim, { toValue: -MENU_WIDTH, duration: 180, useNativeDriver: false }),
        Animated.timing(fadeAnim, { toValue: 0, duration: 180, useNativeDriver: false }),
      ]).start();
    }
  }, [visible]);

  if (!visible && (fadeAnim as any)._value === 0) return null;

  return (
    <View style={StyleSheet.absoluteFill} pointerEvents={visible ? 'auto' : 'none'}>
      {/* Backdrop */}
      <Animated.View style={[styles.backdrop, { opacity: fadeAnim }]}>
        <Pressable style={StyleSheet.absoluteFill} onPress={onClose} />
      </Animated.View>

      {/* Drawer */}
      <Animated.View style={[styles.drawer, { transform: [{ translateX: slideAnim }] }]}>
        {/* Close button */}
        <TouchableOpacity style={styles.closeBtn} onPress={onClose}>
          <Text style={styles.closeBtnText}>✕</Text>
        </TouchableOpacity>

        <View style={styles.content}>
          {/* Pages — scrollable */}
          <ScrollView style={styles.pagesScroll} showsVerticalScrollIndicator={false}>
            <Text style={styles.sectionTitle}>{t('tracker.pages')}</Text>
            <View style={styles.pagesList}>
              {pages.map(page => (
                <TouchableOpacity
                  key={page.id}
                  style={[styles.pageItem, page.id === activePageId && styles.pageItemActive]}
                  onPress={() => { onSelectPage(page.id); onClose(); }}
                >
                  <Text
                    style={[styles.pageText, page.id === activePageId && styles.pageTextActive]}
                    numberOfLines={1}
                  >
                    {page.title}
                  </Text>
                  {pages.length > 1 && (
                    <TouchableOpacity
                      onPress={() => onDeletePage(page.id)}
                      hitSlop={{ top: 8, bottom: 8, left: 8, right: 8 }}
                    >
                      <Text style={styles.pageDeleteText}>x</Text>
                    </TouchableOpacity>
                  )}
                </TouchableOpacity>
              ))}
            </View>
          </ScrollView>

          {/* Add + Settings — pinned at bottom */}
          <View style={styles.bottomSection}>
            <TouchableOpacity style={styles.addPageBtn} onPress={() => { onAddPage(); onClose(); }}>
              <Text style={styles.addPageText}>+ {t('common.add').replace('+ ', '')}</Text>
            </TouchableOpacity>
            <View style={styles.divider} />
            <TouchableOpacity style={styles.menuItem} onPress={() => { onOpenSettings(); onClose(); }}>
              <SettingsIcon width={20} height={20} fill={COLORS.accent} />
              <Text style={styles.menuItemText}>{t('tracker.settings')}</Text>
            </TouchableOpacity>
          </View>
        </View>
      </Animated.View>
    </View>
  );
}

const styles = StyleSheet.create({
  backdrop: {
    ...StyleSheet.absoluteFillObject,
    backgroundColor: 'rgba(0,0,0,0.3)',
  },
  drawer: {
    position: 'absolute',
    top: 0,
    left: 0,
    bottom: 0,
    width: MENU_WIDTH,
    backgroundColor: '#faf5ea',
    borderRightWidth: 2,
    borderRightColor: COLORS.shellBorder,
    paddingTop: 50,
  },
  closeBtn: {
    position: 'absolute',
    top: 12,
    right: 12,
    zIndex: 1,
    padding: 6,
  },
  closeBtnText: {
    fontFamily: FONTS.pixel,
    fontSize: 14,
    color: COLORS.textMuted,
  },
  content: {
    flex: 1,
    paddingHorizontal: 16,
  },
  pagesScroll: {
    flex: 1,
    paddingTop: 16,
  },
  bottomSection: {
    paddingBottom: 24,
  },
  sectionTitle: {
    fontFamily: FONTS.pixel,
    fontSize: 10,
    letterSpacing: 2,
    textTransform: 'uppercase',
    paddingBottom: 6,
    borderBottomWidth: 2,
    borderBottomColor: COLORS.sectionBorder,
    borderStyle: 'dashed',
    color: COLORS.textWarm,
    opacity: 0.7,
    marginBottom: 8,
  },
  pagesList: {
    gap: 4,
  },
  pageItem: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    paddingHorizontal: 12,
    paddingVertical: 9,
    borderRadius: 8,
    borderWidth: 2,
    borderColor: 'transparent',
    backgroundColor: 'transparent',
  },
  pageItemActive: {
    backgroundColor: COLORS.tabActive,
    borderColor: COLORS.tabActiveBorder,
  },
  pageText: {
    fontFamily: FONTS.pixel,
    fontSize: 10,
    letterSpacing: 1,
    color: COLORS.textMuted,
    flex: 1,
  },
  pageTextActive: {
    color: COLORS.accent,
  },
  pageDeleteText: {
    fontSize: 12,
    opacity: 0.4,
    color: COLORS.textMuted,
    marginLeft: 8,
  },
  addPageBtn: {
    paddingHorizontal: 12,
    paddingVertical: 9,
    borderRadius: 8,
    borderWidth: 2,
    borderColor: COLORS.tabBorder,
    borderStyle: 'dashed',
    alignItems: 'center',
    marginTop: 4,
  },
  addPageText: {
    fontFamily: FONTS.pixel,
    fontSize: 10,
    letterSpacing: 1,
    color: COLORS.subtitle,
  },
  divider: {
    height: 2,
    backgroundColor: COLORS.sectionBorder,
    marginVertical: 16,
    opacity: 0.5,
  },
  menuItem: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 8,
    paddingHorizontal: 12,
    paddingVertical: 10,
    borderRadius: 8,
  },
  menuItemText: {
    fontFamily: FONTS.pixel,
    fontSize: 10,
    letterSpacing: 1,
    color: COLORS.accent,
    textTransform: 'uppercase',
  },
});
