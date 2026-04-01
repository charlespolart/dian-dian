import React, { useState, useEffect } from 'react';
import { StatusBar } from 'expo-status-bar';
import { ActivityIndicator, View, StyleSheet, Platform } from 'react-native';
import { SafeAreaProvider } from 'react-native-safe-area-context';
import { useFonts, Silkscreen_400Regular, Silkscreen_700Bold } from '@expo-google-fonts/silkscreen';
import { DotGothic16_400Regular } from '@expo-google-fonts/dotgothic16';
import { AuthProvider, useAuth } from './src/contexts/AuthContext';
import { LanguageProvider } from './src/contexts/LanguageContext';
import { ConfirmProvider } from './src/hooks/useConfirm';
import LoginScreen from './src/screens/LoginScreen';
import RegisterScreen from './src/screens/RegisterScreen';
import TrackerScreen from './src/screens/TrackerScreen';
import PageListScreen from './src/screens/PageListScreen';
import SettingsScreen from './src/screens/SettingsScreen';
import ForgotPasswordScreen from './src/screens/ForgotPasswordScreen';
import ResetPasswordScreen from './src/screens/ResetPasswordScreen';
import { usePages } from './src/hooks/usePages';
import { COLORS } from './src/lib/theme';
import DottedBackground from './src/components/DottedBackground';
import CustomCursor from './src/components/CustomCursor';

// Detect deep link params from URL (web only)
function getUrlParams(): { resetToken?: string } {
  if (Platform.OS !== 'web') return {};
  const url = new URL(window.location.href);
  const path = url.pathname;
  if (path === '/reset-password') {
    return { resetToken: url.searchParams.get('token') || undefined };
  }
  return {};
}

function clearUrlParams() {
  if (Platform.OS === 'web') {
    window.history.replaceState({}, '', '/');
  }
}

function AppContent() {
  const { isLoading, isAuthenticated } = useAuth();
  const { pages, createPage, deletePage } = usePages();
  const [authScreen, setAuthScreen] = useState<'login' | 'register' | 'forgot'>('login');
  const [showSettings, setShowSettings] = useState(false);
  const [activePageId, setActivePageId] = useState<string | null>(null);

  // Reset UI state on logout
  useEffect(() => {
    if (!isAuthenticated) { setShowSettings(false); setActivePageId(null); }
  }, [isAuthenticated]);
  const [resetToken, setResetToken] = useState<string | undefined>();

  useEffect(() => {
    const params = getUrlParams();
    if (params.resetToken) setResetToken(params.resetToken);
  }, []);

  if (isLoading) {
    return (
      <View style={styles.loading}>
        <ActivityIndicator size="large" color={COLORS.accent} />
      </View>
    );
  }

  // Reset password screen (shown regardless of auth state)
  if (resetToken) {
    return <ResetPasswordScreen token={resetToken} onDone={() => { setResetToken(undefined); clearUrlParams(); }} />;
  }

  if (!isAuthenticated) {
    if (authScreen === 'register') return <RegisterScreen onSwitchToLogin={() => setAuthScreen('login')} />;
    if (authScreen === 'forgot') return <ForgotPasswordScreen onBack={() => setAuthScreen('login')} />;
    return <LoginScreen onSwitchToRegister={() => setAuthScreen('register')} onForgotPassword={() => setAuthScreen('forgot')} />;
  }

  if (showSettings) {
    return <SettingsScreen onBack={() => setShowSettings(false)} />;
  }

  if (activePageId) {
    return <TrackerScreen pageId={activePageId} onBack={() => setActivePageId(null)} onOpenSettings={() => setShowSettings(true)} />;
  }

  return <PageListScreen
    pages={pages}
    onSelectPage={setActivePageId}
    onCreatePage={async (year) => {
      const page = await createPage(undefined);
      if (page) setActivePageId(page.id);
    }}
    onDeletePage={deletePage}
    onOpenSettings={() => setShowSettings(true)}
  />;
}

export default function App() {
  const [fontsLoaded] = useFonts({
    Silkscreen_400Regular,
    Silkscreen_700Bold,
    DotGothic16_400Regular,
  });

  if (!fontsLoaded) {
    return (
      <View style={styles.loading}>
        <ActivityIndicator size="large" color={COLORS.accent} />
      </View>
    );
  }

  const content = (
    <DottedBackground>
      <LanguageProvider>
        <AuthProvider>
          <ConfirmProvider>
            <StatusBar style="dark" />
            <CustomCursor />
            <AppContent />
          </ConfirmProvider>
        </AuthProvider>
      </LanguageProvider>
    </DottedBackground>
  );

  // SafeAreaProvider crashes on web with React 19 — skip it on web
  if (Platform.OS === 'web') return content;
  return <SafeAreaProvider>{content}</SafeAreaProvider>;
}

const styles = StyleSheet.create({
  loading: {
    flex: 1,
    backgroundColor: COLORS.bg,
    alignItems: 'center',
    justifyContent: 'center',
  },
});
