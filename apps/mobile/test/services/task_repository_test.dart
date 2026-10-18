import 'package:flutter_test/flutter_test.dart';
import 'package:nimmy/models/goal.dart';
import 'package:nimmy/models/habit.dart';
import 'package:nimmy/models/project.dart';
import 'package:nimmy/models/task.dart';
import 'package:nimmy/services/storage/in_memory_nimmy_repository.dart';

void main() {
  group('Repository Task, Project, Goal, Habit Tests', () {
    late InMemoryNimmyRepository repository;

    setUp(() async {
      repository = InMemoryNimmyRepository();
      await repository.initialize();
    });

    test('saves, lists, and deletes tasks', () async {
      final now = DateTime.utc(2026, 10, 18, 12, 0);
      final task1 = NimmyTask(
        id: 't-1',
        userId: 'user-1',
        requestId: 'req-1',
        title: 'Task 1',
        status: TaskStatus.todo,
        priority: TaskPriority.high,
        createdAt: now,
        updatedAt: now,
      );
      final task2 = NimmyTask(
        id: 't-2',
        userId: 'user-1',
        requestId: 'req-2',
        title: 'Task 2',
        status: TaskStatus.done,
        priority: TaskPriority.low,
        createdAt: now,
        updatedAt: now,
      );

      await repository.saveTask(task1);
      await repository.saveTask(task2);

      final allTasks = await repository.listTasks();
      expect(allTasks.length, 2);

      // Filter by status
      final todoTasks = await repository.listTasks(status: TaskStatus.todo);
      expect(todoTasks.length, 1);
      expect(todoTasks.first.id, 't-1');

      // Find by ID and request ID
      final found = await repository.findTaskById('t-1');
      expect(found?.title, 'Task 1');
      final foundByReq = await repository.findTaskByRequestId('req-2');
      expect(foundByReq?.id, 't-2');

      // Delete
      await repository.deleteTask('t-1');
      final remaining = await repository.listTasks();
      expect(remaining.length, 1);
      expect(remaining.first.id, 't-2');
    });

    test('manages projects correctly', () async {
      final now = DateTime.utc(2026, 10, 18, 12, 0);
      final proj = NimmyProject(
        id: 'p-1',
        userId: 'user-1',
        title: 'Work Project',
        createdAt: now,
        updatedAt: now,
      );

      await repository.saveProject(proj);
      final list = await repository.listProjects();
      expect(list.length, 1);
      expect(list.first.title, 'Work Project');

      await repository.deleteProject('p-1');
      final empty = await repository.listProjects();
      expect(empty.isEmpty, isTrue);
    });

    test('manages goals and habits correctly', () async {
      final now = DateTime.utc(2026, 10, 18, 12, 0);
      final goal = NimmyGoal(
        id: 'g-1',
        userId: 'user-1',
        title: 'Ship Beta',
        createdAt: now,
        updatedAt: now,
      );
      final habit = NimmyHabit(
        id: 'h-1',
        userId: 'user-1',
        title: 'Morning Run',
        createdAt: now,
        updatedAt: now,
      );

      await repository.saveGoal(goal);
      await repository.saveHabit(habit);

      expect((await repository.listGoals()).length, 1);
      expect((await repository.listHabits()).length, 1);

      await repository.deleteGoal('g-1');
      await repository.deleteHabit('h-1');

      expect((await repository.listGoals()).isEmpty, isTrue);
      expect((await repository.listHabits()).isEmpty, isTrue);
    });
  });
}
