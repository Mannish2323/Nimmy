import 'dart:convert';

import 'package:hive_flutter/hive_flutter.dart';

import '../../models/audit_event.dart';
import '../../models/calendar_event.dart';
import '../../models/goal.dart';
import '../../models/habit.dart';
import '../../models/memory.dart';
import '../../models/project.dart';
import '../../models/reminder.dart';
import '../../models/task.dart';
import 'nimmy_repository.dart';

class HiveNimmyRepository implements NimmyRepository {
  static const _calendarEventsBoxName = 'nimmy_calendar_events_v1';
  static const _remindersBoxName = 'nimmy_reminders_v1';
  static const _memoriesBoxName = 'nimmy_memories_v1';
  static const _tasksBoxName = 'nimmy_tasks_v1';
  static const _projectsBoxName = 'nimmy_projects_v1';
  static const _goalsBoxName = 'nimmy_goals_v1';
  static const _habitsBoxName = 'nimmy_habits_v1';
  static const _auditBoxName = 'nimmy_audit_v1';

  late Box<String> _calendarEvents;
  late Box<String> _reminders;
  late Box<String> _memories;
  late Box<String> _tasks;
  late Box<String> _projects;
  late Box<String> _goals;
  late Box<String> _habits;
  late Box<String> _audit;

  @override
  Future<void> initialize() async {
    await Hive.initFlutter();
    _calendarEvents = await Hive.openBox<String>(_calendarEventsBoxName);
    _reminders = await Hive.openBox<String>(_remindersBoxName);
    _memories = await Hive.openBox<String>(_memoriesBoxName);
    _tasks = await Hive.openBox<String>(_tasksBoxName);
    _projects = await Hive.openBox<String>(_projectsBoxName);
    _goals = await Hive.openBox<String>(_goalsBoxName);
    _habits = await Hive.openBox<String>(_habitsBoxName);
    _audit = await Hive.openBox<String>(_auditBoxName);
  }

  // Calendar Events
  @override
  Future<List<NimmyCalendarEvent>> listCalendarEvents() async {
    final events = _calendarEvents.values
        .map(_decode)
        .map(NimmyCalendarEvent.fromJson)
        .toList(growable: false);
    events.sort((a, b) => a.startTime.compareTo(b.startTime));
    return events;
  }

  @override
  Future<NimmyCalendarEvent?> findCalendarEventById(String id) async {
    final raw = _calendarEvents.get(id);
    if (raw == null) return null;
    return NimmyCalendarEvent.fromJson(_decode(raw));
  }

  @override
  Future<void> saveCalendarEvent(NimmyCalendarEvent event) async {
    await _calendarEvents.put(event.id, jsonEncode(event.toJson()));
  }

  @override
  Future<void> deleteCalendarEvent(String id) async {
    await _calendarEvents.delete(id);
  }

  @override
  Future<List<NimmyCalendarEvent>> listCalendarEventsForRange(
    DateTime start,
    DateTime end,
  ) async {
    final events = _calendarEvents.values
        .map(_decode)
        .map(NimmyCalendarEvent.fromJson)
        .where((event) {
          final eventEnd = event.endTime ?? event.startTime;
          return (event.startTime.isBefore(end) || event.startTime.isAtSameMomentAs(end)) &&
              (eventEnd.isAfter(start) || eventEnd.isAtSameMomentAs(start));
        })
        .toList();
    events.sort((a, b) => a.startTime.compareTo(b.startTime));
    return events;
  }

  // Reminders
  @override
  Future<List<NimmyReminder>> listReminders() async {
    final reminders = _reminders.values
        .map(_decode)
        .map(NimmyReminder.fromJson)
        .toList(growable: false);
    reminders.sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));
    return reminders;
  }

  @override
  Future<NimmyReminder?> findReminderByRequestId(String requestId) async {
    for (final raw in _reminders.values) {
      final reminder = NimmyReminder.fromJson(_decode(raw));
      if (reminder.requestId == requestId) return reminder;
    }
    return null;
  }

  @override
  Future<void> saveReminder(NimmyReminder reminder) {
    return _reminders.put(reminder.id, jsonEncode(reminder.toJson()));
  }

  @override
  Future<void> deleteReminder(String id) => _reminders.delete(id);

  // Memories
  @override
  Future<List<NimmyMemory>> listMemories({String query = ''}) async {
    final normalizedQuery = query.trim().toLowerCase();
    final memories = _memories.values
        .map(_decode)
        .map(NimmyMemory.fromJson)
        .where(
          (memory) =>
              normalizedQuery.isEmpty ||
              memory.content.toLowerCase().contains(normalizedQuery) ||
              memory.category.name.contains(normalizedQuery),
        )
        .toList(growable: false);
    memories.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return memories;
  }

  @override
  Future<NimmyMemory?> findMemoryByRequestId(String requestId) async {
    for (final raw in _memories.values) {
      final memory = NimmyMemory.fromJson(_decode(raw));
      if (memory.requestId == requestId) return memory;
    }
    return null;
  }

  @override
  Future<void> saveMemory(NimmyMemory memory) {
    return _memories.put(memory.id, jsonEncode(memory.toJson()));
  }

  @override
  Future<void> deleteMemory(String id) => _memories.delete(id);

  // Tasks
  @override
  Future<List<NimmyTask>> listTasks({String? projectId, TaskStatus? status}) async {
    final tasks = _tasks.values
        .map(_decode)
        .map(NimmyTask.fromJson)
        .where((t) => projectId == null || t.projectId == projectId)
        .where((t) => status == null || t.status == status)
        .toList();

    tasks.sort((a, b) {
      if (a.isCompleted != b.isCompleted) {
        return a.isCompleted ? 1 : -1;
      }
      if (a.dueDate != null && b.dueDate != null) {
        return a.dueDate!.compareTo(b.dueDate!);
      }
      if (a.dueDate != null) return -1;
      if (b.dueDate != null) return 1;
      return b.updatedAt.compareTo(a.updatedAt);
    });
    return tasks;
  }

  @override
  Future<NimmyTask?> findTaskById(String id) async {
    final raw = _tasks.get(id);
    if (raw == null) return null;
    return NimmyTask.fromJson(_decode(raw));
  }

  @override
  Future<NimmyTask?> findTaskByRequestId(String requestId) async {
    for (final raw in _tasks.values) {
      final task = NimmyTask.fromJson(_decode(raw));
      if (task.requestId == requestId) return task;
    }
    return null;
  }

  @override
  Future<void> saveTask(NimmyTask task) {
    return _tasks.put(task.id, jsonEncode(task.toJson()));
  }

  @override
  Future<void> deleteTask(String id) => _tasks.delete(id);

  // Projects
  @override
  Future<List<NimmyProject>> listProjects() async {
    final projects = _projects.values
        .map(_decode)
        .map(NimmyProject.fromJson)
        .toList();
    projects.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    return projects;
  }

  @override
  Future<NimmyProject?> findProjectById(String id) async {
    final raw = _projects.get(id);
    if (raw == null) return null;
    return NimmyProject.fromJson(_decode(raw));
  }

  @override
  Future<void> saveProject(NimmyProject project) {
    return _projects.put(project.id, jsonEncode(project.toJson()));
  }

  @override
  Future<void> deleteProject(String id) => _projects.delete(id);

  // Goals
  @override
  Future<List<NimmyGoal>> listGoals() async {
    final goals = _goals.values
        .map(_decode)
        .map(NimmyGoal.fromJson)
        .toList();
    goals.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return goals;
  }

  @override
  Future<void> saveGoal(NimmyGoal goal) {
    return _goals.put(goal.id, jsonEncode(goal.toJson()));
  }

  @override
  Future<void> deleteGoal(String id) => _goals.delete(id);

  // Habits
  @override
  Future<List<NimmyHabit>> listHabits() async {
    final habits = _habits.values
        .map(_decode)
        .map(NimmyHabit.fromJson)
        .toList();
    habits.sort((a, b) => b.streakCount.compareTo(a.streakCount));
    return habits;
  }

  @override
  Future<void> saveHabit(NimmyHabit habit) {
    return _habits.put(habit.id, jsonEncode(habit.toJson()));
  }

  @override
  Future<void> deleteHabit(String id) => _habits.delete(id);

  // Audit
  @override
  Future<List<AuditEvent>> listAuditEvents({int limit = 100}) async {
    final events = _audit.values
        .map(_decode)
        .map(AuditEvent.fromJson)
        .toList(growable: false);
    events.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return events.take(limit).toList(growable: false);
  }

  @override
  Future<void> appendAuditEvent(AuditEvent event) {
    return _audit.put(event.id, jsonEncode(event.toJson()));
  }

  Map<String, dynamic> _decode(String value) {
    return Map<String, dynamic>.from(jsonDecode(value) as Map);
  }
}
