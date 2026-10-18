import '../../models/audit_event.dart';
import '../../models/calendar_event.dart';
import '../../models/goal.dart';
import '../../models/habit.dart';
import '../../models/memory.dart';
import '../../models/project.dart';
import '../../models/reminder.dart';
import '../../models/task.dart';

abstract interface class NimmyRepository {
  Future<void> initialize();

  // Calendar Events
  Future<List<NimmyCalendarEvent>> listCalendarEvents();

  Future<NimmyCalendarEvent?> findCalendarEventById(String id);

  Future<void> saveCalendarEvent(NimmyCalendarEvent event);

  Future<void> deleteCalendarEvent(String id);

  Future<List<NimmyCalendarEvent>> listCalendarEventsForRange(DateTime start, DateTime end);

  // Reminders
  Future<List<NimmyReminder>> listReminders();

  Future<NimmyReminder?> findReminderByRequestId(String requestId);

  Future<void> saveReminder(NimmyReminder reminder);

  Future<void> deleteReminder(String id);

  // Memories
  Future<List<NimmyMemory>> listMemories({String query = ''});

  Future<NimmyMemory?> findMemoryByRequestId(String requestId);

  Future<void> saveMemory(NimmyMemory memory);

  Future<void> deleteMemory(String id);

  // Tasks
  Future<List<NimmyTask>> listTasks({String? projectId, TaskStatus? status});

  Future<NimmyTask?> findTaskById(String id);

  Future<NimmyTask?> findTaskByRequestId(String requestId);

  Future<void> saveTask(NimmyTask task);

  Future<void> deleteTask(String id);

  // Projects
  Future<List<NimmyProject>> listProjects();

  Future<NimmyProject?> findProjectById(String id);

  Future<void> saveProject(NimmyProject project);

  Future<void> deleteProject(String id);

  // Goals
  Future<List<NimmyGoal>> listGoals();

  Future<void> saveGoal(NimmyGoal goal);

  Future<void> deleteGoal(String id);

  // Habits
  Future<List<NimmyHabit>> listHabits();

  Future<void> saveHabit(NimmyHabit habit);

  Future<void> deleteHabit(String id);

  // Audit
  Future<List<AuditEvent>> listAuditEvents({int limit = 100});

  Future<void> appendAuditEvent(AuditEvent event);
}
