import 'calendar_event.dart';
import 'memory.dart';
import 'reminder.dart';
import 'task.dart';

enum NimmyIntent {
  createReminder,
  saveMemory,
  createTask,
  editTask,
  completeTask,
  deleteTask,
  rescheduleTask,
  createCalendarEvent,
  editCalendarEvent,
  deleteCalendarEvent,
  rescheduleCalendarEvent,
  rescheduleReminder,
  deleteReminder,
  unknown,
}

sealed class ToolInput {
  const ToolInput();

  Map<String, dynamic> toJson();
}

class CreateReminderInput extends ToolInput {
  const CreateReminderInput({
    required this.title,
    required this.scheduledAt,
    required this.timezone,
    this.recurrence,
    this.notes,
  });

  final String title;
  final DateTime scheduledAt;
  final String timezone;
  final String? recurrence;
  final String? notes;

  @override
  Map<String, dynamic> toJson() => {
    'title': title,
    'scheduled_at': scheduledAt.toUtc().toIso8601String(),
    'timezone': timezone,
    'recurrence': recurrence,
    'notes': notes,
  };
}

class SaveMemoryInput extends ToolInput {
  const SaveMemoryInput({
    required this.content,
    required this.category,
    required this.importance,
    this.sourceReference,
  });

  final String content;
  final MemoryCategory category;
  final MemoryImportance importance;
  final String? sourceReference;

  @override
  Map<String, dynamic> toJson() => {
    'content': content,
    'category': category.name,
    'importance': importance.name,
    'source_reference': sourceReference,
  };
}

class CreateTaskInput extends ToolInput {
  const CreateTaskInput({
    required this.title,
    this.priority = TaskPriority.medium,
    this.dueDate,
    this.timezone = 'UTC',
    this.projectId,
    this.description,
    this.recurrence,
    this.tags = const [],
  });

  final String title;
  final TaskPriority priority;
  final DateTime? dueDate;
  final String timezone;
  final String? projectId;
  final String? description;
  final String? recurrence;
  final List<String> tags;

  @override
  Map<String, dynamic> toJson() => {
    'title': title,
    'priority': priority.name,
    'due_date': dueDate?.toUtc().toIso8601String(),
    'timezone': timezone,
    'project_id': projectId,
    'description': description,
    'recurrence': recurrence,
    'tags': tags,
  };
}

class EditTaskInput extends ToolInput {
  const EditTaskInput({
    required this.taskId,
    this.title,
    this.priority,
    this.dueDate,
    this.description,
    this.projectId,
    this.tags,
  });

  final String taskId;
  final String? title;
  final TaskPriority? priority;
  final DateTime? dueDate;
  final String? description;
  final String? projectId;
  final List<String>? tags;

  @override
  Map<String, dynamic> toJson() => {
    'task_id': taskId,
    if (title != null) 'title': title,
    if (priority != null) 'priority': priority!.name,
    if (dueDate != null) 'due_date': dueDate!.toUtc().toIso8601String(),
    if (description != null) 'description': description,
    if (projectId != null) 'project_id': projectId,
    if (tags != null) 'tags': tags,
  };
}

class CompleteTaskInput extends ToolInput {
  const CompleteTaskInput({
    required this.taskId,
    this.completedAt,
  });

  final String taskId;
  final DateTime? completedAt;

  @override
  Map<String, dynamic> toJson() => {
    'task_id': taskId,
    'completed_at': (completedAt ?? DateTime.now()).toUtc().toIso8601String(),
  };
}

class DeleteTaskInput extends ToolInput {
  const DeleteTaskInput({required this.taskId});

  final String taskId;

  @override
  Map<String, dynamic> toJson() => {'task_id': taskId};
}

class RescheduleTaskInput extends ToolInput {
  const RescheduleTaskInput({
    required this.taskId,
    required this.newDueDate,
    this.reason,
  });

  final String taskId;
  final DateTime newDueDate;
  final String? reason;

  @override
  Map<String, dynamic> toJson() => {
    'task_id': taskId,
    'new_due_date': newDueDate.toUtc().toIso8601String(),
    if (reason != null) 'reason': reason,
  };
}

class CreateCalendarEventInput extends ToolInput {
  const CreateCalendarEventInput({
    required this.title,
    required this.startTime,
    this.endTime,
    this.isAllDay = false,
    this.eventType = EventType.personal,
    this.description,
    this.location,
    this.colorHex,
    this.taskId,
  });

  final String title;
  final DateTime startTime;
  final DateTime? endTime;
  final bool isAllDay;
  final EventType eventType;
  final String? description;
  final String? location;
  final String? colorHex;
  final String? taskId;

  @override
  Map<String, dynamic> toJson() => {
    'title': title,
    'start_time': startTime.toUtc().toIso8601String(),
    if (endTime != null) 'end_time': endTime!.toUtc().toIso8601String(),
    'is_all_day': isAllDay,
    'event_type': eventType.name,
    if (description != null) 'description': description,
    if (location != null) 'location': location,
    if (colorHex != null) 'color_hex': colorHex,
    if (taskId != null) 'task_id': taskId,
  };
}

class EditCalendarEventInput extends ToolInput {
  const EditCalendarEventInput({
    required this.id,
    this.title,
    this.startTime,
    this.endTime,
    this.isAllDay,
    this.eventType,
    this.description,
    this.location,
    this.colorHex,
  });

  final String id;
  final String? title;
  final DateTime? startTime;
  final DateTime? endTime;
  final bool? isAllDay;
  final EventType? eventType;
  final String? description;
  final String? location;
  final String? colorHex;

  @override
  Map<String, dynamic> toJson() => {
    'id': id,
    if (title != null) 'title': title,
    if (startTime != null) 'start_time': startTime!.toUtc().toIso8601String(),
    if (endTime != null) 'end_time': endTime!.toUtc().toIso8601String(),
    if (isAllDay != null) 'is_all_day': isAllDay,
    if (eventType != null) 'event_type': eventType!.name,
    if (description != null) 'description': description,
    if (location != null) 'location': location,
    if (colorHex != null) 'color_hex': colorHex,
  };
}

class DeleteCalendarEventInput extends ToolInput {
  const DeleteCalendarEventInput({required this.id});

  final String id;

  @override
  Map<String, dynamic> toJson() => {'id': id};
}

class RescheduleCalendarEventInput extends ToolInput {
  const RescheduleCalendarEventInput({
    required this.id,
    required this.startTime,
    this.endTime,
    this.reason,
  });

  final String id;
  final DateTime startTime;
  final DateTime? endTime;
  final String? reason;

  @override
  Map<String, dynamic> toJson() => {
    'id': id,
    'start_time': startTime.toUtc().toIso8601String(),
    if (endTime != null) 'end_time': endTime!.toUtc().toIso8601String(),
    if (reason != null) 'reason': reason,
  };
}

class RescheduleReminderInput extends ToolInput {
  const RescheduleReminderInput({
    required this.id,
    required this.scheduledAt,
    this.reason,
  });

  final String id;
  final DateTime scheduledAt;
  final String? reason;

  @override
  Map<String, dynamic> toJson() => {
    'id': id,
    'scheduled_at': scheduledAt.toUtc().toIso8601String(),
    if (reason != null) 'reason': reason,
  };
}

class DeleteReminderInput extends ToolInput {
  const DeleteReminderInput({required this.id});

  final String id;

  @override
  Map<String, dynamic> toJson() => {'id': id};
}

class ToolProposal {
  const ToolProposal({
    required this.requestId,
    required this.intent,
    required this.toolName,
    required this.input,
    required this.source,
    required this.originalText,
  });

  final String requestId;
  final NimmyIntent intent;
  final String toolName;
  final ToolInput input;
  final InteractionSource source;
  final String originalText;
}

class IntentParseResult {
  const IntentParseResult._({this.proposal, this.clarification, this.error});

  const IntentParseResult.proposal(ToolProposal proposal)
    : this._(proposal: proposal);

  const IntentParseResult.clarification(String message)
    : this._(clarification: message);

  const IntentParseResult.error(String message) : this._(error: message);

  final ToolProposal? proposal;
  final String? clarification;
  final String? error;

  bool get hasProposal => proposal != null;
}

class ToolExecutionResult {
  const ToolExecutionResult({
    required this.success,
    required this.message,
    this.recordId,
    this.warning,
    this.wasDuplicate = false,
  });

  final bool success;
  final String message;
  final String? recordId;
  final String? warning;
  final bool wasDuplicate;
}
