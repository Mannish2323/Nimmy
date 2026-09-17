import '../../models/audit_event.dart';
import '../../models/memory.dart';
import '../../models/reminder.dart';

abstract interface class NimmyRepository {
  Future<void> initialize();

  Future<List<NimmyReminder>> listReminders();

  Future<NimmyReminder?> findReminderByRequestId(String requestId);

  Future<void> saveReminder(NimmyReminder reminder);

  Future<void> deleteReminder(String id);

  Future<List<NimmyMemory>> listMemories({String query = ''});

  Future<NimmyMemory?> findMemoryByRequestId(String requestId);

  Future<void> saveMemory(NimmyMemory memory);

  Future<void> deleteMemory(String id);

  Future<List<AuditEvent>> listAuditEvents({int limit = 100});

  Future<void> appendAuditEvent(AuditEvent event);
}
