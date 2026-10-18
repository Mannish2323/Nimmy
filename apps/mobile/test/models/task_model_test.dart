import 'package:flutter_test/flutter_test.dart';
import 'package:nimmy/models/goal.dart';
import 'package:nimmy/models/habit.dart';
import 'package:nimmy/models/project.dart';
import 'package:nimmy/models/task.dart';

void main() {
  group('NimmyTask Model Tests', () {
    test('creates and serializes NimmyTask correctly', () {
      final now = DateTime.utc(2026, 10, 18, 12, 0);
      final task = NimmyTask(
        id: 'task-1',
        userId: 'user-123',
        title: 'Complete Phase 3',
        description: 'Implement productivity models and UI',
        priority: TaskPriority.urgent,
        status: TaskStatus.todo,
        dueDate: now.add(const Duration(days: 1)),
        tags: const ['nimmy', 'phase3'],
        createdAt: now,
        updatedAt: now,
      );

      expect(task.isCompleted, isFalse);
      expect(task.title, 'Complete Phase 3');
      expect(task.priority, TaskPriority.urgent);

      final json = task.toJson();
      expect(json['id'], 'task-1');
      expect(json['priority'], 'urgent');
      expect(json['status'], 'todo');

      final deserialized = NimmyTask.fromJson(json);
      expect(deserialized.id, task.id);
      expect(deserialized.priority, task.priority);
      expect(deserialized.tags, ['nimmy', 'phase3']);
    });

    test('copyWith updates fields correctly', () {
      final now = DateTime.utc(2026, 10, 18, 12, 0);
      final task = NimmyTask(
        id: 'task-1',
        userId: 'user-123',
        title: 'Original Title',
        createdAt: now,
        updatedAt: now,
      );

      final updated = task.copyWith(
        title: 'Updated Title',
        status: TaskStatus.done,
        completedAt: now,
      );

      expect(updated.title, 'Updated Title');
      expect(updated.isCompleted, isTrue);
      expect(updated.id, 'task-1');
    });
  });

  group('NimmyProject Model Tests', () {
    test('serializes and deserializes NimmyProject', () {
      final now = DateTime.utc(2026, 10, 18, 12, 0);
      final project = NimmyProject(
        id: 'proj-1',
        userId: 'user-123',
        title: 'Nimmy OS',
        description: 'Voice-first AI OS',
        color: '#A855F7',
        createdAt: now,
        updatedAt: now,
      );

      final json = project.toJson();
      expect(json['title'], 'Nimmy OS');
      expect(json['color'], '#A855F7');

      final deserialized = NimmyProject.fromJson(json);
      expect(deserialized.id, 'proj-1');
      expect(deserialized.title, 'Nimmy OS');
    });
  });

  group('NimmyGoal & NimmyHabit Model Tests', () {
    test('NimmyGoal computes completion and serializes', () {
      final now = DateTime.utc(2026, 10, 18, 12, 0);
      final goal = NimmyGoal(
        id: 'goal-1',
        userId: 'user-123',
        title: 'Launch Nimmy',
        progress: 1.0,
        createdAt: now,
        updatedAt: now,
      );

      expect(goal.isCompleted, isTrue);
      final json = goal.toJson();
      expect(json['progress'], 1.0);
    });

    test('NimmyHabit tracks streak and today completion', () {
      final now = DateTime.now();
      final habit = NimmyHabit(
        id: 'habit-1',
        userId: 'user-123',
        title: 'Daily Meditation',
        frequency: 'daily',
        streakCount: 5,
        bestStreak: 10,
        lastCompletedAt: now,
        createdAt: now,
        updatedAt: now,
      );

      expect(habit.isCompletedToday, isTrue);
      expect(habit.streakCount, 5);
      final json = habit.toJson();
      expect(json['streak_count'], 5);
    });
  });
}
