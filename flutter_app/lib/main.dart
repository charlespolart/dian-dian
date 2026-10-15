import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'data/first_tracker_decision.dart';
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
import 'screens/first_tracker_screen.dart';
import 'screens/tracker_screen.dart';
import 'screens/settings_screen.dart';
import 'theme/app_theme.dart';
import 'widgets/custom_cursor.dart';
import 'widgets/dotted_background.dart';
import 'package:flutter/services.dart';
import 'widgets/undo_delete_bar.dart';

import 'services/ad_service.dart';
import 'services/api_service.dart';
import 'services/purchase_service.dart';
import 'services/sync_service.dart';
import 'services/ws_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
    statusBarColor: AppColors.bg,
    statusBarIconBrightness: Brightness.dark,
    statusBarBrightness: Brightness.light,
  ));
  // Configure RevenueCat early so the listener is ready when providers init.
  await PurchaseService().init();
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
        // Owns loading (bootstrap, disk snapshot, resume/reconnect resync);
        // the three data providers above only hold state.
        Provider<SyncService>(
          create: (ctx) => SyncService(
            api: ApiService(),
            pages: ctx.read<PagesProvider>(),
            cells: ctx.read<CellsProvider>(),
            legends: ctx.read<LegendsProvider>(),
            ws: WsService(),
          ),
          dispose: (_, sync) => sync.dispose(),
          lazy: false,
        ),
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

enum AppScreen { login, register, forgotPassword, firstTracker, pageList, tracker, settings }

class _AppShellState extends State<AppShell> {
  static const _lastTrackerIdKey = 'last_tracker_id';
  static const _lastTrackerYearKey = 'last_tracker_year';

  AppScreen _screen = AppScreen.login;
  String? _activePageId;
  int _selectedYear = DateTime.now().year;
  // One session start per authentication: hydrate + bootstrap + land on
  // the right screen. Reset on logout.
  bool _sessionStarted = false;
  // Session restored from storage but not yet confirmed by the network.
  // When it flips back to confirmed, the store is revalidated.
  bool _wasOffline = false;
  // Keeps the splash screen up while we decide whether to land on the
  // page list or jump straight back into the user's last tracker.
  bool _restoreInProgress = true;

  @override
  void initState() {
    super.initState();
    final auth = context.read<AuthProvider>();
    auth.addListener(_onAuthChange);
  }

  /// Runs once per authenticated session. Hydrates the store from the disk
  /// snapshot (instant first paint), kicks the network bootstrap, then lands
  /// on the first-tracker flow, the last open tracker, or the page list.
  Future<void> _startSession(AuthProvider auth) async {
    try {
      await _startSessionInner(auth);
    } finally {
      // Whatever happened, never leave the splash up forever.
      if (mounted && _restoreInProgress) setState(() => _restoreInProgress = false);
    }
  }

  Future<void> _startSessionInner(AuthProvider auth) async {
    final prefs = await SharedPreferences.getInstance();
    final lastId = prefs.getString(_lastTrackerIdKey);
    final currentYear = DateTime.now().year;
    final year = lastId != null
        ? (prefs.getInt(_lastTrackerYearKey) ?? currentYear)
        : currentYear;
    if (!mounted) return;

    final sync = context.read<SyncService>();
    final hydrated = await sync.start(userId: auth.userId!, year: year);
    if (!mounted) return;

    // Anyone the snapshot already knows as active lands at once (instant
    // first paint). Everyone else waits for the server once: new and dormant
    // accounts get the first-tracker flow only on a confirmed "no cell at
    // all". Offline, `activated` stays null and the normal app shows.
    if (!hydrated || sync.snapshotActivated != true) await sync.ensureYear(year);
    if (!mounted) return;

    final userId = auth.userId!;
    final doneOnThisDevice = await FirstTrackerScreen.isDone(userId);
    if (!mounted) return;
    final pagesProv = context.read<PagesProvider>();
    final legendsProv = context.read<LegendsProvider>();
    if (shouldShowFirstTracker(
      activated: sync.activated,
      doneOnThisDevice: doneOnThisDevice,
      pageCount: pagesProv.pages.length,
      maxTrackers: context.read<PremiumProvider>().maxTrackers,
      hasReplaceablePage: replaceablePageId(pagesProv.pages, legendsProv.legendsFor) != null,
    )) {
      setState(() {
        _screen = AppScreen.firstTracker;
        _selectedYear = year;
        _restoreInProgress = false;
      });
      return;
    }

    if (lastId != null && pagesProv.pages.any((p) => p.id == lastId)) {
      // Wire providers as if the user had tapped the tracker in the page list.
      context.read<CellsProvider>().setContext(pageId: lastId, year: year);
      context.read<LegendsProvider>().setPageId(lastId);
      setState(() {
        _screen = AppScreen.tracker;
        _activePageId = lastId;
        _selectedYear = year;
        _restoreInProgress = false;
      });
      return;
    }

    if (lastId != null) {
      await prefs.remove(_lastTrackerIdKey);
      await prefs.remove(_lastTrackerYearKey);
      if (!mounted) return;
    }
    setState(() {
      _screen = AppScreen.pageList;
      _selectedYear = year;
      _restoreInProgress = false;
    });
  }

  Future<void> _saveLastTracker(String pageId, int year) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_lastTrackerIdKey, pageId);
    await prefs.setInt(_lastTrackerYearKey, year);
  }

  Future<void> _clearLastTracker() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_lastTrackerIdKey);
    await prefs.remove(_lastTrackerYearKey);
  }

  void _onAuthChange() async {
    final auth = context.read<AuthProvider>();
    // Sync VIP → Premium
    context.read<PremiumProvider>().setVip(auth.isVip);

    // Identify the user with RevenueCat so purchases stick to the backend user.
    final purchases = PurchaseService();
    if (auth.isAuthenticated && auth.userId != null) {
      purchases.logIn(auth.userId!);
    } else if (!auth.isAuthenticated) {
      purchases.logOut();
    }

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

    // Init or disable ads based on premium status
    if (auth.isAuthenticated) {
      final adService = AdService();
      if (context.read<PremiumProvider>().isPremium) {
        adService.disable();
      } else {
        adService.enable();
        adService.init();
      }
    }

    if (auth.isAuthenticated && auth.userId != null && !_sessionStarted) {
      _sessionStarted = true;
      _wasOffline = auth.isOffline;
      await _startSession(auth);
    }
    if (!mounted) return;

    // Network confirmation after a pending/offline start: the snapshot may
    // be stale, re-fetch now (deduped with any bootstrap already in flight).
    final cameBackOnline = _wasOffline && auth.isAuthenticated && !auth.isOffline;
    _wasOffline = auth.isAuthenticated && auth.isOffline;
    if (cameBackOnline && _sessionStarted) {
      context.read<SyncService>().revalidate();
    }

    if (!auth.isAuthenticated && _sessionStarted) {
      // Every authenticated → unauthenticated transition forgets the store and
      // the disk snapshot: the next user must never see this one's data.
      _sessionStarted = false;
      context.read<PagesProvider>().cancelPendingDelete();
      context.read<SyncService>().clear();
      _clearLastTracker();
    }
    if (!auth.isAuthenticated && _screen != AppScreen.login &&
        _screen != AppScreen.register && _screen != AppScreen.forgotPassword) {
      setState(() {
        _screen = AppScreen.login;
        _activePageId = null;
        _selectedYear = DateTime.now().year;
        // Next login holds the splash until its own session start lands.
        _restoreInProgress = true;
      });
    }
  }

  void _navigate(AppScreen screen, {String? pageId}) {
    setState(() {
      _screen = screen;
      if (pageId != null) _activePageId = pageId;
    });
    if (screen == AppScreen.tracker && pageId != null) {
      _saveLastTracker(pageId, _selectedYear);
    } else if (screen == AppScreen.pageList) {
      // User explicitly went back to the list — forget which tracker was open.
      _clearLastTracker();
      _activePageId = null;
    }
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
          // Hold the splash while we figure out where to land — avoids a
          // visible flash of the page list before jumping to the saved tracker.
          if (auth.isAuthenticated && _restoreInProgress) {
            return const _LoadingScreen();
          }

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
      case AppScreen.firstTracker:
        return FirstTrackerScreen(
          key: const ValueKey('firstTracker'),
          userId: context.read<AuthProvider>().userId!,
          onLater: () => _navigate(AppScreen.pageList),
          onOpenTracker: (pageId, year) {
            // The created tracker becomes the last-opened one (saved by
            // _navigate) so the next launch lands on it.
            _selectedYear = year;
            _navigate(AppScreen.tracker, pageId: pageId);
          },
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
          initialYear: _selectedYear,
          onBack: () => _navigate(AppScreen.pageList),
          onOpenSettings: () => _navigate(AppScreen.settings),
          onYearChanged: (year) {
            _selectedYear = year;
            if (_activePageId != null) {
              _saveLastTracker(_activePageId!, year);
            }
          },
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
