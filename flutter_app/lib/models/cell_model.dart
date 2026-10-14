class CellModel {
  final String pageId;
  final int year;
  final int month;
  final int day;
  final String color;
  final String? comment;
  final String updatedAt;

  const CellModel({
    required this.pageId,
    required this.year,
    required this.month,
    required this.day,
    required this.color,
    this.comment,
    required this.updatedAt,
  });

  /// Stable O(1) lookup key inside a year: months 1..12, days 1..31.
  static int keyOf(int month, int day) => month * 32 + day;
  int get key => keyOf(month, day);

  /// Bootstrap tuple: `[month, day, color]` or `[month, day, color, comment]`.
  factory CellModel.fromCompact(String pageId, int year, List<dynamic> row) {
    return CellModel(
      pageId: pageId,
      year: year,
      month: row[0] as int,
      day: row[1] as int,
      color: row[2] as String,
      comment: row.length > 3 ? row[3] as String? : null,
      updatedAt: '',
    );
  }

  /// Inverse of [fromCompact]; an empty comment is dropped, not serialized.
  List<dynamic> toCompact() {
    final c = comment;
    return c != null && c.isNotEmpty ? [month, day, color, c] : [month, day, color];
  }

  factory CellModel.fromJson(Map<String, dynamic> json) {
    return CellModel(
      pageId: (json['pageId'] ?? json['page_id'] ?? '') as String,
      year: (json['year'] ?? DateTime.now().year) as int,
      month: (json['month'] ?? 1) as int,
      day: (json['day'] ?? 1) as int,
      color: (json['color'] ?? '') as String,
      comment: json['comment'] as String?,
      updatedAt: (json['updatedAt'] ?? json['updated_at'] ?? '') as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'page_id': pageId,
      'year': year,
      'month': month,
      'day': day,
      'color': color,
      'comment': comment,
      'updated_at': updatedAt,
    };
  }

  CellModel copyWith({
    String? pageId,
    int? year,
    int? month,
    int? day,
    String? color,
    String? comment,
    String? updatedAt,
  }) {
    return CellModel(
      pageId: pageId ?? this.pageId,
      year: year ?? this.year,
      month: month ?? this.month,
      day: day ?? this.day,
      color: color ?? this.color,
      comment: comment ?? this.comment,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
