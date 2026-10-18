import 'package:flutter_test/flutter_test.dart';
import 'package:nimmy/models/calendar_event.dart';

void main() {
  group('NimmyCalendarEvent Model Tests', () {
    test('serializes to and from JSON correctly', () {
      final now = DateTime.utc(2026, 10, 18, 10, 0);
      final later = DateTime.utc(2026, 10, 18, 11, 0);

      final event = NimmyCalendarEvent(
        id: 'event-1',
        userId: 'user-123',
        taskId: 'task-456',
        title: 'Architecture Review',
        description: 'Review Phase 4 implementation',
        eventType: EventType.meeting,
        startTime: now,
        endTime: later,
        isAllDay: false,
        location: 'Room 301',
        colorHex: '#A970FF',
        isRecurring: true,
        recurrenceRule: 'FREQ=WEEKLY',
        aiGenerated: false,
        createdAt: now,
        updatedAt: now,
      );

      final json = event.toJson();
      expect(json['id'], 'event-1');
      expect(json['title'], 'Architecture Review');
      expect(json['event_type'], 'meeting');
      expect(json['is_all_day'], false);
      expect(json['location'], 'Room 301');

      final restored = NimmyCalendarEvent.fromJson(json);
      expect(restored.id, event.id);
      expect(restored.title, event.title);
      expect(restored.description, event.description);
      expect(restored.eventType, EventType.meeting);
      expect(restored.startTime, event.startTime);
      expect(restored.endTime, event.endTime);
      expect(restored.location, event.location);
    });

    test('handles snake_case and default values in fromJson', () {
      final json = {
        'id': 'event-2',
        'title': 'AI Sync',
        'start_time': '2026-10-18T14:00:00.000Z',
        'event_type': 'ai_scheduled',
        'all_day': true,
        'color': '#54D9FF',
        'created_at': '2026-10-18T10:00:00.000Z',
        'updated_at': '2026-10-18T10:00:00.000Z',
      };

      final event = NimmyCalendarEvent.fromJson(json);
      expect(event.id, 'event-2');
      expect(event.title, 'AI Sync');
      expect(event.eventType, EventType.aiScheduled);
      expect(event.isAllDay, true);
      expect(event.colorHex, '#54D9FF');
      expect(event.userId, 'local_user');
      expect(event.endTime, isNull);
    });

    test('copyWith updates specified fields only', () {
      final now = DateTime.utc(2026, 10, 18, 10, 0);
      final event = NimmyCalendarEvent(
        id: 'event-3',
        userId: 'user-1',
        title: 'Original Title',
        startTime: now,
        createdAt: now,
        updatedAt: now,
      );

      final updated = event.copyWith(
        title: 'Updated Title',
        eventType: EventType.deadline,
        location: 'Virtual',
      );

      expect(updated.id, 'event-3');
      expect(updated.title, 'Updated Title');
      expect(updated.eventType, EventType.deadline);
      expect(updated.location, 'Virtual');
      expect(updated.startTime, now);
    });
  });
}
