import 'package:flutter_test/flutter_test.dart';
import 'package:nimmy/models/calendar_event.dart';
import 'package:nimmy/services/storage/in_memory_nimmy_repository.dart';

void main() {
  group('Repository Calendar Event Tests', () {
    late InMemoryNimmyRepository repository;

    setUp(() async {
      repository = InMemoryNimmyRepository();
      await repository.initialize();
    });

    test('saves, lists, and retrieves calendar events', () async {
      final now = DateTime.utc(2026, 10, 18, 14, 0);
      final event = NimmyCalendarEvent(
        id: 'event-1',
        userId: 'user-1',
        title: 'Team Standup',
        startTime: now,
        endTime: now.add(const Duration(minutes: 30)),
        createdAt: now,
        updatedAt: now,
      );

      await repository.saveCalendarEvent(event);

      final events = await repository.listCalendarEvents();
      expect(events.length, 1);
      expect(events.first.title, 'Team Standup');

      final fetched = await repository.findCalendarEventById('event-1');
      expect(fetched, isNotNull);
      expect(fetched!.title, 'Team Standup');
    });

    test('deletes calendar events cleanly', () async {
      final now = DateTime.utc(2026, 10, 18, 15, 0);
      final event = NimmyCalendarEvent(
        id: 'event-2',
        userId: 'user-1',
        title: '1-on-1 with Mentor',
        startTime: now,
        createdAt: now,
        updatedAt: now,
      );

      await repository.saveCalendarEvent(event);
      expect((await repository.listCalendarEvents()).length, 1);

      await repository.deleteCalendarEvent('event-2');
      expect((await repository.listCalendarEvents()).isEmpty, true);
      expect(await repository.findCalendarEventById('event-2'), isNull);
    });

    test('filters events by date range correctly', () async {
      final base = DateTime.utc(2026, 10, 18, 10, 0);

      final eventToday = NimmyCalendarEvent(
        id: 'e-today',
        userId: 'user-1',
        title: 'Today Event',
        startTime: base,
        endTime: base.add(const Duration(hours: 1)),
        createdAt: base,
        updatedAt: base,
      );

      final eventTomorrow = NimmyCalendarEvent(
        id: 'e-tomorrow',
        userId: 'user-1',
        title: 'Tomorrow Event',
        startTime: base.add(const Duration(days: 1)),
        createdAt: base,
        updatedAt: base,
      );

      final eventNextWeek = NimmyCalendarEvent(
        id: 'e-next-week',
        userId: 'user-1',
        title: 'Next Week Event',
        startTime: base.add(const Duration(days: 7)),
        createdAt: base,
        updatedAt: base,
      );

      await repository.saveCalendarEvent(eventToday);
      await repository.saveCalendarEvent(eventTomorrow);
      await repository.saveCalendarEvent(eventNextWeek);

      final rangeResults = await repository.listCalendarEventsForRange(
        base.subtract(const Duration(hours: 1)),
        base.add(const Duration(days: 2)),
      );

      expect(rangeResults.length, 2);
      expect(rangeResults.any((e) => e.id == 'e-today'), true);
      expect(rangeResults.any((e) => e.id == 'e-tomorrow'), true);
      expect(rangeResults.any((e) => e.id == 'e-next-week'), false);
    });
  });
}
