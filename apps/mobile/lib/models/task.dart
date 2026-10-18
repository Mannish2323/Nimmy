enum TaskPriority {
  low,
  medium,
  high,
  urgent;

  static TaskPriority fromString(String? value) {
    return switch (value?.toLowerCase()) {
      'urgent' => TaskPriority.urgent,
      'high' => TaskPriority.high,
      'low' => TaskPriority.low,
      _ => TaskPriority.medium,
    };
  }
}

enum TaskStatus {
  todo,
  inProgress,
  done,
  cancelled;

  static TaskStatus fromString(String? value) {
    return switch (value?.toLowerCase()) {
      'in_progress' || 'inprogress' => TaskStatus.inProgress,
      'done' || 'completed' => TaskStatus.done,
      'cancelled' || 'canceled' => TaskStatus.cancelled,
      _ => TaskStatus.todo,
    };
  }

  String toDbString() {
    return switch (this) {
      TaskStatus.todo => 'todo',
      TaskStatus.inProgress => 'in_progress',
      TaskStatus.done => 'done',
      TaskStatus.cancelled => 'cancelled',
    };
  }
}

class NimmyTask {
  const NimmyTask({
    required this.id,
    required this.userId,
    this.requestId,
    this.projectId,
    required this.title,
    this.description,
    this.priority = TaskPriority.medium,
    this.status = TaskStatus.todo,
    this.dueDate,
    this.completedAt,
    this.tags = const [],
    this.isRecurring = false,
    this.recurrenceRule,
    this.parentTaskId,
    this.sortOrder = 0,
    this.aiGenerated = false,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String userId;
  final String? requestId;
  final String? projectId;
  final String title;
  final String? description;
  final TaskPriority priority;
  final TaskStatus status;
  final DateTime? dueDate;
  final DateTime? completedAt;
  final List<String> tags;
  final bool isRecurring;
  final String? recurrenceRule;
  final String? parentTaskId;
  final int sortOrder;
  final bool aiGenerated;
  final DateTime createdAt;
  final DateTime updatedAt;

  bool get isCompleted => status == TaskStatus.done;
  bool get isOverdue {
    if (dueDate == null || isCompleted) return false;
    return dueDate!.isBefore(DateTime.now());
  }

  NimmyTask copyWith({
    String? id,
    String? userId,
    String? requestId,
    String? projectId,
    String? title,
    String? description,
    TaskPriority? priority,
    TaskStatus? status,
    DateTime? dueDate,
    DateTime? completedAt,
    List<String>? tags,
    bool? isRecurring,
    String? recurrenceRule,
    String? parentTaskId,
    int? sortOrder,
    bool? aiGenerated,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return NimmyTask(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      requestId: requestId ?? this.requestId,
      projectId: projectId ?? this.projectId,
      title: title ?? this.title,
      description: description ?? this.description,
      priority: priority ?? this.priority,
      status: status ?? this.status,
      dueDate: dueDate ?? this.dueDate,
      completedAt: completedAt ?? this.completedAt,
      tags: tags ?? this.tags,
      isRecurring: isRecurring ?? this.isRecurring,
      recurrenceRule: recurrenceRule ?? this.recurrenceRule,
      parentTaskId: parentTaskId ?? this.parentTaskId,
      sortOrder: sortOrder ?? this.sortOrder,
      aiGenerated: aiGenerated ?? this.aiGenerated,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'request_id': requestId,
      'project_id': projectId,
      'title': title,
      'description': description,
      'priority': priority.name,
      'status': status.toDbString(),
      'due_date': dueDate?.toUtc().toIso8601String(),
      'completed_at': completedAt?.toUtc().toIso8601String(),
      'tags': tags,
      'is_recurring': isRecurring,
      'recurrence_rule': recurrenceRule,
      'parent_task_id': parentTaskId,
      'sort_order': sortOrder,
      'ai_generated': aiGenerated,
      'created_at': createdAt.toUtc().toIso8601String(),
      'updated_at': updatedAt.toUtc().toIso8601String(),
    };
  }

  factory NimmyTask.fromJson(Map<String, dynamic> json) {
    return NimmyTask(
      id: json['id'] as String,
      userId: json['user_id'] as String? ?? 'local-user',
      requestId: json['request_id'] as String?,
      projectId: json['project_id'] as String?,
      title: json['title'] as String,
      description: json['description'] as String?,
      priority: TaskPriority.fromString(json['priority'] as String?),
      status: TaskStatus.fromString(json['status'] as String?),
      dueDate: json['due_date'] != null
          ? DateTime.parse(json['due_date'] as String)
          : null,
      completedAt: json['completed_at'] != null
          ? DateTime.parse(json['completed_at'] as String)
          : null,
      tags: json['tags'] != null
          ? List<String>.from(json['tags'] as List)
          : const [],
      isRecurring: json['is_recurring'] as bool? ?? false,
      recurrenceRule: json['recurrence_rule'] as String?,
      parentTaskId: json['parent_task_id'] as String?,
      sortOrder: (json['sort_order'] as num?)?.toInt() ?? 0,
      aiGenerated: json['ai_generated'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  @override
  String toString() => 'NimmyTask(id: $id, title: $title, status: $status, priority: $priority)';
}
