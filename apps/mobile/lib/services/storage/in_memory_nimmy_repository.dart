import '../../models/audit_event.dart';
import '../../models/memory.dart';
import '../../models/reminder.dart';
import 'nimmy_repository.dart';

class InMemoryNimmyRepository implements NimmyRepository {
  final Map<String, NimmyReminder> _reminders = {};
  final Map<String, NimmyMemory> _memories = {};
  final Map<String, AuditEvent> _audit = {};

  @override
  Future<void> initialize() async {}

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
