import '../../models/audit_event.dart';
import '../../models/memory.dart';
import '../../models/reminder.dart';
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
      for (final reminder in await remote.listReminders()) {
        await local.saveReminder(reminder);
      }
      for (final memory in await remote.listMemories()) {
        await local.saveMemory(memory);
      }
      for (final event in await remote.listAuditEvents()) {
        await local.appendAuditEvent(event);
      }
    });
  }

  Future<void> _pushLocalToRemote() async {
    await _bestEffort(() async {
      for (final reminder in await local.listReminders()) {
        await remote.saveReminder(reminder);
      }
      for (final memory in await local.listMemories()) {
        await remote.saveMemory(memory);
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
