enum EventType {
  meeting,
  reminder,
  deadline,
  personal,
  aiScheduled,
}

class NimmyCalendarEvent {
  const NimmyCalendarEvent({
    required this.id,
    required this.userId,
    required this.title,
    required this.startTime,
    this.taskId,
    this.description,
    this.eventType = EventType.personal,
    this.endTime,
    this.isAllDay = false,
    this.location,
    this.colorHex,
    this.isRecurring = false,
    this.recurrenceRule,
    this.aiGenerated = false,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String userId;
  final String? taskId;
  final String title;
  final String? description;
  final EventType eventType;
  final DateTime startTime;
  final DateTime? endTime;
  final bool isAllDay;
  final String? location;
  final String? colorHex;
  final bool isRecurring;
  final String? recurrenceRule;
  final bool aiGenerated;
  final DateTime createdAt;
  final DateTime updatedAt;

  NimmyCalendarEvent copyWith({
    String? id,
    String? userId,
    String? taskId,
    String? title,
    String? description,
    EventType? eventType,
    DateTime? startTime,
    DateTime? endTime,
    bool? isAllDay,
    String? location,
    String? colorHex,
    bool? isRecurring,
    String? recurrenceRule,
    bool? aiGenerated,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return NimmyCalendarEvent(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      taskId: taskId ?? this.taskId,
      title: title ?? this.title,
      description: description ?? this.description,
      eventType: eventType ?? this.eventType,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      isAllDay: isAllDay ?? this.isAllDay,
      location: location ?? this.location,
      colorHex: colorHex ?? this.colorHex,
      isRecurring: isRecurring ?? this.isRecurring,
      recurrenceRule: recurrenceRule ?? this.recurrenceRule,
      aiGenerated: aiGenerated ?? this.aiGenerated,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'user_id': userId,
        'task_id': taskId,
        'title': title,
        'description': description,
        'event_type': eventType.name,
        'start_time': startTime.toUtc().toIso8601String(),
        'end_time': endTime?.toUtc().toIso8601String(),
        'is_all_day': isAllDay,
        'location': location,
        'color_hex': colorHex,
        'is_recurring': isRecurring,
        'recurrence_rule': recurrenceRule,
        'ai_generated': aiGenerated,
        'created_at': createdAt.toUtc().toIso8601String(),
        'updated_at': updatedAt.toUtc().toIso8601String(),
      };

  factory NimmyCalendarEvent.fromJson(Map<String, dynamic> json) {
    return NimmyCalendarEvent(
      id: json['id'] as String,
      userId: json['user_id'] as String? ?? 'local_user',
      taskId: json['task_id'] as String?,
      title: json['title'] as String,
      description: json['description'] as String?,
      eventType: EventType.values.firstWhere(
        (e) =>
            e.name == json['event_type'] ||
            _toSnake(e.name) == json['event_type'],
        orElse: () => EventType.personal,
      ),
      startTime: DateTime.parse(json['start_time'] as String),
      endTime: json['end_time'] != null
          ? DateTime.parse(json['end_time'] as String)
          : null,
      isAllDay: json['is_all_day'] as bool? ?? json['all_day'] as bool? ?? false,
      location: json['location'] as String?,
      colorHex: json['color_hex'] as String? ?? json['color'] as String?,
      isRecurring: json['is_recurring'] as bool? ?? false,
      recurrenceRule: json['recurrence_rule'] as String?,
      aiGenerated: json['ai_generated'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  static String _toSnake(String camel) {
    return camel.replaceAllMapped(
      RegExp(r'[A-Z]'),
      (match) => '_${match.group(0)!.toLowerCase()}',
    );
  }
}
