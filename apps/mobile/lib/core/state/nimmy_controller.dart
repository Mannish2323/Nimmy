import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../../models/audit_event.dart';
import '../../models/memory.dart';
import '../../models/nimmy_state.dart';
import '../../models/reminder.dart';
import '../../models/tool_action.dart';
import '../../services/ai/intent_parser.dart';
import '../../services/storage/nimmy_repository.dart';
import '../../services/tools/tool_registry.dart';

class NimmyController extends ChangeNotifier {
  NimmyController({
    required NimmyRepository repository,
    required NimmyIntentParser intentParser,
    required ToolRegistry toolRegistry,
    this.cloudConfigured = false,
    Clock? clock,
    Uuid? uuid,
  }) : _repository = repository,
       _intentParser = intentParser,
       _toolRegistry = toolRegistry,
       _clock = clock ?? DateTime.now,
       _uuid = uuid ?? const Uuid();

  final NimmyRepository _repository;
  final NimmyIntentParser _intentParser;
  final ToolRegistry _toolRegistry;
  final Clock _clock;
  final Uuid _uuid;
  final bool cloudConfigured;

  List<NimmyReminder> _reminders = const [];
  List<NimmyMemory> _memories = const [];
  List<AuditEvent> _auditEvents = const [];
  NimmyOrbState _orbState = NimmyOrbState.idle;
  ToolProposal? _pendingProposal;
  String _assistantMessage =
      'Tell me what you want to remember or be reminded about.';
  String? _warning;
  bool _isBusy = false;

  List<NimmyReminder> get reminders => List.unmodifiable(_reminders);
  List<NimmyMemory> get memories => List.unmodifiable(_memories);
  List<AuditEvent> get auditEvents => List.unmodifiable(_auditEvents);
  NimmyOrbState get orbState => _orbState;
  ToolProposal? get pendingProposal => _pendingProposal;
  String get assistantMessage => _assistantMessage;
  String? get warning => _warning;
  bool get isBusy => _isBusy;
  bool get isLocalOnly => !cloudConfigured;

  int get pendingReminderCount => _reminders
      .where(
        (item) =>
            item.status == ReminderStatus.pending &&
            item.scheduledAt.isAfter(_clock().toUtc()),
      )
      .length;

  NimmyReminder? get nextReminder {
    for (final reminder in _reminders) {
      if (reminder.status == ReminderStatus.pending &&
          reminder.scheduledAt.isAfter(_clock().toUtc())) {
        return reminder;
      }
    }
    return null;
  }

  Future<void> initialize() => refresh();

  Future<void> refresh() async {
    _reminders = await _repository.listReminders();
    _memories = await _repository.listMemories();
    _auditEvents = await _repository.listAuditEvents();
    notifyListeners();
  }

  Future<void> submitCommand(
    String text, {
    InteractionSource source = InteractionSource.text,
  }) async {
    if (_isBusy) return;
    _warning = null;
    _pendingProposal = null;
    _orbState = NimmyOrbState.understanding;
    _assistantMessage = 'Understanding your request…';
    notifyListeners();

    final result = _intentParser.parse(text, source: source);
    if (!result.hasProposal) {
      _orbState = NimmyOrbState.error;
      _assistantMessage =
          result.clarification ??
          result.error ??
          'I could not understand that request.';
      notifyListeners();
      return;
    }

    final proposal = result.proposal!;
    try {
      await _toolRegistry.audit(
        proposal,
        AuditStatus.proposed,
        metadata: {'input': proposal.input.toJson()},
      );
      _pendingProposal = proposal;
      _orbState = NimmyOrbState.confirming;
      _assistantMessage = 'Here’s what I understood. Please confirm it.';
      await refresh();
    } catch (_) {
      _orbState = NimmyOrbState.error;
      _assistantMessage =
          'I understood you, but I could not prepare the action. Nothing was changed.';
      notifyListeners();
    }
  }

  Future<ToolExecutionResult?> confirmPending() async {
    final proposal = _pendingProposal;
    if (proposal == null || _isBusy) return null;

    _isBusy = true;
    _orbState = NimmyOrbState.executing;
    _assistantMessage = 'Completing that now…';
    _warning = null;
    notifyListeners();

    try {
      await _toolRegistry.audit(proposal, AuditStatus.confirmed);
      final result = await _toolRegistry.execute(proposal, confirmed: true);
      _pendingProposal = null;
      _assistantMessage = result.message;
      _warning = result.warning;
      _orbState = result.success ? NimmyOrbState.success : NimmyOrbState.error;
      await refresh();
      return result;
    } catch (_) {
      _pendingProposal = null;
      _orbState = NimmyOrbState.error;
      _assistantMessage =
          'I couldn’t complete that action. Nothing was changed.';
      notifyListeners();
      return const ToolExecutionResult(
        success: false,
        message: 'I couldn’t complete that action. Nothing was changed.',
      );
    } finally {
      _isBusy = false;
      notifyListeners();
    }
  }

  Future<void> cancelPending({String reason = 'user_cancelled'}) async {
    final proposal = _pendingProposal;
    if (proposal == null) return;
    _pendingProposal = null;
    _orbState = NimmyOrbState.idle;
    _assistantMessage = 'Cancelled. Nothing was changed.';
    try {
      await _toolRegistry.audit(
        proposal,
        AuditStatus.cancelled,
        metadata: {'reason': reason},
      );
      await refresh();
    } catch (_) {
      notifyListeners();
    }
  }

  Future<void> updateMemory(NimmyMemory memory, String content) async {
    final trimmed = content.trim();
    if (trimmed.isEmpty) return;
    final updated = memory.copyWith(
      content: trimmed,
      updatedAt: _clock().toUtc(),
    );
    await _repository.saveMemory(updated);
    await _appendDirectAudit(
      actionType: 'editMemory',
      toolName: 'edit_memory',
      metadata: {'record_id': memory.id},
    );
    await refresh();
  }

  Future<void> deleteMemory(NimmyMemory memory) async {
    await _repository.deleteMemory(memory.id);
    await _appendDirectAudit(
      actionType: 'deleteMemory',
      toolName: 'delete_memory',
      metadata: {'record_id': memory.id},
    );
    await refresh();
  }

  Future<void> deleteReminder(NimmyReminder reminder) async {
    await _toolRegistry.cancelReminderNotification(reminder.id);
    await _repository.deleteReminder(reminder.id);
    await _appendDirectAudit(
      actionType: 'deleteReminder',
      toolName: 'delete_reminder',
      metadata: {'record_id': reminder.id},
    );
    await refresh();
  }

  void setOrbState(NimmyOrbState value, {String? message}) {
    _orbState = value;
    if (message != null) _assistantMessage = message;
    notifyListeners();
  }

  Future<void> _appendDirectAudit({
    required String actionType,
    required String toolName,
    required Map<String, dynamic> metadata,
  }) {
    final now = _clock().toUtc();
    return _repository.appendAuditEvent(
      AuditEvent(
        id: _uuid.v4(),
        userId: _toolRegistry.userId,
        actionType: actionType,
        toolName: toolName,
        requestId: _uuid.v4(),
        source: InteractionSource.text,
        status: AuditStatus.executed,
        createdAt: now,
        executedAt: now,
        metadata: metadata,
      ),
    );
  }
}
