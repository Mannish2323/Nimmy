import 'package:supabase/supabase.dart';

import '../../models/audit_event.dart';
import '../../models/memory.dart';
import '../../models/reminder.dart';
import 'nimmy_repository.dart';

class SupabaseNimmyRepository implements NimmyRepository {
  SupabaseNimmyRepository(this._client);

  final SupabaseClient _client;
  String? _profileId;

  String get profileId {
    final value = _profileId;
    if (value == null) {
      throw StateError('An authenticated Nimmy profile is required.');
    }
    return value;
  }

  @override
  Future<void> initialize() async {
    final authUser = _client.auth.currentUser;
    if (authUser == null) {
      throw StateError('Supabase session is not authenticated.');
    }
    final profile = await _client
        .from('users')
        .select('id')
        .eq('auth_id', authUser.id)
        .maybeSingle();
    if (profile == null) {
      final email = authUser.email;
      if (email == null || email.isEmpty) {
        throw StateError('The current account has no email-backed profile.');
      }
      final inserted = await _client
          .from('users')
          .insert({
            'auth_id': authUser.id,
            'email': email,
            'display_name':
                authUser.userMetadata?['display_name'] as String? ??
                'Nimmy User',
          })
          .select('id')
          .single();
      _profileId = inserted['id'] as String;
      return;
    }
    _profileId = profile['id'] as String;
  }

  @override
  Future<List<NimmyReminder>> listReminders() async {
    final rows = await _client
        .from('reminders')
        .select()
        .eq('user_id', profileId)
        .order('remind_at');
    return rows.map<NimmyReminder>(_reminderFromRow).toList();
  }

  @override
  Future<NimmyReminder?> findReminderByRequestId(String requestId) async {
    final row = await _client
        .from('reminders')
        .select()
        .eq('user_id', profileId)
        .eq('request_id', requestId)
        .maybeSingle();
    return row == null ? null : _reminderFromRow(row);
  }

  @override
  Future<void> saveReminder(NimmyReminder reminder) async {
    await _client.from('reminders').upsert({
      'id': reminder.id,
      'user_id': profileId,
      'request_id': reminder.requestId,
      'title': reminder.title,
      'message': reminder.notes,
      'remind_at': reminder.scheduledAt.toUtc().toIso8601String(),
      'timezone': reminder.timezone,
      'status': _reminderStatusToDatabase(reminder.status),
      'is_recurring': reminder.recurrence != null,
      'recurrence_rule': reminder.recurrence,
      'source': reminder.source.name,
      'notification_scheduled': reminder.notificationScheduled,
      'created_at': reminder.createdAt.toUtc().toIso8601String(),
      'updated_at': reminder.updatedAt.toUtc().toIso8601String(),
    });
  }

  @override
  Future<void> deleteReminder(String id) async {
    await _client
        .from('reminders')
        .delete()
        .eq('id', id)
        .eq('user_id', profileId);
  }

  @override
  Future<List<NimmyMemory>> listMemories({String query = ''}) async {
    final rows = await _client
        .from('memories')
        .select()
        .eq('user_id', profileId)
        .eq('is_active', true)
        .order('updated_at', ascending: false);
    final normalized = query.trim().toLowerCase();
    return rows
        .map<NimmyMemory>(_memoryFromRow)
        .where(
          (memory) =>
              normalized.isEmpty ||
              memory.content.toLowerCase().contains(normalized) ||
              memory.category.name.contains(normalized),
        )
        .toList();
  }

  @override
  Future<NimmyMemory?> findMemoryByRequestId(String requestId) async {
    final row = await _client
        .from('memories')
        .select()
        .eq('user_id', profileId)
        .eq('request_id', requestId)
        .maybeSingle();
    return row == null ? null : _memoryFromRow(row);
  }

  @override
  Future<void> saveMemory(NimmyMemory memory) async {
    await _client.from('memories').upsert({
      'id': memory.id,
      'user_id': profileId,
      'request_id': memory.requestId,
      'memory_type': _memoryCategoryToDatabase(memory.category),
      'source': memory.source.name,
      'source_reference': memory.sourceReference,
      'content': memory.content,
      'importance': _importanceToDatabase(memory.importance),
      'is_active': true,
      'created_at': memory.createdAt.toUtc().toIso8601String(),
      'updated_at': memory.updatedAt.toUtc().toIso8601String(),
    });
  }

  @override
  Future<void> deleteMemory(String id) async {
    await _client
        .from('memories')
        .delete()
        .eq('id', id)
        .eq('user_id', profileId);
  }

  @override
  Future<List<AuditEvent>> listAuditEvents({int limit = 100}) async {
    final rows = await _client
        .from('audit_logs')
        .select()
        .eq('user_id', profileId)
        .order('created_at', ascending: false)
        .limit(limit);
    return rows.map<AuditEvent>(_auditFromRow).toList();
  }

  @override
  Future<void> appendAuditEvent(AuditEvent event) async {
    await _client.from('audit_logs').upsert({
      'id': event.id,
      'user_id': profileId,
      'action_type': event.actionType,
      'tool_name': event.toolName,
      'request_id': event.requestId,
      'source': event.source.name,
      'status': event.status.name,
      'created_at': event.createdAt.toUtc().toIso8601String(),
      'executed_at': event.executedAt?.toUtc().toIso8601String(),
      'metadata': event.metadata,
      'error_code': event.errorCode,
    }, onConflict: 'id');
  }

  NimmyReminder _reminderFromRow(Map<String, dynamic> row) {
    final now = DateTime.now().toUtc();
    return NimmyReminder(
      id: row['id'] as String,
      userId: row['user_id'] as String,
      requestId: row['request_id'] as String,
      title: row['title'] as String,
      scheduledAt: DateTime.parse(row['remind_at'] as String),
      timezone: row['timezone'] as String? ?? 'UTC',
      recurrence: row['recurrence_rule'] as String?,
      notes: row['message'] as String?,
      source: InteractionSource.values.byName(
        row['source'] as String? ?? 'text',
      ),
      status: _reminderStatusFromDatabase(row['status'] as String),
      createdAt: _parseDate(row['created_at'], now),
      updatedAt: _parseDate(row['updated_at'], now),
      notificationScheduled: row['notification_scheduled'] as bool? ?? false,
    );
  }

  NimmyMemory _memoryFromRow(Map<String, dynamic> row) {
    final now = DateTime.now().toUtc();
    return NimmyMemory(
      id: row['id'] as String,
      userId: row['user_id'] as String,
      requestId: row['request_id'] as String,
      content: row['content'] as String,
      category: _memoryCategoryFromDatabase(row['memory_type'] as String),
      importance: _importanceFromDatabase(row['importance'] as int? ?? 5),
      source: InteractionSource.values.byName(
        row['source'] as String? ?? 'text',
      ),
      sourceReference: row['source_reference'] as String?,
      createdAt: _parseDate(row['created_at'], now),
      updatedAt: _parseDate(row['updated_at'], now),
    );
  }

  AuditEvent _auditFromRow(Map<String, dynamic> row) {
    return AuditEvent(
      id: row['id'] as String,
      userId: row['user_id'] as String,
      actionType: row['action_type'] as String,
      toolName: row['tool_name'] as String,
      requestId: row['request_id'] as String,
      source: InteractionSource.values.byName(row['source'] as String),
      status: AuditStatus.values.byName(row['status'] as String),
      createdAt: DateTime.parse(row['created_at'] as String),
      executedAt: row['executed_at'] == null
          ? null
          : DateTime.parse(row['executed_at'] as String),
      metadata: Map<String, dynamic>.from(
        row['metadata'] as Map? ?? const <String, dynamic>{},
      ),
      errorCode: row['error_code'] as String?,
    );
  }

  DateTime _parseDate(dynamic value, DateTime fallback) {
    return value is String ? DateTime.parse(value) : fallback;
  }

  String _reminderStatusToDatabase(ReminderStatus status) {
    return switch (status) {
      ReminderStatus.pending => 'pending',
      ReminderStatus.triggered => 'triggered',
      ReminderStatus.completed || ReminderStatus.cancelled => 'dismissed',
    };
  }

  ReminderStatus _reminderStatusFromDatabase(String status) {
    return switch (status) {
      'triggered' => ReminderStatus.triggered,
      'dismissed' => ReminderStatus.completed,
      _ => ReminderStatus.pending,
    };
  }

  String _memoryCategoryToDatabase(MemoryCategory category) {
    return category == MemoryCategory.reminderContext
        ? 'reminder_context'
        : category.name;
  }

  MemoryCategory _memoryCategoryFromDatabase(String value) {
    if (value == 'reminder_context') return MemoryCategory.reminderContext;
    return MemoryCategory.values.firstWhere(
      (category) => category.name == value,
      orElse: () => MemoryCategory.other,
    );
  }

  int _importanceToDatabase(MemoryImportance value) {
    return switch (value) {
      MemoryImportance.low => 3,
      MemoryImportance.normal => 5,
      MemoryImportance.high => 9,
    };
  }

  MemoryImportance _importanceFromDatabase(int value) {
    if (value >= 8) return MemoryImportance.high;
    if (value <= 3) return MemoryImportance.low;
    return MemoryImportance.normal;
  }
}
