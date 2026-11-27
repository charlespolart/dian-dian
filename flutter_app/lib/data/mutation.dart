/// What the phone and the server exchange for offline sync (chantier 10).
/// The JSON mirrors `backend/src/sync/mutations.ts` and
/// `backend/src/routes/sync.ts`; a change of one is a change of the other.
library;

/// A change written on the phone and queued for the server.
class Mutation {
  /// Unique, chosen by the phone: the server answers a resend the same way.
  final String id;

  /// One of the server's kinds: `cell.set`, `cell.clear`, `page.create`,
  /// `page.update`, `page.delete`, `pages.reorder`, `pages.keep`,
  /// `legend.create`, `legend.update`, `legend.delete`, `legends.reorder`,
  /// `setting.set`.
  final String kind;

  /// What it changes, for merging and rebasing: `cell:<page>:<yyyy-mm-dd>`,
  /// `page:<id>`, `page-delete:<id>`, `pages-order`, `pages-keep`,
  /// `legend:<id>`, `legends-order:<page>`, `setting:<key>`.
  final String element;

  /// The number of its element as the phone knew it; null for a creation.
  final int? base;
  final Map<String, dynamic> data;

  /// Made offline, or its first send failed: the server judges it by the
  /// offline rule ("the server wins").
  final bool waited;

  /// Included in a request whose answer has not come back yet.
  final bool sent;

  const Mutation({
    required this.id,
    required this.kind,
    required this.element,
    required this.base,
    required this.data,
    required this.waited,
    required this.sent,
  });

  /// The tracker this change belongs to (null for an order of trackers, the
  /// open ones, or a setting).
  String? get pageId => pageOf(kind, data);

  static String? pageOf(String kind, Map<String, dynamic> data) {
    if (kind.startsWith('cell.') || kind == 'legend.create' || kind == 'legends.reorder') return data['pageId'] as String?;
    if (kind.startsWith('page.')) return data['id'] as String?;
    return null; // legend.update / legend.delete: looked up by the store
  }

  Map<String, dynamic> toJson() => {'id': id, 'kind': kind, 'waited': waited, 'base': base, 'data': data};
}

/// The server's answer to one change.
class MutationResult {
  final String id;

  /// `applied`, `changed` (changed elsewhere), `deleted` (deleted elsewhere)
  /// or `rejected` (refused for another reason, see [reason]).
  final String status;

  /// For `applied`: the numbers it left (`element`, `content`, `account`).
  final Map<String, int> revs;

  /// For `changed`: what the server keeps.
  final Object? current;
  final String? reason;

  const MutationResult({required this.id, required this.status, this.revs = const {}, this.current, this.reason});

  factory MutationResult.fromJson(Map<String, dynamic> json) => MutationResult(
        id: json['id'] as String? ?? '',
        status: json['status'] as String,
        revs: {for (final e in ((json['revs'] as Map?) ?? const {}).entries) e.key as String: (e.value as num).toInt()},
        current: json['current'],
        reason: json['reason'] as String?,
      );
}

/// A change the server did not keep, as the message tells it (H17, H20, H21,
/// H22, H12): what it was, and why.
class SyncOutcome {
  final String kind;
  final Map<String, dynamic> data;

  /// `changed`, `deleted` or `rejected`.
  final String status;
  final Object? current;
  final String? reason;

  /// The tracker's title as the phone knew it when the change was made.
  final String? pageTitle;

  /// The legend's label as the phone knew it, for a legend change.
  final String? legendLabel;

  const SyncOutcome({required this.kind, required this.data, required this.status, this.current, this.reason, this.pageTitle, this.legendLabel});

  Map<String, dynamic> toJson() =>
      {'kind': kind, 'data': data, 'status': status, 'current': current, 'reason': reason, 'pageTitle': pageTitle, 'legendLabel': legendLabel};

  factory SyncOutcome.fromJson(Map<String, dynamic> json) => SyncOutcome(
        kind: json['kind'] as String,
        data: (json['data'] as Map).cast<String, dynamic>(),
        status: json['status'] as String,
        current: json['current'],
        reason: json['reason'] as String?,
        pageTitle: json['pageTitle'] as String?,
        legendLabel: json['legendLabel'] as String?,
      );
}

/// What `GET /api/sync?since=` returns.
class SyncDelta {
  final int rev;
  final bool full;
  final List<Map<String, dynamic>> pages;
  final List<Map<String, dynamic>> legends;

  /// pageId → [year, month, day, color, comment, rev, editRev, updatedAtMs].
  final Map<String, List<List<dynamic>>> cells;
  final List<Map<String, dynamic>> deletions;

  /// {rev, ids}: present when the trackers' order changed.
  final Map<String, dynamic>? pagesOrder;

  /// {rev, ids}: present when the choice of open trackers changed.
  final Map<String, dynamic>? keepFree;

  /// pageId → {rev, ids}.
  final Map<String, Map<String, dynamic>> legendsOrder;

  /// key → {rev, value}, for the settings that changed.
  final Map<String, Map<String, dynamic>> settings;
  final bool premium;
  final bool vip;

  const SyncDelta({
    required this.rev,
    required this.full,
    required this.pages,
    required this.legends,
    required this.cells,
    required this.deletions,
    this.pagesOrder,
    this.keepFree,
    required this.legendsOrder,
    required this.settings,
    required this.premium,
    required this.vip,
  });

  factory SyncDelta.fromJson(Map<String, dynamic> json) {
    List<Map<String, dynamic>> rows(String key) =>
        [for (final r in (json[key] as List?) ?? const []) (r as Map).cast<String, dynamic>()];
    Map<String, Map<String, dynamic>> byKey(String key) => {
          for (final e in ((json[key] as Map?) ?? const {}).entries)
            if (e.value != null) e.key as String: (e.value as Map).cast<String, dynamic>(),
        };
    return SyncDelta(
      rev: (json['rev'] as num).toInt(),
      full: json['full'] == true,
      pages: rows('pages'),
      legends: rows('legends'),
      cells: {
        for (final e in ((json['cells'] as Map?) ?? const {}).entries)
          e.key as String: [for (final c in e.value as List) (c as List).cast<dynamic>()],
      },
      deletions: rows('deletions'),
      pagesOrder: (json['pagesOrder'] as Map?)?.cast<String, dynamic>(),
      keepFree: (json['keepFree'] as Map?)?.cast<String, dynamic>(),
      legendsOrder: byKey('legendsOrder'),
      settings: byKey('settings'),
      premium: json['premium'] == true,
      vip: json['vip'] == true,
    );
  }
}
