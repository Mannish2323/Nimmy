import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../../models/audit_event.dart';
import '../../models/calendar_event.dart';
import '../../models/goal.dart';
import '../../models/habit.dart';
import '../../models/memory.dart';
import '../../models/nimmy_state.dart';
import '../../models/project.dart';
import '../../models/reminder.dart';
import '../../models/task.dart';
import '../../models/tool_action.dart';
import '../../services/ai/intent_parser.dart';
import '../../services/storage/nimmy_repository.dart';
import '../../services/tools/tool_registry.dart';
import '../logging/nimmy_logger.dart';

class NimmyController extends ChangeNotifier {
  NimmyController({
    required NimmyRepository repository,
    required NimmyIntentParser intentParser,
    required ToolRegistry toolRegistry,
    bool cloudConfigured = false,
    Clock? clock,
    Uuid? uuid,
  }) : _repository = repository,
       _intentParser = intentParser,
       _toolRegistry = toolRegistry,
       _cloudConfigured = cloudConfigured,
       _clock = clock ?? DateTime.now,
       _uuid = uuid ?? const Uuid();

  NimmyRepository _repository;
  final NimmyIntentParser _intentParser;
  ToolRegistry _toolRegistry;
  final Clock _clock;
  final Uuid _uuid;
  bool _cloudConfigured;

  bool get cloudConfigured => _cloudConfigured;

  List<NimmyCalendarEvent> _calendarEvents = const [];
  List<NimmyReminder> _reminders = const [];
  List<NimmyMemory> _memories = const [];
  List<NimmyTask> _tasks = const [];
  List<NimmyProject> _projects = const [];
  List<NimmyGoal> _goals = const [];
  List<NimmyHabit> _habits = const [];
  List<AuditEvent> _auditEvents = const [];
  DateTime _selectedCalendarDate = DateTime.now();

  NimmyOrbState _orbState = NimmyOrbState.idle;
  ToolProposal? _pendingProposal;
  String _assistantMessage =
      'Tell me what you want to remember, schedule, or accomplish.';
  String? _warning;
  bool _isBusy = false;

  List<NimmyCalendarEvent> get calendarEvents =>
      List.unmodifiable(_calendarEvents);
  DateTime get selectedCalendarDate => _selectedCalendarDate;
  void selectCalendarDate(DateTime date) {
    _selectedCalendarDate = date;
    notifyListeners();
  }

  List<NimmyCalendarEvent> get eventsForSelectedDate {
    return _calendarEvents.where((event) {
      final local = event.startTime.toLocal();
      return local.year == _selectedCalendarDate.year &&
          local.month == _selectedCalendarDate.month &&
          local.day == _selectedCalendarDate.day;
    }).toList();
  }

  List<NimmyReminder> get remindersForSelectedDate {
    return _reminders.where((reminder) {
      final local = reminder.scheduledAt.toLocal();
      return local.year == _selectedCalendarDate.year &&
          local.month == _selectedCalendarDate.month &&
          local.day == _selectedCalendarDate.day;
    }).toList();
  }

  List<NimmyTask> get tasksForSelectedDate {
    return _tasks.where((task) {
      if (task.dueDate == null) return false;
      final local = task.dueDate!.toLocal();
      return local.year == _selectedCalendarDate.year &&
          local.month == _selectedCalendarDate.month &&
          local.day == _selectedCalendarDate.day;
    }).toList();
  }

  List<NimmyReminder> get reminders => List.unmodifiable(_reminders);
  List<NimmyMemory> get memories => List.unmodifiable(_memories);
  List<NimmyTask> get tasks => List.unmodifiable(_tasks);
  List<NimmyProject> get projects => List.unmodifiable(_projects);
  List<NimmyGoal> get goals => List.unmodifiable(_goals);
  List<NimmyHabit> get habits => List.unmodifiable(_habits);
  List<AuditEvent> get auditEvents => List.unmodifiable(_auditEvents);

  NimmyOrbState get orbState => _orbState;
  ToolProposal? get pendingProposal => _pendingProposal;
  String get assistantMessage => _assistantMessage;
  String? get warning => _warning;
  bool get isBusy => _isBusy;
  bool get isLocalOnly => !cloudConfigured;

  int get pendingReminderCount => _reminders
      .where(
        (item) =>
            item.status == ReminderStatus.pending &&
            item.scheduledAt.isAfter(_clock().toUtc()),
      )
      .length;

  int get pendingTaskCount => _tasks.where((t) => !t.isCompleted).length;

  NimmyReminder? get nextReminder {
    for (final reminder in _reminders) {
      if (reminder.status == ReminderStatus.pending &&
          reminder.scheduledAt.isAfter(_clock().toUtc())) {
        return reminder;
      }
    }
    return null;
  }

  Future<void> initialize() => refresh();

  Future<void> refresh() async {
    _calendarEvents = await _repository.listCalendarEvents();
    _reminders = await _repository.listReminders();
    _memories = await _repository.listMemories();
    _tasks = await _repository.listTasks();
    _projects = await _repository.listProjects();
    _goals = await _repository.listGoals();
    _habits = await _repository.listHabits();
    _auditEvents = await _repository.listAuditEvents();
    notifyListeners();
  }

  Future<void> updateRepository({
    required NimmyRepository repository,
    required ToolRegistry toolRegistry,
    required bool cloudConfigured,
  }) async {
    _repository = repository;
    _toolRegistry = toolRegistry;
    _cloudConfigured = cloudConfigured;
    await refresh();
  }

  Future<IntentParseResult> submitCommand(
    String text, {
    InteractionSource source = InteractionSource.text,
    Map<String, dynamic> auditMetadata = const {},
  }) async {
    if (_isBusy) {
      return const IntentParseResult.error(
        'Nimmy is already handling another action.',
      );
    }
    _isBusy = true;
    try {
      NimmyLogger.info(
        'Command submitted',
        category: LogCategory.voice,
        context: {'source': source.name, 'characterCount': text.length},
      );
      _warning = null;
      _pendingProposal = null;
      _orbState = NimmyOrbState.understanding;
      _assistantMessage = 'Understanding your request…';
      notifyListeners();

      final result = _intentParser.parse(text, source: source);
      if (!result.hasProposal) {
        NimmyLogger.warn('Intent parsing failed to produce proposal', category: LogCategory.ai, context: {
          'error': result.error,
          'clarification': result.clarification,
        });
        _orbState = NimmyOrbState.error;
        _assistantMessage =
            result.clarification ??
            result.error ??
            'I could not understand that request.';
        notifyListeners();
        return result;
      }

      final proposal = result.proposal!;
      NimmyLogger.info(
        'Proposal created: ${proposal.toolName}',
        category: LogCategory.tool,
        context: {'tool': proposal.toolName},
      );
      try {
        await _toolRegistry.audit(
          proposal,
          AuditStatus.proposed,
          metadata: {...auditMetadata, 'input': proposal.input.toJson()},
        );
        _pendingProposal = proposal;
        _orbState = NimmyOrbState.confirming;
        _assistantMessage = 'Here’s what I understood. Please confirm it.';
        await refresh();
        return result;
      } catch (e, st) {
        NimmyLogger.error('Failed to audit proposal', category: LogCategory.tool, error: e, stackTrace: st);
        _orbState = NimmyOrbState.error;
        _assistantMessage =
            'I understood you, but I could not prepare the action. Nothing was changed.';
        notifyListeners();
        return const IntentParseResult.error(
          'I understood you, but I could not prepare the action. Nothing was changed.',
        );
      }
    } finally {
      _isBusy = false;
    }
  }

  Future<ToolExecutionResult?> confirmPending({
    Map<String, dynamic> auditMetadata = const {},
  }) async {
    final proposal = _pendingProposal;
    if (proposal == null || _isBusy) return null;

    _isBusy = true;
    _orbState = NimmyOrbState.executing;
    _assistantMessage = 'Completing that now…';
    _warning = null;
    notifyListeners();

    NimmyLogger.info('Executing confirmed proposal: ${proposal.toolName}', category: LogCategory.tool);
    try {
      await _toolRegistry.audit(
        proposal,
        AuditStatus.confirmed,
        metadata: auditMetadata,
      );
      final result = await _toolRegistry.execute(proposal, confirmed: true);
      _pendingProposal = null;
      _assistantMessage = result.message;
      _warning = result.warning;
      _orbState = result.success ? NimmyOrbState.success : NimmyOrbState.error;
      NimmyLogger.info(
        'Tool execution finished: success=${result.success}',
        category: LogCategory.tool,
        context: {'tool': proposal.toolName, 'success': result.success, 'message': result.message},
      );
      await refresh();
      return result;
    } catch (e, st) {
      NimmyLogger.error('Tool execution exception', category: LogCategory.tool, error: e, stackTrace: st);
      _pendingProposal = null;
      _orbState = NimmyOrbState.error;
      _assistantMessage =
          'I understood the request, but nothing was changed.';
      notifyListeners();
      return null;
    } finally {
      _isBusy = false;
    }
  }

  Future<void> cancelPending({String? reason}) async {
    final proposal = _pendingProposal;
    if (proposal == null) return;
    try {
      await _toolRegistry.audit(
        proposal,
        AuditStatus.cancelled,
        metadata: {if (reason != null) 'reason': reason},
      );
    } catch (_) {
      // Best-effort audit on user cancellation
    }
    _pendingProposal = null;
    _orbState = NimmyOrbState.idle;
    _assistantMessage = 'Cancelled. Nothing was changed.';
    await refresh();
  }

  // --- Task Operations ---

  Future<void> createTask({
    required String title,
    TaskPriority priority = TaskPriority.medium,
    DateTime? dueDate,
    String? projectId,
    String? description,
    List<String> tags = const [],
  }) async {
    final now = _clock().toUtc();
    final task = NimmyTask(
      id: _uuid.v4(),
      userId: _toolRegistry.userId,
      projectId: projectId,
      title: title.trim(),
      description: description?.trim(),
      priority: priority,
      status: TaskStatus.todo,
      dueDate: dueDate?.toUtc(),
      tags: tags,
      createdAt: now,
      updatedAt: now,
    );
    await _repository.saveTask(task);
    await _appendDirectAudit(
      actionType: 'createTask',
      toolName: 'create_task',
      metadata: {'record_id': task.id, 'title': task.title},
    );
    await refresh();
  }

  Future<void> toggleTaskCompletion(NimmyTask task) async {
    final now = _clock().toUtc();
    final isDone = task.status == TaskStatus.done;
    final updated = task.copyWith(
      status: isDone ? TaskStatus.todo : TaskStatus.done,
      completedAt: isDone ? null : now,
      updatedAt: now,
    );
    await _repository.saveTask(updated);
    await _appendDirectAudit(
      actionType: isDone ? 'uncompleteTask' : 'completeTask',
      toolName: 'complete_task',
      metadata: {'record_id': task.id, 'status': updated.status.name},
    );
    await refresh();
  }

  Future<void> updateTask(NimmyTask task) async {
    final now = _clock().toUtc();
    final updated = task.copyWith(updatedAt: now);
    await _repository.saveTask(updated);
    await _appendDirectAudit(
      actionType: 'editTask',
      toolName: 'edit_task',
      metadata: {'record_id': task.id},
    );
    await refresh();
  }

  Future<void> deleteTask(String id) async {
    await _repository.deleteTask(id);
    await _appendDirectAudit(
      actionType: 'deleteTask',
      toolName: 'delete_task',
      metadata: {'record_id': id},
    );
    await refresh();
  }

  // --- Project Operations ---

  Future<void> createProject({
    required String title,
    String? description,
    String color = '#A855F7',
    String? icon,
  }) async {
    final now = _clock().toUtc();
    final project = NimmyProject(
      id: _uuid.v4(),
      userId: _toolRegistry.userId,
      title: title.trim(),
      description: description?.trim(),
      color: color,
      icon: icon,
      createdAt: now,
      updatedAt: now,
    );
    await _repository.saveProject(project);
    await _appendDirectAudit(
      actionType: 'createProject',
      toolName: 'create_project',
      metadata: {'record_id': project.id, 'title': project.title},
    );
    await refresh();
  }

  Future<void> deleteProject(String id) async {
    await _repository.deleteProject(id);
    await _appendDirectAudit(
      actionType: 'deleteProject',
      toolName: 'delete_project',
      metadata: {'record_id': id},
    );
    await refresh();
  }

  // --- Goal Operations ---

  Future<void> createGoal({
    required String title,
    String? description,
    DateTime? targetDate,
  }) async {
    final now = _clock().toUtc();
    final goal = NimmyGoal(
      id: _uuid.v4(),
      userId: _toolRegistry.userId,
      title: title.trim(),
      description: description?.trim(),
      targetDate: targetDate?.toUtc(),
      createdAt: now,
      updatedAt: now,
    );
    await _repository.saveGoal(goal);
    await _appendDirectAudit(
      actionType: 'createGoal',
      toolName: 'create_goal',
      metadata: {'record_id': goal.id, 'title': goal.title},
    );
    await refresh();
  }

  Future<void> updateGoalProgress(NimmyGoal goal, double progress) async {
    final now = _clock().toUtc();
    final clamped = progress.clamp(0.0, 1.0);
    final updated = goal.copyWith(
      progress: clamped,
      status: clamped >= 1.0 ? 'completed' : 'in_progress',
      updatedAt: now,
    );
    await _repository.saveGoal(updated);
    await _appendDirectAudit(
      actionType: 'updateGoalProgress',
      toolName: 'update_goal',
      metadata: {'record_id': goal.id, 'progress': clamped},
    );
    await refresh();
  }

  Future<void> deleteGoal(String id) async {
    await _repository.deleteGoal(id);
    await _appendDirectAudit(
      actionType: 'deleteGoal',
      toolName: 'delete_goal',
      metadata: {'record_id': id},
    );
    await refresh();
  }

  // --- Habit Operations ---

  Future<void> createHabit({
    required String title,
    String frequency = 'daily',
  }) async {
    final now = _clock().toUtc();
    final habit = NimmyHabit(
      id: _uuid.v4(),
      userId: _toolRegistry.userId,
      title: title.trim(),
      frequency: frequency,
      createdAt: now,
      updatedAt: now,
    );
    await _repository.saveHabit(habit);
    await _appendDirectAudit(
      actionType: 'createHabit',
      toolName: 'create_habit',
      metadata: {'record_id': habit.id, 'title': habit.title},
    );
    await refresh();
  }

  Future<void> toggleHabitToday(NimmyHabit habit) async {
    final now = _clock().toUtc();
    final isDone = habit.isCompletedToday;
    final newStreak = isDone ? (habit.streakCount > 0 ? habit.streakCount - 1 : 0) : habit.streakCount + 1;
    final best = newStreak > habit.bestStreak ? newStreak : habit.bestStreak;
    final updated = habit.copyWith(
      lastCompletedAt: isDone ? null : now,
      streakCount: newStreak,
      bestStreak: best,
      updatedAt: now,
    );
    await _repository.saveHabit(updated);
    await _appendDirectAudit(
      actionType: isDone ? 'uncompleteHabit' : 'completeHabit',
      toolName: 'complete_habit',
      metadata: {'record_id': habit.id, 'streak': newStreak},
    );
    await refresh();
  }

  Future<void> deleteHabit(String id) async {
    await _repository.deleteHabit(id);
    await _appendDirectAudit(
      actionType: 'deleteHabit',
      toolName: 'delete_habit',
      metadata: {'record_id': id},
    );
    await refresh();
  }

  // --- Memory & Reminder Operations ---

  Future<void> editMemory(NimmyMemory memory, String newContent) async {
    final updated = memory.copyWith(
      content: newContent.trim(),
      updatedAt: _clock().toUtc(),
    );
    await _repository.saveMemory(updated);
    await _appendDirectAudit(
      actionType: 'editMemory',
      toolName: 'edit_memory',
      metadata: {'record_id': memory.id},
    );
    await refresh();
  }

  Future<void> updateMemory(NimmyMemory memory, String newContent) =>
      editMemory(memory, newContent);

  Future<void> deleteMemory(NimmyMemory memory) async {
    await _repository.deleteMemory(memory.id);
    await _appendDirectAudit(
      actionType: 'deleteMemory',
      toolName: 'delete_memory',
      metadata: {'record_id': memory.id},
    );
    await refresh();
  }

  Future<void> deleteReminder(NimmyReminder reminder) async {
    await _toolRegistry.cancelReminderNotification(reminder.id);
    await _repository.deleteReminder(reminder.id);
    await _appendDirectAudit(
      actionType: 'deleteReminder',
      toolName: 'delete_reminder',
      metadata: {'record_id': reminder.id},
    );
    await refresh();
  }

  Future<void> rescheduleReminder(
    NimmyReminder reminder,
    DateTime newScheduledAt, {
    String? reason,
  }) async {
    final now = _clock().toUtc();
    await _toolRegistry.cancelReminderNotification(reminder.id);
    final updated = reminder.copyWith(
      scheduledAt: newScheduledAt.toUtc(),
      updatedAt: now,
    );
    await _repository.saveReminder(updated);
    await _appendDirectAudit(
      actionType: 'rescheduleReminder',
      toolName: 'reschedule_reminder',
      metadata: {
        'record_id': reminder.id,
        'new_scheduled_at': newScheduledAt.toUtc().toIso8601String(),
        if (reason != null) 'reason': reason,
      },
    );
    await refresh();
  }

  // --- Calendar Event Operations ---

  Future<void> createCalendarEvent({
    required String title,
    required DateTime startTime,
    DateTime? endTime,
    bool isAllDay = false,
    EventType eventType = EventType.personal,
    String? description,
    String? location,
    String? colorHex,
    String? taskId,
  }) async {
    final now = _clock().toUtc();
    final event = NimmyCalendarEvent(
      id: _uuid.v4(),
      userId: _toolRegistry.userId,
      taskId: taskId,
      title: title.trim(),
      description: description?.trim(),
      eventType: eventType,
      startTime: startTime.toUtc(),
      endTime: endTime?.toUtc(),
      isAllDay: isAllDay,
      location: location?.trim(),
      colorHex: colorHex,
      createdAt: now,
      updatedAt: now,
    );
    await _repository.saveCalendarEvent(event);
    await _appendDirectAudit(
      actionType: 'createCalendarEvent',
      toolName: 'create_calendar_event',
      metadata: {'record_id': event.id, 'title': event.title},
    );
    await refresh();
  }

  Future<void> updateCalendarEvent(NimmyCalendarEvent event) async {
    final now = _clock().toUtc();
    final updated = event.copyWith(updatedAt: now);
    await _repository.saveCalendarEvent(updated);
    await _appendDirectAudit(
      actionType: 'editCalendarEvent',
      toolName: 'edit_calendar_event',
      metadata: {'record_id': event.id},
    );
    await refresh();
  }

  Future<void> deleteCalendarEvent(String id) async {
    await _repository.deleteCalendarEvent(id);
    await _appendDirectAudit(
      actionType: 'deleteCalendarEvent',
      toolName: 'delete_calendar_event',
      metadata: {'record_id': id},
    );
    await refresh();
  }

  Future<void> rescheduleCalendarEvent(
    String id,
    DateTime newStart, {
    DateTime? newEnd,
    String? reason,
  }) async {
    final existing = await _repository.findCalendarEventById(id);
    if (existing == null) return;
    final now = _clock().toUtc();
    DateTime? finalEnd = newEnd?.toUtc();
    if (finalEnd == null && existing.endTime != null) {
      final duration = existing.endTime!.difference(existing.startTime);
      finalEnd = newStart.toUtc().add(duration);
    }
    final updated = existing.copyWith(
      startTime: newStart.toUtc(),
      endTime: finalEnd,
      updatedAt: now,
    );
    await _repository.saveCalendarEvent(updated);
    await _appendDirectAudit(
      actionType: 'rescheduleCalendarEvent',
      toolName: 'reschedule_calendar_event',
      metadata: {
        'record_id': id,
        'new_start': newStart.toUtc().toIso8601String(),
        if (reason != null) 'reason': reason,
      },
    );
    await refresh();
  }

  void setOrbState(NimmyOrbState value, {String? message}) {
    _orbState = value;
    if (message != null) _assistantMessage = message;
    notifyListeners();
  }

  Future<void> _appendDirectAudit({
    required String actionType,
    required String toolName,
    required Map<String, dynamic> metadata,
  }) {
    final now = _clock().toUtc();
    return _repository.appendAuditEvent(
      AuditEvent(
        id: _uuid.v4(),
        userId: _toolRegistry.userId,
        actionType: actionType,
        toolName: toolName,
        requestId: _uuid.v4(),
        source: InteractionSource.text,
        status: AuditStatus.executed,
        createdAt: now,
        executedAt: now,
        metadata: metadata,
      ),
    );
  }
}
