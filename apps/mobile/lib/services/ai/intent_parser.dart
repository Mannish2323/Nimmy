import 'package:uuid/uuid.dart';

import '../../models/calendar_event.dart';
import '../../models/memory.dart';
import '../../models/reminder.dart';
import '../../models/task.dart';
import '../../models/tool_action.dart';

typedef Clock = DateTime Function();

class NimmyIntentParser {
  NimmyIntentParser({Clock? clock, Uuid? uuid, this.timezone = 'UTC'})
    : _clock = clock ?? DateTime.now,
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
        'Tell me what you want me to remember, schedule, or add as a task.',
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
    if (_looksLikeCalendarIntent(lower)) {
      return _parseCalendar(normalized, original, source);
    }
    if (_looksLikeTaskIntent(lower)) {
      return _parseTask(normalized, original, source);
    }

    return const IntentParseResult.error(
      'This build currently supports reminders, calendar events, tasks, and explicit “remember this” requests.',
    );
  }

  bool _looksLikeCalendarIntent(String text) {
    return text == 'schedule' ||
        text.startsWith('schedule ') ||
        text.startsWith('schedule a ') ||
        text.startsWith('schedule an ') ||
        text == 'calendar' ||
        text.startsWith('calendar:') ||
        text == 'add event' ||
        text.startsWith('add event') ||
        text == 'new event' ||
        text.startsWith('new event') ||
        text.startsWith('event:');
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

  bool _looksLikeTaskIntent(String text) {
    return text.startsWith('create task') ||
        text.startsWith('create a task') ||
        text.startsWith('add task') ||
        text.startsWith('add a task') ||
        text.startsWith('new task') ||
        text.startsWith('task:') ||
        text.startsWith('todo:') ||
        text.startsWith('to-do:');
  }

  IntentParseResult _parseTask(
    String text,
    String original,
    InteractionSource source,
  ) {
    var content = text;
    final patterns = [
      RegExp(r'^(?:create|add)\s+(?:a\s+)?task(?:\s+to)?\s*:?\s*', caseSensitive: false),
      RegExp(r'^new\s+task\s*:?\s*', caseSensitive: false),
      RegExp(r'^(?:task|todo|to-do)\s*:?\s*', caseSensitive: false),
    ];
    for (final pattern in patterns) {
      content = content.replaceFirst(pattern, '');
    }

    var priority = TaskPriority.medium;
    if (RegExp(r'\b(?:urgent|critical)\b', caseSensitive: false).hasMatch(content)) {
      priority = TaskPriority.urgent;
      content = content.replaceAll(RegExp(r'\b(?:with\s+)?(?:urgent|critical)(?:\s+priority)?\b', caseSensitive: false), '');
    } else if (RegExp(r'\b(?:high\s+priority|important)\b', caseSensitive: false).hasMatch(content)) {
      priority = TaskPriority.high;
      content = content.replaceAll(RegExp(r'\b(?:with\s+)?(?:high\s+priority|important)\b', caseSensitive: false), '');
    } else if (RegExp(r'\b(?:low\s+priority)\b', caseSensitive: false).hasMatch(content)) {
      priority = TaskPriority.low;
      content = content.replaceAll(RegExp(r'\b(?:with\s+)?low\s+priority\b', caseSensitive: false), '');
    }

    DateTime? dueDate;
    final now = _clock();
    if (RegExp(r'\b(?:by|due)\s+tomorrow\b', caseSensitive: false).hasMatch(content)) {
      dueDate = DateTime(now.year, now.month, now.day + 1, 18, 0);
      content = content.replaceAll(RegExp(r'\b(?:by|due)\s+tomorrow\b', caseSensitive: false), '');
    } else if (RegExp(r'\b(?:by|due)\s+today\b', caseSensitive: false).hasMatch(content)) {
      dueDate = DateTime(now.year, now.month, now.day, 18, 0);
      content = content.replaceAll(RegExp(r'\b(?:by|due)\s+today\b', caseSensitive: false), '');
    }

    content = _trimTrailingPunctuation(content).trim();
    if (content.isEmpty) {
      return const IntentParseResult.clarification(
        'What would you like the task to be?',
      );
    }

    return IntentParseResult.proposal(
      ToolProposal(
        requestId: _uuid.v4(),
        intent: NimmyIntent.createTask,
        toolName: 'create_task',
        input: CreateTaskInput(
          title: _sentenceCase(content),
          priority: priority,
          dueDate: dueDate,
          timezone: timezone,
        ),
        source: source,
        originalText: original,
      ),
    );
  }

  IntentParseResult _parseCalendar(
    String text,
    String original,
    InteractionSource source,
  ) {
    var content = text;
    final patterns = [
      RegExp(r'^schedule(?:\s+(?:a\s+|an\s+)?(?:meeting\s+with\s+|event\s+for\s+|event\s*:?\s*)?)?', caseSensitive: false),
      RegExp(r'^add\s+event\s*:?\s*', caseSensitive: false),
      RegExp(r'^new\s+event\s*:?\s*', caseSensitive: false),
      RegExp(r'^(?:calendar|event)\s*:?\s*', caseSensitive: false),
    ];
    for (final pattern in patterns) {
      content = content.replaceFirst(pattern, '');
    }

    var eventType = EventType.personal;
    final lower = text.toLowerCase();
    if (lower.contains('meeting')) {
      eventType = EventType.meeting;
    } else if (lower.contains('deadline')) {
      eventType = EventType.deadline;
    }

    final now = _clock();
    DateTime? startTime;
    final timeMatch = RegExp(
      r'\b(?:on\s+)?(today|tomorrow)\s+at\s+(\d{1,2})(?::(\d{2}))?\s*(am|pm)?\b',
      caseSensitive: false,
    ).firstMatch(content);

    if (timeMatch != null) {
      final parsedTime = _parseTime(
        hourText: timeMatch.group(2)!,
        minuteText: timeMatch.group(3),
        meridiem: timeMatch.group(4),
      );
      if (parsedTime == null) return _ambiguousTime();
      final dayOffset = timeMatch.group(1)!.toLowerCase() == 'tomorrow' ? 1 : 0;
      startTime = DateTime(
        now.year,
        now.month,
        now.day + dayOffset,
        parsedTime.$1,
        parsedTime.$2,
      );
      content = content.replaceRange(timeMatch.start, timeMatch.end, '').trim();
    } else {
      final simpleTimeMatch = RegExp(
        r'\bat\s+(\d{1,2})(?::(\d{2}))?\s*(am|pm)?\b',
        caseSensitive: false,
      ).firstMatch(content);
      if (simpleTimeMatch != null) {
        final parsedTime = _parseTime(
          hourText: simpleTimeMatch.group(1)!,
          minuteText: simpleTimeMatch.group(2),
          meridiem: simpleTimeMatch.group(3),
        );
        if (parsedTime == null) return _ambiguousTime();
        final candidate = DateTime(
          now.year,
          now.month,
          now.day,
          parsedTime.$1,
          parsedTime.$2,
        );
        startTime = candidate.isAfter(now)
            ? candidate
            : DateTime(now.year, now.month, now.day + 1, parsedTime.$1, parsedTime.$2);
        content = content.replaceRange(simpleTimeMatch.start, simpleTimeMatch.end, '').trim();
      }
    }

    content = _trimTrailingPunctuation(content).trim();
    if (content.isEmpty) {
      return const IntentParseResult.clarification(
        'What event would you like me to schedule?',
      );
    }

    startTime ??= DateTime(now.year, now.month, now.day + 1, 9, 0);
    final endTime = startTime.add(const Duration(hours: 1));

    return IntentParseResult.proposal(
      ToolProposal(
        requestId: _uuid.v4(),
        intent: NimmyIntent.createCalendarEvent,
        toolName: 'create_calendar_event',
        input: CreateCalendarEventInput(
          title: _sentenceCase(content),
          startTime: startTime,
          endTime: endTime,
          eventType: eventType,
        ),
        source: source,
        originalText: original,
      ),
    );
  }

  String _sentenceCase(String value) {
    if (value.isEmpty) return value;
    return '${value[0].toUpperCase()}${value.substring(1)}';
  }
}
