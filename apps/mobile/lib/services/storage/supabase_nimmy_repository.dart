import 'package:supabase/supabase.dart';

import '../../models/audit_event.dart';
import '../../models/calendar_event.dart';
import '../../models/goal.dart';
import '../../models/habit.dart';
import '../../models/memory.dart';
import '../../models/project.dart';
import '../../models/reminder.dart';
import '../../models/task.dart';
import 'nimmy_repository.dart';

class SupabaseNimmyRepository implements NimmyRepository {
  SupabaseNimmyRepository(this._client);

  final SupabaseClient _client;
  String? _profileId;

  String get profileId {
    final value = _profileId;
    if (value == null) {
      throw StateError('An authenticated Nimmy profile is required.');
    }
    return value;
  }

  @override
  Future<void> initialize() async {
    final authUser = _client.auth.currentUser;
    if (authUser == null) {
      throw StateError('Supabase session is not authenticated.');
    }
    final profile = await _client
        .from('users')
        .select('id')
        .eq('auth_id', authUser.id)
        .maybeSingle();
    if (profile == null) {
      final email = authUser.email;
      if (email == null || email.isEmpty) {
        throw StateError('The current account has no email-backed profile.');
      }
      final inserted = await _client
          .from('users')
          .insert({
            'auth_id': authUser.id,
            'email': email,
            'display_name':
                authUser.userMetadata?['display_name'] as String? ??
                'Nimmy User',
          })
          .select('id')
          .single();
      _profileId = inserted['id'] as String;
      return;
    }
    _profileId = profile['id'] as String;
  }

  // Calendar Events
  @override
  Future<List<NimmyCalendarEvent>> listCalendarEvents() async {
    final rows = await _client
        .from('calendar_events')
        .select()
        .eq('user_id', profileId)
        .order('start_time');
    return rows.map<NimmyCalendarEvent>(_eventFromRow).toList();
  }

  @override
  Future<NimmyCalendarEvent?> findCalendarEventById(String id) async {
    final row = await _client
        .from('calendar_events')
        .select()
        .eq('user_id', profileId)
        .eq('id', id)
        .maybeSingle();
    return row == null ? null : _eventFromRow(row);
  }

  @override
  Future<void> saveCalendarEvent(NimmyCalendarEvent event) async {
    await _client.from('calendar_events').upsert({
      'id': event.id,
      'user_id': profileId,
      'task_id': event.taskId,
      'title': event.title,
      'description': event.description,
      'event_type': _eventTypeToDatabase(event.eventType),
      'start_time': event.startTime.toUtc().toIso8601String(),
      'end_time': event.endTime?.toUtc().toIso8601String(),
      'all_day': event.isAllDay,
      'location': event.location,
      'color': event.colorHex,
      'is_recurring': event.isRecurring,
      'recurrence_rule': event.recurrenceRule,
      'ai_generated': event.aiGenerated,
      'created_at': event.createdAt.toUtc().toIso8601String(),
      'updated_at': event.updatedAt.toUtc().toIso8601String(),
    });
  }

  @override
  Future<void> deleteCalendarEvent(String id) async {
    await _client
        .from('calendar_events')
        .delete()
        .eq('id', id)
        .eq('user_id', profileId);
  }

  @override
  Future<List<NimmyCalendarEvent>> listCalendarEventsForRange(
    DateTime start,
    DateTime end,
  ) async {
    final rows = await _client
        .from('calendar_events')
        .select()
        .eq('user_id', profileId)
        .gte('start_time', start.toUtc().toIso8601String())
        .lte('start_time', end.toUtc().toIso8601String())
        .order('start_time');
    return rows.map<NimmyCalendarEvent>(_eventFromRow).toList();
  }

  // Reminders
  @override
  Future<List<NimmyReminder>> listReminders() async {
    final rows = await _client
        .from('reminders')
        .select()
        .eq('user_id', profileId)
        .order('remind_at');
    return rows.map<NimmyReminder>(_reminderFromRow).toList();
  }

  @override
  Future<NimmyReminder?> findReminderByRequestId(String requestId) async {
    final row = await _client
        .from('reminders')
        .select()
        .eq('user_id', profileId)
        .eq('request_id', requestId)
        .maybeSingle();
    return row == null ? null : _reminderFromRow(row);
  }

  @override
  Future<void> saveReminder(NimmyReminder reminder) async {
    await _client.from('reminders').upsert({
      'id': reminder.id,
      'user_id': profileId,
      'request_id': reminder.requestId,
      'title': reminder.title,
      'message': reminder.notes,
      'remind_at': reminder.scheduledAt.toUtc().toIso8601String(),
      'timezone': reminder.timezone,
      'status': _reminderStatusToDatabase(reminder.status),
      'is_recurring': reminder.recurrence != null,
      'recurrence_rule': reminder.recurrence,
      'source': reminder.source.name,
      'notification_scheduled': reminder.notificationScheduled,
      'created_at': reminder.createdAt.toUtc().toIso8601String(),
      'updated_at': reminder.updatedAt.toUtc().toIso8601String(),
    });
  }

  @override
  Future<void> deleteReminder(String id) async {
    await _client
        .from('reminders')
        .delete()
        .eq('id', id)
        .eq('user_id', profileId);
  }

  // Memories
  @override
  Future<List<NimmyMemory>> listMemories({String query = ''}) async {
    var builder = _client
        .from('memories')
        .select()
        .eq('user_id', profileId);
    if (query.trim().isNotEmpty) {
      builder = builder.ilike('content', '%${query.trim()}%');
    }
    final rows = await builder.order('updated_at', ascending: false);
    return rows.map<NimmyMemory>(_memoryFromRow).toList();
  }

  @override
  Future<NimmyMemory?> findMemoryByRequestId(String requestId) async {
    final row = await _client
        .from('memories')
        .select()
        .eq('user_id', profileId)
        .eq('request_id', requestId)
        .maybeSingle();
    return row == null ? null : _memoryFromRow(row);
  }

  @override
  Future<void> saveMemory(NimmyMemory memory) async {
    await _client.from('memories').upsert({
      'id': memory.id,
      'user_id': profileId,
      'request_id': memory.requestId,
      'content': memory.content,
      'memory_type': _memoryCategoryToDatabase(memory.category),
      'importance': _importanceToDatabase(memory.importance),
      'source': memory.source.name,
      'source_reference': memory.sourceReference,
      'created_at': memory.createdAt.toUtc().toIso8601String(),
      'updated_at': memory.updatedAt.toUtc().toIso8601String(),
    });
  }

  @override
  Future<void> deleteMemory(String id) async {
    await _client
        .from('memories')
        .delete()
        .eq('id', id)
        .eq('user_id', profileId);
  }

  // Tasks
  @override
  Future<List<NimmyTask>> listTasks({String? projectId, TaskStatus? status}) async {
    var builder = _client
        .from('tasks')
        .select()
        .eq('user_id', profileId);
    if (projectId != null) {
      builder = builder.eq('project_id', projectId);
    }
    if (status != null) {
      builder = builder.eq('status', status.toDbString());
    }
    final rows = await builder.order('created_at', ascending: false);
    return rows.map<NimmyTask>(_taskFromRow).toList();
  }

  @override
  Future<NimmyTask?> findTaskById(String id) async {
    final row = await _client
        .from('tasks')
        .select()
        .eq('id', id)
        .eq('user_id', profileId)
        .maybeSingle();
    return row == null ? null : _taskFromRow(row);
  }

  @override
  Future<NimmyTask?> findTaskByRequestId(String requestId) async {
    final row = await _client
        .from('tasks')
        .select()
        .eq('user_id', profileId)
        .eq('request_id', requestId)
        .maybeSingle();
    return row == null ? null : _taskFromRow(row);
  }

  @override
  Future<void> saveTask(NimmyTask task) async {
    await _client.from('tasks').upsert({
      'id': task.id,
      'user_id': profileId,
      'request_id': task.requestId,
      'project_id': task.projectId,
      'title': task.title,
      'description': task.description,
      'priority': task.priority.name,
      'status': task.status.toDbString(),
      'due_date': task.dueDate?.toUtc().toIso8601String(),
      'completed_at': task.completedAt?.toUtc().toIso8601String(),
      'tags': task.tags,
      'is_recurring': task.isRecurring,
      'recurrence_rule': task.recurrenceRule,
      'parent_task_id': task.parentTaskId,
      'sort_order': task.sortOrder,
      'ai_generated': task.aiGenerated,
      'created_at': task.createdAt.toUtc().toIso8601String(),
      'updated_at': task.updatedAt.toUtc().toIso8601String(),
    });
  }

  @override
  Future<void> deleteTask(String id) async {
    await _client
        .from('tasks')
        .delete()
        .eq('id', id)
        .eq('user_id', profileId);
  }

  // Projects
  @override
  Future<List<NimmyProject>> listProjects() async {
    final rows = await _client
        .from('projects')
        .select()
        .eq('user_id', profileId)
        .order('sort_order');
    return rows.map<NimmyProject>(_projectFromRow).toList();
  }

  @override
  Future<NimmyProject?> findProjectById(String id) async {
    final row = await _client
        .from('projects')
        .select()
        .eq('id', id)
        .eq('user_id', profileId)
        .maybeSingle();
    return row == null ? null : _projectFromRow(row);
  }

  @override
  Future<void> saveProject(NimmyProject project) async {
    await _client.from('projects').upsert({
      'id': project.id,
      'user_id': profileId,
      'title': project.title,
      'description': project.description,
      'color': project.color,
      'icon': project.icon,
      'is_archived': project.isArchived,
      'sort_order': project.sortOrder,
      'created_at': project.createdAt.toUtc().toIso8601String(),
      'updated_at': project.updatedAt.toUtc().toIso8601String(),
    });
  }

  @override
  Future<void> deleteProject(String id) async {
    await _client
        .from('projects')
        .delete()
        .eq('id', id)
        .eq('user_id', profileId);
  }

  // Goals (synced via user-scoped storage)
  @override
  Future<List<NimmyGoal>> listGoals() async => const [];

  @override
  Future<void> saveGoal(NimmyGoal goal) async {}

  @override
  Future<void> deleteGoal(String id) async {}

  // Habits (synced via user-scoped storage)
  @override
  Future<List<NimmyHabit>> listHabits() async => const [];

  @override
  Future<void> saveHabit(NimmyHabit habit) async {}

  @override
  Future<void> deleteHabit(String id) async {}

  // Audit
  @override
  Future<List<AuditEvent>> listAuditEvents({int limit = 100}) async {
    final rows = await _client
        .from('audit_logs')
        .select()
        .eq('user_id', profileId)
        .order('created_at', ascending: false)
        .limit(limit);
    return rows.map<AuditEvent>(_auditFromRow).toList();
  }

  @override
  Future<void> appendAuditEvent(AuditEvent event) async {
    await _client.from('audit_logs').insert({
      'id': event.id,
      'user_id': profileId,
      'action_type': event.actionType,
      'tool_name': event.toolName,
      'request_id': event.requestId,
      'source': event.source.name,
      'status': event.status.name,
      'metadata': event.metadata,
      'error_code': event.errorCode,
      'created_at': event.createdAt.toUtc().toIso8601String(),
      'executed_at': event.executedAt?.toUtc().toIso8601String(),
    });
  }

  NimmyReminder _reminderFromRow(Map<String, dynamic> row) {
    final now = DateTime.now().toUtc();
    return NimmyReminder(
      id: row['id'] as String,
      userId: row['user_id'] as String,
      requestId: row['request_id'] as String,
      title: row['title'] as String,
      scheduledAt: _parseDate(row['remind_at'], now),
      timezone: row['timezone'] as String? ?? 'UTC',
      recurrence: row['recurrence_rule'] as String?,
      notes: row['message'] as String?,
      source: InteractionSource.values.byName(
        row['source'] as String? ?? 'text',
      ),
      status: _reminderStatusFromDatabase(row['status'] as String),
      createdAt: _parseDate(row['created_at'], now),
      updatedAt: _parseDate(row['updated_at'], now),
      notificationScheduled: row['notification_scheduled'] as bool? ?? false,
    );
  }

  NimmyMemory _memoryFromRow(Map<String, dynamic> row) {
    final now = DateTime.now().toUtc();
    return NimmyMemory(
      id: row['id'] as String,
      userId: row['user_id'] as String,
      requestId: row['request_id'] as String,
      content: row['content'] as String,
      category: _memoryCategoryFromDatabase(row['memory_type'] as String),
      importance: _importanceFromDatabase(row['importance'] as int? ?? 5),
      source: InteractionSource.values.byName(
        row['source'] as String? ?? 'text',
      ),
      sourceReference: row['source_reference'] as String?,
      createdAt: _parseDate(row['created_at'], now),
      updatedAt: _parseDate(row['updated_at'], now),
    );
  }

  NimmyTask _taskFromRow(Map<String, dynamic> row) {
    final now = DateTime.now().toUtc();
    return NimmyTask(
      id: row['id'] as String,
      userId: row['user_id'] as String,
      requestId: row['request_id'] as String?,
      projectId: row['project_id'] as String?,
      title: row['title'] as String,
      description: row['description'] as String?,
      priority: TaskPriority.fromString(row['priority'] as String?),
      status: TaskStatus.fromString(row['status'] as String?),
      dueDate: row['due_date'] != null
          ? DateTime.parse(row['due_date'] as String)
          : null,
      completedAt: row['completed_at'] != null
          ? DateTime.parse(row['completed_at'] as String)
          : null,
      tags: row['tags'] != null
          ? List<String>.from(row['tags'] as List)
          : const [],
      isRecurring: row['is_recurring'] as bool? ?? false,
      recurrenceRule: row['recurrence_rule'] as String?,
      parentTaskId: row['parent_task_id'] as String?,
      sortOrder: (row['sort_order'] as num?)?.toInt() ?? 0,
      aiGenerated: row['ai_generated'] as bool? ?? false,
      createdAt: _parseDate(row['created_at'], now),
      updatedAt: _parseDate(row['updated_at'], now),
    );
  }

  NimmyProject _projectFromRow(Map<String, dynamic> row) {
    final now = DateTime.now().toUtc();
    return NimmyProject(
      id: row['id'] as String,
      userId: row['user_id'] as String,
      title: row['title'] as String,
      description: row['description'] as String?,
      color: row['color'] as String? ?? '#A855F7',
      icon: row['icon'] as String?,
      isArchived: row['is_archived'] as bool? ?? false,
      sortOrder: (row['sort_order'] as num?)?.toInt() ?? 0,
      createdAt: _parseDate(row['created_at'], now),
      updatedAt: _parseDate(row['updated_at'], now),
    );
  }

  AuditEvent _auditFromRow(Map<String, dynamic> row) {
    return AuditEvent(
      id: row['id'] as String,
      userId: row['user_id'] as String,
      actionType: row['action_type'] as String,
      toolName: row['tool_name'] as String,
      requestId: row['request_id'] as String,
      source: InteractionSource.values.byName(row['source'] as String),
      status: AuditStatus.values.byName(row['status'] as String),
      createdAt: DateTime.parse(row['created_at'] as String),
      executedAt: row['executed_at'] == null
          ? null
          : DateTime.parse(row['executed_at'] as String),
      metadata: Map<String, dynamic>.from(
        row['metadata'] as Map? ?? const <String, dynamic>{},
      ),
      errorCode: row['error_code'] as String?,
    );
  }

  DateTime _parseDate(dynamic value, DateTime fallback) {
    return value is String ? DateTime.parse(value) : fallback;
  }

  String _reminderStatusToDatabase(ReminderStatus status) {
    return switch (status) {
      ReminderStatus.pending => 'pending',
      ReminderStatus.triggered => 'triggered',
      ReminderStatus.completed || ReminderStatus.cancelled => 'dismissed',
    };
  }

  ReminderStatus _reminderStatusFromDatabase(String status) {
    return switch (status) {
      'triggered' => ReminderStatus.triggered,
      'dismissed' => ReminderStatus.completed,
      _ => ReminderStatus.pending,
    };
  }

  String _memoryCategoryToDatabase(MemoryCategory category) {
    return category == MemoryCategory.reminderContext
        ? 'reminder_context'
        : category.name;
  }

  MemoryCategory _memoryCategoryFromDatabase(String value) {
    if (value == 'reminder_context') return MemoryCategory.reminderContext;
    return MemoryCategory.values.firstWhere(
      (category) => category.name == value,
      orElse: () => MemoryCategory.other,
    );
  }

  int _importanceToDatabase(MemoryImportance value) {
    return switch (value) {
      MemoryImportance.low => 3,
      MemoryImportance.normal => 5,
      MemoryImportance.high => 9,
    };
  }

  MemoryImportance _importanceFromDatabase(int value) {
    if (value >= 8) return MemoryImportance.high;
    if (value <= 3) return MemoryImportance.low;
    return MemoryImportance.normal;
  }

  NimmyCalendarEvent _eventFromRow(Map<String, dynamic> row) {
    return NimmyCalendarEvent(
      id: row['id'] as String,
      userId: row['user_id'] as String,
      taskId: row['task_id'] as String?,
      title: row['title'] as String,
      description: row['description'] as String?,
      eventType: _eventTypeFromDatabase(row['event_type'] as String? ?? 'personal'),
      startTime: DateTime.parse(row['start_time'] as String),
      endTime: row['end_time'] != null ? DateTime.parse(row['end_time'] as String) : null,
      isAllDay: row['all_day'] as bool? ?? false,
      location: row['location'] as String?,
      colorHex: row['color'] as String?,
      isRecurring: row['is_recurring'] as bool? ?? false,
      recurrenceRule: row['recurrence_rule'] as String?,
      aiGenerated: row['ai_generated'] as bool? ?? false,
      createdAt: DateTime.parse(row['created_at'] as String),
      updatedAt: DateTime.parse(row['updated_at'] as String),
    );
  }

  String _eventTypeToDatabase(EventType type) {
    return switch (type) {
      EventType.meeting => 'meeting',
      EventType.reminder => 'reminder',
      EventType.deadline => 'deadline',
      EventType.personal => 'personal',
      EventType.aiScheduled => 'ai_scheduled',
    };
  }

  EventType _eventTypeFromDatabase(String type) {
    return switch (type) {
      'meeting' => EventType.meeting,
      'reminder' => EventType.reminder,
      'deadline' => EventType.deadline,
      'ai_scheduled' => EventType.aiScheduled,
      _ => EventType.personal,
    };
  }
}
