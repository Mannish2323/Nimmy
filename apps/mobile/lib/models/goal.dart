class NimmyGoal {
  const NimmyGoal({
    required this.id,
    required this.userId,
    required this.title,
    this.description,
    this.targetDate,
    this.progress = 0.0,
    this.status = 'in_progress',
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String userId;
  final String title;
  final String? description;
  final DateTime? targetDate;
  final double progress; // 0.0 to 1.0
  final String status;
  final DateTime createdAt;
  final DateTime updatedAt;

  bool get isCompleted => progress >= 1.0 || status == 'completed';

  NimmyGoal copyWith({
    String? id,
    String? userId,
    String? title,
    String? description,
    DateTime? targetDate,
    double? progress,
    String? status,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return NimmyGoal(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      description: description ?? this.description,
      targetDate: targetDate ?? this.targetDate,
      progress: progress ?? this.progress,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'title': title,
      'description': description,
      'target_date': targetDate?.toUtc().toIso8601String(),
      'progress': progress,
      'status': status,
      'created_at': createdAt.toUtc().toIso8601String(),
      'updated_at': updatedAt.toUtc().toIso8601String(),
    };
  }

  factory NimmyGoal.fromJson(Map<String, dynamic> json) {
    return NimmyGoal(
      id: json['id'] as String,
      userId: json['user_id'] as String? ?? 'local-user',
      title: json['title'] as String,
      description: json['description'] as String?,
      targetDate: json['target_date'] != null
          ? DateTime.parse(json['target_date'] as String)
          : null,
      progress: (json['progress'] as num?)?.toDouble() ?? 0.0,
      status: json['status'] as String? ?? 'in_progress',
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  @override
  String toString() => 'NimmyGoal(id: $id, title: $title, progress: ${(progress * 100).toInt()}%)';
}
