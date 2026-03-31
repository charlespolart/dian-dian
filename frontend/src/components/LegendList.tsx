import React, { useState } from 'react';
import { View, Text, TextInput, TouchableOpacity, StyleSheet, Alert, Platform } from 'react-native';
import { COLORS, FONTS } from '../lib/theme';
import { useLanguage } from '../contexts/LanguageContext';
import type { Legend } from '../hooks/useLegends';

interface Props {
  legends: Legend[];
  selectedColor: string | null;
  onCreateLegend: (color: string, label: string) => Promise<any>;
  onDeleteLegend: (id: string, color: string) => Promise<void>;
}

export default function LegendList({ legends, selectedColor, onCreateLegend, onDeleteLegend }: Props) {
  const { t } = useLanguage();
  const [newLabel, setNewLabel] = useState('');
  const [adding, setAdding] = useState(false);

  const handleAdd = async () => {
    if (!selectedColor || !newLabel.trim()) return;
    setAdding(true);
    try {
      await onCreateLegend(selectedColor, newLabel.trim());
      setNewLabel('');
    } catch { /* ignore */ }
    setAdding(false);
  };

  return (
    <View style={styles.container}>
      {/* Legend items */}
      <View style={styles.legends}>
        {legends.map(legend => (
          <View key={legend.id} style={styles.legendItem}>
            <View style={[styles.legendDot, { backgroundColor: legend.color }]} />
            <Text style={styles.legendLabel} numberOfLines={1}>{legend.label}</Text>
            <TouchableOpacity onPress={() => {
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
          </View>
        ))}
      </View>

      {/* Add legend input */}
      <View style={styles.inputRow}>
        <TextInput
          style={styles.input}
          placeholder={t('tracker.legendPlaceholder')}
          placeholderTextColor="#b0a890"
          value={newLabel}
          onChangeText={setNewLabel}
          onSubmitEditing={handleAdd}
        />
        <TouchableOpacity style={styles.addBtn} onPress={handleAdd} disabled={adding || !selectedColor}>
          <Text style={styles.addBtnText}>{t('common.add')}</Text>
        </TouchableOpacity>
      </View>
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
    paddingVertical: 3,
    paddingHorizontal: 5,
    borderRadius: 6,
  },
  legendDot: {
    width: 14,
    height: 14,
    borderRadius: 7,
    borderWidth: 2,
    borderColor: 'rgba(0,0,0,0.08)',
  },
  legendLabel: {
    flex: 1,
    fontFamily: FONTS.dot,
    fontSize: 12,
    color: COLORS.textLabel,
  },
  deleteText: {
    fontSize: 12,
    opacity: 0.5,
    color: COLORS.textLabel,
  },
  inputRow: {
    gap: 4,
    marginTop: 2,
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
