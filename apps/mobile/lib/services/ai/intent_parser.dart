import 'package:uuid/uuid.dart';

import '../../models/memory.dart';
import '../../models/reminder.dart';
import '../../models/tool_action.dart';

typedef Clock = DateTime Function();

class NimmyIntentParser {
  NimmyIntentParser({
    Clock? clock,
    Uuid? uuid,
    this.timezone = 'UTC',
  })  : _clock = clock ?? DateTime.now,
        _uuid = uuid ?? const Uuid();

  final Clock _clock;
  final Uuid _uuid;
  final String timezone;

  IntentParseResult parse(
    String rawText, {
    InteractionSource source = InteractionSource.text,
  }) {
    final original = rawText.trim();
    if (original.isEmpty) {
      return const IntentParseResult.clarification(
        'Tell me what you want me to remember or when I should remind you.',
      );
    }

    final normalized = _stripWakePhrase(original);
    final lower = normalized.toLowerCase();

    if (_looksLikeMemoryIntent(lower)) {
      return _parseMemory(normalized, original, source);
    }
    if (_looksLikeReminderIntent(lower)) {
      return _parseReminder(normalized, original, source);
    }

    return const IntentParseResult.error(
      'This build currently supports reminders and explicit “remember this” requests.',
    );
  }

  bool _looksLikeMemoryIntent(String text) {
    return text.startsWith('remember this') ||
        text.startsWith('remember that') ||
        text.startsWith('save this as');
  }

  bool _looksLikeReminderIntent(String text) {
    return text.contains('remind me') || text.startsWith('every ');
  }

  IntentParseResult _parseMemory(
    String text,
    String original,
    InteractionSource source,
  ) {
    var content = text;
    final patterns = [
      RegExp(r'^remember\s+this\s*:?\s*', caseSensitive: false),
      RegExp(r'^remember\s+that\s+', caseSensitive: false),
      RegExp(
        r'^save\s+this\s+as\s+(?:an?\s+)?(?:important\s+)?note\s*:?\s*',
        caseSensitive: false,
      ),
    ];
    for (final pattern in patterns) {
      content = content.replaceFirst(pattern, '');
    }
    content = _trimTrailingPunctuation(content);

    if (content.isEmpty) {
      return const IntentParseResult.clarification(
        'What would you like me to remember?',
      );
    }

    final lower = content.toLowerCase();
    final category = switch (lower) {
      _ when lower.contains('prefer') => MemoryCategory.preference,
      _ when lower.contains('goal') => MemoryCategory.goal,
      _ when lower.contains('project') => MemoryCategory.project,
      _ when lower.contains('decided') || lower.contains('decision') =>
        MemoryCategory.decision,
      _ => MemoryCategory.note,
    };
    final importance = original.toLowerCase().contains('important')
        ? MemoryImportance.high
        : MemoryImportance.normal;

    return IntentParseResult.proposal(
      ToolProposal(
        requestId: _uuid.v4(),
        intent: NimmyIntent.saveMemory,
        toolName: 'save_memory',
        input: SaveMemoryInput(
          content: content,
          category: category,
          importance: importance,
        ),
        source: source,
        originalText: original,
      ),
    );
  }

  IntentParseResult _parseReminder(
    String text,
    String original,
    InteractionSource source,
  ) {
    var body = text.replaceFirst(
      RegExp(r'^remind\s+me\s+', caseSensitive: false),
      '',
    );
    body = _trimTrailingPunctuation(body);

    final relative = RegExp(
      r'^in\s+(\d+)\s+(minutes?|hours?|days?)\s+to\s+(.+)$',
      caseSensitive: false,
    ).firstMatch(body);
    if (relative != null) {
      final amount = int.parse(relative.group(1)!);
      final unit = relative.group(2)!.toLowerCase();
      final duration = unit.startsWith('minute')
          ? Duration(minutes: amount)
          : unit.startsWith('hour')
              ? Duration(hours: amount)
              : Duration(days: amount);
      return _reminderProposal(
        title: relative.group(3)!,
        scheduledAt: _clock().add(duration),
        original: original,
        source: source,
      );
    }

    final recurring = RegExp(
      r'^every\s+(monday|tuesday|wednesday|thursday|friday|saturday|sunday)\s+(?:at\s+)?(\d{1,2})(?::(\d{2}))?\s*(am|pm)?\s+(?:remind\s+me\s+)?to\s+(.+)$',
      caseSensitive: false,
    ).firstMatch(body);
    if (recurring != null) {
      final parsedTime = _parseTime(
        hourText: recurring.group(2)!,
        minuteText: recurring.group(3),
        meridiem: recurring.group(4),
      );
      if (parsedTime == null) return _ambiguousTime();
      final weekday = _weekdayNumber(recurring.group(1)!);
      final now = _clock();
      var daysAhead = (weekday - now.weekday) % 7;
      var scheduledAt = DateTime(
        now.year,
        now.month,
        now.day + daysAhead,
        parsedTime.$1,
        parsedTime.$2,
      );
      if (!scheduledAt.isAfter(now)) {
        daysAhead += 7;
        scheduledAt = DateTime(
          now.year,
          now.month,
          now.day + daysAhead,
          parsedTime.$1,
          parsedTime.$2,
        );
      }
      return _reminderProposal(
        title: recurring.group(5)!,
        scheduledAt: scheduledAt,
        recurrence: 'weekly:${recurring.group(1)!.toLowerCase()}',
        original: original,
        source: source,
      );
    }

    final absolute = RegExp(
      r'^(today|tomorrow)\s+(?:at\s+)?(\d{1,2})(?::(\d{2}))?\s*(am|pm)?\s+to\s+(.+)$',
      caseSensitive: false,
    ).firstMatch(body);
    if (absolute != null) {
      final parsedTime = _parseTime(
        hourText: absolute.group(2)!,
        minuteText: absolute.group(3),
        meridiem: absolute.group(4),
      );
      if (parsedTime == null) return _ambiguousTime();
      final now = _clock();
      final dayOffset = absolute.group(1)!.toLowerCase() == 'tomorrow' ? 1 : 0;
      final scheduledAt = DateTime(
        now.year,
        now.month,
        now.day + dayOffset,
        parsedTime.$1,
        parsedTime.$2,
      );
      if (!scheduledAt.isAfter(now)) {
        return const IntentParseResult.clarification(
          'That time has already passed. What future time should I use?',
        );
      }
      return _reminderProposal(
        title: absolute.group(5)!,
        scheduledAt: scheduledAt,
        original: original,
        source: source,
      );
    }

    return const IntentParseResult.clarification(
      'I understood the reminder, but I need a clear time such as “tomorrow at 9 AM” or “in 30 minutes.”',
    );
  }

  IntentParseResult _reminderProposal({
    required String title,
    required DateTime scheduledAt,
    required String original,
    required InteractionSource source,
    String? recurrence,
  }) {
    return IntentParseResult.proposal(
      ToolProposal(
        requestId: _uuid.v4(),
        intent: NimmyIntent.createReminder,
        toolName: 'create_reminder',
        input: CreateReminderInput(
          title: _sentenceCase(_trimTrailingPunctuation(title)),
          scheduledAt: scheduledAt.toUtc(),
          timezone: timezone,
          recurrence: recurrence,
        ),
        source: source,
        originalText: original,
      ),
    );
  }

  (int, int)? _parseTime({
    required String hourText,
    String? minuteText,
    String? meridiem,
  }) {
    var hour = int.parse(hourText);
    final minute = minuteText == null ? 0 : int.parse(minuteText);
    if (minute > 59 || hour > 23) return null;
    if (meridiem == null && hour <= 12) return null;
    if (meridiem != null) {
      if (hour < 1 || hour > 12) return null;
      final normalized = meridiem.toLowerCase();
      if (normalized == 'pm' && hour != 12) hour += 12;
      if (normalized == 'am' && hour == 12) hour = 0;
    }
    return (hour, minute);
  }

  IntentParseResult _ambiguousTime() {
    return const IntentParseResult.clarification(
      'I’m not sure whether you mean AM or PM. Which one should I use?',
    );
  }

  int _weekdayNumber(String value) {
    const weekdays = {
      'monday': DateTime.monday,
      'tuesday': DateTime.tuesday,
      'wednesday': DateTime.wednesday,
      'thursday': DateTime.thursday,
      'friday': DateTime.friday,
      'saturday': DateTime.saturday,
      'sunday': DateTime.sunday,
    };
    return weekdays[value.toLowerCase()]!;
  }

  String _stripWakePhrase(String text) {
    return text.replaceFirst(
      RegExp(r'^\s*(?:hey\s+)?nimmy\s*[,,:-]?\s*', caseSensitive: false),
      '',
    );
  }

  String _trimTrailingPunctuation(String value) {
    return value.trim().replaceFirst(RegExp(r'[.!?]+$'), '').trim();
  }

  String _sentenceCase(String value) {
    if (value.isEmpty) return value;
    return '${value[0].toUpperCase()}${value.substring(1)}';
  }
}
