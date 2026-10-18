import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nimmy/core/state/nimmy_controller.dart';
import 'package:nimmy/core/theme/app_theme.dart';
import 'package:nimmy/features/tasks/tasks_screen.dart';
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

Widget _buildTasksScreen(NimmyController controller) {
  return MaterialApp(
    theme: NimmyTheme.darkTheme,
    home: ChangeNotifierProvider<NimmyController>.value(
      value: controller,
      child: const Scaffold(body: TasksScreen()),
    ),
  );
}

void main() {
  group('TasksScreen Widget Tests', () {
    late InMemoryNimmyRepository repository;
    late NimmyController controller;

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

    testWidgets('renders productivity header and 4 tabs with empty state', (tester) async {
      await tester.pumpWidget(_buildTasksScreen(controller));
      await tester.pumpAndSettle();

      expect(find.text('Productivity'), findsOneWidget);
      expect(find.text('Tasks'), findsOneWidget);
      expect(find.text('Projects (0)'), findsOneWidget);
      expect(find.text('Goals (0)'), findsOneWidget);
      expect(find.text('Habits (0)'), findsOneWidget);

      expect(find.text('No tasks found'), findsOneWidget);
      expect(find.text('Create Task'), findsOneWidget);
    });

    testWidgets('displays tasks, filters, and toggles completion', (tester) async {
      final now = DateTime.now();
      await repository.saveTask(NimmyTask(
        id: 'task-1',
        userId: 'user-1',
        title: 'Complete Phase 3 Audit',
        priority: TaskPriority.urgent,
        status: TaskStatus.todo,
        createdAt: now,
        updatedAt: now,
      ));
      await controller.refresh();

      await tester.pumpWidget(_buildTasksScreen(controller));
      await tester.pumpAndSettle();

      expect(find.text('Complete Phase 3 Audit'), findsOneWidget);
      expect(find.text('URGENT'), findsOneWidget);
      expect(find.byIcon(Icons.circle_outlined), findsOneWidget);

      // Tap completion button
      await tester.tap(find.byIcon(Icons.circle_outlined));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.check_circle_rounded), findsOneWidget);
      expect(controller.tasks.first.isCompleted, isTrue);
    });

    testWidgets('navigates between Projects, Goals, and Habits tabs', (tester) async {
      await tester.pumpWidget(_buildTasksScreen(controller));
      await tester.pumpAndSettle();

      // Tap Projects tab
      await tester.tap(find.text('Projects (0)'));
      await tester.pumpAndSettle();
      expect(find.text('No projects yet'), findsOneWidget);
      expect(find.text('New Project'), findsOneWidget);

      // Tap Goals tab
      await tester.tap(find.text('Goals (0)'));
      await tester.pumpAndSettle();
      expect(find.text('No active goals'), findsOneWidget);
      expect(find.text('New Goal'), findsOneWidget);

      // Tap Habits tab
      await tester.tap(find.text('Habits (0)'));
      await tester.pumpAndSettle();
      expect(find.text('No habits tracked'), findsOneWidget);
      expect(find.text('New Habit'), findsOneWidget);
    });
  });
}
