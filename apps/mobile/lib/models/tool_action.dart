import 'memory.dart';
import 'reminder.dart';

enum NimmyIntent { createReminder, saveMemory, unknown }

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
