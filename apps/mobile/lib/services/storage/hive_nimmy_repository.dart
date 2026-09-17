import 'dart:convert';

import 'package:hive_flutter/hive_flutter.dart';

import '../../models/audit_event.dart';
import '../../models/memory.dart';
import '../../models/reminder.dart';
import 'nimmy_repository.dart';

class HiveNimmyRepository implements NimmyRepository {
  static const _remindersBoxName = 'nimmy_reminders_v1';
  static const _memoriesBoxName = 'nimmy_memories_v1';
  static const _auditBoxName = 'nimmy_audit_v1';

  late Box<String> _reminders;
  late Box<String> _memories;
  late Box<String> _audit;

  @override
  Future<void> initialize() async {
    await Hive.initFlutter();
    _reminders = await Hive.openBox<String>(_remindersBoxName);
    _memories = await Hive.openBox<String>(_memoriesBoxName);
    _audit = await Hive.openBox<String>(_auditBoxName);
  }

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
