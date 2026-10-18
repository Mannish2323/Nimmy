import 'package:flutter_test/flutter_test.dart';
import 'package:nimmy/models/audit_event.dart';
import 'package:nimmy/models/reminder.dart';
import 'package:nimmy/models/task.dart';
import 'package:nimmy/models/tool_action.dart';
import 'package:nimmy/services/notifications/notification_service.dart';
import 'package:nimmy/services/storage/in_memory_nimmy_repository.dart';
import 'package:nimmy/services/tools/tool_registry.dart';

void main() {
  final now = DateTime.utc(2026, 10, 18, 12, 0);
  late InMemoryNimmyRepository repository;
  late ToolRegistry registry;

  setUp(() async {
    repository = InMemoryNimmyRepository();
    await repository.initialize();
    registry = ToolRegistry(
      repository: repository,
      reminderScheduler: _StubScheduler(),
      clock: () => now,
    );
  });

  test('create_task requires confirmation', () async {
    const proposal = ToolProposal(
      requestId: 'task-req-1',
      intent: NimmyIntent.createTask,
      toolName: 'create_task',
      input: CreateTaskInput(title: 'Review PR'),
      source: InteractionSource.text,
      originalText: 'create task Review PR',
    );

    final unconfirmed = await registry.execute(proposal, confirmed: false);
    expect(unconfirmed.success, isFalse);
    expect((await repository.listTasks()).isEmpty, isTrue);

    final confirmed = await registry.execute(proposal, confirmed: true);
    expect(confirmed.success, isTrue);
    expect(confirmed.recordId, isNotNull);

    final tasks = await repository.listTasks();
    expect(tasks.length, 1);
    expect(tasks.first.title, 'Review PR');

    final audits = await repository.listAuditEvents();
    expect(audits.first.status, AuditStatus.executed);
  });

  test('create_task handles idempotency for duplicate requestId', () async {
    const proposal = ToolProposal(
      requestId: 'task-req-dup',
      intent: NimmyIntent.createTask,
      toolName: 'create_task',
      input: CreateTaskInput(title: 'Duplicate Test'),
      source: InteractionSource.text,
      originalText: 'create task Duplicate Test',
    );

    final first = await registry.execute(proposal, confirmed: true);
    final second = await registry.execute(proposal, confirmed: true);

    expect(first.success, isTrue);
    expect(second.wasDuplicate, isTrue);
    expect((await repository.listTasks()).length, 1);
  });

  test('complete_task marks task done and audits', () async {
    final task = NimmyTask(
      id: 'task-to-complete',
      userId: 'user-1',
      title: 'Finish Feature',
      status: TaskStatus.todo,
      createdAt: now,
      updatedAt: now,
    );
    await repository.saveTask(task);

    const proposal = ToolProposal(
      requestId: 'complete-req-1',
      intent: NimmyIntent.completeTask,
      toolName: 'complete_task',
      input: CompleteTaskInput(taskId: 'task-to-complete'),
      source: InteractionSource.text,
      originalText: 'complete task',
    );

    final result = await registry.execute(proposal, confirmed: true);
    expect(result.success, isTrue);

    final updated = await repository.findTaskById('task-to-complete');
    expect(updated?.isCompleted, isTrue);
    expect(updated?.completedAt, isNotNull);
  });

  test('delete_task removes task and audits', () async {
    final task = NimmyTask(
      id: 'task-to-delete',
      userId: 'user-1',
      title: 'Obsolete Task',
      status: TaskStatus.todo,
      createdAt: now,
      updatedAt: now,
    );
    await repository.saveTask(task);

    const proposal = ToolProposal(
      requestId: 'del-req-1',
      intent: NimmyIntent.deleteTask,
      toolName: 'delete_task',
      input: DeleteTaskInput(taskId: 'task-to-delete'),
      source: InteractionSource.text,
      originalText: 'delete task',
    );

    final result = await registry.execute(proposal, confirmed: true);
    expect(result.success, isTrue);
    expect(await repository.findTaskById('task-to-delete'), isNull);
  });

  test('reschedule_task updates dueDate with reason audit', () async {
    final task = NimmyTask(
      id: 'task-reschedule',
      userId: 'user-1',
      title: 'Meet with team',
      dueDate: now.add(const Duration(days: 1)),
      status: TaskStatus.todo,
      createdAt: now,
      updatedAt: now,
    );
    await repository.saveTask(task);

    final newDate = now.add(const Duration(days: 5));
    final proposal = ToolProposal(
      requestId: 'resched-req-1',
      intent: NimmyIntent.rescheduleTask,
      toolName: 'reschedule_task',
      input: RescheduleTaskInput(
        taskId: 'task-reschedule',
        newDueDate: newDate,
        reason: 'Postponed due to holiday',
      ),
      source: InteractionSource.text,
      originalText: 'reschedule task',
    );

    final result = await registry.execute(proposal, confirmed: true);
    expect(result.success, isTrue);

    final updated = await repository.findTaskById('task-reschedule');
    expect(updated?.dueDate, newDate);

    final audits = await repository.listAuditEvents();
    expect(audits.first.metadata['reason'], 'Postponed due to holiday');
  });
}

class _StubScheduler implements ReminderScheduler {
  @override
  String get timezone => 'UTC';

  @override
  Future<void> initialize() async {}

  @override
  Future<bool> schedule(NimmyReminder reminder) async => true;

  @override
  Future<void> cancel(String reminderId) async {}
}
