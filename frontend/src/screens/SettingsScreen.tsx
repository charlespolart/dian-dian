import React from 'react';
import { View, Text, TouchableOpacity, ScrollView, StyleSheet, Linking, Platform } from 'react-native';
import { SafeAreaView } from 'react-native-safe-area-context';

const SafeContainer = Platform.OS === 'web'
  ? ({ children, ...props }: any) => <View style={props.style}>{children}</View>
  : SafeAreaView;
import { useAuth } from '../contexts/AuthContext';
import { useLanguage } from '../contexts/LanguageContext';
import { useConfirm } from '../hooks/useConfirm';
import { apiFetch } from '../lib/api';
import { COLORS, FONTS } from '../lib/theme';

interface Props {
  onBack: () => void;
}

export default function SettingsScreen({ onBack }: Props) {
  const { logout } = useAuth();
  const { lang, setLang, t } = useLanguage();
  const confirm = useConfirm();

  const handleLogout = async () => {
    const ok = await confirm({
      title: t('settings.logout'),
      message: t('settings.logoutConfirm'),
      confirmText: t('common.yes'),
      cancelText: t('common.cancel'),
    });
    if (ok) logout();
  };

  const handleDeleteAccount = async () => {
    const ok = await confirm({
      title: t('settings.deleteAccount'),
      message: t('settings.deleteAccountConfirm'),
      confirmText: t('common.delete'),
      cancelText: t('common.cancel'),
      destructive: true,
    });
    if (ok) {
      try {
        await apiFetch('/auth/account', { method: 'DELETE' });
        logout();
      } catch { /* ignore */ }
    }
  };

  return (
    <SafeContainer style={styles.safeArea} edges={['top', 'bottom']}>
      {/* Header */}
      <View style={styles.header}>
        <TouchableOpacity onPress={onBack} style={styles.backBtn}>
          <Text style={styles.backText}>← {t('settings.back')}</Text>
        </TouchableOpacity>
        <Text style={styles.title}>{t('settings.title')}</Text>
        <View style={{ width: 80 }} />
      </View>

      <ScrollView style={styles.scrollArea} contentContainerStyle={styles.content}>
        {/* Language */}
        <View style={styles.section}>
          <Text style={styles.sectionTitle}>{t('settings.language')}</Text>
          <View style={styles.langGrid}>
            <View style={styles.optionRow}>
              <TouchableOpacity
                style={[styles.langBtn, lang === 'fr' && styles.langBtnActive]}
                onPress={() => setLang('fr')}
              >
                <Text style={[styles.langBtnText, lang === 'fr' && styles.langBtnTextActive]}>
                  {t('settings.french')}
                </Text>
              </TouchableOpacity>
              <TouchableOpacity
                style={[styles.langBtn, lang === 'en' && styles.langBtnActive]}
                onPress={() => setLang('en')}
              >
                <Text style={[styles.langBtnText, lang === 'en' && styles.langBtnTextActive]}>
                  {t('settings.english')}
                </Text>
              </TouchableOpacity>
            </View>
            <View style={styles.optionRow}>
              <TouchableOpacity
                style={[styles.langBtn, lang === 'zh-CN' && styles.langBtnActive]}
                onPress={() => setLang('zh-CN')}
              >
                <Text style={[styles.langBtnText, lang === 'zh-CN' && styles.langBtnTextActive]}>
                  {t('settings.chineseSimplified')}
                </Text>
              </TouchableOpacity>
              <TouchableOpacity
                style={[styles.langBtn, lang === 'zh-TW' && styles.langBtnActive]}
                onPress={() => setLang('zh-TW')}
              >
                <Text style={[styles.langBtnText, lang === 'zh-TW' && styles.langBtnTextActive]}>
                  {t('settings.chineseTraditional')}
                </Text>
              </TouchableOpacity>
            </View>
          </View>
        </View>

        {/* Theme - coming soon */}
        <View style={styles.section}>
          <Text style={styles.sectionTitle}>{t('settings.theme')}</Text>
          <Text style={styles.comingSoon}>{t('settings.comingSoon')}</Text>
        </View>

        {/* Subscription - coming soon */}
        <View style={styles.section}>
          <Text style={styles.sectionTitle}>{t('settings.subscription')}</Text>
          <Text style={styles.comingSoon}>{t('settings.comingSoon')}</Text>
        </View>

        {/* Info */}
        <View style={styles.section}>
          <Text style={styles.sectionTitle}>{t('settings.about')}</Text>
          <TouchableOpacity onPress={() => Linking.openURL(`https://mydiandian.app/about?lang=${lang}`)}>
            <Text style={styles.linkText}>{t('settings.about')}</Text>
          </TouchableOpacity>
          <TouchableOpacity onPress={() => Linking.openURL(`https://mydiandian.app/contact?lang=${lang}`)}>
            <Text style={styles.linkText}>{t('settings.contact')}</Text>
          </TouchableOpacity>
          <TouchableOpacity onPress={() => Linking.openURL(`https://mydiandian.app/privacy?lang=${lang}`)}>
            <Text style={styles.linkText}>{t('settings.privacy')}</Text>
          </TouchableOpacity>
          <TouchableOpacity onPress={() => Linking.openURL(`https://mydiandian.app/terms?lang=${lang}`)}>
            <Text style={styles.linkText}>{t('settings.terms')}</Text>
          </TouchableOpacity>
          <Text style={styles.versionText}>{t('settings.version')} 1.0.0</Text>
        </View>

        {/* Account */}
        <View style={[styles.section, { marginTop: 'auto' as any }]}>
          <Text style={styles.sectionTitle}>{t('settings.account')}</Text>
          <TouchableOpacity style={styles.logoutBtn} onPress={handleLogout}>
            <Text style={styles.logoutText}>{t('settings.logout')}</Text>
          </TouchableOpacity>
          <TouchableOpacity style={styles.deleteBtn} onPress={handleDeleteAccount}>
            <Text style={styles.deleteText}>{t('settings.deleteAccount')}</Text>
          </TouchableOpacity>
        </View>
      </ScrollView>
    </SafeContainer>
  );
}

const styles = StyleSheet.create({
  safeArea: {
    flex: 1,
  },
  header: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    paddingHorizontal: 16,
    paddingVertical: 10,
  },
  backBtn: {
    width: 80,
  },
  backText: {
    fontFamily: FONTS.pixel,
    fontSize: 11,
    color: COLORS.accent,
    letterSpacing: 1,
  },
  title: {
    fontFamily: FONTS.pixel,
    fontSize: 18,
    color: COLORS.title,
    letterSpacing: 2,
    textAlign: 'center',
  },
  scrollArea: {
    flex: 1,
  },
  content: {
    padding: 20,
    paddingBottom: 40,
    maxWidth: 500,
    width: '100%',
    alignSelf: 'center',
    gap: 24,
  },
  section: {
    gap: 10,
  },
  sectionTitle: {
    fontFamily: FONTS.pixel,
    fontSize: 11,
    letterSpacing: 2,
    textTransform: 'uppercase',
    paddingBottom: 6,
    borderBottomWidth: 2,
    borderBottomColor: COLORS.sectionBorder,
    borderStyle: 'dashed',
    color: COLORS.textWarm,
  },
  langGrid: {
    gap: 10,
  },
  optionRow: {
    flexDirection: 'row',
    gap: 10,
  },
  langBtn: {
    flex: 1,
    paddingVertical: 10,
    borderRadius: 10,
    borderWidth: 2,
    borderColor: COLORS.tabBorder,
    backgroundColor: COLORS.tab,
    alignItems: 'center',
  },
  langBtnActive: {
    borderColor: COLORS.tabActiveBorder,
    backgroundColor: COLORS.tabActive,
  },
  langBtnText: {
    fontFamily: FONTS.dot,
    fontSize: 14,
    color: COLORS.textMuted,
  },
  langBtnTextActive: {
    color: COLORS.accent,
    fontWeight: '600',
  },
  comingSoon: {
    fontFamily: FONTS.dot,
    fontSize: 13,
    color: COLORS.textMuted,
    fontStyle: 'italic',
  },
  logoutBtn: {
    backgroundColor: COLORS.btnReset,
    borderWidth: 2,
    borderColor: COLORS.btnResetBorder,
    borderRadius: 10,
    paddingVertical: 10,
    paddingHorizontal: 14,
    alignItems: 'center',
  },
  logoutText: {
    fontFamily: FONTS.pixel,
    fontSize: 11,
    letterSpacing: 1,
    color: COLORS.btnResetText,
    textTransform: 'uppercase',
  },
  linkText: {
    fontFamily: FONTS.dot,
    fontSize: 13,
    color: COLORS.accent,
    paddingVertical: 4,
  },
  versionText: {
    fontFamily: FONTS.dot,
    fontSize: 12,
    color: COLORS.textMuted,
    marginTop: 4,
  },
  deleteBtn: {
    borderWidth: 2,
    borderColor: '#c0392b',
    borderRadius: 10,
    paddingVertical: 10,
    paddingHorizontal: 14,
    alignItems: 'center',
  },
  deleteText: {
    fontFamily: FONTS.pixel,
    fontSize: 11,
    letterSpacing: 1,
    color: '#c0392b',
    textTransform: 'uppercase',
  },
});
