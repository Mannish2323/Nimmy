import 'package:flutter_test/flutter_test.dart';
import 'package:nimmy/models/memory.dart';
import 'package:nimmy/models/tool_action.dart';
import 'package:nimmy/services/ai/intent_parser.dart';

void main() {
  final now = DateTime(2026, 9, 17, 10, 0);
  late NimmyIntentParser parser;

  setUp(() {
    parser = NimmyIntentParser(clock: () => now, timezone: 'Asia/Kolkata');
  });

  test('parses canonical tomorrow reminder', () {
    final result = parser.parse(
      'Nimmy, remind me tomorrow at 9 AM to study Geography.',
    );

    expect(result.hasProposal, isTrue);
    expect(result.proposal!.toolName, 'create_reminder');
    final input = result.proposal!.input as CreateReminderInput;
    expect(input.title, 'Study Geography');
    expect(input.scheduledAt.toLocal(), DateTime(2026, 9, 18, 9));
    expect(input.timezone, 'Asia/Kolkata');
  });

  test('parses relative reminder', () {
    final result = parser.parse('Remind me in 30 minutes to call Rahul');
    final input = result.proposal!.input as CreateReminderInput;

    expect(input.title, 'Call Rahul');
    expect(input.scheduledAt.toLocal(), now.add(const Duration(minutes: 30)));
  });

  test('asks for clarification when AM or PM is missing', () {
    final result = parser.parse('Remind me tomorrow at 9 to study');

    expect(result.proposal, isNull);
    expect(result.clarification, contains('AM or PM'));
  });

  test('parses explicit memory and classifies preference', () {
    final result = parser.parse(
      'Nimmy, remember this: I prefer a minimal dashboard.',
    );
    final input = result.proposal!.input as SaveMemoryInput;

    expect(result.proposal!.toolName, 'save_memory');
    expect(input.content, 'I prefer a minimal dashboard');
    expect(input.category, MemoryCategory.preference);
  });

  test('does not expose unsupported intents as functional', () {
    final result = parser.parse('Send Rahul a WhatsApp message');

    expect(result.proposal, isNull);
    expect(result.error, contains('currently supports'));
  });
}
