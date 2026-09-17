enum InteractionSource { voice, text, system }

enum ReminderStatus { pending, triggered, completed, cancelled }

class NimmyReminder {
  const NimmyReminder({
    required this.id,
    required this.userId,
    required this.requestId,
    required this.title,
    required this.scheduledAt,
    required this.timezone,
    required this.source,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.recurrence,
    this.notes,
    this.notificationScheduled = false,
  });

  final String id;
  final String userId;
  final String requestId;
  final String title;
  final DateTime scheduledAt;
  final String timezone;
  final String? recurrence;
  final String? notes;
  final InteractionSource source;
  final ReminderStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool notificationScheduled;

  NimmyReminder copyWith({
    String? title,
    DateTime? scheduledAt,
    String? timezone,
    String? recurrence,
    String? notes,
    ReminderStatus? status,
    DateTime? updatedAt,
    bool? notificationScheduled,
  }) {
    return NimmyReminder(
      id: id,
      userId: userId,
      requestId: requestId,
      title: title ?? this.title,
      scheduledAt: scheduledAt ?? this.scheduledAt,
      timezone: timezone ?? this.timezone,
      recurrence: recurrence ?? this.recurrence,
      notes: notes ?? this.notes,
      source: source,
      status: status ?? this.status,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      notificationScheduled:
          notificationScheduled ?? this.notificationScheduled,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'user_id': userId,
    'request_id': requestId,
    'title': title,
    'scheduled_at': scheduledAt.toUtc().toIso8601String(),
    'timezone': timezone,
    'recurrence': recurrence,
    'notes': notes,
    'source': source.name,
    'status': status.name,
    'created_at': createdAt.toUtc().toIso8601String(),
    'updated_at': updatedAt.toUtc().toIso8601String(),
    'notification_scheduled': notificationScheduled,
  };

  factory NimmyReminder.fromJson(Map<String, dynamic> json) {
    return NimmyReminder(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      requestId: json['request_id'] as String,
      title: json['title'] as String,
      scheduledAt: DateTime.parse(json['scheduled_at'] as String),
      timezone: json['timezone'] as String,
      recurrence: json['recurrence'] as String?,
      notes: json['notes'] as String?,
      source: InteractionSource.values.byName(json['source'] as String),
      status: ReminderStatus.values.byName(json['status'] as String),
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      notificationScheduled: json['notification_scheduled'] as bool? ?? false,
    );
  }
}
