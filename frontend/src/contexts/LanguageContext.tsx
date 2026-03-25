import React, { createContext, useContext, useState, useEffect, useCallback } from 'react';
import AsyncStorage from '@react-native-async-storage/async-storage';
import { getLocales } from 'expo-localization';
import { translate, type Language, type TranslationKey } from '../lib/i18n';

const SUPPORTED_LANGS: Language[] = ['fr', 'en', 'zh-CN', 'zh-TW'];

function getDeviceLanguage(): Language {
  try {
    const locales = getLocales();
    for (const locale of locales) {
      const tag = locale.languageTag; // e.g. "fr-FR", "en-US", "zh-Hans-CN"
      // Exact match (zh-CN, zh-TW)
      if (SUPPORTED_LANGS.includes(tag as Language)) return tag as Language;
      // Map zh-Hans* → zh-CN, zh-Hant* → zh-TW
      if (tag.startsWith('zh-Hans') || tag === 'zh-CN') return 'zh-CN';
      if (tag.startsWith('zh-Hant') || tag === 'zh-TW') return 'zh-TW';
      // Match base language (fr-*, en-*)
      const base = locale.languageCode;
      if (base === 'fr') return 'fr';
      if (base === 'en') return 'en';
    }
  } catch {}
  return 'en';
}

interface LanguageState {
  lang: Language;
  setLang: (lang: Language) => void;
  t: (key: TranslationKey) => string;
}

const LanguageContext = createContext<LanguageState>({
  lang: 'en',
  setLang: () => {},
  t: (key) => key,
});

const STORAGE_KEY = 'app_language';

export function LanguageProvider({ children }: { children: React.ReactNode }) {
  const [lang, setLangState] = useState<Language>(getDeviceLanguage);

  useEffect(() => {
    AsyncStorage.getItem(STORAGE_KEY).then((saved) => {
      if (saved && SUPPORTED_LANGS.includes(saved as Language)) setLangState(saved as Language);
    });
  }, []);

  const setLang = useCallback((l: Language) => {
    setLangState(l);
    AsyncStorage.setItem(STORAGE_KEY, l);
  }, []);

  const t = useCallback((key: TranslationKey) => translate(lang, key), [lang]);

  return (
    <LanguageContext.Provider value={{ lang, setLang, t }}>
      {children}
    </LanguageContext.Provider>
  );
}

export function useLanguage() {
  return useContext(LanguageContext);
}
