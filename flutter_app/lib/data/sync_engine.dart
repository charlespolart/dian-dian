import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../services/api_service.dart';
import 'connectivity.dart';
import 'local_store.dart';
import 'mutation.dart';

/// Whether the server can be reached, as the last attempt found it.
enum SyncState { online, offline }

/// Sends the queue and brings back what changed (offline sync, chantier 10).
///
/// A cycle: the queue leaves in order, by batches of 100; the answers leave
/// the queue (LocalStore.settle); then the phone asks what changed since the
/// last number it saw (or the full copy) and updates its copy. A network
/// failure stops the cycle: everything still queued is marked as having
/// waited, and a new attempt is planned, 5 seconds later then doubling up
/// to 2 minutes. The network coming back, the app coming to the front, a
/// `sync` message from the server and every gesture start a cycle at once.
class SyncEngine extends ChangeNotifier {
  SyncEngine({
    required LocalStore store,
    required ApiService api,
    NetworkWatcher? network,
    void Function(Duration delay, void Function() run)? schedule,
  })  : _store = store,
        _api = api,
        _schedule = schedule {
    _network = network?.onChange.listen((_) => kick());
  }

  static const batchSize = 100;
  static const firstRetry = Duration(seconds: 5);
  static const lastRetry = Duration(minutes: 2);

  final LocalStore _store;
  final ApiService _api;
  /// Plans the next attempt; a [Timer] unless a test gives its own.
  final void Function(Duration, void Function())? _schedule;
  StreamSubscription<void>? _network;
  Timer? _retry;

  SyncState _state = SyncState.online;
  int _pending = 0;
  int? _lastSentCount;
  Duration? _delay;
  final List<SyncOutcome> _outcomes = [];
  final _copyChanged = StreamController<void>.broadcast();
  Future<void>? _running;
  bool _again = false;
  bool _disposed = false;

  SyncState get state => _state;
  bool get isOffline => _state == SyncState.offline;

  /// Changes written on the phone and not yet accepted by the server.
  int get pendingCount => _pending;

  /// How many changes the last cycle that sent any sent
  /// (« Synchronisé · 31 modifications envoyées »).
  int? get lastSentCount => _lastSentCount;

  /// The copy changed from the server's side: the screens reload it.
  Stream<void> get onCopyChanged => _copyChanged.stream;

  /// Completes when no cycle is running.
  Future<void> get idle => _running ?? Future.value();

  /// Reads what the store holds from a previous run: the queue's size and
  /// what was not kept and not told yet.
  Future<void> restore() async {
    _pending = await _store.pendingCount();
    _outcomes.addAll(await _store.storedOutcomes());
    notifyListeners();
  }

  /// The changes the server did not keep, to tell once (H17): taken, they
  /// are forgotten.
  List<SyncOutcome> takeOutcomes() {
    final told = List<SyncOutcome>.of(_outcomes);
    _outcomes.clear();
    if (told.isNotEmpty) unawaited(_store.clearOutcomes());
    return told;
  }

  /// A gesture was written: count it and start a cycle.
  Future<void> kick() {
    if (_disposed) return Future.value();
    if (_running != null) {
      _again = true;
      return _running!;
    }
    return _running = _loop().whenComplete(() => _running = null);
  }

  /// Sends the queue now, for a gesture that must not leave it behind
  /// (sign-out, account gestures). True when nothing is left waiting.
  Future<bool> flush({Duration timeout = const Duration(seconds: 20)}) async {
    try {
      await kick().timeout(timeout);
    } on TimeoutException {
      return false;
    }
    return !isOffline && await _store.pendingCount() == 0;
  }

  Future<void> _loop() async {
    do {
      _again = false;
      await _cycle();
    } while (_again && !_disposed && !isOffline);
  }

  Future<void> _cycle() async {
    _pending = await _store.pendingCount();
    notifyListeners();
    var sent = 0;
    final outcomes = <SyncOutcome>[];
    try {
      while (true) {
        final batch = await _store.pending(limit: batchSize);
        if (batch.isEmpty) break;
        await _store.markSent(batch.map((m) => m.id));
        final res = await _api.apiFetch('/api/sync/mutations', method: 'POST', body: {
          'mutations': [for (final m in batch) m.toJson()],
        });
        if (res.statusCode == 401) return _sessionEnded();
        if (res.statusCode != 200) throw _Unreachable(res.statusCode);
        final results = [
          for (final r in (jsonDecode(res.body)['results'] as List)) MutationResult.fromJson((r as Map).cast<String, dynamic>()),
        ];
        outcomes.addAll(await _store.settle(results));
        sent += batch.length;
        _pending = await _store.pendingCount();
        notifyListeners();
      }
      final since = await _store.needsFullCopy() ? 0 : await _store.lastRev();
      final res = await _api.apiFetch('/api/sync?since=$since');
      if (res.statusCode == 401) return _sessionEnded();
      if (res.statusCode != 200) throw _Unreachable(res.statusCode);
      await _store.applyServer(SyncDelta.fromJson((jsonDecode(res.body) as Map).cast<String, dynamic>()));
      if (!_copyChanged.isClosed) _copyChanged.add(null);
      _state = SyncState.online;
      _delay = null;
      _retry?.cancel();
      if (sent > 0) _lastSentCount = sent;
    } catch (e) {
      debugPrint('Sync: server unreachable ($e)');
      await _store.markWaited();
      _state = SyncState.offline;
      _planRetry();
    } finally {
      if (outcomes.isNotEmpty) {
        _outcomes.addAll(outcomes);
        await _store.storeOutcomes(outcomes);
      }
      _pending = await _store.pendingCount();
      if (!_disposed) notifyListeners();
    }
  }

  /// The server refused the session: ApiService has told the app (log in
  /// again, or the account is gone). Nothing more is tried until then.
  void _sessionEnded() {
    _retry?.cancel();
    _state = SyncState.offline;
  }

  void _planRetry() {
    final next = _delay == null ? firstRetry : _delay! * 2;
    _delay = next > lastRetry ? lastRetry : next;
    final schedule = _schedule;
    if (schedule != null) {
      schedule(_delay!, () => kick());
    } else {
      _retry?.cancel();
      _retry = Timer(_delay!, () => kick());
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _network?.cancel();
    _retry?.cancel();
    _copyChanged.close();
    super.dispose();
  }
}

class _Unreachable implements Exception {
  _Unreachable(this.status);
  final int status;
  @override
  String toString() => 'HTTP $status';
}
