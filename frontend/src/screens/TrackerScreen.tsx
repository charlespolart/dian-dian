import React, { useState, useCallback } from 'react';
import { View, Text, TextInput, TouchableOpacity, ScrollView, StyleSheet, Platform, useWindowDimensions } from 'react-native';
import { SafeAreaView } from 'react-native-safe-area-context';

const SafeContainer = Platform.OS === 'web'
  ? ({ children, ...props }: any) => <View style={props.style}>{children}</View>
  : SafeAreaView;
import { usePages } from '../hooks/usePages';
import { useCells } from '../hooks/useCells';
import { useLegends } from '../hooks/useLegends';
import { useLanguage } from '../contexts/LanguageContext';
import TrackerGrid from '../components/TrackerGrid';
import PaletteEditor from '../components/PaletteEditor';
import LegendEditor from '../components/LegendEditor';
import LegendList from '../components/LegendList';
import CellEditor from '../components/CellEditor';
import Stats from '../components/Stats';
import { useTapSound } from '../hooks/useTapSound';
import { apiFetch } from '../lib/api';
import { useConfirm } from '../hooks/useConfirm';
import { COLORS, FONTS, DEFAULT_PALETTE } from '../lib/theme';

interface Props {
  pageId: string;
  onBack: () => void;
  onOpenSettings: () => void;
}

export default function TrackerScreen({ pageId, onBack, onOpenSettings }: Props) {
  const { t } = useLanguage();
  const { pages, updatePage } = usePages();
  const confirm = useConfirm();
  const { playTap, playErase } = useTapSound();
  const [paletteEditorOpen, setPaletteEditorOpen] = useState(false);
  const [legendEditorOpen, setLegendEditorOpen] = useState(false);
  const [cellEditorTarget, setCellEditorTarget] = useState<{ month: number; day: number } | null>(null);
  const [editingTitle, setEditingTitle] = useState(false);
  const { width, height } = useWindowDimensions();

  const currentPageId = pageId;

  const { cells, getCellColor, getCell, setCell, deleteCell, resetAll } = useCells(currentPageId);
  const { legends, createLegend, deleteLegend, reorderLegends } = useLegends(currentPageId);

  const currentPage = pages.find(p => p.id === currentPageId);
  const currentPalette = currentPage?.palette || DEFAULT_PALETTE;

  const handleCellPress = useCallback((month: number, day: number) => {
    setCellEditorTarget({ month, day });
  }, []);

  const handleResetAll = useCallback(async () => {
    const ok = await confirm({
      title: t('tracker.resetAll'),
      message: t('tracker.resetConfirm'),
      confirmText: t('common.erase'),
      cancelText: t('common.cancel'),
      destructive: true,
    });
    if (ok) resetAll();
  }, [resetAll, confirm, t]);

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
            <Text style={styles.sidebarTitle}>{t('tracker.legend')}</Text>
            <LegendList legends={legends} />
            <TouchableOpacity style={styles.legendEditBtn} onPress={() => setLegendEditorOpen(true)}>
              <Text style={styles.legendEditBtnText}>{t('tracker.editLegends')}</Text>
            </TouchableOpacity>

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
                selectedColor={null}
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
      {/* Back button */}
      <View style={styles.backBar}>
        <TouchableOpacity style={styles.backBtn} onPress={onBack}>
          <Text style={styles.backBtnText}>← {t('settings.back')}</Text>
        </TouchableOpacity>
      </View>

      <ScrollView
        style={styles.outerScroll}
        contentContainerStyle={[styles.pageLayout, isWide ? styles.pageLayoutCentered : styles.pageLayoutMobile]}
        showsVerticalScrollIndicator={false}
      >
        {isWide ? (
          <View style={styles.wideLayout}>
            <View style={styles.leftColumn}>
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

          }}
          onClose={() => { setPaletteEditorOpen(false); setLegendEditorOpen(true); }}
        />
      )}

      {legendEditorOpen && currentPageId && (
        <LegendEditor
          legends={legends}
          cells={cells}
          palette={currentPalette}
          brushColor={null}
          onCreateLegend={createLegend}
          onDeleteLegend={async (id, color) => {
            await deleteLegend(id);
            const matching = cells.filter(c => c.color.toUpperCase() === color.toUpperCase());
            await Promise.all(matching.map(c => deleteCell(c.month, c.day)));
          }}
          onReorderLegends={reorderLegends}
          onOpenPaletteConfig={() => { setLegendEditorOpen(false); setPaletteEditorOpen(true); }}
          onClose={() => setLegendEditorOpen(false)}
        />
      )}

      {/* Cell Editor Popup */}
      {cellEditorTarget && currentPageId && (
        <CellEditor
          month={cellEditorTarget.month}
          day={cellEditorTarget.day}
          year={currentPage?.year ?? new Date().getFullYear()}
          cell={getCell(cellEditorTarget.month, cellEditorTarget.day)}
          legends={legends}
          onSave={(color, comment) => {
            playTap();
            setCell(cellEditorTarget.month, cellEditorTarget.day, color, comment);
            setCellEditorTarget(null);
          }}
          onDelete={() => {
            playErase();
            deleteCell(cellEditorTarget.month, cellEditorTarget.day);
            setCellEditorTarget(null);
          }}
          onNavigate={(dir) => {
            let { month, day } = cellEditorTarget;
            const yr = currentPage?.year ?? new Date().getFullYear();
            const daysInMonth = (m: number) => new Date(yr, m + 1, 0).getDate();
            day += dir;
            if (day < 1) { month--; if (month < 0) month = 11; day = daysInMonth(month); }
            else if (day > daysInMonth(month)) { month++; if (month > 11) month = 0; day = 1; }
            setCellEditorTarget({ month, day });
          }}
          onClose={() => setCellEditorTarget(null)}
        />
      )}
    </SafeContainer>
  );
}

const styles = StyleSheet.create({
  safeArea: {
    flex: 1,
  },
  backBar: {
    paddingHorizontal: 12,
    paddingVertical: 8,
  },
  backBtn: {
    paddingVertical: 4,
  },
  backBtnText: {
    fontFamily: FONTS.pixel,
    fontSize: 11,
    color: COLORS.accent,
    letterSpacing: 1,
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
  legendEditBtn: {
    alignSelf: 'center',
    marginTop: 4,
    paddingHorizontal: 10,
    paddingVertical: 4,
    borderWidth: 1,
    borderColor: COLORS.tabBorder,
    borderRadius: 8,
    borderStyle: 'dashed',
  },
  legendEditBtnText: {
    fontFamily: FONTS.pixel,
    fontSize: 8,
    letterSpacing: 1,
    color: COLORS.textMuted,
    textTransform: 'uppercase',
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
