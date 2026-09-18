import 'package:uuid/uuid.dart';

import '../../models/audit_event.dart';
import '../../models/memory.dart';
import '../../models/reminder.dart';
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
}
