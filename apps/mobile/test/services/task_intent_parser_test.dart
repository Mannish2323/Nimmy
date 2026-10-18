import 'package:flutter_test/flutter_test.dart';
import 'package:nimmy/models/task.dart';
import 'package:nimmy/models/tool_action.dart';
import 'package:nimmy/services/ai/intent_parser.dart';

void main() {
  final now = DateTime(2026, 10, 18, 10, 0);
  late NimmyIntentParser parser;

  setUp(() {
    parser = NimmyIntentParser(clock: () => now);
  });

  group('Task Intent Parsing', () {
    test('parses simple task command', () {
      final result = parser.parse('create task buy groceries');
      expect(result.hasProposal, isTrue);

      final proposal = result.proposal!;
      expect(proposal.intent, NimmyIntent.createTask);
      expect(proposal.toolName, 'create_task');

      final input = proposal.input as CreateTaskInput;
      expect(input.title, 'Buy groceries');
      expect(input.priority, TaskPriority.medium);
      expect(input.dueDate, isNull);
    });

    test('parses task with urgent priority', () {
      final result = parser.parse('add a task to fix production bug with urgent priority');
      expect(result.hasProposal, isTrue);

      final input = result.proposal!.input as CreateTaskInput;
      expect(input.title, 'Fix production bug');
      expect(input.priority, TaskPriority.urgent);
    });

    test('parses task with due tomorrow date', () {
      final result = parser.parse('new task: submit budget proposal due tomorrow');
      expect(result.hasProposal, isTrue);

      final input = result.proposal!.input as CreateTaskInput;
      expect(input.title, 'Submit budget proposal');
      expect(input.dueDate, isNotNull);
      expect(input.dueDate?.day, now.day + 1);
    });

    test('handles wake phrase with task command', () {
      final result = parser.parse('Nimmy, add task clean desk');
      expect(result.hasProposal, isTrue);
      final input = result.proposal!.input as CreateTaskInput;
      expect(input.title, 'Clean desk');
    });

    test('returns clarification when task title is empty', () {
      final result = parser.parse('create task: ');
      expect(result.hasProposal, isFalse);
      expect(result.clarification, isNotNull);
    });
  });
}
