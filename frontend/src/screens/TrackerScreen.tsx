import React, { useState, useCallback, useRef } from 'react';
import { View, Text, TextInput, TouchableOpacity, ScrollView, Animated, StyleSheet, Alert, Platform, useWindowDimensions } from 'react-native';
import { SafeAreaView } from 'react-native-safe-area-context';

const SafeContainer = Platform.OS === 'web'
  ? ({ children, ...props }: any) => <View style={props.style}>{children}</View>
  : SafeAreaView;
import { usePages } from '../hooks/usePages';
import { useCells } from '../hooks/useCells';
import { useLegends } from '../hooks/useLegends';
import { useLanguage } from '../contexts/LanguageContext';
import { useAuth } from '../contexts/AuthContext';
import TrackerGrid from '../components/TrackerGrid';
import ColorPicker from '../components/ColorPicker';
import PaletteEditor from '../components/PaletteEditor';
import LegendList from '../components/LegendList';
import PageTabs from '../components/PageTabs';
import SideMenu from '../components/SideMenu';
import Stats from '../components/Stats';
import { apiFetch } from '../lib/api';
import { COLORS, FONTS, DEFAULT_PALETTE } from '../lib/theme';

interface Props {
  onOpenSettings: () => void;
}

export default function TrackerScreen({ onOpenSettings }: Props) {
  const { t } = useLanguage();
  const { emailVerified, resendVerification } = useAuth();
  const [verificationSent, setVerificationSent] = useState(false);
  const { pages, createPage, updatePage, deletePage } = usePages();
  const [activePageId, setActivePageId] = useState<string | null>(null);
  const [selectedColor, setSelectedColor] = useState<string | null>(DEFAULT_PALETTE[0][0]);
  const [paletteEditorOpen, setPaletteEditorOpen] = useState(false);
  const [editingTitle, setEditingTitle] = useState(false);
  const [menuOpen, setMenuOpen] = useState(false);
  const { width, height } = useWindowDimensions();

  // Collapsing header via diffClamp
  const TAB_H = 50;
  const scrollY = useRef(new Animated.Value(0)).current;
  const tabBarAnim = useRef(new Animated.Value(0)).current;
  const lastScrollY = useRef(0);
  const tabOffset = useRef(0);
  const contentHeight = useRef(0);
  const layoutHeight = useRef(0);
  const wasBouncing = useRef(false);

  const onScroll = useCallback((e: any) => {
    const y = e.nativeEvent.contentOffset.y;
    const maxScroll = contentHeight.current - layoutHeight.current;

    // Ignore bounce zones
    if (y < 0 || y > maxScroll) {
      wasBouncing.current = true;
      return;
    }

    // Skip first event after bounce to reset baseline
    if (wasBouncing.current) {
      wasBouncing.current = false;
      lastScrollY.current = y;
      return;
    }

    const diff = y - lastScrollY.current;
    lastScrollY.current = y;

    tabOffset.current = Math.min(0, Math.max(-TAB_H, tabOffset.current - diff));
    tabBarAnim.setValue(tabOffset.current);
  }, []);

  const onContentSizeChange = useCallback((_w: number, h: number) => { contentHeight.current = h; }, []);
  const onScrollLayout = useCallback((e: any) => { layoutHeight.current = e.nativeEvent.layout.height; }, []);

  const tabTranslateY = tabBarAnim;

  const currentPageId = activePageId && pages.find(p => p.id === activePageId)
    ? activePageId
    : pages[0]?.id ?? null;

  const { cells, getCellColor, setCell, deleteCell, resetAll } = useCells(currentPageId);
  const { legends, createLegend, deleteLegend } = useLegends(currentPageId);

  const currentPage = pages.find(p => p.id === currentPageId);
  const currentPalette = currentPage?.palette || DEFAULT_PALETTE;

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
  const isTablet = !isMobile && !isWide;
  const SIDEBAR_W = hasSidebarRow ? (isTablet ? 130 : 160) : 0;
  const SIDEBAR_GAP = hasSidebarRow ? 12 : 0;
  const LABEL_W = 24;

  // Vertical: shell padding(8+6) + screen padding+border(8+2)*2 + section title(~30) + header row(~20)
  const vOverhead = 8 + 6 + 20 + 30 + 20;
  const maxShellH = height - 4;
  const availH = maxShellH - vOverhead;
  const dotFromH = Math.floor((availH - 32 * spacingV) / 31);

  // Horizontal overhead: all paddings, borders, sidebar, labels, and safety margin
  const pagePadH = isWide ? 60 : 8;
  const shellPadH = 24 + 8 + 2;
  const screenPadH = (8 + 2) * 2;
  const safetyMargin = 16;
  const hOverhead = shellPadH + screenPadH + SIDEBAR_W + SIDEBAR_GAP + LABEL_W + pagePadH + safetyMargin;
  const availW = width - hOverhead;
  const dotFromW = Math.floor((availW - 13 * spacingH) / 12);

  // Vertical layout (non-wide) scrolls, so use width only; wide layout uses min(h, w)
  const maxDot = isWide ? 48 : 32;
  const dotSize = Math.max(8, Math.min(isWide ? Math.min(dotFromH, dotFromW) : dotFromW, maxDot));

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
    <View style={[styles.shell, isWide && { maxHeight: height - 4 }]}>
      <View style={styles.spineLine} />
      <View style={styles.screen}>
        <Text style={styles.sectionTitle}>{currentPage?.title || 'Tracker'}</Text>

        <View style={[styles.trackerLayout, width >= 768 && styles.trackerLayoutRow]}>
          <View style={[styles.sidebar, width >= 768 && [styles.sidebarVertical, { width: SIDEBAR_W }]]}>
            <Text style={styles.sidebarTitle}>{t('tracker.colors')}</Text>
            <ColorPicker palette={currentPalette} selectedColor={selectedColor} onSelect={setSelectedColor} onOpenPaletteConfig={() => setPaletteEditorOpen(true)} />

            <Text style={styles.sidebarTitle}>{t('tracker.legend')}</Text>
            <LegendList
              legends={legends}
              selectedColor={selectedColor}
              onCreateLegend={createLegend}
              onDeleteLegend={async (id, color) => {
                await deleteLegend(id);
                // Delete all cells with this color
                const matching = cells.filter(c => c.color.toUpperCase() === color.toUpperCase());
                await Promise.all(matching.map(c => deleteCell(c.month, c.day)));
              }}
            />

            <Text style={[styles.sidebarTitle, { marginTop: 8 }]}>{t('tracker.stats')}</Text>
            <Stats cells={cells} />

            <TouchableOpacity style={styles.resetBtn} onPress={handleResetAll}>
              <Text style={styles.resetBtnText}>{t('tracker.resetAll')}</Text>
            </TouchableOpacity>
          </View>

          <View style={styles.gridContainer}>
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
          </View>
        </View>
      </View>
    </View>
  );

  return (
    <SafeContainer style={styles.safeArea} edges={['top', 'bottom']}>
      {/* Email verification banner */}
      {!emailVerified && (
        <View style={styles.verifyBanner}>
          <Text style={styles.verifyText}>{t('auth.verifyEmailBanner')}</Text>
          <TouchableOpacity onPress={async () => { await resendVerification(); setVerificationSent(true); }}>
            <Text style={styles.verifyLink}>{verificationSent ? t('auth.verificationSent') : t('auth.resendVerification')}</Text>
          </TouchableOpacity>
        </View>
      )}
      {/* Top bar: hamburger + horizontal tabs — collapses on scroll */}
      {!isWide && (
        <Animated.View style={[styles.topBarOverlay, { transform: [{ translateY: tabTranslateY }] }]}>
          <View style={styles.topBar}>
            <TouchableOpacity style={styles.hamburger} onPress={() => setMenuOpen(true)}>
              <Text style={styles.hamburgerText}>☰</Text>
            </TouchableOpacity>
            <View style={styles.tabsBarInline}>
              {renderTabs()}
            </View>
          </View>
        </Animated.View>
      )}

      <ScrollView
        style={styles.outerScroll}
        contentContainerStyle={[styles.pageLayout, isWide ? styles.pageLayoutCentered : styles.pageLayoutMobile]}
        showsVerticalScrollIndicator={false}
        onScroll={!isWide ? onScroll : undefined}
        onContentSizeChange={!isWide ? onContentSizeChange : undefined}
        onLayout={!isWide ? onScrollLayout : undefined}
        scrollEventThrottle={16}
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

      {paletteEditorOpen && currentPageId && (
        <PaletteEditor
          palette={currentPalette}
          cells={cells}
          legends={legends}
          onSave={async (palette, colorMap) => {
            const isDefault = JSON.stringify(palette) === JSON.stringify(DEFAULT_PALETTE);
            updatePage(currentPageId, { palette: isDefault ? null : palette });

            // Recolor cells and legends if colors changed
            if (Object.keys(colorMap).length > 0) {
              await apiFetch(`/cells/${currentPageId}/recolor`, {
                method: 'PATCH',
                body: JSON.stringify({ colorMap }),
              });
              await apiFetch(`/legends/${currentPageId}/recolor`, {
                method: 'PATCH',
                body: JSON.stringify({ colorMap }),
              });
            }

            // Reset selected color if it's no longer in the new palette
            if (palette && selectedColor) {
              const newColor = colorMap[selectedColor.toUpperCase()] || selectedColor;
              const flat = palette.flat();
              if (!flat.includes(newColor)) setSelectedColor(palette[0]?.[0] || null);
              else setSelectedColor(newColor);
            }
          }}
          onClose={() => setPaletteEditorOpen(false)}
        />
      )}
    </SafeContainer>
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
  topBarOverlay: {
    position: 'absolute',
    top: 0,
    left: 0,
    right: 0,
    zIndex: 10,
    backgroundColor: COLORS.bg,
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
    alignItems: 'center',
    padding: 4,
    gap: 4,
  },
  pageLayoutMobile: {
    paddingTop: 54,
    paddingBottom: 12,
  },
  pageLayoutCentered: {
    minHeight: '100%',
    paddingVertical: 8,
  },
  wideLayout: {
    flex: 1,
    flexDirection: 'row',
    justifyContent: 'center',
    alignItems: 'stretch',
    gap: 20,
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
    gap: 12,
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
  gridContainer: {
    flex: 1,
    overflow: 'hidden',
  },
  loadingText: {
    fontFamily: FONTS.dot,
    fontSize: 14,
    color: COLORS.textMuted,
    textAlign: 'center',
    padding: 40,
  },
});
