import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'providers/auth_provider.dart';
import 'providers/cells_provider.dart';
import 'providers/language_provider.dart';
import 'providers/legends_provider.dart';
import 'providers/pages_provider.dart';
import 'providers/premium_provider.dart';
import 'providers/theme_provider.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/forgot_password_screen.dart';
import 'screens/page_list_screen.dart';
import 'screens/tracker_screen.dart';
import 'screens/onboarding_screen.dart';
import 'screens/settings_screen.dart';
import 'theme/app_theme.dart';
import 'widgets/custom_cursor.dart';
import 'widgets/dotted_background.dart';
import 'package:flutter/services.dart';
import 'widgets/undo_delete_bar.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
    statusBarColor: AppColors.bg,
    statusBarIconBrightness: Brightness.dark,
    statusBarBrightness: Brightness.light,
  ));
  runApp(const DianDianApp());
}

class DianDianApp extends StatelessWidget {
  const DianDianApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => LanguageProvider()),
        ChangeNotifierProvider(create: (_) => PagesProvider()),
        ChangeNotifierProvider(create: (_) => CellsProvider()),
        ChangeNotifierProvider(create: (_) => LegendsProvider()),
        ChangeNotifierProvider(create: (_) => PremiumProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProv, _) => MaterialApp(
          title: 'Dian Dian',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.themeDataFor(themeProv.currentTheme).copyWith(
            scaffoldBackgroundColor: AppColors.bg,
            pageTransitionsTheme: const PageTransitionsTheme(
              builders: {
                TargetPlatform.android: FadeUpwardsPageTransitionsBuilder(),
                TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
                TargetPlatform.linux: FadeUpwardsPageTransitionsBuilder(),
                TargetPlatform.macOS: FadeUpwardsPageTransitionsBuilder(),
                TargetPlatform.windows: FadeUpwardsPageTransitionsBuilder(),
              },
            ),
          ),
          builder: (context, child) => CustomCursorOverlay(child: child!),
          home: const AppShell(),
        ),
      ),
    );
  }
}

/// The single root widget that manages all screen transitions.
/// Uses a stack-based approach: DottedBackground is always rendered,
/// and screens are swapped on top without Navigator transitions.
class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

enum AppScreen { login, register, forgotPassword, onboarding, pageList, tracker, settings }

class _AppShellState extends State<AppShell> {
  AppScreen _screen = AppScreen.login;
  String? _activePageId;
  int _selectedYear = DateTime.now().year;

  @override
  void initState() {
    super.initState();
    // Reset to login on auth expiry
    final auth = context.read<AuthProvider>();
    auth.addListener(_onAuthChange);
  }

  void _onAuthChange() async {
    final auth = context.read<AuthProvider>();
    // Sync VIP → Premium
    context.read<PremiumProvider>().setVip(auth.isVip);

    // Apply server settings to providers
    final settings = auth.serverSettings;
    if (auth.isAuthenticated && settings != null) {
      context.read<ThemeProvider>().applyServerSettings(settings['theme'] as String?);
      context.read<LanguageProvider>().applyServerSettings(settings['language'] as String?);
      context.read<PremiumProvider>().applyServerSettings(
        cursorId: settings['cursorId'] as String?,
        cursorEnabled: settings['cursorEnabled'] as bool?,
      );
    }

    // Show onboarding after first login
    if (auth.isAuthenticated && _screen != AppScreen.onboarding &&
        _screen != AppScreen.pageList && _screen != AppScreen.tracker &&
        _screen != AppScreen.settings) {
      final shouldShow = await OnboardingScreen.shouldShow();
      if (shouldShow && mounted) {
        setState(() => _screen = AppScreen.onboarding);
        return;
      }
    }
    if (!auth.isAuthenticated && _screen != AppScreen.login &&
        _screen != AppScreen.register && _screen != AppScreen.forgotPassword) {
      // Cancel any pending page deletion on logout
      context.read<PagesProvider>().cancelPendingDelete();
      setState(() {
        _screen = AppScreen.login;
        _activePageId = null;
      });
    }
  }

  void _navigate(AppScreen screen, {String? pageId}) {
    setState(() {
      _screen = screen;
      if (pageId != null) _activePageId = pageId;
    });
  }

  @override
  void dispose() {
    context.read<AuthProvider>().removeListener(_onAuthChange);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DottedBackground(
      child: Consumer<AuthProvider>(
        builder: (context, auth, _) {
          if (auth.isLoading) return const _LoadingScreen();

          if (!auth.isAuthenticated) {
            return AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: _buildAuthScreen(),
            );
          }

          return Stack(
            children: [
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: _buildAppScreen(),
              ),
              // Global undo delete bar
              Consumer<PagesProvider>(
                builder: (context, pagesProv, _) {
                  if (pagesProv.pendingDeletePage == null) {
                    return const SizedBox.shrink();
                  }
                  return Positioned(
                    left: 16,
                    right: 16,
                    bottom: 24 + MediaQuery.of(context).padding.bottom,
                    child: UndoDeleteBar(
                      pageName: pagesProv.pendingDeletePage!.title,
                      onUndo: () => pagesProv.undoDeletePage(),
                      duration: const Duration(seconds: 8),
                      key: ValueKey(pagesProv.pendingDeletePage!.id),
                    ),
                  );
                },
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildAuthScreen() {
    switch (_screen) {
      case AppScreen.register:
        return RegisterScreen(
          key: const ValueKey('register'),
          onSwitchToLogin: () => _navigate(AppScreen.login),
        );
      case AppScreen.forgotPassword:
        return ForgotPasswordScreen(
          key: const ValueKey('forgot'),
          onBack: () => _navigate(AppScreen.login),
        );
      default:
        return LoginScreen(
          key: const ValueKey('login'),
          onSwitchToRegister: () => _navigate(AppScreen.register),
          onForgotPassword: () => _navigate(AppScreen.forgotPassword),
        );
    }
  }

  Widget _buildAppScreen() {
    switch (_screen) {
      case AppScreen.onboarding:
        return OnboardingScreen(
          key: const ValueKey('onboarding'),
          onDone: () => _navigate(AppScreen.pageList),
        );
      case AppScreen.settings:
        return SettingsScreen(
          key: const ValueKey('settings'),
          onBack: () => _navigate(AppScreen.pageList),
        );
      case AppScreen.tracker:
        return TrackerScreen(
          key: ValueKey('tracker_$_activePageId'),
          pageId: _activePageId!,
          onBack: () => _navigate(AppScreen.pageList),
          onOpenSettings: () => _navigate(AppScreen.settings),
        );
      default:
        return PageListScreen(
          key: const ValueKey('pageList'),
          selectedYear: _selectedYear,
          onYearChanged: (year) => _selectedYear = year,
          onSelectPage: (id, year) {
            _selectedYear = year;
            _navigate(AppScreen.tracker, pageId: id);
          },
          onOpenSettings: () => _navigate(AppScreen.settings),
        );
    }
  }
}

class _LoadingScreen extends StatelessWidget {
  const _LoadingScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '点点',
              style: AppFonts.pixel(fontSize: 36, color: AppColors.title),
            ),
            const SizedBox(height: 8),
            Text(
              'Dian Dian',
              style: AppFonts.pixel(fontSize: 14, color: AppColors.subtitle),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppColors.accent,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
