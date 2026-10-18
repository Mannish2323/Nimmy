import 'package:uuid/uuid.dart';

import '../../models/audit_event.dart';
import '../../models/calendar_event.dart';
import '../../models/memory.dart';
import '../../models/reminder.dart';
import '../../models/task.dart';
import '../../models/tool_action.dart';
import '../ai/intent_parser.dart';
import '../notifications/notification_service.dart';
import '../storage/nimmy_repository.dart';
import 'confirmation_policy.dart';

class ToolRegistry {
  ToolRegistry({
    required NimmyRepository repository,
    required ReminderScheduler reminderScheduler,
    this.userId = 'local-user',
    ConfirmationPolicy confirmationPolicy = const ConfirmationPolicy(),
    Clock? clock,
    Uuid? uuid,
  }) : _repository = repository,
       _reminderScheduler = reminderScheduler,
       _confirmationPolicy = confirmationPolicy,
       _clock = clock ?? DateTime.now,
       _uuid = uuid ?? const Uuid();

  final NimmyRepository _repository;
  final ReminderScheduler _reminderScheduler;
  final ConfirmationPolicy _confirmationPolicy;
  final Clock _clock;
  final Uuid _uuid;
  final String userId;

  bool requiresConfirmation(ToolProposal proposal) {
    return _confirmationPolicy.requiresConfirmation(proposal.toolName);
  }

  Future<void> cancelReminderNotification(String reminderId) {
    return _reminderScheduler.cancel(reminderId);
  }

  Future<void> audit(
    ToolProposal proposal,
    AuditStatus status, {
    Map<String, dynamic> metadata = const {},
    String? errorCode,
  }) {
    final now = _clock().toUtc();
    return _repository.appendAuditEvent(
      AuditEvent(
        id: _uuid.v4(),
        userId: userId,
        actionType: proposal.intent.name,
        toolName: proposal.toolName,
        requestId: proposal.requestId,
        source: proposal.source,
        status: status,
        createdAt: now,
        executedAt: status == AuditStatus.executed ? now : null,
        metadata: metadata,
        errorCode: errorCode,
      ),
    );
  }

  Future<ToolExecutionResult> execute(
    ToolProposal proposal, {
    required bool confirmed,
  }) async {
    if (requiresConfirmation(proposal) && !confirmed) {
      return const ToolExecutionResult(
        success: false,
        message: 'Confirmation is required before I can do that.',
      );
    }

    try {
      return await switch (proposal.input) {
        CreateReminderInput input => _createReminder(proposal, input),
        SaveMemoryInput input => _saveMemory(proposal, input),
        CreateTaskInput input => _createTask(proposal, input),
        EditTaskInput input => _editTask(proposal, input),
        CompleteTaskInput input => _completeTask(proposal, input),
        DeleteTaskInput input => _deleteTask(proposal, input),
        RescheduleTaskInput input => _rescheduleTask(proposal, input),
        CreateCalendarEventInput input => _createCalendarEvent(proposal, input),
        EditCalendarEventInput input => _editCalendarEvent(proposal, input),
        DeleteCalendarEventInput input => _deleteCalendarEvent(proposal, input),
        RescheduleCalendarEventInput input => _rescheduleCalendarEvent(proposal, input),
        RescheduleReminderInput input => _rescheduleReminder(proposal, input),
        DeleteReminderInput input => _deleteReminder(proposal, input),
      };
    } catch (_) {
      try {
        await audit(
          proposal,
          AuditStatus.failed,
          errorCode: 'tool_execution_failed',
        );
      } catch (_) {
        // The caller still receives a truthful failure if audit persistence fails.
      }
      return const ToolExecutionResult(
        success: false,
        message: 'I understood the request, but nothing was changed.',
      );
    }
  }

  Future<ToolExecutionResult> _createReminder(
    ToolProposal proposal,
    CreateReminderInput input,
  ) async {
    if (input.title.trim().isEmpty ||
        !input.scheduledAt.isAfter(_clock().toUtc())) {
      throw const FormatException(
        'Reminder title and future time are required.',
      );
    }

    final duplicate = await _repository.findReminderByRequestId(
      proposal.requestId,
    );
    if (duplicate != null) {
      return ToolExecutionResult(
        success: true,
        message: 'That reminder is already scheduled.',
        recordId: duplicate.id,
        wasDuplicate: true,
      );
    }

    final now = _clock().toUtc();
    var reminder = NimmyReminder(
      id: _uuid.v4(),
      userId: userId,
      requestId: proposal.requestId,
      title: input.title.trim(),
      scheduledAt: input.scheduledAt.toUtc(),
      timezone: input.timezone,
      recurrence: input.recurrence,
      notes: input.notes,
      source: proposal.source,
      status: ReminderStatus.pending,
      createdAt: now,
      updatedAt: now,
    );

    await _repository.saveReminder(reminder);
    String? warning;
    try {
      final scheduled = await _reminderScheduler.schedule(reminder);
      reminder = reminder.copyWith(
        notificationScheduled: scheduled,
        updatedAt: _clock().toUtc(),
      );
      await _repository.saveReminder(reminder);
      if (!scheduled) {
        warning = 'The reminder was saved, but its notification is not active.';
      }
    } catch (_) {
      warning =
          'The reminder was saved, but its notification could not be scheduled.';
    }

    try {
      await audit(
        proposal,
        AuditStatus.executed,
        metadata: {
          'record_id': reminder.id,
          'notification_scheduled': reminder.notificationScheduled,
        },
      );
    } catch (_) {
      await _repository.deleteReminder(reminder.id);
      await _reminderScheduler.cancel(reminder.id);
      rethrow;
    }

    return ToolExecutionResult(
      success: true,
      recordId: reminder.id,
      message: 'Done. Your reminder is scheduled.',
      warning: warning,
    );
  }

  Future<ToolExecutionResult> _saveMemory(
    ToolProposal proposal,
    SaveMemoryInput input,
  ) async {
    if (input.content.trim().isEmpty) {
      throw const FormatException('Memory content is required.');
    }

    final duplicate = await _repository.findMemoryByRequestId(
      proposal.requestId,
    );
    if (duplicate != null) {
      return ToolExecutionResult(
        success: true,
        message: 'That memory is already saved.',
        recordId: duplicate.id,
        wasDuplicate: true,
      );
    }

    final now = _clock().toUtc();
    final memory = NimmyMemory(
      id: _uuid.v4(),
      userId: userId,
      requestId: proposal.requestId,
      content: input.content.trim(),
      category: input.category,
      importance: input.importance,
      source: proposal.source,
      sourceReference: input.sourceReference,
      createdAt: now,
      updatedAt: now,
    );

    await _repository.saveMemory(memory);
    try {
      await audit(
        proposal,
        AuditStatus.executed,
        metadata: {'record_id': memory.id},
      );
    } catch (_) {
      await _repository.deleteMemory(memory.id);
      rethrow;
    }

    return ToolExecutionResult(
      success: true,
      recordId: memory.id,
      message: 'Done. I saved that to your memory.',
    );
  }

  Future<ToolExecutionResult> _createTask(
    ToolProposal proposal,
    CreateTaskInput input,
  ) async {
    if (input.title.trim().isEmpty) {
      throw const FormatException('Task title is required.');
    }

    final duplicate = await _repository.findTaskByRequestId(proposal.requestId);
    if (duplicate != null) {
      return ToolExecutionResult(
        success: true,
        message: 'That task already exists.',
        recordId: duplicate.id,
        wasDuplicate: true,
      );
    }

    final now = _clock().toUtc();
    final task = NimmyTask(
      id: _uuid.v4(),
      userId: userId,
      requestId: proposal.requestId,
      projectId: input.projectId,
      title: input.title.trim(),
      description: input.description?.trim(),
      priority: input.priority,
      status: TaskStatus.todo,
      dueDate: input.dueDate?.toUtc(),
      tags: input.tags,
      isRecurring: input.recurrence != null,
      recurrenceRule: input.recurrence,
      aiGenerated: proposal.source != InteractionSource.text,
      createdAt: now,
      updatedAt: now,
    );

    await _repository.saveTask(task);
    try {
      await audit(
        proposal,
        AuditStatus.executed,
        metadata: {'record_id': task.id, 'priority': task.priority.name},
      );
    } catch (_) {
      await _repository.deleteTask(task.id);
      rethrow;
    }

    return ToolExecutionResult(
      success: true,
      recordId: task.id,
      message: 'Done. Task added to your list.',
    );
  }

  Future<ToolExecutionResult> _editTask(
    ToolProposal proposal,
    EditTaskInput input,
  ) async {
    final existing = await _repository.findTaskById(input.taskId);
    if (existing == null) {
      return const ToolExecutionResult(
        success: false,
        message: 'Task not found.',
      );
    }

    final now = _clock().toUtc();
    final updated = existing.copyWith(
      title: input.title?.trim().isNotEmpty == true ? input.title!.trim() : null,
      priority: input.priority,
      dueDate: input.dueDate?.toUtc(),
      description: input.description?.trim(),
      projectId: input.projectId,
      tags: input.tags,
      updatedAt: now,
    );

    await _repository.saveTask(updated);
    try {
      await audit(
        proposal,
        AuditStatus.executed,
        metadata: {'record_id': updated.id},
      );
    } catch (_) {
      // Restore previous state if audit fails
      await _repository.saveTask(existing);
      rethrow;
    }

    return ToolExecutionResult(
      success: true,
      recordId: updated.id,
      message: 'Task updated.',
    );
  }

  Future<ToolExecutionResult> _completeTask(
    ToolProposal proposal,
    CompleteTaskInput input,
  ) async {
    final existing = await _repository.findTaskById(input.taskId);
    if (existing == null) {
      return const ToolExecutionResult(
        success: false,
        message: 'Task not found.',
      );
    }

    final now = _clock().toUtc();
    final updated = existing.copyWith(
      status: TaskStatus.done,
      completedAt: input.completedAt?.toUtc() ?? now,
      updatedAt: now,
    );

    await _repository.saveTask(updated);
    try {
      await audit(
        proposal,
        AuditStatus.executed,
        metadata: {'record_id': updated.id},
      );
    } catch (_) {
      await _repository.saveTask(existing);
      rethrow;
    }

    return ToolExecutionResult(
      success: true,
      recordId: updated.id,
      message: 'Task marked as completed.',
    );
  }

  Future<ToolExecutionResult> _deleteTask(
    ToolProposal proposal,
    DeleteTaskInput input,
  ) async {
    final existing = await _repository.findTaskById(input.taskId);
    if (existing == null) {
      return const ToolExecutionResult(
        success: false,
        message: 'Task not found.',
      );
    }

    await _repository.deleteTask(input.taskId);
    try {
      await audit(
        proposal,
        AuditStatus.executed,
        metadata: {'record_id': input.taskId},
      );
    } catch (_) {
      await _repository.saveTask(existing);
      rethrow;
    }

    return ToolExecutionResult(
      success: true,
      recordId: input.taskId,
      message: 'Task deleted.',
    );
  }

  Future<ToolExecutionResult> _rescheduleTask(
    ToolProposal proposal,
    RescheduleTaskInput input,
  ) async {
    final existing = await _repository.findTaskById(input.taskId);
    if (existing == null) {
      return const ToolExecutionResult(
        success: false,
        message: 'Task not found.',
      );
    }

    final now = _clock().toUtc();
    final updated = existing.copyWith(
      dueDate: input.newDueDate.toUtc(),
      updatedAt: now,
    );

    await _repository.saveTask(updated);
    try {
      await audit(
        proposal,
        AuditStatus.executed,
        metadata: {
          'record_id': updated.id,
          'new_due_date': input.newDueDate.toUtc().toIso8601String(),
          if (input.reason != null) 'reason': input.reason,
        },
      );
    } catch (_) {
      await _repository.saveTask(existing);
      rethrow;
    }

    return ToolExecutionResult(
      success: true,
      recordId: updated.id,
      message: 'Task rescheduled.',
    );
  }

  Future<ToolExecutionResult> _createCalendarEvent(
    ToolProposal proposal,
    CreateCalendarEventInput input,
  ) async {
    if (input.title.trim().isEmpty) {
      throw const FormatException('Event title is required.');
    }

    final now = _clock().toUtc();
    final event = NimmyCalendarEvent(
      id: _uuid.v4(),
      userId: userId,
      taskId: input.taskId,
      title: input.title.trim(),
      description: input.description?.trim(),
      eventType: input.eventType,
      startTime: input.startTime.toUtc(),
      endTime: input.endTime?.toUtc(),
      isAllDay: input.isAllDay,
      location: input.location?.trim(),
      colorHex: input.colorHex,
      createdAt: now,
      updatedAt: now,
    );

    await _repository.saveCalendarEvent(event);
    try {
      await audit(
        proposal,
        AuditStatus.executed,
        metadata: {
          'record_id': event.id,
          'title': event.title,
          'start_time': event.startTime.toIso8601String(),
        },
      );
    } catch (_) {
      await _repository.deleteCalendarEvent(event.id);
      rethrow;
    }

    return ToolExecutionResult(
      success: true,
      recordId: event.id,
      message: 'Event scheduled.',
    );
  }

  Future<ToolExecutionResult> _editCalendarEvent(
    ToolProposal proposal,
    EditCalendarEventInput input,
  ) async {
    final existing = await _repository.findCalendarEventById(input.id);
    if (existing == null) {
      return const ToolExecutionResult(
        success: false,
        message: 'Event not found.',
      );
    }

    final now = _clock().toUtc();
    final updated = existing.copyWith(
      title: input.title != null && input.title!.trim().isNotEmpty
          ? input.title!.trim()
          : null,
      startTime: input.startTime?.toUtc(),
      endTime: input.endTime?.toUtc(),
      isAllDay: input.isAllDay,
      eventType: input.eventType,
      description: input.description?.trim(),
      location: input.location?.trim(),
      colorHex: input.colorHex,
      updatedAt: now,
    );

    await _repository.saveCalendarEvent(updated);
    try {
      await audit(
        proposal,
        AuditStatus.executed,
        metadata: {'record_id': updated.id},
      );
    } catch (_) {
      await _repository.saveCalendarEvent(existing);
      rethrow;
    }

    return ToolExecutionResult(
      success: true,
      recordId: updated.id,
      message: 'Event updated.',
    );
  }

  Future<ToolExecutionResult> _deleteCalendarEvent(
    ToolProposal proposal,
    DeleteCalendarEventInput input,
  ) async {
    final existing = await _repository.findCalendarEventById(input.id);
    if (existing == null) {
      return const ToolExecutionResult(
        success: false,
        message: 'Event not found.',
      );
    }

    await _repository.deleteCalendarEvent(input.id);
    try {
      await audit(
        proposal,
        AuditStatus.executed,
        metadata: {'record_id': input.id},
      );
    } catch (_) {
      await _repository.saveCalendarEvent(existing);
      rethrow;
    }

    return ToolExecutionResult(
      success: true,
      recordId: input.id,
      message: 'Event deleted.',
    );
  }

  Future<ToolExecutionResult> _rescheduleCalendarEvent(
    ToolProposal proposal,
    RescheduleCalendarEventInput input,
  ) async {
    final existing = await _repository.findCalendarEventById(input.id);
    if (existing == null) {
      return const ToolExecutionResult(
        success: false,
        message: 'Event not found.',
      );
    }

    final now = _clock().toUtc();
    final newStart = input.startTime.toUtc();
    DateTime? newEnd;
    if (input.endTime != null) {
      newEnd = input.endTime!.toUtc();
    } else if (existing.endTime != null) {
      final duration = existing.endTime!.difference(existing.startTime);
      newEnd = newStart.add(duration);
    }

    final updated = existing.copyWith(
      startTime: newStart,
      endTime: newEnd,
      updatedAt: now,
    );

    await _repository.saveCalendarEvent(updated);
    try {
      await audit(
        proposal,
        AuditStatus.executed,
        metadata: {
          'record_id': updated.id,
          'start_time': newStart.toIso8601String(),
          if (newEnd != null) 'end_time': newEnd.toIso8601String(),
          if (input.reason != null) 'reason': input.reason,
        },
      );
    } catch (_) {
      await _repository.saveCalendarEvent(existing);
      rethrow;
    }

    return ToolExecutionResult(
      success: true,
      recordId: updated.id,
      message: 'Event rescheduled.',
    );
  }

  Future<ToolExecutionResult> _rescheduleReminder(
    ToolProposal proposal,
    RescheduleReminderInput input,
  ) async {
    if (!input.scheduledAt.isAfter(_clock().toUtc())) {
      throw const FormatException('Reminder must be scheduled for a future time.');
    }

    final reminders = await _repository.listReminders();
    NimmyReminder? existing;
    for (final r in reminders) {
      if (r.id == input.id) {
        existing = r;
        break;
      }
    }

    if (existing == null) {
      return const ToolExecutionResult(
        success: false,
        message: 'Reminder not found.',
      );
    }

    final now = _clock().toUtc();
    await _reminderScheduler.cancel(existing.id);
    var updated = existing.copyWith(
      scheduledAt: input.scheduledAt.toUtc(),
      updatedAt: now,
    );
    bool scheduled = false;
    try {
      scheduled = await _reminderScheduler.schedule(updated);
    } catch (_) {
      scheduled = false;
    }
    updated = updated.copyWith(notificationScheduled: scheduled);

    await _repository.saveReminder(updated);
    try {
      await audit(
        proposal,
        AuditStatus.executed,
        metadata: {
          'record_id': updated.id,
          'scheduled_at': input.scheduledAt.toUtc().toIso8601String(),
          if (input.reason != null) 'reason': input.reason,
        },
      );
    } catch (_) {
      await _repository.saveReminder(existing);
      rethrow;
    }

    return ToolExecutionResult(
      success: true,
      recordId: updated.id,
      message: 'Reminder rescheduled.',
    );
  }

  Future<ToolExecutionResult> _deleteReminder(
    ToolProposal proposal,
    DeleteReminderInput input,
  ) async {
    final reminders = await _repository.listReminders();
    NimmyReminder? existing;
    for (final r in reminders) {
      if (r.id == input.id) {
        existing = r;
        break;
      }
    }

    if (existing == null) {
      return const ToolExecutionResult(
        success: false,
        message: 'Reminder not found.',
      );
    }

    await _reminderScheduler.cancel(input.id);
    await _repository.deleteReminder(input.id);
    try {
      await audit(
        proposal,
        AuditStatus.executed,
        metadata: {'record_id': input.id},
      );
    } catch (_) {
      await _repository.saveReminder(existing);
      rethrow;
    }

    return ToolExecutionResult(
      success: true,
      recordId: input.id,
      message: 'Reminder deleted.',
    );
  }
}
