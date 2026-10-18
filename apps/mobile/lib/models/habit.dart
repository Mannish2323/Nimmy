class NimmyHabit {
  const NimmyHabit({
    required this.id,
    required this.userId,
    required this.title,
    this.frequency = 'daily', // 'daily', 'weekdays', 'weekly'
    this.streakCount = 0,
    this.bestStreak = 0,
    this.lastCompletedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String userId;
  final String title;
  final String frequency;
  final int streakCount;
  final int bestStreak;
  final DateTime? lastCompletedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  bool get isCompletedToday {
    if (lastCompletedAt == null) return false;
    final now = DateTime.now();
    final local = lastCompletedAt!.toLocal();
    return local.year == now.year &&
        local.month == now.month &&
        local.day == now.day;
  }

  NimmyHabit copyWith({
    String? id,
    String? userId,
    String? title,
    String? frequency,
    int? streakCount,
    int? bestStreak,
    DateTime? lastCompletedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return NimmyHabit(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      frequency: frequency ?? this.frequency,
      streakCount: streakCount ?? this.streakCount,
      bestStreak: bestStreak ?? this.bestStreak,
      lastCompletedAt: lastCompletedAt ?? this.lastCompletedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'title': title,
      'frequency': frequency,
      'streak_count': streakCount,
      'best_streak': bestStreak,
      'last_completed_at': lastCompletedAt?.toUtc().toIso8601String(),
      'created_at': createdAt.toUtc().toIso8601String(),
      'updated_at': updatedAt.toUtc().toIso8601String(),
    };
  }

  factory NimmyHabit.fromJson(Map<String, dynamic> json) {
    return NimmyHabit(
      id: json['id'] as String,
      userId: json['user_id'] as String? ?? 'local-user',
      title: json['title'] as String,
      frequency: json['frequency'] as String? ?? 'daily',
      streakCount: (json['streak_count'] as num?)?.toInt() ?? 0,
      bestStreak: (json['best_streak'] as num?)?.toInt() ?? 0,
      lastCompletedAt: json['last_completed_at'] != null
          ? DateTime.parse(json['last_completed_at'] as String)
          : null,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  @override
  String toString() => 'NimmyHabit(id: $id, title: $title, streak: $streakCount)';
}
