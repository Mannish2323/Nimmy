import '../../models/audit_event.dart';
import '../../models/calendar_event.dart';
import '../../models/goal.dart';
import '../../models/habit.dart';
import '../../models/memory.dart';
import '../../models/project.dart';
import '../../models/reminder.dart';
import '../../models/task.dart';
import 'nimmy_repository.dart';

/// Local storage is authoritative for immediate UX; the optional remote is a
/// synchronized mirror. Failed create/update writes remain available locally
/// and are retried the next time [initialize] runs. Deletes require the remote
/// acknowledgement first so stale cloud data cannot silently reappear.
class OfflineFirstNimmyRepository implements NimmyRepository {
  OfflineFirstNimmyRepository({required this.local, required this.remote});

  final NimmyRepository local;
  final NimmyRepository remote;

  @override
  Future<void> initialize() async {
    await local.initialize();
    await remote.initialize();
    await synchronize();
  }

  Future<void> synchronize() async {
    await _mergeRemoteIntoLocal();
    await _pushLocalToRemote();
  }

  // Calendar Events
  @override
  Future<List<NimmyCalendarEvent>> listCalendarEvents() => local.listCalendarEvents();

  @override
  Future<NimmyCalendarEvent?> findCalendarEventById(String id) {
    return local.findCalendarEventById(id);
  }

  @override
  Future<void> saveCalendarEvent(NimmyCalendarEvent event) async {
    await local.saveCalendarEvent(event);
    await _bestEffort(() => remote.saveCalendarEvent(event));
  }

  @override
  Future<void> deleteCalendarEvent(String id) async {
    await remote.deleteCalendarEvent(id);
    await local.deleteCalendarEvent(id);
  }

  @override
  Future<List<NimmyCalendarEvent>> listCalendarEventsForRange(
    DateTime start,
    DateTime end,
  ) {
    return local.listCalendarEventsForRange(start, end);
  }

  // Reminders
  @override
  Future<List<NimmyReminder>> listReminders() => local.listReminders();

  @override
  Future<NimmyReminder?> findReminderByRequestId(String requestId) {
    return local.findReminderByRequestId(requestId);
  }

  @override
  Future<void> saveReminder(NimmyReminder reminder) async {
    await local.saveReminder(reminder);
    await _bestEffort(() => remote.saveReminder(reminder));
  }

  @override
  Future<void> deleteReminder(String id) async {
    await remote.deleteReminder(id);
    await local.deleteReminder(id);
  }

  // Memories
  @override
  Future<List<NimmyMemory>> listMemories({String query = ''}) {
    return local.listMemories(query: query);
  }

  @override
  Future<NimmyMemory?> findMemoryByRequestId(String requestId) {
    return local.findMemoryByRequestId(requestId);
  }

  @override
  Future<void> saveMemory(NimmyMemory memory) async {
    await local.saveMemory(memory);
    await _bestEffort(() => remote.saveMemory(memory));
  }

  @override
  Future<void> deleteMemory(String id) async {
    await remote.deleteMemory(id);
    await local.deleteMemory(id);
  }

  // Tasks
  @override
  Future<List<NimmyTask>> listTasks({String? projectId, TaskStatus? status}) {
    return local.listTasks(projectId: projectId, status: status);
  }

  @override
  Future<NimmyTask?> findTaskById(String id) {
    return local.findTaskById(id);
  }

  @override
  Future<NimmyTask?> findTaskByRequestId(String requestId) {
    return local.findTaskByRequestId(requestId);
  }

  @override
  Future<void> saveTask(NimmyTask task) async {
    await local.saveTask(task);
    await _bestEffort(() => remote.saveTask(task));
  }

  @override
  Future<void> deleteTask(String id) async {
    await remote.deleteTask(id);
    await local.deleteTask(id);
  }

  // Projects
  @override
  Future<List<NimmyProject>> listProjects() => local.listProjects();

  @override
  Future<NimmyProject?> findProjectById(String id) => local.findProjectById(id);

  @override
  Future<void> saveProject(NimmyProject project) async {
    await local.saveProject(project);
    await _bestEffort(() => remote.saveProject(project));
  }

  @override
  Future<void> deleteProject(String id) async {
    await remote.deleteProject(id);
    await local.deleteProject(id);
  }

  // Goals
  @override
  Future<List<NimmyGoal>> listGoals() => local.listGoals();

  @override
  Future<void> saveGoal(NimmyGoal goal) async {
    await local.saveGoal(goal);
    await _bestEffort(() => remote.saveGoal(goal));
  }

  @override
  Future<void> deleteGoal(String id) async {
    await remote.deleteGoal(id);
    await local.deleteGoal(id);
  }

  // Habits
  @override
  Future<List<NimmyHabit>> listHabits() => local.listHabits();

  @override
  Future<void> saveHabit(NimmyHabit habit) async {
    await local.saveHabit(habit);
    await _bestEffort(() => remote.saveHabit(habit));
  }

  @override
  Future<void> deleteHabit(String id) async {
    await remote.deleteHabit(id);
    await local.deleteHabit(id);
  }

  // Audit
  @override
  Future<List<AuditEvent>> listAuditEvents({int limit = 100}) {
    return local.listAuditEvents(limit: limit);
  }

  @override
  Future<void> appendAuditEvent(AuditEvent event) async {
    await local.appendAuditEvent(event);
    await _bestEffort(() => remote.appendAuditEvent(event));
  }

  Future<void> _mergeRemoteIntoLocal() async {
    await _bestEffort(() async {
      for (final event in await remote.listCalendarEvents()) {
        await local.saveCalendarEvent(event);
      }
      for (final reminder in await remote.listReminders()) {
        await local.saveReminder(reminder);
      }
      for (final memory in await remote.listMemories()) {
        await local.saveMemory(memory);
      }
      for (final task in await remote.listTasks()) {
        await local.saveTask(task);
      }
      for (final project in await remote.listProjects()) {
        await local.saveProject(project);
      }
      for (final goal in await remote.listGoals()) {
        await local.saveGoal(goal);
      }
      for (final habit in await remote.listHabits()) {
        await local.saveHabit(habit);
      }
      for (final event in await remote.listAuditEvents()) {
        await local.appendAuditEvent(event);
      }
    });
  }

  Future<void> _pushLocalToRemote() async {
    await _bestEffort(() async {
      for (final event in await local.listCalendarEvents()) {
        await remote.saveCalendarEvent(event);
      }
      for (final reminder in await local.listReminders()) {
        await remote.saveReminder(reminder);
      }
      for (final memory in await local.listMemories()) {
        await remote.saveMemory(memory);
      }
      for (final task in await local.listTasks()) {
        await remote.saveTask(task);
      }
      for (final project in await local.listProjects()) {
        await remote.saveProject(project);
      }
      for (final goal in await local.listGoals()) {
        await remote.saveGoal(goal);
      }
      for (final habit in await local.listHabits()) {
        await remote.saveHabit(habit);
      }
      for (final event in await local.listAuditEvents()) {
        await remote.appendAuditEvent(event);
      }
    });
  }

  Future<void> _bestEffort(Future<void> Function() operation) async {
    try {
      await operation();
    } catch (_) {
      // Local state remains intact and will be retried on a future bootstrap.
    }
  }
}
