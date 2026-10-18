import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nimmy/core/state/nimmy_controller.dart';
import 'package:nimmy/core/theme/app_theme.dart';
import 'package:nimmy/features/calendar/calendar_screen.dart';
import 'package:nimmy/models/calendar_event.dart';
import 'package:nimmy/models/reminder.dart';
import 'package:nimmy/models/task.dart';
import 'package:nimmy/services/ai/intent_parser.dart';
import 'package:nimmy/services/notifications/notification_service.dart';
import 'package:nimmy/services/storage/in_memory_nimmy_repository.dart';
import 'package:nimmy/services/tools/tool_registry.dart';
import 'package:provider/provider.dart';

class _FakeScheduler implements ReminderScheduler {
  @override
  String get timezone => 'UTC';

  @override
  Future<void> initialize() async {}

  @override
  Future<bool> schedule(NimmyReminder reminder) async => true;

  @override
  Future<void> cancel(String reminderId) async {}
}

Widget _buildCalendarScreen(NimmyController controller) {
  return ChangeNotifierProvider<NimmyController>.value(
    value: controller,
    child: MaterialApp(
      theme: NimmyTheme.darkTheme,
      home: const CalendarScreen(),
    ),
  );
}

void main() {
  group('CalendarScreen Widget Tests', () {
    late InMemoryNimmyRepository repository;
    late NimmyController controller;
    final now = DateTime.now();

    setUp(() async {
      repository = InMemoryNimmyRepository();
      await repository.initialize();
      final registry = ToolRegistry(
        repository: repository,
        reminderScheduler: _FakeScheduler(),
      );
      final parser = NimmyIntentParser();
      controller = NimmyController(
        repository: repository,
        intentParser: parser,
        toolRegistry: registry,
      );
      await controller.initialize();
    });

    testWidgets('renders headline, date strip, and empty state when no items', (tester) async {
      await tester.pumpWidget(_buildCalendarScreen(controller));
      await tester.pumpAndSettle();

      expect(find.text('Calendar & Agenda'), findsOneWidget);
      expect(find.text('Agenda'), findsOneWidget);
      expect(find.text('Timeline'), findsOneWidget);
      expect(find.byTooltip('Schedule event'), findsOneWidget);
      expect(find.byTooltip('Today'), findsOneWidget);

      // Empty state
      expect(find.text('No agenda for this date'), findsOneWidget);
    });

    testWidgets('renders events, reminders, and tasks scheduled for today', (tester) async {
      // Add an event for today
      final event = NimmyCalendarEvent(
        id: 'ev-1',
        userId: 'local',
        title: 'Product Sync',
        startTime: DateTime(now.year, now.month, now.day, 14, 0),
        endTime: DateTime(now.year, now.month, now.day, 15, 0),
        eventType: EventType.meeting,
        createdAt: now,
        updatedAt: now,
      );
      await repository.saveCalendarEvent(event);

      // Add a reminder for today
      final reminder = NimmyReminder(
        id: 'rem-1',
        userId: 'local',
        requestId: 'req-rem-1',
        title: 'Review PRs',
        scheduledAt: DateTime(now.year, now.month, now.day, 16, 0),
        timezone: 'UTC',
        source: InteractionSource.text,
        status: ReminderStatus.pending,
        createdAt: now,
        updatedAt: now,
      );
      await repository.saveReminder(reminder);

      // Add a task due today
      final task = NimmyTask(
        id: 'task-1',
        userId: 'local',
        title: 'Finish API integration',
        status: TaskStatus.todo,
        priority: TaskPriority.high,
        dueDate: DateTime(now.year, now.month, now.day, 18, 0),
        createdAt: now,
        updatedAt: now,
      );
      await repository.saveTask(task);

      await controller.refresh();
      await tester.pumpWidget(_buildCalendarScreen(controller));
      await tester.pumpAndSettle();

      expect(find.text('Product Sync'), findsOneWidget);
      expect(find.text('Review PRs'), findsOneWidget);
      expect(find.text('Finish API integration'), findsOneWidget);
      expect(find.text('EVENTS'), findsOneWidget);
      expect(find.text('REMINDERS'), findsOneWidget);
      expect(find.text('TASKS DUE'), findsOneWidget);
      expect(find.text('3 ITEMS'), findsOneWidget);
    });

    testWidgets('opens schedule event bottom sheet on button tap', (tester) async {
      await tester.pumpWidget(_buildCalendarScreen(controller));
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('Schedule event'));
      await tester.pumpAndSettle();

      expect(find.text('Schedule Event'), findsWidgets);
      expect(find.text('Event Title'), findsOneWidget);
      expect(find.text('Description (optional)'), findsOneWidget);
      expect(find.text('Location / Platform (optional)'), findsOneWidget);
    });
  });
}
