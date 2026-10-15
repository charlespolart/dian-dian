import 'dart:async';
import 'dart:convert';

import 'package:flutter/widgets.dart';

import '../providers/cells_provider.dart';
import '../providers/legends_provider.dart';
import '../providers/pages_provider.dart';
import 'api_service.dart';
import 'snapshot_store.dart';
import 'ws_service.dart';

/// Owns *loading*; the providers own *state*.
///
/// One `GET /api/bootstrap?year=` brings pages, legends and the cells of a
/// year for every page. This class:
///   - fetches a year on demand ([ensureYear]) and dedupes concurrent calls,
///   - hydrates the providers from a disk snapshot before the network so a
///     cold start paints instantly ([start]),
///   - re-fetches silently on app resume and WebSocket reconnection
///     ([revalidate]) — events missed in the background are reconciled,
///   - skips the apply + notify when the server body is byte-identical to
///     the last one (no repaint storms on resume).
class SyncService with WidgetsBindingObserver {
  static const _snapshotVersion = 1;

  final ApiService _api;
  final PagesProvider _pages;
  final CellsProvider _cells;
  final LegendsProvider _legends;
  final WsService _ws;
  final SnapshotStore _snapshots;
  final bool _observeLifecycle;

  String? _userId;
  bool _started = false;
  int _activeYear = DateTime.now().year;
  // Bumped by clear(): a fetch that completes after a clear is discarded.
  int _generation = 0;
  final Map<int, Future<void>> _inflight = {};
  final Map<int, String> _lastBody = {};
  // Store epoch at the time each year's body was last applied. A byte-identical
  // body may be skipped only if nothing touched the store since then.
  final Map<int, int> _lastAppliedEpoch = {};
  // `activated` = the account has at least one cell (any page, any year).
  // Network value and snapshot value are kept apart: the first-tracker flow
  // only runs on a network `false`, the snapshot `true` only lets an active
  // user land without waiting for the network.
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
  })  : _api = api,
        _pages = pages,
        _cells = cells,
        _legends = legends,
        _ws = ws,
        _snapshots = snapshots ?? FileSnapshotStore(),
        _observeLifecycle = observeLifecycle {
    if (_observeLifecycle) WidgetsBinding.instance.addObserver(this);
    _ws.onReconnected = () => revalidate();
  }

  /// The year the UI is currently looking at (last requested).
  int get activeYear => _activeYear;

  /// From the last successful network bootstrap of this session; `null`
  /// until then, or when the server did not send it (backend < 1.2.0).
  bool? get activated => _activated;

  /// From the disk snapshot read by [start]; `null` when absent.
  bool? get snapshotActivated => _snapshotActivated;

  // ---------------------------------------------------------------------------
  // Public API
  // ---------------------------------------------------------------------------

  /// Session start: hydrate from disk (only a snapshot of [userId]), then
  /// kick a network bootstrap of [year] in the background.
  /// Returns true when pages were hydrated, i.e. the UI can render now.
  Future<bool> start({required String userId, required int year}) async {
    _userId = userId;
    _started = true;
    _activeYear = year;
    final hydrated = await _hydrate(userId, year);
    unawaited(_bootstrap(year));
    return hydrated;
  }

  /// Makes [year] the active year and loads it unless every page already has
  /// its entry for that year (a page discovered through another year's
  /// bootstrap has none yet). A fetch of [year] already in flight (the one
  /// [start] kicked off, a revalidation) is awaited instead of skipped, so a
  /// hydrated session can wait for the server's answer — [activated] — by
  /// awaiting this.
  Future<void> ensureYear(int year) {
    _started = true;
    _activeYear = year;
    final inflight = _inflight[year];
    if (inflight != null) return inflight;
    if (_yearComplete(year)) return Future.value();
    return _bootstrap(year);
  }

  bool _yearComplete(int year) =>
      _cells.isYearLoaded(year) &&
      _pages.pages.every((p) => _cells.cellsFor(p.id, year) != null);

  int get _epoch => _pages.mutationEpoch + _cells.mutationEpoch + _legends.mutationEpoch;

  /// Re-fetches the active year unconditionally (silent when unchanged).
  Future<void> revalidate() {
    if (!_started) return Future.value();
    return _bootstrap(_activeYear);
  }

  /// Writes the current store (active year) to disk in bootstrap format.
  Future<void> persistSnapshot() async {
    // Nothing worth keeping until the active year is actually loaded: a
    // pages-only snapshot would overwrite a good one with empty grids.
    if (!_cells.isYearLoaded(_activeYear)) return;
    final payload = jsonEncode({
      'v': _snapshotVersion,
      'userId': _userId,
      'year': _activeYear,
      'savedAt': DateTime.now().toIso8601String(),
      'data': _serialize(_activeYear),
    });
    await _snapshots.write(payload);
  }

  /// Logout / account switch: forget everything, including the disk snapshot.
  Future<void> clear() async {
    _generation++;
    _userId = null;
    _started = false;
    _inflight.clear();
    _lastBody.clear();
    _lastAppliedEpoch.clear();
    _activated = null;
    _snapshotActivated = null;
    _pages.clear();
    _legends.clear();
    _cells.clear();
    await _snapshots.delete();
  }

  void dispose() {
    if (_observeLifecycle) WidgetsBinding.instance.removeObserver(this);
    _ws.onReconnected = null;
  }

  // ---------------------------------------------------------------------------
  // Lifecycle
  // ---------------------------------------------------------------------------

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!_started) return;
    switch (state) {
      case AppLifecycleState.resumed:
        // iOS kills sockets in the background; events sent meanwhile are gone.
        _ws.ensureConnected();
        unawaited(revalidate());
      case AppLifecycleState.paused:
      case AppLifecycleState.hidden:
        unawaited(persistSnapshot());
      case AppLifecycleState.inactive:
      case AppLifecycleState.detached:
        break;
    }
  }

  // ---------------------------------------------------------------------------
  // Internal
  // ---------------------------------------------------------------------------

  Future<void> _bootstrap(int year) {
    final existing = _inflight[year];
    if (existing != null) return existing;
    final future = _fetch(year);
    _inflight[year] = future;
    future.whenComplete(() {
      if (identical(_inflight[year], future)) _inflight.remove(year);
    });
    return future;
  }

  Future<void> _fetch(int year, {bool retried = false}) async {
    final generation = _generation;
    final epochBefore = _epoch;
    try {
      final res = await _api.apiFetch('/api/bootstrap?year=$year');
      if (generation != _generation) return; // cleared while in flight
      if (res.statusCode != 200) return; // keep whatever we have
      if (_epoch != epochBefore) {
        // Something was edited while this body was in flight: it may predate
        // that edit. Drop it and ask once more rather than erase a fresh tap.
        if (!retried) await _fetch(year, retried: true);
        return;
      }
      if (_lastBody[year] == res.body && _lastAppliedEpoch[year] == _epoch) {
        return; // byte-identical and the store is untouched since → nothing to do
      }
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      _apply(data, applyCells: true);
      _activated = data['activated'] as bool?;
      _lastBody[year] = res.body;
      _lastAppliedEpoch[year] = _epoch;
      await persistSnapshot();
    } catch (e) {
      debugPrint('SyncService: bootstrap($year) failed: $e');
    }
  }

  void _apply(Map<String, dynamic> data, {required bool applyCells}) {
    _pages.applyBootstrap(data['pages'] as List<dynamic>);
    _legends.applyBootstrap(data['legends'] as Map<String, dynamic>);
    if (applyCells) {
      _cells.applyBootstrap(data['year'] as int, data['cells'] as Map<String, dynamic>);
    }
  }

  Future<bool> _hydrate(String userId, int year) async {
    final raw = await _snapshots.read();
    if (raw == null) return false;
    try {
      final snap = jsonDecode(raw) as Map<String, dynamic>;
      if (snap['v'] != _snapshotVersion || snap['userId'] != userId) return false;
      final data = snap['data'] as Map<String, dynamic>;
      _apply(data, applyCells: data['year'] == year);
      _snapshotActivated = data['activated'] as bool?;
      return (data['pages'] as List<dynamic>).isNotEmpty;
    } catch (e) {
      debugPrint('SyncService: snapshot hydrate failed: $e');
      return false;
    }
  }

  Map<String, dynamic> _serialize(int year) {
    final pages = _pages.pages;
    return {
      'year': year,
      if ((_activated ?? _snapshotActivated) != null) 'activated': _activated ?? _snapshotActivated,
      'pages': [for (final p in pages) p.toJson()],
      'legends': {
        for (final p in pages) p.id: [for (final l in _legends.legendsFor(p.id)) l.toJson()],
      },
      'cells': {
        for (final p in pages) p.id: _cells.cellsFor(p.id, year)?.toCompact() ?? const <List<dynamic>>[],
      },
    };
  }
}
