import '../../models/audit_event.dart';
import '../../models/calendar_event.dart';
import '../../models/goal.dart';
import '../../models/habit.dart';
import '../../models/memory.dart';
import '../../models/project.dart';
import '../../models/reminder.dart';
import '../../models/task.dart';
import 'nimmy_repository.dart';

class InMemoryNimmyRepository implements NimmyRepository {
  final Map<String, NimmyCalendarEvent> _calendarEvents = {};
  final Map<String, NimmyReminder> _reminders = {};
  final Map<String, NimmyMemory> _memories = {};
  final Map<String, NimmyTask> _tasks = {};
  final Map<String, NimmyProject> _projects = {};
  final Map<String, NimmyGoal> _goals = {};
  final Map<String, NimmyHabit> _habits = {};
  final Map<String, AuditEvent> _audit = {};

  @override
  Future<void> initialize() async {}

  // Calendar Events
  @override
  Future<List<NimmyCalendarEvent>> listCalendarEvents() async {
    final values = _calendarEvents.values.toList();
    values.sort((a, b) => a.startTime.compareTo(b.startTime));
    return values;
  }

  @override
  Future<NimmyCalendarEvent?> findCalendarEventById(String id) async {
    return _calendarEvents[id];
  }

  @override
  Future<void> saveCalendarEvent(NimmyCalendarEvent event) async {
    _calendarEvents[event.id] = event;
  }

  @override
  Future<void> deleteCalendarEvent(String id) async {
    _calendarEvents.remove(id);
  }

  @override
  Future<List<NimmyCalendarEvent>> listCalendarEventsForRange(
    DateTime start,
    DateTime end,
  ) async {
    final values = _calendarEvents.values.where((event) {
      final eventEnd = event.endTime ?? event.startTime;
      return (event.startTime.isBefore(end) || event.startTime.isAtSameMomentAs(end)) &&
          (eventEnd.isAfter(start) || eventEnd.isAtSameMomentAs(start));
    }).toList();
    values.sort((a, b) => a.startTime.compareTo(b.startTime));
    return values;
  }

  // Reminders
  @override
  Future<List<NimmyReminder>> listReminders() async {
    final values = _reminders.values.toList();
    values.sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));
    return values;
  }

  @override
  Future<NimmyReminder?> findReminderByRequestId(String requestId) async {
    for (final reminder in _reminders.values) {
      if (reminder.requestId == requestId) return reminder;
    }
    return null;
  }

  @override
  Future<void> saveReminder(NimmyReminder reminder) async {
    _reminders[reminder.id] = reminder;
  }

  @override
  Future<void> deleteReminder(String id) async {
    _reminders.remove(id);
  }

  // Memories
  @override
  Future<List<NimmyMemory>> listMemories({String query = ''}) async {
    final normalizedQuery = query.trim().toLowerCase();
    final values = _memories.values
        .where(
          (memory) =>
              normalizedQuery.isEmpty ||
              memory.content.toLowerCase().contains(normalizedQuery) ||
              memory.category.name.contains(normalizedQuery),
        )
        .toList();
    values.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return values;
  }

  @override
  Future<NimmyMemory?> findMemoryByRequestId(String requestId) async {
    for (final memory in _memories.values) {
      if (memory.requestId == requestId) return memory;
    }
    return null;
  }

  @override
  Future<void> saveMemory(NimmyMemory memory) async {
    _memories[memory.id] = memory;
  }

  @override
  Future<void> deleteMemory(String id) async {
    _memories.remove(id);
  }

  // Tasks
  @override
  Future<List<NimmyTask>> listTasks({String? projectId, TaskStatus? status}) async {
    final values = _tasks.values
        .where((t) => projectId == null || t.projectId == projectId)
        .where((t) => status == null || t.status == status)
        .toList();
    values.sort((a, b) {
      // Uncompleted tasks first, then sorted by due date or updated at
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
    return values;
  }

  @override
  Future<NimmyTask?> findTaskById(String id) async {
    return _tasks[id];
  }

  @override
  Future<NimmyTask?> findTaskByRequestId(String requestId) async {
    for (final task in _tasks.values) {
      if (task.requestId == requestId) return task;
    }
    return null;
  }

  @override
  Future<void> saveTask(NimmyTask task) async {
    _tasks[task.id] = task;
  }

  @override
  Future<void> deleteTask(String id) async {
    _tasks.remove(id);
  }

  // Projects
  @override
  Future<List<NimmyProject>> listProjects() async {
    final values = _projects.values.toList();
    values.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    return values;
  }

  @override
  Future<NimmyProject?> findProjectById(String id) async {
    return _projects[id];
  }

  @override
  Future<void> saveProject(NimmyProject project) async {
    _projects[project.id] = project;
  }

  @override
  Future<void> deleteProject(String id) async {
    _projects.remove(id);
  }

  // Goals
  @override
  Future<List<NimmyGoal>> listGoals() async {
    final values = _goals.values.toList();
    values.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return values;
  }

  @override
  Future<void> saveGoal(NimmyGoal goal) async {
    _goals[goal.id] = goal;
  }

  @override
  Future<void> deleteGoal(String id) async {
    _goals.remove(id);
  }

  // Habits
  @override
  Future<List<NimmyHabit>> listHabits() async {
    final values = _habits.values.toList();
    values.sort((a, b) => b.streakCount.compareTo(a.streakCount));
    return values;
  }

  @override
  Future<void> saveHabit(NimmyHabit habit) async {
    _habits[habit.id] = habit;
  }

  @override
  Future<void> deleteHabit(String id) async {
    _habits.remove(id);
  }

  // Audit
  @override
  Future<List<AuditEvent>> listAuditEvents({int limit = 100}) async {
    final values = _audit.values.toList();
    values.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return values.take(limit).toList();
  }

  @override
  Future<void> appendAuditEvent(AuditEvent event) async {
    _audit[event.id] = event;
  }
}
