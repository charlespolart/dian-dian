import React, { useState, useCallback, useRef, useEffect } from 'react';
import { View, Text, TextInput, TouchableOpacity, ScrollView, StyleSheet, Pressable, Platform } from 'react-native';
import { COLORS, FONTS, DEFAULT_PALETTE } from '../lib/theme';
import { useLanguage } from '../contexts/LanguageContext';
import { useConfirm } from '../hooks/useConfirm';
import type { Cell } from '../hooks/useCells';
import type { Legend } from '../hooks/useLegends';

interface Props {
  palette: string[][];
  cells: Cell[];
  legends: Legend[];
  onSave: (palette: string[][] | null, colorMap: Record<string, string>) => void;
  onClose: () => void;
}

const MAX_ROWS = 7;

function hexToRgb(hex: string): { r: number; g: number; b: number } {
  const n = parseInt(hex.replace('#', ''), 16);
  return { r: (n >> 16) & 255, g: (n >> 8) & 255, b: n & 255 };
}

function rgbToHex(r: number, g: number, b: number): string {
  return '#' + [r, g, b].map(v => Math.max(0, Math.min(255, v)).toString(16).padStart(2, '0')).join('').toUpperCase();
}

function isValidHex(s: string): boolean {
  return /^#[0-9A-Fa-f]{6}$/.test(s);
}

export default function PaletteEditor({ palette, cells, legends, onSave, onClose }: Props) {
  const { t } = useLanguage();
  const confirmDialog = useConfirm();
  const [rows, setRows] = useState<string[][]>(() => palette.map(r => [...r]));
  const originalPalette = useRef(palette.map(r => [...r]));
  const colorMapRef = useRef<Record<string, string>>({});
  const [editingColor, setEditingColor] = useState<{ row: number; col: number } | null>(null);
  const [hexInput, setHexInput] = useState('');
  const [rInput, setRInput] = useState('');
  const [gInput, setGInput] = useState('');
  const [bInput, setBInput] = useState('');
  const saveTimer = useRef<ReturnType<typeof setTimeout> | null>(null);

  // Auto-save with debounce
  const scheduleAutoSave = useCallback((newRows: string[][]) => {
    if (saveTimer.current) clearTimeout(saveTimer.current);
    saveTimer.current = setTimeout(() => {
      onSave(newRows, colorMapRef.current);
    }, 500);
  }, [onSave]);

  // Save immediately on unmount
  useEffect(() => {
    return () => {
      if (saveTimer.current) {
        clearTimeout(saveTimer.current);
        saveTimer.current = null;
      }
    };
  }, []);

  const trackColorChange = (row: number, col: number, newColor: string) => {
    const origRow = originalPalette.current[row];
    if (!origRow) return;
    const origColor = origRow[col];
    if (!origColor) return;
    const upper = origColor.toUpperCase();
    const newUpper = newColor.toUpperCase();
    if (upper !== newUpper) {
      colorMapRef.current[upper] = newUpper;
    } else {
      delete colorMapRef.current[upper];
    }
  };

  const openColorEditor = (row: number, col: number) => {
    const color = rows[row][col];
    const { r, g, b } = hexToRgb(color);
    setEditingColor({ row, col });
    setHexInput(color);
    setRInput(String(r));
    setGInput(String(g));
    setBInput(String(b));
  };

  const updateColorFromHex = (hex: string) => {
    setHexInput(hex);
    if (isValidHex(hex)) {
      const { r, g, b } = hexToRgb(hex);
      setRInput(String(r));
      setGInput(String(g));
      setBInput(String(b));
      if (editingColor) {
        const newHex = hex.toUpperCase();
        trackColorChange(editingColor.row, editingColor.col, newHex);
        setRows(prev => {
          const next = prev.map(r => [...r]);
          next[editingColor.row][editingColor.col] = newHex;
          scheduleAutoSave(next);
          return next;
        });
      }
    }
  };

  const updateColorFromRgb = (rs: string, gs: string, bs: string) => {
    setRInput(rs);
    setGInput(gs);
    setBInput(bs);
    const r = parseInt(rs) || 0;
    const g = parseInt(gs) || 0;
    const b = parseInt(bs) || 0;
    if (r >= 0 && r <= 255 && g >= 0 && g <= 255 && b >= 0 && b <= 255) {
      const hex = rgbToHex(r, g, b);
      setHexInput(hex);
      if (editingColor) {
        trackColorChange(editingColor.row, editingColor.col, hex);
        setRows(prev => {
          const next = prev.map(r => [...r]);
          next[editingColor.row][editingColor.col] = hex;
          scheduleAutoSave(next);
          return next;
        });
      }
    }
  };

  const addRow = () => {
    if (rows.length >= MAX_ROWS) return;
    setRows(prev => {
      const rowKey = (r: string[]) => r.map(c => c.toUpperCase()).join(',');
      const currentKeys = new Set(prev.map(rowKey));
      const missing = DEFAULT_PALETTE.find(defRow => !currentKeys.has(rowKey(defRow)));
      const newRow = missing ? [...missing] : ['#F8F8F8', '#DADADA', '#B0B0B0', '#888888', '#5C5C5C', '#3C3C3C'];
      const next = [...prev, newRow];
      scheduleAutoSave(next);
      return next;
    });
  };

  const getColorsInUse = useCallback((rowColors: string[]): { inCells: string[]; inLegends: string[] } => {
    const set = new Set(rowColors.map(c => c.toUpperCase()));
    const inCells = [...new Set(cells.filter(c => set.has(c.color.toUpperCase())).map(c => c.color))];
    const inLegends = [...new Set(legends.filter(l => set.has(l.color.toUpperCase())).map(l => l.color))];
    return { inCells, inLegends };
  }, [cells, legends]);

  const deleteRow = (rowIdx: number) => {
    if (rows.length <= 1) return;
    const { inCells, inLegends } = getColorsInUse(rows[rowIdx]);
    const hasUsage = inCells.length > 0 || inLegends.length > 0;

    if (hasUsage) {
      confirmDialog({
        title: t('palette.deleteRow'),
        message: t('palette.deleteRowBlocked'),
        confirmText: 'OK',
      });
      return;
    }

    setRows(prev => {
      const next = prev.filter((_, i) => i !== rowIdx);
      scheduleAutoSave(next);
      return next;
    });
    if (editingColor?.row === rowIdx) setEditingColor(null);
    else if (editingColor && editingColor.row > rowIdx) {
      setEditingColor({ ...editingColor, row: editingColor.row - 1 });
    }
  };

  const handleClose = () => {
    // Flush pending save
    if (saveTimer.current) {
      clearTimeout(saveTimer.current);
      onSave(rows, colorMapRef.current);
    }
    onClose();
  };

  const currentColor = editingColor ? rows[editingColor.row]?.[editingColor.col] : null;

  return (
    <View style={styles.overlay}>
      <Pressable style={styles.backdrop} onPress={handleClose} />
      <View style={styles.modal}>
        <View style={styles.header}>
          <Text style={styles.title}>{t('palette.title')}</Text>
          <TouchableOpacity onPress={handleClose}>
            <Text style={styles.closeBtn}>✕</Text>
          </TouchableOpacity>
        </View>

        <ScrollView style={styles.content} showsVerticalScrollIndicator={false}>
          {rows.map((row, rowIdx) => (
            <View key={rowIdx} style={styles.rowContainer}>
              <View style={styles.swatchRow}>
                {row.map((color, colIdx) => (
                  <TouchableOpacity
                    key={colIdx}
                    style={[
                      styles.swatch,
                      { backgroundColor: color },
                      editingColor?.row === rowIdx && editingColor?.col === colIdx && styles.swatchEditing,
                    ]}
                    onPress={() => openColorEditor(rowIdx, colIdx)}
                  />
                ))}
              </View>
              {rows.length > 1 && (
                <TouchableOpacity style={styles.deleteRowBtn} onPress={() => deleteRow(rowIdx)}>
                  <Text style={styles.deleteRowText}>✕</Text>
                </TouchableOpacity>
              )}
            </View>
          ))}

          {rows.length < MAX_ROWS && (
            <TouchableOpacity style={styles.addRowBtn} onPress={addRow}>
              <Text style={styles.addRowText}>{t('palette.addRow')}</Text>
            </TouchableOpacity>
          )}

          {editingColor && currentColor && (
            <View style={styles.colorEditor}>
              <View style={styles.previewRow}>
                {Platform.OS === 'web' ? (
                  <TouchableOpacity
                    style={[styles.preview, { backgroundColor: currentColor, position: 'relative', overflow: 'hidden' }]}
                    activeOpacity={0.8}
                  >
                    <input
                      type="color"
                      value={currentColor}
                      onChange={(e: any) => updateColorFromHex(e.target.value)}
                      style={{
                        position: 'absolute',
                        top: 0, left: 0, width: '100%', height: '100%',
                        opacity: 0, cursor: 'pointer',
                      }}
                    />
                  </TouchableOpacity>
                ) : (
                  <View style={[styles.preview, { backgroundColor: currentColor }]} />
                )}
                <Text style={styles.previewHex}>{currentColor}</Text>
              </View>

              <View style={styles.inputRow}>
                <Text style={styles.inputLabel}>HEX</Text>
                <TextInput
                  style={styles.hexField}
                  value={hexInput}
                  onChangeText={updateColorFromHex}
                  autoCapitalize="characters"
                  maxLength={7}
                />
              </View>

              <View style={styles.inputRow}>
                <Text style={styles.inputLabel}>R</Text>
                <TextInput
                  style={styles.rgbField}
                  value={rInput}
                  onChangeText={(v) => updateColorFromRgb(v, gInput, bInput)}
                  keyboardType="number-pad"
                  maxLength={3}
                />
                <Text style={styles.inputLabel}>G</Text>
                <TextInput
                  style={styles.rgbField}
                  value={gInput}
                  onChangeText={(v) => updateColorFromRgb(rInput, v, bInput)}
                  keyboardType="number-pad"
                  maxLength={3}
                />
                <Text style={styles.inputLabel}>B</Text>
                <TextInput
                  style={styles.rgbField}
                  value={bInput}
                  onChangeText={(v) => updateColorFromRgb(rInput, gInput, v)}
                  keyboardType="number-pad"
                  maxLength={3}
                />
              </View>
            </View>
          )}
        </ScrollView>
      </View>
    </View>
  );
}

const styles = StyleSheet.create({
  overlay: {
    ...StyleSheet.absoluteFillObject,
    zIndex: 100,
    justifyContent: 'center',
    alignItems: 'center',
  },
  backdrop: {
    ...StyleSheet.absoluteFillObject,
    backgroundColor: 'rgba(0,0,0,0.3)',
  },
  modal: {
    width: '90%',
    maxWidth: 400,
    maxHeight: '85%',
    backgroundColor: '#faf5ea',
    borderRadius: 14,
    borderWidth: 1,
    borderColor: COLORS.shellBorder,
    overflow: 'hidden',
  },
  header: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    padding: 16,
    borderBottomWidth: 1,
    borderBottomColor: COLORS.sectionBorder,
  },
  title: {
    fontFamily: FONTS.pixel,
    fontSize: 12,
    letterSpacing: 2,
    color: COLORS.accent,
    textTransform: 'uppercase',
  },
  closeBtn: {
    fontSize: 16,
    color: COLORS.textMuted,
  },
  content: {
    padding: 16,
  },
  rowContainer: {
    flexDirection: 'row',
    alignItems: 'center',
    marginBottom: 8,
    gap: 8,
  },
  swatchRow: {
    flexDirection: 'row',
    gap: 6,
    flex: 1,
  },
  swatch: {
    width: 28,
    height: 28,
    borderRadius: 14,
    borderWidth: 2,
    borderColor: COLORS.tabBorder,
  },
  swatchEditing: {
    borderColor: '#8880a8',
    borderWidth: 3,
    transform: [{ scale: 1.1 }],
  },
  deleteRowBtn: {
    padding: 6,
  },
  deleteRowText: {
    fontSize: 12,
    color: '#c0392b',
  },
  addRowBtn: {
    alignSelf: 'center',
    marginVertical: 8,
    paddingHorizontal: 14,
    paddingVertical: 6,
    borderWidth: 2,
    borderColor: COLORS.tabBorder,
    borderStyle: 'dashed',
    borderRadius: 10,
  },
  addRowText: {
    fontFamily: FONTS.pixel,
    fontSize: 9,
    letterSpacing: 1,
    color: COLORS.subtitle,
    textTransform: 'uppercase',
  },
  colorEditor: {
    marginTop: 12,
    padding: 10,
    backgroundColor: COLORS.inputBg,
    borderRadius: 10,
    borderWidth: 1,
    borderColor: COLORS.inputBorder,
    gap: 8,
    overflow: 'hidden',
  },
  previewRow: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 10,
  },
  preview: {
    width: 48,
    height: 48,
    borderRadius: 24,
    borderWidth: 2,
    borderColor: COLORS.tabBorder,
  },
  previewHex: {
    fontFamily: FONTS.pixel,
    fontSize: 12,
    color: COLORS.accent,
    letterSpacing: 1,
  },
  inputRow: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 6,
  },
  inputLabel: {
    fontFamily: FONTS.pixel,
    fontSize: 10,
    color: COLORS.textMuted,
    width: 18,
  },
  hexField: {
    flex: 1,
    minWidth: 0,
    fontFamily: FONTS.dot,
    fontSize: 13,
    paddingVertical: 5,
    paddingHorizontal: 8,
    borderWidth: 2,
    borderColor: COLORS.inputBorder,
    borderRadius: 8,
    backgroundColor: '#fff',
    color: COLORS.inputText,
  },
  rgbField: {
    flex: 1,
    minWidth: 0,
    fontFamily: FONTS.dot,
    fontSize: 13,
    paddingVertical: 5,
    paddingHorizontal: 6,
    borderWidth: 2,
    borderColor: COLORS.inputBorder,
    borderRadius: 8,
    backgroundColor: '#fff',
    color: COLORS.inputText,
    textAlign: 'center',
  },
});
