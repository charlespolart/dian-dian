class PageModel {
  final String id;
  final String userId;
  final String title;
  final int year;
  final int position;
  final List<List<String>>? palette;
  final String createdAt;

  /// Cells touched in the last 90 days (server-computed, all years) and the
  /// last cell date: what "most active" means for the free-tier lock.
  final int recentCells;
  final String? lastCellAt;

  /// The user's choice of trackers that stay open on a free account over
  /// the limit (none chosen → the most active ones).
  final bool keepFree;

  const PageModel({
    required this.id,
    required this.userId,
    required this.title,
    required this.year,
    required this.position,
    this.palette,
    required this.createdAt,
    this.recentCells = 0,
    this.lastCellAt,
    this.keepFree = false,
  });

  factory PageModel.fromJson(Map<String, dynamic> json) {
    return PageModel(
      id: json['id'] as String,
      userId: (json['userId'] ?? json['user_id'] ?? '') as String,
      title: (json['title'] ?? 'Tracker') as String,
      year: (json['year'] ?? DateTime.now().year) as int,
      position: (json['position'] ?? 0) as int,
      palette: json['palette'] != null
          ? (json['palette'] as List<dynamic>)
              .map((row) =>
                  (row as List<dynamic>).map((c) => c as String).toList())
              .toList()
          : null,
      createdAt: (json['createdAt'] ?? json['created_at'] ?? '') as String,
      recentCells: (json['recentCells'] ?? 0) as int,
      lastCellAt: json['lastCellAt'] as String?,
      keepFree: (json['keepFree'] ?? json['keep_free'] ?? false) as bool,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'title': title,
      'year': year,
      'position': position,
      'palette': palette,
      'createdAt': createdAt,
      'recentCells': recentCells,
      'lastCellAt': lastCellAt,
      'keepFree': keepFree,
    };
  }

  PageModel copyWith({
    String? id,
    String? userId,
    String? title,
    int? year,
    int? position,
    List<List<String>>? palette,
    String? createdAt,
    int? recentCells,
    String? lastCellAt,
    bool? keepFree,
  }) {
    return PageModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      year: year ?? this.year,
      position: position ?? this.position,
      palette: palette ?? this.palette,
      createdAt: createdAt ?? this.createdAt,
      recentCells: recentCells ?? this.recentCells,
      lastCellAt: lastCellAt ?? this.lastCellAt,
      keepFree: keepFree ?? this.keepFree,
    );
  }
}
