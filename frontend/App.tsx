import React, { useState } from 'react';
import { StatusBar } from 'expo-status-bar';
import { ActivityIndicator, View, StyleSheet } from 'react-native';
import { SafeAreaProvider } from 'react-native-safe-area-context';
import { useFonts, Silkscreen_400Regular, Silkscreen_700Bold } from '@expo-google-fonts/silkscreen';
import { DotGothic16_400Regular } from '@expo-google-fonts/dotgothic16';
import { AuthProvider, useAuth } from './src/contexts/AuthContext';
import { LanguageProvider } from './src/contexts/LanguageContext';
import LoginScreen from './src/screens/LoginScreen';
import RegisterScreen from './src/screens/RegisterScreen';
import TrackerScreen from './src/screens/TrackerScreen';
import SettingsScreen from './src/screens/SettingsScreen';
import { COLORS } from './src/lib/theme';
import DottedBackground from './src/components/DottedBackground';
import CustomCursor from './src/components/CustomCursor';

function AppContent() {
  const { isLoading, isAuthenticated } = useAuth();
  const [showRegister, setShowRegister] = useState(false);
  const [showSettings, setShowSettings] = useState(false);

  if (isLoading) {
    return (
      <View style={styles.loading}>
        <ActivityIndicator size="large" color={COLORS.accent} />
      </View>
    );
  }

  if (!isAuthenticated) {
    return showRegister
      ? <RegisterScreen onSwitchToLogin={() => setShowRegister(false)} />
      : <LoginScreen onSwitchToRegister={() => setShowRegister(true)} />;
  }

  if (showSettings) {
    return <SettingsScreen onBack={() => setShowSettings(false)} />;
  }

  return <TrackerScreen onOpenSettings={() => setShowSettings(true)} />;
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

  return (
    <SafeAreaProvider>
      <DottedBackground>
        <LanguageProvider>
          <AuthProvider>
            <StatusBar style="dark" />
            <CustomCursor />
            <AppContent />
          </AuthProvider>
        </LanguageProvider>
      </DottedBackground>
    </SafeAreaProvider>
  );
}

const styles = StyleSheet.create({
  loading: {
    flex: 1,
    backgroundColor: COLORS.bg,
    alignItems: 'center',
    justifyContent: 'center',
  },
});
