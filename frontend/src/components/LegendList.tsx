import React, { useState } from 'react';
import { View, Text, TextInput, TouchableOpacity, StyleSheet, Alert, Platform } from 'react-native';
import { COLORS, FONTS } from '../lib/theme';
import { useLanguage } from '../contexts/LanguageContext';
import type { Legend } from '../hooks/useLegends';

interface Props {
  legends: Legend[];
  pickerColor: string | null;
  brushColor: string | null;
  onSelectLegend: (color: string) => void;
  onCreateLegend: (color: string, label: string) => Promise<any>;
  onDeleteLegend: (id: string, color: string) => Promise<void>;
}

export default function LegendList({ legends, pickerColor, brushColor, onSelectLegend, onCreateLegend, onDeleteLegend }: Props) {
  const { t } = useLanguage();
  const [newLabel, setNewLabel] = useState('');
  const [adding, setAdding] = useState(false);

  const handleAdd = async () => {
    if (!pickerColor || !newLabel.trim()) return;
    setAdding(true);
    try {
      await onCreateLegend(pickerColor, newLabel.trim());
      setNewLabel('');
    } catch { /* ignore */ }
    setAdding(false);
  };

  return (
    <View style={styles.container}>
      {/* Legend items — clickable to select as brush */}
      <View style={styles.legends}>
        {legends.map(legend => {
          const isSelected = brushColor?.toUpperCase() === legend.color.toUpperCase();
          return (
            <TouchableOpacity
              key={legend.id}
              style={[styles.legendItem, isSelected && styles.legendItemSelected]}
              onPress={() => onSelectLegend(legend.color)}
              activeOpacity={0.7}
            >
              <View style={[styles.legendDot, { backgroundColor: legend.color }, isSelected && styles.legendDotSelected]} />
              <Text style={[styles.legendLabel, isSelected && styles.legendLabelSelected]} numberOfLines={1}>{legend.label}</Text>
              <TouchableOpacity onPress={(e) => {
                e.stopPropagation?.();
                const doDelete = () => onDeleteLegend(legend.id, legend.color);
                if (Platform.OS === 'web') {
                  if (confirm(t('tracker.deleteLegendConfirm'))) doDelete();
                } else {
                  Alert.alert(t('common.delete'), t('tracker.deleteLegendConfirm'), [
                    { text: t('common.cancel'), style: 'cancel' },
                    { text: t('common.delete'), style: 'destructive', onPress: doDelete },
                  ]);
                }
              }} hitSlop={{ top: 8, bottom: 8, left: 8, right: 8 }}>
                <Text style={styles.deleteText}>x</Text>
              </TouchableOpacity>
            </TouchableOpacity>
          );
        })}
      </View>

      {/* Add legend input */}
      <View style={styles.inputRow}>
        {pickerColor && (
          <View style={[styles.pickerPreview, { backgroundColor: pickerColor }]} />
        )}
        <TextInput
          style={[styles.input, { flex: 1 }]}
          placeholder={t('tracker.legendPlaceholder')}
          placeholderTextColor="#b0a890"
          value={newLabel}
          onChangeText={setNewLabel}
          onSubmitEditing={handleAdd}
        />
      </View>
      <TouchableOpacity style={styles.addBtn} onPress={handleAdd} disabled={adding || !pickerColor}>
        <Text style={styles.addBtnText}>{t('common.add')}</Text>
      </TouchableOpacity>
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    gap: 4,
  },
  legends: {
    gap: 3,
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
  legendLabel: {
    flex: 1,
    fontFamily: FONTS.dot,
    fontSize: 12,
    color: COLORS.textLabel,
  },
  legendLabelSelected: {
    color: COLORS.accent,
  },
  deleteText: {
    fontSize: 12,
    opacity: 0.5,
    color: COLORS.textLabel,
  },
  inputRow: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 6,
    marginTop: 2,
  },
  pickerPreview: {
    width: 18,
    height: 18,
    borderRadius: 9,
    borderWidth: 2,
    borderColor: 'rgba(0,0,0,0.08)',
  },
  input: {
    fontFamily: FONTS.dot,
    fontSize: 12,
    borderWidth: 2,
    borderColor: COLORS.inputBorder,
    borderRadius: 8,
    paddingHorizontal: 7,
    paddingVertical: 5,
    backgroundColor: COLORS.inputBg,
    color: COLORS.inputText,
  },
  addBtn: {
    backgroundColor: COLORS.btnAdd,
    borderWidth: 2,
    borderColor: COLORS.btnAddBorder,
    borderRadius: 10,
    paddingVertical: 6,
    paddingHorizontal: 12,
    alignItems: 'center',
  },
  addBtnText: {
    fontFamily: FONTS.pixel,
    fontSize: 10,
    letterSpacing: 1,
    color: COLORS.btnAddText,
    textTransform: 'uppercase',
  },
});
