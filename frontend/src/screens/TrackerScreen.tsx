import React, { useState, useCallback } from 'react';
import { View, Text, TextInput, TouchableOpacity, ScrollView, StyleSheet, Alert, Platform, useWindowDimensions } from 'react-native';
import { SafeAreaView } from 'react-native-safe-area-context';
import { usePages } from '../hooks/usePages';
import { useCells } from '../hooks/useCells';
import { useLegends } from '../hooks/useLegends';
import { useLanguage } from '../contexts/LanguageContext';
import { useAuth } from '../contexts/AuthContext';
import TrackerGrid from '../components/TrackerGrid';
import ColorPicker from '../components/ColorPicker';
import LegendList from '../components/LegendList';
import PageTabs from '../components/PageTabs';
import SideMenu from '../components/SideMenu';
import Stats from '../components/Stats';
import { COLORS, FONTS, PALETTE } from '../lib/theme';

interface Props {
  onOpenSettings: () => void;
}

export default function TrackerScreen({ onOpenSettings }: Props) {
  const { t } = useLanguage();
  const { emailVerified, resendVerification } = useAuth();
  const [verificationSent, setVerificationSent] = useState(false);
  const { pages, createPage, updatePage, deletePage } = usePages();
  const [activePageId, setActivePageId] = useState<string | null>(null);
  const [selectedColor, setSelectedColor] = useState<string | null>(PALETTE[0]);
  const [editingTitle, setEditingTitle] = useState(false);
  const [menuOpen, setMenuOpen] = useState(false);
  const { width, height } = useWindowDimensions();

  const currentPageId = activePageId && pages.find(p => p.id === activePageId)
    ? activePageId
    : pages[0]?.id ?? null;

  const { cells, getCellColor, setCell, deleteCell, resetAll } = useCells(currentPageId);
  const { legends, createLegend, deleteLegend } = useLegends(currentPageId);

  const currentPage = pages.find(p => p.id === currentPageId);

  const handleCellPress = useCallback((month: number, day: number) => {
    if (selectedColor) {
      setCell(month, day, selectedColor);
    } else {
      deleteCell(month, day);
    }
  }, [selectedColor, setCell, deleteCell]);

  const handleAddPage = useCallback(async () => {
    const page = await createPage();
    if (page) setActivePageId(page.id);
  }, [createPage]);

  const handleDeletePage = useCallback(async (id: string) => {
    const doDelete = async () => {
      await deletePage(id);
      if (currentPageId === id) setActivePageId(null);
    };
    if (Platform.OS === 'web') {
      if (confirm(t('tracker.deletePageConfirm'))) doDelete();
    } else {
      Alert.alert(t('common.delete'), t('tracker.deletePageConfirm'), [
        { text: t('common.cancel'), style: 'cancel' },
        { text: t('common.delete'), style: 'destructive', onPress: doDelete },
      ]);
    }
  }, [deletePage, currentPageId]);

  const handleResetAll = useCallback(() => {
    const doReset = () => resetAll();
    if (Platform.OS === 'web') {
      if (confirm(t('tracker.resetConfirm'))) doReset();
    } else {
      Alert.alert(t('tracker.resetAll'), t('tracker.resetConfirm'), [
        { text: t('common.cancel'), style: 'cancel' },
        { text: t('common.erase'), style: 'destructive', onPress: doReset },
      ]);
    }
  }, [resetAll]);

  const handleTitleSubmit = useCallback((text: string) => {
    if (currentPageId && text.trim()) {
      updatePage(currentPageId, { title: text.trim() });
    }
    setEditingTitle(false);
  }, [currentPageId, updatePage]);

  const isWide = width >= 1100;
  const isMobile = width < 768;
  const hasSidebarRow = !isMobile; // sidebar beside grid on tablet+
  const titleSize = isWide ? (width >= 1700 ? 52 : 42) : width >= 768 ? 28 : 22;
  const subtitleSize = isWide ? (width >= 1700 ? 24 : 18) : width >= 768 ? 16 : 14;
  const starsSize = isWide ? (width >= 1700 ? 22 : 18) : 14;

  // Dynamic dot sizing (matching original resizeDots logic)
  const spacingH = 3;
  const spacingV = 2;
  const SIDEBAR_W = hasSidebarRow ? 160 : 0;
  const SIDEBAR_GAP = hasSidebarRow ? 16 : 0;
  const LABEL_W = 24;

  // Vertical: shell padding(12+10) + screen padding+border(10+2)*2 + section title(~30) + header row(~20) + shell gap(8)
  const vOverhead = 12 + 10 + 24 + 8 + 30 + 20;
  const maxShellH = height - 24;
  const availH = maxShellH - vOverhead;
  const dotFromH = Math.floor((availH - 32 * spacingV) / 31);

  // Horizontal: shell padding(28+10) + screen padding+border(10+2)*2 + sidebar + label col + page padding
  const pagePadH = isWide ? 80 : 24;
  const shellPadH = 28 + 10;
  const screenPadH = (10 + 2) * 2;
  const hOverhead = shellPadH + screenPadH + SIDEBAR_W + SIDEBAR_GAP + LABEL_W + pagePadH;
  const availW = width - hOverhead;
  const dotFromW = Math.floor((availW - 13 * spacingH) / 12);

  // On mobile (stacked), screen scrolls vertically → use width only; otherwise min(h, w)
  const dotSize = Math.max(8, Math.min(isMobile ? dotFromW : Math.min(dotFromH, dotFromW), 32));

  const renderTabs = () => (
    <PageTabs
      pages={pages}
      activePageId={currentPageId}
      onSelect={setActivePageId}
      onAdd={handleAddPage}
      onDelete={handleDeletePage}
    />
  );

  const renderHeader = () => (
    <View style={styles.headerBlock}>
      {editingTitle ? (
        <TextInput
          style={[styles.titleInput, { fontSize: titleSize }]}
          defaultValue={currentPage?.title}
          autoFocus
          onBlur={(e) => handleTitleSubmit((e.nativeEvent as any).text ?? currentPage?.title ?? '')}
          onSubmitEditing={(e) => handleTitleSubmit(e.nativeEvent.text)}
          selectTextOnFocus
        />
      ) : (
        <TouchableOpacity onPress={() => setEditingTitle(true)}>
          <Text style={[styles.pageTitle, { fontSize: titleSize }]}>{currentPage?.title || 'Dian Dian'}</Text>
        </TouchableOpacity>
      )}
      <Text style={[styles.subtitle, { fontSize: subtitleSize }]}>~ {new Date().getFullYear()} ~</Text>
      <Text style={[styles.starsDeco, { fontSize: starsSize }]}>☆ ☆ ☆ ☆ ☆</Text>
    </View>
  );

  const renderShell = () => (
    <View style={[styles.shell, !isMobile && { maxHeight: height - 24 }]}>
      <View style={styles.spineLine} />
      <View style={styles.screen}>
        <Text style={styles.sectionTitle}>{currentPage?.title || 'Tracker'}</Text>

        <View style={[styles.trackerLayout, width >= 768 && styles.trackerLayoutRow]}>
          <View style={[styles.sidebar, width >= 768 && styles.sidebarVertical]}>
            <Text style={styles.sidebarTitle}>{t('tracker.colors')}</Text>
            <ColorPicker selectedColor={selectedColor} onSelect={setSelectedColor} />

            <Text style={styles.sidebarTitle}>{t('tracker.legend')}</Text>
            <LegendList
              legends={legends}
              selectedColor={selectedColor}
              onCreateLegend={createLegend}
              onDeleteLegend={deleteLegend}
            />

            <Text style={[styles.sidebarTitle, { marginTop: 8 }]}>{t('tracker.stats')}</Text>
            <Stats cells={cells} />

            <TouchableOpacity style={styles.resetBtn} onPress={handleResetAll}>
              <Text style={styles.resetBtnText}>{t('tracker.resetAll')}</Text>
            </TouchableOpacity>
          </View>

          <ScrollView horizontal showsHorizontalScrollIndicator={false}>
            {currentPageId ? (
              <TrackerGrid
                getCellColor={getCellColor}
                selectedColor={selectedColor}
                onCellPress={handleCellPress}
                dotSize={dotSize}
              />
            ) : (
              <Text style={styles.loadingText}>{t('tracker.loading')}</Text>
            )}
          </ScrollView>
        </View>
      </View>
    </View>
  );

  return (
    <SafeAreaView style={styles.safeArea} edges={['top', 'bottom']}>
      {/* Email verification banner */}
      {!emailVerified && (
        <View style={styles.verifyBanner}>
          <Text style={styles.verifyText}>{t('auth.verifyEmailBanner')}</Text>
          <TouchableOpacity onPress={async () => { await resendVerification(); setVerificationSent(true); }}>
            <Text style={styles.verifyLink}>{verificationSent ? t('auth.verificationSent') : t('auth.resendVerification')}</Text>
          </TouchableOpacity>
        </View>
      )}
      {/* Top bar: hamburger + horizontal tabs */}
      {!isWide && (
        <View style={styles.topBar}>
          <TouchableOpacity style={styles.hamburger} onPress={() => setMenuOpen(true)}>
            <Text style={styles.hamburgerText}>☰</Text>
          </TouchableOpacity>
          <View style={styles.tabsBarInline}>
            {renderTabs()}
          </View>
        </View>
      )}

      <ScrollView
        style={styles.outerScroll}
        contentContainerStyle={[styles.pageLayout, isWide && styles.pageLayoutCentered]}
        showsVerticalScrollIndicator={false}
      >
        {isWide ? (
          <View style={styles.wideLayout}>
            <View style={styles.leftColumn}>
              <View style={styles.leftColumnTopRow}>
                <TouchableOpacity style={styles.hamburgerWide} onPress={() => setMenuOpen(true)}>
                  <Text style={styles.hamburgerText}>☰</Text>
                </TouchableOpacity>
                <View style={styles.tabsBarWide}>
                  {renderTabs()}
                </View>
              </View>
              <View style={styles.leftColumnCenter}>
                {renderHeader()}
              </View>
            </View>
            {renderShell()}
          </View>
        ) : (
          <>
            {renderHeader()}
            {renderShell()}
          </>
        )}
      </ScrollView>

      <SideMenu
        visible={menuOpen}
        onClose={() => setMenuOpen(false)}
        pages={pages}
        activePageId={currentPageId}
        onSelectPage={(id) => setActivePageId(id)}
        onAddPage={handleAddPage}
        onDeletePage={handleDeletePage}
        onOpenSettings={onOpenSettings}
      />
    </SafeAreaView>
  );
}

const styles = StyleSheet.create({
  safeArea: {
    flex: 1,
  },
  verifyBanner: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
    gap: 10,
    backgroundColor: '#fff3cd',
    paddingVertical: 8,
    paddingHorizontal: 12,
  },
  verifyText: {
    fontFamily: FONTS.dot,
    fontSize: 12,
    color: '#856404',
  },
  verifyLink: {
    fontFamily: FONTS.pixel,
    fontSize: 10,
    color: '#856404',
    textDecorationLine: 'underline',
  },
  topBar: {
    flexDirection: 'row',
    alignItems: 'flex-end',
    paddingHorizontal: 8,
    paddingTop: 8,
    paddingBottom: 4,
    gap: 6,
  },
  hamburger: {
    paddingHorizontal: 10,
    paddingVertical: 6,
    marginBottom: 1,
  },
  hamburgerText: {
    fontSize: 20,
    color: COLORS.accent,
  },
  hamburgerWide: {
    paddingHorizontal: 10,
    paddingVertical: 6,
    marginBottom: 1,
  },
  leftColumnTopRow: {
    flexDirection: 'row',
    alignItems: 'flex-end',
    alignSelf: 'stretch',
    gap: 6,
  },
  tabsBarWide: {
    flex: 1,
    overflow: 'hidden',
  },
  tabsBarInline: {
    flex: 1,
  },
  outerScroll: {
    flex: 1,
  },
  pageLayout: {
    minHeight: '100%',
    alignItems: 'center',
    padding: 6,
    gap: 6,
    paddingBottom: 8,
  },
  pageLayoutCentered: {
    justifyContent: 'center',
  },
  wideLayout: {
    flexDirection: 'row',
    justifyContent: 'center',
    alignItems: 'stretch',
    gap: 30,
    width: '100%',
  },
  leftColumn: {
    alignItems: 'center',
    width: 350,
    overflow: 'hidden',
  },
  leftColumnCenter: {
    flex: 1,
    justifyContent: 'center',
    alignItems: 'center',
  },
  headerBlock: {
    alignItems: 'center',
    gap: 2,
    width: '100%',
    maxWidth: 350,
  },
  pageTitle: {
    fontFamily: FONTS.pixel,
    fontSize: 22,
    color: COLORS.title,
    textAlign: 'center',
    letterSpacing: 2,
  },
  titleInput: {
    fontFamily: FONTS.pixel,
    fontSize: 22,
    color: COLORS.title,
    textAlign: 'center',
    letterSpacing: 2,
    borderBottomWidth: 3,
    borderBottomColor: COLORS.tabActiveBorder,
    borderStyle: 'dashed',
    paddingVertical: 4,
    width: '100%',
  },
  subtitle: {
    fontFamily: FONTS.dot,
    fontSize: 14,
    color: COLORS.subtitle,
    textAlign: 'center',
    letterSpacing: 4,
    marginBottom: 2,
  },
  starsDeco: {
    fontSize: 14,
    color: COLORS.star,
    letterSpacing: 6,
    textAlign: 'center',
    marginBottom: 4,
  },
  // Book shell
  shell: {
    backgroundColor: '#faf5ea',
    borderTopLeftRadius: 4,
    borderBottomLeftRadius: 4,
    borderTopRightRadius: 16,
    borderBottomRightRadius: 16,
    paddingTop: 8,
    paddingBottom: 6,
    paddingRight: 8,
    paddingLeft: 24,
    borderWidth: 1,
    borderColor: COLORS.shellBorder,
    maxWidth: '100%' as any,
    boxShadow: '2px 3px 10px rgba(0,0,0,0.08)',
  },
  spineLine: {
    position: 'absolute',
    left: 18,
    top: 10,
    bottom: 10,
    width: 2,
    backgroundColor: COLORS.shellSpine1,
    borderRadius: 1,
  },
  screen: {
    backgroundColor: COLORS.screen,
    borderWidth: 2,
    borderColor: COLORS.screenBorder,
    borderStyle: 'dashed',
    borderRadius: 14,
    padding: 8,
  },
  sectionTitle: {
    fontFamily: FONTS.pixel,
    fontSize: 11,
    letterSpacing: 3,
    textTransform: 'uppercase',
    textAlign: 'center',
    marginBottom: 6,
    paddingBottom: 4,
    borderBottomWidth: 2,
    borderBottomColor: COLORS.sectionBorder,
    borderStyle: 'dashed',
    color: COLORS.textWarm,
  },

  // Tracker layout
  trackerLayout: {
    gap: 10,
  },
  trackerLayoutRow: {
    flexDirection: 'row',
    gap: 16,
  },
  sidebar: {
    gap: 6,
    alignItems: 'center',
    paddingHorizontal: 8,
  },
  sidebarVertical: {
    width: 160,
    alignItems: 'stretch',
  },
  sidebarTitle: {
    fontFamily: FONTS.pixel,
    fontSize: 9,
    letterSpacing: 2,
    textTransform: 'uppercase',
    textAlign: 'center',
    paddingBottom: 4,
    borderBottomWidth: 2,
    borderBottomColor: COLORS.sectionBorder,
    borderStyle: 'dashed',
    color: COLORS.textWarm,
    opacity: 0.7,
  },
  resetBtn: {
    backgroundColor: COLORS.btnReset,
    borderWidth: 2,
    borderColor: COLORS.btnResetBorder,
    borderRadius: 10,
    paddingVertical: 7,
    paddingHorizontal: 14,
    alignItems: 'center',
    marginTop: 6,
  },
  resetBtnText: {
    fontFamily: FONTS.pixel,
    fontSize: 9,
    letterSpacing: 1,
    color: COLORS.btnResetText,
    textTransform: 'uppercase',
  },
  loadingText: {
    fontFamily: FONTS.dot,
    fontSize: 14,
    color: COLORS.textMuted,
    textAlign: 'center',
    padding: 40,
  },
});
