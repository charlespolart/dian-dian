import 'dart:convert';
import 'dart:io';

import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';

import '../models/cell_model.dart';
import '../models/legend_model.dart';
import '../models/page_model.dart';
import '../models/year_cells.dart';
import 'mutation.dart';

/// Everything the screens read, as the phone holds it.
class LocalCopy {
  final List<PageModel> pages;
  final Map<String, List<LegendModel>> legends;

  /// pageId → year → the coloured days of that year.
  final Map<String, Map<int, YearCells>> cells;

  /// theme / language / cursor → their value (as the server stores them).
  final Map<String, Object?> settings;
  final bool premium;
  final bool vip;

  const LocalCopy({
    required this.pages,
    required this.legends,
    required this.cells,
    required this.settings,
    required this.premium,
    required this.vip,
  });
}

/// The copy of one account on the phone, and its queue of changes (offline
/// sync, chantier 10): one SQLite file per account, `dian_<userId>.db`.
///
/// Every change is written here first, with its entry in the queue, in one
/// transaction; the screens read only this copy. What the server sends
/// updates it, except an element that has a change waiting: that change
/// stays shown until the server has decided (spec, "La copie du téléphone").
class LocalStore {
  LocalStore._(this._db, this.userId);

  final Database _db;
  final String userId;

  static const _schemaVersion = 1;
  static const _uuid = Uuid();
  static const _activityDays = 90;

  /// The account's file: `dian_<userId>.db` in [dir] (default: the app's
  /// databases folder).
  static Future<String> pathFor(String userId, {DatabaseFactory? factory, String? dir}) async =>
      '${dir ?? await (factory ?? databaseFactory).getDatabasesPath()}/dian_$userId.db';

  /// The accounts that have a copy on this phone (a closed session keeps
  /// its copy for the reconnection, H25).
  static Future<List<String>> accountsOnPhone({DatabaseFactory? factory, String? dir}) async {
    final folder = Directory(dir ?? await (factory ?? databaseFactory).getDatabasesPath());
    if (!await folder.exists()) return const [];
    final name = RegExp(r'^dian_(.+)\.db$');
    return [
      await for (final entry in folder.list())
        if (entry is File) ?name.firstMatch(entry.uri.pathSegments.last)?.group(1),
    ];
  }

  static Future<LocalStore> open(String userId, {DatabaseFactory? factory, String? path, String? dir}) async {
    final f = factory ?? databaseFactory;
    final at = path ?? await pathFor(userId, factory: f, dir: dir);
    final db = await f.openDatabase(
      at,
      // In memory (tests), each open is a database of its own.
      options: OpenDatabaseOptions(version: _schemaVersion, onCreate: (db, _) => _create(db), singleInstance: at != inMemoryDatabasePath),
    );
    return LocalStore._(db, userId);
  }

  /// Forgets the account's copy and queue (sign-out, deleted account).
  static Future<void> deleteFor(String userId, {DatabaseFactory? factory, String? path, String? dir}) async {
    final f = factory ?? databaseFactory;
    await f.deleteDatabase(path ?? await pathFor(userId, factory: f, dir: dir));
  }

  Future<void> close() => _db.close();

  static Future<void> _create(Database db) async {
    final batch = db.batch()
      ..execute('CREATE TABLE meta (key TEXT PRIMARY KEY, value TEXT NOT NULL)')
      ..execute('''CREATE TABLE pages (
          id TEXT PRIMARY KEY, title TEXT NOT NULL, position INTEGER NOT NULL, palette TEXT,
          keep_free INTEGER NOT NULL DEFAULT 0, year INTEGER NOT NULL, created_at TEXT NOT NULL,
          rev INTEGER NOT NULL DEFAULT 0, edit_rev INTEGER NOT NULL DEFAULT 0,
          content_rev INTEGER NOT NULL DEFAULT 0, legends_order_rev INTEGER NOT NULL DEFAULT 0)''')
      ..execute('''CREATE TABLE legends (
          id TEXT PRIMARY KEY, page_id TEXT NOT NULL, color TEXT NOT NULL, label TEXT NOT NULL,
          position INTEGER NOT NULL, created_at TEXT NOT NULL,
          rev INTEGER NOT NULL DEFAULT 0, edit_rev INTEGER NOT NULL DEFAULT 0)''')
      ..execute('CREATE INDEX legends_page ON legends(page_id)')
      // A cleared day keeps its row with a null colour: its number is what
      // the next change of that day is compared with.
      ..execute('''CREATE TABLE cells (
          page_id TEXT NOT NULL, year INTEGER NOT NULL, month INTEGER NOT NULL, day INTEGER NOT NULL,
          color TEXT, comment TEXT, updated_at INTEGER NOT NULL DEFAULT 0,
          rev INTEGER NOT NULL DEFAULT 0, edit_rev INTEGER NOT NULL DEFAULT 0,
          PRIMARY KEY (page_id, year, month, day))''')
      ..execute('CREATE TABLE settings (key TEXT PRIMARY KEY, value TEXT, rev INTEGER NOT NULL DEFAULT 0)')
      ..execute('''CREATE TABLE queue (
          seq INTEGER PRIMARY KEY AUTOINCREMENT, id TEXT NOT NULL UNIQUE, kind TEXT NOT NULL,
          element TEXT NOT NULL, page_id TEXT, base INTEGER, data TEXT NOT NULL,
          waited INTEGER NOT NULL DEFAULT 0, sent INTEGER NOT NULL DEFAULT 0,
          page_title TEXT, legend_label TEXT)''')
      ..execute('CREATE INDEX queue_element ON queue(element)')
      ..execute('CREATE TABLE pending_delete (page_id TEXT PRIMARY KEY, until_ms INTEGER NOT NULL)')
      ..execute('CREATE TABLE outcomes (seq INTEGER PRIMARY KEY AUTOINCREMENT, json TEXT NOT NULL)');
    await batch.commit(noResult: true);
  }

  // ---------------------------------------------------------------------------
  // Reading
  // ---------------------------------------------------------------------------

  Future<LocalCopy> load() async {
    final since = DateTime.now().millisecondsSinceEpoch - _activityDays * 24 * 60 * 60 * 1000;
    final activity = {
      for (final r in await _db.rawQuery(
        'SELECT page_id, SUM(CASE WHEN updated_at >= ? THEN 1 ELSE 0 END) AS recent, MAX(updated_at) AS last '
        'FROM cells WHERE color IS NOT NULL GROUP BY page_id',
        [since],
      ))
        r['page_id'] as String: r,
    };
    final pages = [
      for (final r in await _db.query('pages', orderBy: 'position, created_at'))
        PageModel(
          id: r['id'] as String,
          userId: userId,
          title: r['title'] as String,
          year: r['year'] as int,
          position: r['position'] as int,
          palette: _palette(r['palette'] as String?),
          createdAt: r['created_at'] as String,
          keepFree: r['keep_free'] == 1,
          recentCells: (activity[r['id']]?['recent'] as int?) ?? 0,
          lastCellAt: _iso(activity[r['id']]?['last'] as int?),
        ),
    ];
    final legends = <String, List<LegendModel>>{};
    for (final r in await _db.query('legends', orderBy: 'page_id, position')) {
      (legends[r['page_id'] as String] ??= []).add(LegendModel(
        id: r['id'] as String,
        pageId: r['page_id'] as String,
        color: r['color'] as String,
        label: r['label'] as String,
        position: r['position'] as int,
        createdAt: r['created_at'] as String,
      ));
    }
    final byYear = <String, Map<int, List<CellModel>>>{};
    for (final r in await _db.query('cells', where: 'color IS NOT NULL')) {
      final pageId = r['page_id'] as String;
      final year = r['year'] as int;
      ((byYear[pageId] ??= {})[year] ??= []).add(CellModel(
        pageId: pageId,
        year: year,
        month: r['month'] as int,
        day: r['day'] as int,
        color: r['color'] as String,
        comment: r['comment'] as String?,
        updatedAt: _iso(r['updated_at'] as int?) ?? '',
      ));
    }
    final cells = {
      for (final p in byYear.entries) p.key: {for (final y in p.value.entries) y.key: YearCells.fromList(p.key, y.key, y.value)},
    };
    final settings = {
      for (final r in await _db.query('settings')) r['key'] as String: r['value'] == null ? null : jsonDecode(r['value'] as String),
    };
    return LocalCopy(
      pages: pages,
      legends: legends,
      cells: cells,
      settings: settings,
      premium: await _metaOf(_db, 'premium') == '1',
      vip: await _metaOf(_db, 'vip') == '1',
    );
  }

  Future<int> lastRev() async => int.tryParse(await _metaOf(_db, 'last_rev') ?? '') ?? 0;
  Future<bool> hasFullCopy() async => await _metaOf(_db, 'full_copy') == '1';

  /// The copy of an account born on this phone (« Continuer sans compte »,
  /// chantier 9, case 5): the server has nothing of it, so the empty copy is
  /// already whole — it is written to offline at once, and a later launch
  /// still knows it.
  Future<void> startEmpty() => _setMeta(_db, 'full_copy', '1');

  /// A change was set aside: the server's version must come back whole.
  Future<bool> needsFullCopy() async => await _metaOf(_db, 'needs_full') == '1';

  // ---------------------------------------------------------------------------
  // Writing a change
  // ---------------------------------------------------------------------------

  /// Writes the change on the phone and queues it, in one transaction. Two
  /// changes of one element not yet sent become one: the last state, with
  /// the first one's base (H28). [offline]: made while the server could not
  /// be reached (it "waited").
  Future<Mutation> record(String kind, Map<String, dynamic> data, {required bool offline}) {
    return _db.transaction((txn) async {
      final element = _elementOf(kind, data);
      final pageId = Mutation.pageOf(kind, data) ?? await _legendPage(txn, data['id'] as String?);
      final base = await _baseOf(txn, kind, data);
      // The names as they are now, for the message if the server does not
      // keep the change (a deleted tracker has no name left on the phone).
      final pageTitle = await _titleOf(txn, pageId) ?? (kind == 'page.create' ? data['title'] as String? : null);
      final legendLabel = kind.startsWith('legend.') ? await _labelOf(txn, data['id'] as String?) ?? data['label'] as String? : null;
      await _applyLocal(txn, kind, data);

      if (kind == 'page.delete') {
        final unsentCreate = await txn.query('queue', columns: ['seq'], where: "kind = 'page.create' AND page_id = ? AND sent = 0", whereArgs: [pageId], limit: 1);
        if (unsentCreate.isNotEmpty) {
          // The server never knew this tracker: nothing of it leaves (C1).
          await txn.delete('queue', where: 'page_id = ? AND sent = 0', whereArgs: [pageId]);
          return Mutation(id: _uuid.v4(), kind: kind, element: element, base: base, data: data, waited: offline, sent: false, page: pageId);
        }
      }

      final last = await txn.query('queue', where: 'element = ? AND sent = 0', whereArgs: [element], orderBy: 'seq DESC', limit: 1);
      if (last.isNotEmpty && _merges(last.first['kind'] as String, kind)) {
        final row = last.first;
        final previous = (jsonDecode(row['data'] as String) as Map).cast<String, dynamic>();
        final merged = kind.endsWith('.update') ? {...previous, ...data} : data;
        final waited = offline || row['waited'] == 1;
        if (const {'pages.reorder', 'pages.keep', 'legends.reorder'}.contains(kind)) {
          // An order or a choice names trackers or legends that may have been
          // created since the first one: it moves to the end of the queue,
          // after them, keeping the first one's base (I5).
          await txn.delete('queue', where: 'seq = ?', whereArgs: [row['seq']]);
          await txn.insert('queue', {
            'id': row['id'], 'kind': kind, 'element': element, 'page_id': pageId, 'base': row['base'],
            'data': jsonEncode(merged), 'waited': waited ? 1 : 0, 'sent': 0, 'page_title': pageTitle, 'legend_label': legendLabel,
          });
          return Mutation(id: row['id'] as String, kind: kind, element: element, base: row['base'] as int?, data: merged, waited: waited, sent: false, page: pageId);
        }
        await txn.update('queue', {'kind': kind, 'data': jsonEncode(merged), 'waited': waited ? 1 : 0, 'page_title': pageTitle, 'legend_label': legendLabel},
            where: 'seq = ?', whereArgs: [row['seq']]);
        return Mutation(id: row['id'] as String, kind: kind, element: element, base: row['base'] as int?, data: merged, waited: waited, sent: false, page: pageId);
      }
      final id = _uuid.v4();
      await txn.insert('queue', {
        'id': id, 'kind': kind, 'element': element, 'page_id': pageId, 'base': base,
        'data': jsonEncode(data), 'waited': offline ? 1 : 0, 'sent': 0, 'page_title': pageTitle, 'legend_label': legendLabel,
      });
      return Mutation(id: id, kind: kind, element: element, base: base, data: data, waited: offline, sent: false, page: pageId);
    });
  }

  // ---------------------------------------------------------------------------
  // A tracker deletion still undoable (H14)
  // ---------------------------------------------------------------------------

  /// Keeps a deletion that can still be undone for [delay]: an app killed
  /// meanwhile finds it done when reopened ([commitHeldDeletes]).
  Future<void> holdDelete(String pageId, {Duration delay = const Duration(seconds: 8)}) => _db.insert(
        'pending_delete',
        {'page_id': pageId, 'until_ms': DateTime.now().add(delay).millisecondsSinceEpoch},
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

  /// The deletion was undone.
  Future<void> releaseDelete(String pageId) => _db.delete('pending_delete', where: 'page_id = ?', whereArgs: [pageId]);

  Future<List<String>> heldDeletes() async =>
      [for (final r in await _db.query('pending_delete', orderBy: 'until_ms')) r['page_id'] as String];

  /// At launch: the deletions the app was killed holding are done now, each
  /// with its entry in the queue. One whose tracker is gone meanwhile is let go.
  Future<void> commitHeldDeletes({required bool offline}) async {
    for (final id in await heldDeletes()) {
      final exists = await _db.query('pages', columns: ['id'], where: 'id = ?', whereArgs: [id]);
      if (exists.isEmpty) {
        await releaseDelete(id);
      } else {
        await record('page.delete', {'id': id}, offline: offline);
      }
    }
  }

  static bool _merges(String earlier, String later) {
    const days = {'cell.set', 'cell.clear'};
    if (days.contains(earlier) && days.contains(later)) return true;
    if (earlier != later) return false;
    return !const {'page.create', 'legend.create', 'page.delete', 'legend.delete'}.contains(later);
  }

  static String _two(int n) => n.toString().padLeft(2, '0');

  static String _elementOf(String kind, Map<String, dynamic> d) {
    switch (kind) {
      case 'cell.set':
      case 'cell.clear':
        return 'cell:${_req<String>(d, 'pageId')}:${_req<int>(d, 'year')}-${_two(_req<int>(d, 'month'))}-${_two(_req<int>(d, 'day'))}';
      case 'page.create':
      case 'page.update':
        return 'page:${_req<String>(d, 'id')}';
      case 'page.delete':
        return 'page-delete:${_req<String>(d, 'id')}';
      case 'pages.reorder':
        return 'pages-order';
      case 'pages.keep':
        return 'pages-keep';
      case 'legend.create':
      case 'legend.update':
      case 'legend.delete':
        return 'legend:${_req<String>(d, 'id')}';
      case 'legends.reorder':
        return 'legends-order:${_req<String>(d, 'pageId')}';
      case 'setting.set':
        return 'setting:${_req<String>(d, 'key')}';
    }
    throw ArgumentError('Unknown change: $kind');
  }

  static T _req<T>(Map<String, dynamic> d, String key) {
    final v = d[key];
    if (v is! T) throw ArgumentError('Change without a valid "$key"');
    return v;
  }

  Future<String?> _legendPage(DatabaseExecutor db, String? legendId) async {
    if (legendId == null) return null;
    final rows = await db.query('legends', columns: ['page_id'], where: 'id = ?', whereArgs: [legendId]);
    return rows.isEmpty ? null : rows.first['page_id'] as String;
  }

  /// The number of the change's element as the phone knows it (null for a creation).
  Future<int?> _baseOf(DatabaseExecutor db, String kind, Map<String, dynamic> d) async {
    Future<int> col(String table, String column, String where, List<Object?> args) async {
      final rows = await db.query(table, columns: [column], where: where, whereArgs: args);
      return rows.isEmpty ? 0 : (rows.first[column] as int);
    }

    switch (kind) {
      case 'page.create':
      case 'legend.create':
        return null;
      case 'cell.set':
      case 'cell.clear':
        // A day the phone never saw (no row, not even a trace) has no number:
        // the server then sees no conflict while it is still empty (I2).
        final rows = await db.query('cells', columns: ['edit_rev'],
            where: 'page_id = ? AND year = ? AND month = ? AND day = ?', whereArgs: [d['pageId'], d['year'], d['month'], d['day']]);
        return rows.isEmpty ? null : rows.first['edit_rev'] as int;
      case 'page.update':
        return col('pages', 'edit_rev', 'id = ?', [d['id']]);
      case 'page.delete':
        return col('pages', 'content_rev', 'id = ?', [d['id']]);
      case 'pages.reorder':
        return int.tryParse(await _metaOf(db, 'pages_order_rev') ?? '') ?? 0;
      case 'pages.keep':
        return int.tryParse(await _metaOf(db, 'keep_free_rev') ?? '') ?? 0;
      case 'legend.update':
      case 'legend.delete':
        return col('legends', 'edit_rev', 'id = ?', [d['id']]);
      case 'legends.reorder':
        return col('pages', 'legends_order_rev', 'id = ?', [d['pageId']]);
      case 'setting.set':
        return col('settings', 'rev', 'key = ?', [d['key']]);
    }
    throw ArgumentError('Unknown change: $kind');
  }

  /// What a change does to the copy, as the server will do it.
  Future<void> _applyLocal(Transaction txn, String kind, Map<String, dynamic> d) async {
    final now = DateTime.now();
    switch (kind) {
      case 'cell.set':
        await txn.rawInsert(
          'INSERT INTO cells (page_id, year, month, day, color, comment, updated_at) VALUES (?, ?, ?, ?, ?, ?, ?) '
          'ON CONFLICT (page_id, year, month, day) DO UPDATE SET color = excluded.color, comment = excluded.comment, updated_at = excluded.updated_at',
          [_req<String>(d, 'pageId'), _req<int>(d, 'year'), _req<int>(d, 'month'), _req<int>(d, 'day'), _req<String>(d, 'color'), d['comment'], now.millisecondsSinceEpoch],
        );
      case 'cell.clear':
        await txn.update('cells', {'color': null, 'comment': null, 'updated_at': now.millisecondsSinceEpoch},
            where: 'page_id = ? AND year = ? AND month = ? AND day = ?', whereArgs: [d['pageId'], d['year'], d['month'], d['day']]);
      case 'page.create':
        final position = Sqflite.firstIntValue(await txn.rawQuery('SELECT COALESCE(MAX(position), -1) + 1 FROM pages')) ?? 0;
        await txn.insert('pages', {
          'id': _req<String>(d, 'id'), 'title': _req<String>(d, 'title'), 'position': position,
          'palette': d['palette'] == null ? null : jsonEncode(d['palette']),
          'keep_free': 0, 'year': now.year, 'created_at': now.toUtc().toIso8601String(),
        });
        final legends = (d['legends'] as List?) ?? const [];
        for (var i = 0; i < legends.length; i++) {
          final l = (legends[i] as Map).cast<String, dynamic>();
          await txn.insert('legends', {
            'id': _req<String>(l, 'id'), 'page_id': d['id'], 'color': _req<String>(l, 'color'), 'label': _req<String>(l, 'label'),
            'position': i, 'created_at': now.toUtc().toIso8601String(),
          });
        }
      case 'page.update':
        await txn.update('pages', {
          if (d.containsKey('title')) 'title': _req<String>(d, 'title'),
          if (d.containsKey('palette')) 'palette': d['palette'] == null ? null : jsonEncode(d['palette']),
        }, where: 'id = ?', whereArgs: [_req<String>(d, 'id')]);
      case 'page.delete':
        final id = _req<String>(d, 'id');
        await txn.delete('pending_delete', where: 'page_id = ?', whereArgs: [id]);
        await txn.delete('pages', where: 'id = ?', whereArgs: [id]);
        await txn.delete('legends', where: 'page_id = ?', whereArgs: [id]);
        await txn.delete('cells', where: 'page_id = ?', whereArgs: [id]);
      case 'pages.reorder':
        final existing = [for (final r in await txn.query('pages', columns: ['id'], orderBy: 'position, created_at')) r['id'] as String];
        final order = mergeOrder(_req<List>(d, 'ids').cast<String>(), existing);
        for (var i = 0; i < order.length; i++) {
          await txn.update('pages', {'position': i}, where: 'id = ?', whereArgs: [order[i]]);
        }
      case 'pages.keep':
        final ids = _req<List>(d, 'ids').cast<String>();
        await txn.update('pages', {'keep_free': 0});
        for (final id in ids) {
          await txn.update('pages', {'keep_free': 1}, where: 'id = ?', whereArgs: [id]);
        }
      case 'legend.create':
        final pageId = _req<String>(d, 'pageId');
        final position = Sqflite.firstIntValue(await txn.rawQuery('SELECT COALESCE(MAX(position), -1) + 1 FROM legends WHERE page_id = ?', [pageId])) ?? 0;
        await txn.insert('legends', {
          'id': _req<String>(d, 'id'), 'page_id': pageId, 'color': _req<String>(d, 'color'), 'label': _req<String>(d, 'label'),
          'position': position, 'created_at': now.toUtc().toIso8601String(),
        });
      case 'legend.update':
        final id = _req<String>(d, 'id');
        final rows = await txn.query('legends', where: 'id = ?', whereArgs: [id]);
        if (rows.isEmpty) return;
        final old = rows.first;
        if (d['color'] is String && d['color'] != old['color']) {
          // The legend's days take the new colour (as the server does it),
          // and so do the queued days in its old colour: merged with an
          // earlier recolour, this change may leave before them (I5).
          await _recolorWaiting(txn, old['page_id'] as String, old['color'] as String, d['color'] as String);
        }
        await txn.update('legends', {
          if (d.containsKey('label')) 'label': _req<String>(d, 'label'),
          if (d.containsKey('color')) 'color': _req<String>(d, 'color'),
        }, where: 'id = ?', whereArgs: [id]);
      case 'legend.delete':
        await txn.delete('legends', where: 'id = ?', whereArgs: [_req<String>(d, 'id')]);
      case 'legends.reorder':
        final pageId = _req<String>(d, 'pageId');
        final existing = [
          for (final r in await txn.query('legends', columns: ['id'], where: 'page_id = ?', whereArgs: [pageId], orderBy: 'position')) r['id'] as String,
        ];
        final order = mergeOrder(_req<List>(d, 'ids').cast<String>(), existing);
        for (var i = 0; i < order.length; i++) {
          await txn.update('legends', {'position': i}, where: 'id = ?', whereArgs: [order[i]]);
        }
      case 'setting.set':
        await txn.rawInsert(
          'INSERT INTO settings (key, value) VALUES (?, ?) ON CONFLICT (key) DO UPDATE SET value = excluded.value',
          [_req<String>(d, 'key'), jsonEncode(d['value'])],
        );
      default:
        throw ArgumentError('Unknown change: $kind');
    }
  }

  // ---------------------------------------------------------------------------
  // The queue
  // ---------------------------------------------------------------------------

  Future<List<Mutation>> pending({int limit = 100}) async =>
      [for (final r in await _db.query('queue', orderBy: 'seq', limit: limit)) _mutation(r)];

  Future<int> pendingCount() async => Sqflite.firstIntValue(await _db.rawQuery('SELECT COUNT(*) FROM queue')) ?? 0;

  Future<void> markSent(Iterable<String> ids) async {
    final batch = _db.batch();
    for (final id in ids) {
      batch.update('queue', {'sent': 1}, where: 'id = ?', whereArgs: [id]);
    }
    await batch.commit(noResult: true);
  }

  /// A send failed, or the server cannot be reached: every change waiting
  /// is now judged by the offline rule.
  Future<void> markWaited() => _db.update('queue', {'waited': 1});

  static Mutation _mutation(Map<String, Object?> r) => Mutation(
        id: r['id'] as String,
        kind: r['kind'] as String,
        element: r['element'] as String,
        base: r['base'] as int?,
        data: (jsonDecode(r['data'] as String) as Map).cast<String, dynamic>(),
        waited: r['waited'] == 1,
        sent: r['sent'] == 1,
        page: r['page_id'] as String?,
      );

  /// Takes the server's answers out of the queue. An applied change makes
  /// the next ones of its element (and a deletion of its tracker) start from
  /// the number it left: the phone's own changes never count as made
  /// elsewhere (H28). A change set aside is returned for the message, takes
  /// with it what was queued in a tracker deleted elsewhere (H20), and asks
  /// for the full copy back (the server's version of what it touched).
  Future<List<SyncOutcome>> settle(List<MutationResult> results) {
    return _db.transaction((txn) async {
      final outcomes = <SyncOutcome>[];
      for (final r in results) {
        final rows = await txn.query('queue', where: 'id = ?', whereArgs: [r.id]);
        if (rows.isEmpty) continue;
        final row = rows.first;
        final m = _mutation(row);
        final seq = row['seq'] as int;
        final pageId = row['page_id'] as String?;
        await txn.delete('queue', where: 'seq = ?', whereArgs: [seq]);

        if (r.status == 'applied') {
          final element = r.revs['element'];
          final content = r.revs['content'];
          if (element != null) {
            await txn.update('queue', {'base': element}, where: 'element = ? AND seq > ?', whereArgs: [m.element, seq]);
            await _setNumber(txn, m, element);
            // The legends a tracker was created with take its number too (C1).
            if (m.kind == 'page.create') {
              for (final l in (m.data['legends'] as List?) ?? const []) {
                final legendId = (l as Map)['id'] as String;
                await txn.update('legends', {'edit_rev': element, 'rev': element}, where: 'id = ?', whereArgs: [legendId]);
                await txn.update('queue', {'base': element}, where: 'element = ? AND seq > ?', whereArgs: ['legend:$legendId', seq]);
              }
            }
          }
          if (content != null && pageId != null) {
            await txn.update('queue', {'base': content}, where: "kind = 'page.delete' AND page_id = ? AND seq > ?", whereArgs: [pageId, seq]);
            await txn.update('pages', {'content_rev': content}, where: 'id = ?', whereArgs: [pageId]);
          }
          continue;
        }

        final title = row['page_title'] as String? ?? await _titleOf(txn, pageId);
        outcomes.add(SyncOutcome(
          kind: m.kind, data: m.data, status: r.status, current: r.current, reason: r.reason,
          pageTitle: title, legendLabel: row['legend_label'] as String?,
        ));
        // Set aside or refused, the phone had it and the server does not:
        // the full copy comes back and puts the phone right (H12, H17).
        await _setMeta(txn, 'needs_full', '1');
        if (r.status == 'rejected') {
          // A tracker refused takes its queued changes with it, under the
          // same reason: they are not "deleted elsewhere" (minor 2).
          if (m.kind == 'page.create' && pageId != null) {
            final dependents = await txn.query('queue', where: 'page_id = ? AND seq > ?', whereArgs: [pageId, seq], orderBy: 'seq');
            for (final d in dependents) {
              final dm = _mutation(d);
              outcomes.add(SyncOutcome(kind: dm.kind, data: dm.data, status: 'rejected', reason: r.reason, pageTitle: title, legendLabel: d['legend_label'] as String?));
            }
            await txn.delete('queue', where: 'page_id = ? AND seq > ?', whereArgs: [pageId, seq]);
          }
          continue;
        }
        // A tracker gone elsewhere: everything queued inside it goes too.
        final trackerGone = r.status == 'deleted' && pageId != null && !m.kind.startsWith('legend.update') && !m.kind.startsWith('legend.delete');
        if (trackerGone) {
          final dependents = await txn.query('queue', where: 'page_id = ? AND seq > ?', whereArgs: [pageId, seq], orderBy: 'seq');
          for (final d in dependents) {
            final dm = _mutation(d);
            outcomes.add(SyncOutcome(kind: dm.kind, data: dm.data, status: 'deleted', pageTitle: title, legendLabel: d['legend_label'] as String?));
          }
          await txn.delete('queue', where: 'page_id = ? AND seq > ?', whereArgs: [pageId, seq]);
        }
      }
      // Kept to tell in the same step as they leave the queue: an app killed
      // right after loses nothing it has to say (I4).
      for (final o in outcomes) {
        await txn.insert('outcomes', {'json': jsonEncode(o.toJson())});
      }
      return outcomes;
    });
  }

  /// A legend recoloured elsewhere (H29): the days waiting on the phone take
  /// the new colour, and so do the changes queued for them, which then leave
  /// in it — a recolour is one element, never a change of each day. (The
  /// other days come recoloured from the server.)
  Future<void> _recolorWaiting(Transaction txn, String pageId, String from, String to) async {
    await txn.update('cells', {'color': to}, where: 'page_id = ? AND color = ?', whereArgs: [pageId, from]);
    // Sent ones too: an answer lost means the server may never have had it.
    for (final q in await txn.query('queue', where: "page_id = ? AND kind = 'cell.set'", whereArgs: [pageId])) {
      final data = (jsonDecode(q['data'] as String) as Map).cast<String, dynamic>();
      if (data['color'] != from) continue;
      await txn.update('queue', {'data': jsonEncode({...data, 'color': to})}, where: 'seq = ?', whereArgs: [q['seq']]);
    }
  }

  /// Whether changes that waited (made or kept offline) are still queued.
  Future<bool> hasWaited() async =>
      (await _db.query('queue', columns: ['seq'], where: 'waited = 1', limit: 1)).isNotEmpty;

  Future<String?> _titleOf(DatabaseExecutor db, String? pageId) async {
    if (pageId == null) return null;
    final rows = await db.query('pages', columns: ['title'], where: 'id = ?', whereArgs: [pageId]);
    return rows.isEmpty ? null : rows.first['title'] as String;
  }

  Future<String?> _labelOf(DatabaseExecutor db, String? legendId) async {
    if (legendId == null) return null;
    final rows = await db.query('legends', columns: ['label'], where: 'id = ?', whereArgs: [legendId]);
    return rows.isEmpty ? null : rows.first['label'] as String;
  }

  /// The number an applied change left on its element, on the phone.
  Future<void> _setNumber(Transaction txn, Mutation m, int rev) async {
    final d = m.data;
    switch (m.kind) {
      case 'cell.set':
      case 'cell.clear':
        await txn.update('cells', {'edit_rev': rev, 'rev': rev},
            where: 'page_id = ? AND year = ? AND month = ? AND day = ?', whereArgs: [d['pageId'], d['year'], d['month'], d['day']]);
      case 'page.create':
      case 'page.update':
        await txn.update('pages', {'edit_rev': rev, 'rev': rev}, where: 'id = ?', whereArgs: [d['id']]);
      case 'legend.create':
      case 'legend.update':
        await txn.update('legends', {'edit_rev': rev, 'rev': rev}, where: 'id = ?', whereArgs: [d['id']]);
      case 'pages.reorder':
        await _setMeta(txn, 'pages_order_rev', '$rev');
      case 'pages.keep':
        await _setMeta(txn, 'keep_free_rev', '$rev');
      case 'legends.reorder':
        await txn.update('pages', {'legends_order_rev': rev}, where: 'id = ?', whereArgs: [d['pageId']]);
      case 'setting.set':
        await txn.update('settings', {'rev': rev}, where: 'key = ?', whereArgs: [d['key']]);
    }
  }

  // ---------------------------------------------------------------------------
  // What the server sends
  // ---------------------------------------------------------------------------

  /// Updates the copy with what changed on the server (or with the full
  /// copy), except the elements that have a change waiting.
  ///
  /// True when it brought something: the screens reload only then.
  Future<bool> applyServer(SyncDelta d) {
    return _db.transaction((txn) async {
      final news = d.full || d.pages.isNotEmpty || d.legends.isNotEmpty || d.cells.isNotEmpty || d.deletions.isNotEmpty ||
          d.pagesOrder != null || d.keepFree != null || d.legendsOrder.isNotEmpty || d.settings.isNotEmpty ||
          await _metaOf(txn, 'premium') != (d.premium ? '1' : '0') || await _metaOf(txn, 'vip') != (d.vip ? '1' : '0');
      final queued = await txn.query('queue', columns: ['kind', 'element', 'page_id']);
      final waiting = {for (final q in queued) q['element'] as String};
      final deleting = {for (final q in queued) if (q['kind'] == 'page.delete') q['page_id'] as String?};
      final creatingPages = {for (final q in queued) if (q['kind'] == 'page.create') q['page_id'] as String?};
      final creatingLegends = {
        for (final q in queued) if (q['kind'] == 'legend.create') (q['element'] as String).substring('legend:'.length),
      };

      if (d.full) {
        // What the server does not have is gone — unless it is being created here.
        final serverPages = {for (final p in d.pages) p['id'] as String};
        for (final r in await txn.query('pages', columns: ['id'])) {
          final id = r['id'] as String;
          if (!serverPages.contains(id) && !creatingPages.contains(id)) await _dropPage(txn, id);
        }
        final serverLegends = {for (final l in d.legends) l['id'] as String};
        for (final r in await txn.query('legends', columns: ['id', 'page_id'])) {
          final id = r['id'] as String;
          // A tracker still being created keeps the legends it was created with.
          final ofCreated = creatingPages.contains(r['page_id']);
          if (!serverLegends.contains(id) && !creatingLegends.contains(id) && !ofCreated && !waiting.contains('legend:$id')) {
            await txn.delete('legends', where: 'id = ?', whereArgs: [id]);
          }
        }
        final serverCells = {
          for (final e in d.cells.entries)
            for (final c in e.value) 'cell:${e.key}:${c[0]}-${_two(c[1] as int)}-${_two(c[2] as int)}',
        };
        for (final r in await txn.query('cells', columns: ['page_id', 'year', 'month', 'day'])) {
          final key = 'cell:${r['page_id']}:${r['year']}-${_two(r['month'] as int)}-${_two(r['day'] as int)}';
          if (!serverCells.contains(key) && !waiting.contains(key) && !creatingPages.contains(r['page_id'])) {
            await txn.delete('cells', where: 'page_id = ? AND year = ? AND month = ? AND day = ?', whereArgs: [r['page_id'], r['year'], r['month'], r['day']]);
          }
        }
      }

      final pagesOrderWaiting = waiting.contains('pages-order');
      for (final p in d.pages) {
        final id = p['id'] as String;
        if (deleting.contains(id)) continue;
        final mine = waiting.contains('page:$id');
        final existing = await txn.query('pages', columns: ['id'], where: 'id = ?', whereArgs: [id]);
        final row = <String, Object?>{
          if (!mine) 'title': p['title'],
          if (!mine) 'palette': p['palette'] == null ? null : jsonEncode(p['palette']),
          if (!pagesOrderWaiting || existing.isEmpty) 'position': p['position'],
          if (!waiting.contains('pages-keep')) 'keep_free': p['keepFree'] == true ? 1 : 0,
          'rev': p['rev'], 'content_rev': p['contentRev'], 'legends_order_rev': p['legendsOrderRev'],
          if (!mine) 'edit_rev': p['editRev'],
        };
        if (existing.isEmpty) {
          await txn.insert('pages', {
            ...row, 'id': id, 'title': p['title'], 'year': DateTime.now().year, 'created_at': '${p['createdAt'] ?? ''}',
            'position': p['position'], 'keep_free': p['keepFree'] == true ? 1 : 0, 'edit_rev': p['editRev'],
          });
        } else {
          await txn.update('pages', row, where: 'id = ?', whereArgs: [id]);
        }
      }

      for (final l in d.legends) {
        final id = l['id'] as String;
        final pageId = l['pageId'] as String;
        if (deleting.contains(pageId) || waiting.contains('legend:$id')) continue;
        final orderWaiting = waiting.contains('legends-order:$pageId');
        final existing = await txn.query('legends', columns: ['id', 'color'], where: 'id = ?', whereArgs: [id]);
        final before = existing.isEmpty ? null : existing.first['color'] as String?;
        final after = l['color'] as String?;
        if (before != null && after != null && before != after) await _recolorWaiting(txn, pageId, before, after);
        final row = <String, Object?>{
          'page_id': pageId, 'color': l['color'], 'label': l['label'], 'rev': l['rev'], 'edit_rev': l['editRev'],
          if (!orderWaiting || existing.isEmpty) 'position': l['position'],
        };
        if (existing.isEmpty) {
          await txn.insert('legends', {...row, 'id': id, 'created_at': ''});
        } else {
          await txn.update('legends', row, where: 'id = ?', whereArgs: [id]);
        }
      }

      for (final e in d.cells.entries) {
        if (deleting.contains(e.key)) continue;
        for (final c in e.value) {
          final key = 'cell:${e.key}:${c[0]}-${_two(c[1] as int)}-${_two(c[2] as int)}';
          if (waiting.contains(key)) continue;
          await txn.rawInsert(
            'INSERT INTO cells (page_id, year, month, day, color, comment, rev, edit_rev, updated_at) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?) '
            'ON CONFLICT (page_id, year, month, day) DO UPDATE SET color = excluded.color, comment = excluded.comment, '
            'rev = excluded.rev, edit_rev = excluded.edit_rev, updated_at = excluded.updated_at',
            [e.key, c[0], c[1], c[2], c[3], c[4], c[5], c[6], c.length > 7 ? c[7] : 0],
          );
        }
      }

      for (final t in d.deletions) {
        final key = t['key'] as String;
        final rev = (t['rev'] as num).toInt();
        switch (t['kind']) {
          case 'page':
            if (!creatingPages.contains(key)) await _dropPage(txn, key);
          case 'legend':
            if (!waiting.contains('legend:$key')) await txn.delete('legends', where: 'id = ?', whereArgs: [key]);
          case 'cell':
            if (waiting.contains('cell:$key')) continue;
            final pageId = t['pageId'] as String;
            final date = key.substring(pageId.length + 1).split('-').map(int.parse).toList();
            // Only a trace newer than the day the phone has clears it: a day
            // cleared then coloured again comes with both, the row newer.
            await txn.rawInsert(
              'INSERT INTO cells (page_id, year, month, day, color, comment, rev, edit_rev) VALUES (?, ?, ?, ?, NULL, NULL, ?, ?) '
              'ON CONFLICT (page_id, year, month, day) DO UPDATE SET color = NULL, comment = NULL, rev = excluded.rev, edit_rev = excluded.edit_rev '
              'WHERE cells.rev < excluded.rev',
              [pageId, date[0], date[1], date[2], rev, rev],
            );
        }
      }

      final order = d.pagesOrder;
      if (order != null && !pagesOrderWaiting) {
        final ids = (order['ids'] as List).cast<String>();
        for (var i = 0; i < ids.length; i++) {
          await txn.update('pages', {'position': i}, where: 'id = ?', whereArgs: [ids[i]]);
        }
        await _setMeta(txn, 'pages_order_rev', '${order['rev']}');
      }
      final keep = d.keepFree;
      if (keep != null && !waiting.contains('pages-keep')) {
        await txn.update('pages', {'keep_free': 0});
        for (final id in (keep['ids'] as List).cast<String>()) {
          await txn.update('pages', {'keep_free': 1}, where: 'id = ?', whereArgs: [id]);
        }
        await _setMeta(txn, 'keep_free_rev', '${keep['rev']}');
      }
      for (final e in d.legendsOrder.entries) {
        if (waiting.contains('legends-order:${e.key}')) continue;
        final ids = (e.value['ids'] as List).cast<String>();
        for (var i = 0; i < ids.length; i++) {
          await txn.update('legends', {'position': i}, where: 'id = ?', whereArgs: [ids[i]]);
        }
        await txn.update('pages', {'legends_order_rev': e.value['rev']}, where: 'id = ?', whereArgs: [e.key]);
      }
      for (final e in d.settings.entries) {
        if (waiting.contains('setting:${e.key}')) continue;
        await txn.rawInsert(
          'INSERT INTO settings (key, value, rev) VALUES (?, ?, ?) ON CONFLICT (key) DO UPDATE SET value = excluded.value, rev = excluded.rev',
          [e.key, jsonEncode(e.value['value']), e.value['rev']],
        );
      }

      await _setMeta(txn, 'last_rev', '${d.rev}');
      await _setMeta(txn, 'premium', d.premium ? '1' : '0');
      await _setMeta(txn, 'vip', d.vip ? '1' : '0');
      if (d.full) {
        await _setMeta(txn, 'full_copy', '1');
        await _setMeta(txn, 'needs_full', '0');
      }
      return news;
    });
  }

  Future<void> _dropPage(Transaction txn, String id) async {
    await txn.delete('pages', where: 'id = ?', whereArgs: [id]);
    await txn.delete('legends', where: 'page_id = ?', whereArgs: [id]);
    await txn.delete('cells', where: 'page_id = ?', whereArgs: [id]);
  }

  // ---------------------------------------------------------------------------
  // The message of what was not kept (shown once, even after a restart)
  // ---------------------------------------------------------------------------


  /// What was not kept and not told yet (kept across a restart).
  Future<List<SyncOutcome>> storedOutcomes() async => [
        for (final r in await _db.query('outcomes', orderBy: 'seq'))
          SyncOutcome.fromJson((jsonDecode(r['json'] as String) as Map).cast<String, dynamic>()),
      ];

  /// Told: forget it.
  Future<void> clearOutcomes() => _db.delete('outcomes');

  // ---------------------------------------------------------------------------

  static Future<String?> _metaOf(DatabaseExecutor db, String key) async {
    final rows = await db.query('meta', columns: ['value'], where: 'key = ?', whereArgs: [key]);
    return rows.isEmpty ? null : rows.first['value'] as String;
  }

  static Future<void> _setMeta(DatabaseExecutor db, String key, String value) =>
      db.rawInsert('INSERT INTO meta (key, value) VALUES (?, ?) ON CONFLICT (key) DO UPDATE SET value = excluded.value', [key, value]);

  static List<List<String>>? _palette(String? json) =>
      json == null ? null : [for (final row in jsonDecode(json) as List) (row as List).cast<String>()];

  static String? _iso(int? ms) => ms == null || ms == 0 ? null : DateTime.fromMillisecondsSinceEpoch(ms, isUtc: true).toIso8601String();
}

/// An order sent for some ids against the ids there are (in their order):
/// the listed ones first, then the others — as the server merges it.
List<String> mergeOrder(List<String> listed, List<String> existing) {
  final known = existing.toSet();
  final first = <String>[];
  for (final id in listed) {
    if (known.contains(id) && !first.contains(id)) first.add(id);
  }
  final placed = first.toSet();
  return [...first, ...existing.where((id) => !placed.contains(id))];
}
