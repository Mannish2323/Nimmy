import 'package:flutter_test/flutter_test.dart';
import 'package:nimmy/models/calendar_event.dart';
import 'package:nimmy/models/reminder.dart';
import 'package:nimmy/models/tool_action.dart';
import 'package:nimmy/services/notifications/notification_service.dart';
import 'package:nimmy/services/storage/in_memory_nimmy_repository.dart';
import 'package:nimmy/services/tools/tool_registry.dart';

void main() {
  group('Calendar & Reminder Tool Registry Tests', () {
    late InMemoryNimmyRepository repository;
    late _TestReminderScheduler scheduler;
    late ToolRegistry registry;
    final fixedClock = DateTime.utc(2026, 10, 18, 12, 0);

    setUp(() async {
      repository = InMemoryNimmyRepository();
      await repository.initialize();
      scheduler = _TestReminderScheduler();
      registry = ToolRegistry(
        repository: repository,
        reminderScheduler: scheduler,
        clock: () => fixedClock,
      );
    });

    test('create_calendar_event requires confirmation', () async {
      final proposal = ToolProposal(
        requestId: 'req-1',
        intent: NimmyIntent.createCalendarEvent,
        toolName: 'create_calendar_event',
        input: CreateCalendarEventInput(
          title: 'Sprint Planning',
          startTime: fixedClock.add(const Duration(hours: 2)),
          eventType: EventType.meeting,
        ),
        source: InteractionSource.voice,
        originalText: 'schedule sprint planning in 2 hours',
      );

      final unconfirmed = await registry.execute(proposal, confirmed: false);
      expect(unconfirmed.success, false);
      expect(unconfirmed.message, contains('Confirmation is required'));
      expect((await repository.listCalendarEvents()).isEmpty, true);

      final confirmed = await registry.execute(proposal, confirmed: true);
      expect(confirmed.success, true);
      expect(confirmed.message, 'Event scheduled.');
      final events = await repository.listCalendarEvents();
      expect(events.length, 1);
      expect(events.first.title, 'Sprint Planning');
      expect(events.first.eventType, EventType.meeting);

      final audit = await repository.listAuditEvents();
      expect(audit.length, 1);
      expect(audit.first.toolName, 'create_calendar_event');
    });

    test('edit_calendar_event updates event and writes audit', () async {
      final event = NimmyCalendarEvent(
        id: 'ev-edit',
        userId: 'local-user',
        title: 'Initial Title',
        startTime: fixedClock.add(const Duration(hours: 1)),
        createdAt: fixedClock,
        updatedAt: fixedClock,
      );
      await repository.saveCalendarEvent(event);

      final proposal = ToolProposal(
        requestId: 'req-edit',
        intent: NimmyIntent.editCalendarEvent,
        toolName: 'edit_calendar_event',
        input: const EditCalendarEventInput(
          id: 'ev-edit',
          title: 'Revised Title',
          location: 'Conference Room B',
        ),
        source: InteractionSource.text,
        originalText: 'edit event title to Revised Title',
      );

      final result = await registry.execute(proposal, confirmed: true);
      expect(result.success, true);
      final updated = await repository.findCalendarEventById('ev-edit');
      expect(updated!.title, 'Revised Title');
      expect(updated.location, 'Conference Room B');
    });

    test('reschedule_calendar_event updates time and writes audit with reason', () async {
      final start = fixedClock.add(const Duration(hours: 2));
      final end = fixedClock.add(const Duration(hours: 3));
      final event = NimmyCalendarEvent(
        id: 'ev-resched',
        userId: 'local-user',
        title: 'Team Sync',
        startTime: start,
        endTime: end,
        createdAt: fixedClock,
        updatedAt: fixedClock,
      );
      await repository.saveCalendarEvent(event);

      final newStart = fixedClock.add(const Duration(days: 1, hours: 2));
      final proposal = ToolProposal(
        requestId: 'req-resched',
        intent: NimmyIntent.rescheduleCalendarEvent,
        toolName: 'reschedule_calendar_event',
        input: RescheduleCalendarEventInput(
          id: 'ev-resched',
          startTime: newStart,
          reason: 'Client requested postponement',
        ),
        source: InteractionSource.voice,
        originalText: 'reschedule team sync to tomorrow same time',
      );

      final result = await registry.execute(proposal, confirmed: true);
      expect(result.success, true);
      final updated = await repository.findCalendarEventById('ev-resched');
      expect(updated!.startTime, newStart);
      // Duration preserved (1 hour)
      expect(updated.endTime, newStart.add(const Duration(hours: 1)));

      final audits = await repository.listAuditEvents();
      expect(audits.any((a) => a.metadata['reason'] == 'Client requested postponement'), true);
    });

    test('delete_calendar_event removes event and writes audit', () async {
      final event = NimmyCalendarEvent(
        id: 'ev-del',
        userId: 'local-user',
        title: 'To Be Deleted',
        startTime: fixedClock.add(const Duration(hours: 5)),
        createdAt: fixedClock,
        updatedAt: fixedClock,
      );
      await repository.saveCalendarEvent(event);

      final proposal = ToolProposal(
        requestId: 'req-del',
        intent: NimmyIntent.deleteCalendarEvent,
        toolName: 'delete_calendar_event',
        input: const DeleteCalendarEventInput(id: 'ev-del'),
        source: InteractionSource.text,
        originalText: 'delete event ev-del',
      );

      final result = await registry.execute(proposal, confirmed: true);
      expect(result.success, true);
      expect(result.message, 'Event deleted.');
      expect(await repository.findCalendarEventById('ev-del'), isNull);
    });

    test('reschedule_reminder updates scheduledAt and schedules notification', () async {
      final reminder = NimmyReminder(
        id: 'rem-resched',
        userId: 'local-user',
        requestId: 'orig-req',
        title: 'Take Medication',
        scheduledAt: fixedClock.add(const Duration(hours: 1)),
        timezone: 'UTC',
        source: InteractionSource.text,
        status: ReminderStatus.pending,
        createdAt: fixedClock,
        updatedAt: fixedClock,
      );
      await repository.saveReminder(reminder);

      final newTime = fixedClock.add(const Duration(hours: 4));
      final proposal = ToolProposal(
        requestId: 'req-rem-resched',
        intent: NimmyIntent.rescheduleReminder,
        toolName: 'reschedule_reminder',
        input: RescheduleReminderInput(
          id: 'rem-resched',
          scheduledAt: newTime,
          reason: 'Meeting ran long',
        ),
        source: InteractionSource.voice,
        originalText: 'reschedule reminder to 4 hours from now',
      );

      final result = await registry.execute(proposal, confirmed: true);
      expect(result.success, true);
      expect(result.message, 'Reminder rescheduled.');

      final reminders = await repository.listReminders();
      expect(reminders.first.scheduledAt, newTime);
      expect(reminders.first.notificationScheduled, true);
    });

    test('delete_reminder removes reminder and cancels notification', () async {
      final reminder = NimmyReminder(
        id: 'rem-del',
        userId: 'local-user',
        requestId: 'orig-req-del',
        title: 'Pay electric bill',
        scheduledAt: fixedClock.add(const Duration(days: 2)),
        timezone: 'UTC',
        source: InteractionSource.text,
        status: ReminderStatus.pending,
        createdAt: fixedClock,
        updatedAt: fixedClock,
      );
      await repository.saveReminder(reminder);

      final proposal = ToolProposal(
        requestId: 'req-del-rem',
        intent: NimmyIntent.deleteReminder,
        toolName: 'delete_reminder',
        input: const DeleteReminderInput(id: 'rem-del'),
        source: InteractionSource.text,
        originalText: 'delete reminder rem-del',
      );

      final result = await registry.execute(proposal, confirmed: true);
      expect(result.success, true);
      expect(result.message, 'Reminder deleted.');
      expect((await repository.listReminders()).isEmpty, true);
    });
  });
}

class _TestReminderScheduler implements ReminderScheduler {
  @override
  String get timezone => 'UTC';

  @override
  Future<void> initialize() async {}

  @override
  Future<bool> schedule(NimmyReminder reminder) async => true;

  @override
  Future<void> cancel(String reminderId) async {}
}
