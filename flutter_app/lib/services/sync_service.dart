import 'dart:async';
import 'dart:convert';

import 'package:flutter/widgets.dart';
import 'package:sqflite/sqflite.dart';

import '../data/change_sink.dart';
import '../data/connectivity.dart';
import '../data/local_store.dart';
import '../data/network_gate.dart';
import '../data/sync_engine.dart';
import '../providers/cells_provider.dart';
import '../providers/legends_provider.dart';
import '../providers/pages_provider.dart';
import 'api_service.dart';
import 'snapshot_store.dart';
import 'ws_service.dart';

/// Owns the session's data (offline sync, chantier 10); the providers own
/// what the screens show.
///
/// At [start], the account's copy on the phone (LocalStore) is loaded into
/// the providers and bound to them: every change they make is written there
/// with its entry in the queue ([record]), and the SyncEngine sends the
/// queue and brings back what changed — at once, then whenever the network
/// returns, the app comes back to the front, or the server says something
/// changed. Every year of every tracker is on the phone: [ensureYear] only
/// waits for the session's first sync when the phone has no full copy yet
/// (the first launch after the update from 1.4.0, which shows that version's
/// snapshot meanwhile).
class SyncService with WidgetsBindingObserver implements ChangeSink {
  static const _snapshotVersion = 1;

  final ApiService _api;
  final PagesProvider _pages;
  final CellsProvider _cells;
  final LegendsProvider _legends;
  final WsService _ws;
  final SnapshotStore _snapshots;
  final bool _observeLifecycle;
  final DatabaseFactory? _databaseFactory;
  final String? _databaseDir;
  final NetworkWatcher? _network;

  /// Applies the account's settings (theme, language, cursor) from the copy.
  void Function(Map<String, Object?> settings)? onSettings;

  /// Premium as the server last said it (the copy), once the phone has a
  /// full copy.
  void Function(bool premium)? onPremium;

  /// A change was refused: the phone has no full copy yet (H15). The app
  /// says a connection is needed to finish the update.
  void Function()? onWriteRefused;

  /// The session's engine, for what the screens tell (banner, message).
  final ValueNotifier<SyncEngine?> engine = ValueNotifier(null);

  String? _userId;
  bool _started = false;
  int _activeYear = DateTime.now().year;
  // Bumped by clear(): work that completes after a clear is discarded.
  int _generation = 0;
  LocalStore? _store;
  StreamSubscription<void>? _copyChanged;
  RemoveListener? _removeWsListener;
  final Set<Future<void>> _recording = {};
  // Counts the changes written; a reload that saw one start reads the copy again.
  int _writes = 0;
  bool _hasFullCopy = false;
  Future<void>? _firstSync;
  Future<void> _reloads = Future.value();
  bool? _activated;
  bool? _snapshotActivated;

  SyncService({
    required ApiService api,
    required PagesProvider pages,
    required CellsProvider cells,
    required LegendsProvider legends,
    required WsService ws,
    SnapshotStore? snapshots,
    bool observeLifecycle = true,
    DatabaseFactory? databaseFactory,
    String? databaseDir,
    NetworkWatcher? network,
  })  : _api = api,
        _pages = pages,
        _cells = cells,
        _legends = legends,
        _ws = ws,
        _snapshots = snapshots ?? FileSnapshotStore(),
        _observeLifecycle = observeLifecycle,
        _databaseFactory = databaseFactory,
        _databaseDir = databaseDir,
        _network = network {
    if (_observeLifecycle) WidgetsBinding.instance.addObserver(this);
    _ws.onReconnected = () => revalidate();
    _removeWsListener = _ws.addListener((message) {
      if (message.event == 'sync') revalidate();
    });
  }

  /// The year the UI is currently looking at (last requested).
  int get activeYear => _activeYear;

  /// Whether the account has at least one coloured day, from the full copy;
  /// null until the phone has one.
  bool? get activated => _activated;

  /// The same from what the phone had when the session started (its copy, or
  /// the 1.4.0 snapshot); null when it had nothing.
  bool? get snapshotActivated => _snapshotActivated;

  /// Completes when the session's first sync has ended and the screens show
  /// its result (reached the server or not).
  Future<void> get firstSync => _firstSync ?? Future.value();

  // ---------------------------------------------------------------------------
  // Session
  // ---------------------------------------------------------------------------

  /// Opens [userId]'s copy, shows it, and starts syncing. Returns true when
  /// the UI can render now (the phone had trackers to show). [newAccount]:
  /// the account was just made on this phone, the server has nothing of it
  /// (chantier 9, case 5) — its empty copy is whole from the start.
  Future<bool> start({required String userId, required int year, bool newAccount = false}) async {
    final generation = ++_generation;
    _userId = userId;
    _started = true;
    _activeYear = year;
    final store = await LocalStore.open(userId, factory: _databaseFactory, dir: _databaseDir);
    if (generation != _generation) {
      await store.close();
      return false;
    }
    _store = store;
    if (newAccount) await store.startEmpty();
    final syncEngine = SyncEngine(store: store, api: _api, network: _network ?? DeviceNetwork());
    await syncEngine.restore();
    engine.value = syncEngine;
    _copyChanged = syncEngine.onCopyChanged.listen((_) => _reload());
    // Deletions the app was killed holding are done now (H14); they waited
    // since, so another phone's changes meanwhile keep the tracker (H21, I3).
    await store.commitHeldDeletes(offline: true);
    _hasFullCopy = await store.hasFullCopy();
    _bind(this);
    NetworkGate.serverReachable = _reachServerTearOff;
    NetworkGate.serverUnreachableNow = _unreachableNowTearOff;

    var hydrated = false;
    if (_hasFullCopy) {
      await _reload();
      hydrated = _pages.pages.isNotEmpty;
      _snapshotActivated = _activated;
    } else {
      // First launch after the update from 1.4.0 (H15): that version's year,
      // until the full copy arrives.
      hydrated = await _hydrate(userId, year);
    }
    _firstSync = () async {
      try {
        await syncEngine.kick();
      } catch (e) {
        debugPrint('SyncService: first sync failed: $e');
      }
      // The copy's change reaches the listener in a later microtask.
      await Future<void>.delayed(Duration.zero);
      await _reloads;
    }();
    return hydrated;
  }

  /// Makes [year] the active year. Every year is on the phone once it has
  /// the full copy; until then, this waits for the session's first sync.
  Future<void> ensureYear(int year) async {
    _started = true;
    _activeYear = year;
    if (_hasFullCopy) return;
    await firstSync;
  }

  /// Something may have changed on the server: sync now.
  Future<void> revalidate() async {
    if (!_started) return;
    await engine.value?.kick();
  }

  /// Ends the session and says how many changes were still waiting.
  /// [keepCopy]: the server closed it (H25) — the copy and its queue stay on
  /// the phone, hidden, for the reconnection to this account; otherwise
  /// (sign-out, account deleted) they are erased.
  Future<int> clear({bool keepCopy = false}) async {
    _generation++;
    final userId = _userId;
    _userId = null;
    _started = false;
    _hasFullCopy = false;
    _firstSync = null;
    _activated = null;
    _snapshotActivated = null;
    _bind(null);
    await _copyChanged?.cancel();
    _copyChanged = null;
    final syncEngine = engine.value;
    engine.value = null;
    final store = _store;
    _store = null;
    if (syncEngine != null) {
      syncEngine.dispose();
      // A cycle in flight finishes on the open copy (a send is never cut in
      // the middle of writing its answers).
      await syncEngine.idle.catchError((Object _) {});
    }
    await Future.wait(_recording.toList());
    await _reloads;
    final pending = store == null ? 0 : await store.pendingCount();
    await store?.close();
    if (identical(NetworkGate.serverReachable, _reachServerTearOff)) NetworkGate.serverReachable = null;
    if (identical(NetworkGate.serverUnreachableNow, _unreachableNowTearOff)) NetworkGate.serverUnreachableNow = null;
    _pages.clear();
    _legends.clear();
    _cells.clear();
    if (!keepCopy && userId != null) {
      await LocalStore.deleteFor(userId, factory: _databaseFactory, dir: _databaseDir);
    }
    await _snapshots.delete();
    return pending;
  }

  /// The copies other accounts left on this phone (closed sessions, H25),
  /// with how many changes each still waits to send.
  Future<Map<String, int>> copiesOfOtherAccounts(String userId) async {
    final copies = <String, int>{};
    for (final other in await LocalStore.accountsOnPhone(factory: _databaseFactory, dir: _databaseDir)) {
      if (other == userId) continue;
      final store = await LocalStore.open(other, factory: _databaseFactory, dir: _databaseDir);
      try {
        copies[other] = await store.pendingCount();
      } finally {
        await store.close();
      }
    }
    return copies;
  }

  /// Erases those copies (signing in to another account, H25).
  Future<void> forgetCopies(Iterable<String> userIds) async {
    for (final id in userIds) {
      await LocalStore.deleteFor(id, factory: _databaseFactory, dir: _databaseDir);
    }
  }

  late final bool Function() _unreachableNowTearOff = _unreachableNow;
  bool _unreachableNow() => engine.value?.isOffline ?? false;

  /// For a gesture that needs the server (NetworkGate, H6): one cheap
  /// request, answered or not within 5 seconds — never a whole sync, which a
  /// long queue would make look like no network.
  late final Future<bool> Function() _reachServerTearOff = _reachServer;
  Future<bool> _reachServer() async {
    try {
      final res = await _api.apiFetch('/api/health').timeout(const Duration(seconds: 5));
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  void dispose() {
    if (_observeLifecycle) WidgetsBinding.instance.removeObserver(this);
    _ws.onReconnected = null;
    _removeWsListener?.call();
  }

  // ---------------------------------------------------------------------------
  // Changes (ChangeSink)
  // ---------------------------------------------------------------------------

  /// Without a session nothing is written anyway; within one, only once the
  /// phone has the full copy (H15).
  @override
  bool get canWrite => _store == null || _hasFullCopy;

  @override
  void refused() => onWriteRefused?.call();

  @override
  Future<void> holdDelete(String pageId) async => _store?.holdDelete(pageId);

  @override
  Future<void> releaseDelete(String pageId) async => _store?.releaseDelete(pageId);

  /// Writes a provider's change on the phone with its entry in the queue,
  /// then starts a sync.
  @override
  Future<void> record(String kind, Map<String, dynamic> data, {bool judged = false}) async {
    final store = _store;
    final syncEngine = engine.value;
    if (store == null || syncEngine == null) return;
    _writes++;
    final write = store.record(kind, data, offline: syncEngine.isOffline || judged);
    final done = write.then((_) {});
    _recording.add(done);
    try {
      await write;
    } finally {
      _recording.remove(done);
    }
    unawaited(syncEngine.kick());
  }

  void _bind(ChangeSink? sink) {
    _pages.bind(sink);
    _cells.bind(sink);
    _legends.bind(sink);
    SettingsSink.sink = sink;
  }

  /// Shows the copy again after the server changed it, one reload at a time.
  Future<void> _reload() => _reloads = _reloads.then((_) async {
        try {
          await _reloadOnce();
        } catch (e) {
          // The copy closed meanwhile (sign-out): the next session reloads.
          debugPrint('SyncService: reload failed: $e');
        }
      });

  /// Waits for the changes being written, so that one is never shown undone
  /// for a moment.
  Future<void> _reloadOnce() async {
    final generation = _generation;
    final store = _store;
    if (store == null) return;
    LocalCopy copy;
    int writes;
    do {
      await Future.wait(_recording.toList());
      writes = _writes;
      copy = await store.load();
      if (generation != _generation) return;
    } while (writes != _writes || _recording.isNotEmpty);
    _hasFullCopy = await store.hasFullCopy();
    _pages.userId = _userId ?? '';
    _pages.applyPages(copy.pages);
    _legends.applyCopy(copy.legends);
    _cells.applyCopy(copy.cells);
    if (_hasFullCopy) {
      _activated = copy.cells.values.any((years) => years.values.any((yc) => !yc.isEmpty));
      unawaited(_snapshots.delete()); // the 1.4.0 snapshot is no longer needed
      onPremium?.call(copy.premium);
    }
    if (copy.settings.isNotEmpty) onSettings?.call(copy.settings);
  }

  // ---------------------------------------------------------------------------
  // Lifecycle
  // ---------------------------------------------------------------------------

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!_started) return;
    if (state == AppLifecycleState.resumed) {
      // iOS kills sockets in the background; changes made meanwhile come with the sync.
      _ws.ensureConnected();
      unawaited(revalidate());
    }
  }

  // ---------------------------------------------------------------------------
  // The 1.4.0 snapshot (H15)
  // ---------------------------------------------------------------------------

  Future<bool> _hydrate(String userId, int year) async {
    final raw = await _snapshots.read();
    if (raw == null) return false;
    try {
      final snap = jsonDecode(raw) as Map<String, dynamic>;
      if (snap['v'] != _snapshotVersion || snap['userId'] != userId) return false;
      final data = snap['data'] as Map<String, dynamic>;
      _pages.userId = userId;
      _pages.applyBootstrap(data['pages'] as List<dynamic>);
      _legends.applyBootstrap(data['legends'] as Map<String, dynamic>);
      if (data['year'] == year) _cells.applyBootstrap(data['year'] as int, data['cells'] as Map<String, dynamic>);
      _snapshotActivated = data['activated'] as bool? ?? _activatedFromCells(data);
      return (data['pages'] as List<dynamic>).isNotEmpty;
    } catch (e) {
      debugPrint('SyncService: snapshot hydrate failed: $e');
      return false;
    }
  }

  /// A snapshot written by app ≤ 1.3.0 has no `activated` flag, but a cell
  /// on disk is proof enough. No cell proves nothing (other years exist).
  static bool? _activatedFromCells(Map<String, dynamic> data) {
    final cells = data['cells'] as Map<String, dynamic>?;
    if (cells == null) return null;
    for (final rows in cells.values) {
      if ((rows as List<dynamic>).isNotEmpty) return true;
    }
    return null;
  }
}
