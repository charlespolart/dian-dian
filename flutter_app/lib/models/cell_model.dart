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
