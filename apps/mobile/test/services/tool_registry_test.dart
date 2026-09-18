import 'package:flutter_test/flutter_test.dart';
import 'package:nimmy/models/audit_event.dart';
import 'package:nimmy/models/memory.dart';
import 'package:nimmy/models/reminder.dart';
import 'package:nimmy/models/tool_action.dart';
import 'package:nimmy/services/notifications/notification_service.dart';
import 'package:nimmy/services/storage/in_memory_nimmy_repository.dart';
import 'package:nimmy/services/tools/tool_registry.dart';

void main() {
  final now = DateTime.utc(2026, 9, 17, 8);
  late InMemoryNimmyRepository repository;
  late ToolRegistry registry;

  setUp(() async {
    repository = InMemoryNimmyRepository();
    await repository.initialize();
    registry = ToolRegistry(
      repository: repository,
      reminderScheduler: _SuccessfulScheduler(),
      clock: () => now,
    );
  });

  test('refuses mutation without confirmation', () async {
    final proposal = _reminderProposal();

    final result = await registry.execute(proposal, confirmed: false);

    expect(result.success, isFalse);
    expect(await repository.listReminders(), isEmpty);
  });

  test('creates reminder exactly once and writes executed audit', () async {
    final proposal = _reminderProposal();

    final first = await registry.execute(proposal, confirmed: true);
    final second = await registry.execute(proposal, confirmed: true);

    expect(first.success, isTrue);
    expect(second.wasDuplicate, isTrue);
    expect(await repository.listReminders(), hasLength(1));
    final audit = await repository.listAuditEvents();
    expect(audit.single.status, AuditStatus.executed);
  });

  test('saves explicit memory after confirmation', () async {
    const proposal = ToolProposal(
      requestId: 'memory-request',
      intent: NimmyIntent.saveMemory,
      toolName: 'save_memory',
      input: SaveMemoryInput(
        content: 'Keep the dashboard minimal',
        category: MemoryCategory.preference,
        importance: MemoryImportance.normal,
      ),
      source: InteractionSource.text,
      originalText: 'Remember this: Keep the dashboard minimal',
    );

    final result = await registry.execute(proposal, confirmed: true);

    expect(result.success, isTrue);
    expect(await repository.listMemories(), hasLength(1));
  });
}

ToolProposal _reminderProposal() {
  return ToolProposal(
    requestId: 'reminder-request',
    intent: NimmyIntent.createReminder,
    toolName: 'create_reminder',
    input: CreateReminderInput(
      title: 'Study Geography',
      scheduledAt: DateTime.utc(2026, 9, 18, 3, 30),
      timezone: 'Asia/Kolkata',
    ),
    source: InteractionSource.text,
    originalText: 'Remind me tomorrow at 9 AM to study Geography',
  );
}

class _SuccessfulScheduler implements ReminderScheduler {
  @override
  String get timezone => 'Asia/Kolkata';

  @override
  Future<void> initialize() async {}

  @override
  Future<bool> schedule(NimmyReminder reminder) async => true;

  @override
  Future<void> cancel(String reminderId) async {}
}
