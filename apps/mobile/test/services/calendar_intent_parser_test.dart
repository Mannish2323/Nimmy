import 'package:flutter_test/flutter_test.dart';
import 'package:nimmy/models/calendar_event.dart';
import 'package:nimmy/models/tool_action.dart';
import 'package:nimmy/services/ai/intent_parser.dart';

void main() {
  group('Calendar Intent Parsing Tests', () {
    final fixedClock = DateTime(2026, 10, 18, 9, 0);
    late NimmyIntentParser parser;

    setUp(() {
      parser = NimmyIntentParser(clock: () => fixedClock, timezone: 'UTC');
    });

    test('parses schedule meeting with tomorrow at 3pm', () {
      final result = parser.parse('schedule meeting with Alex tomorrow at 3pm');
      expect(result.hasProposal, true);
      final proposal = result.proposal!;
      expect(proposal.intent, NimmyIntent.createCalendarEvent);
      expect(proposal.toolName, 'create_calendar_event');

      final input = proposal.input as CreateCalendarEventInput;
      expect(input.title, 'Alex');
      expect(input.eventType, EventType.meeting);
      expect(input.startTime, DateTime(2026, 10, 19, 15, 0));
      expect(input.endTime, DateTime(2026, 10, 19, 16, 0));
    });

    test('parses schedule dentist appointment today at 4pm', () {
      final result = parser.parse('schedule dentist appointment today at 4pm');
      expect(result.hasProposal, true);
      final proposal = result.proposal!;
      expect(proposal.intent, NimmyIntent.createCalendarEvent);

      final input = proposal.input as CreateCalendarEventInput;
      expect(input.title, 'Dentist appointment');
      expect(input.startTime, DateTime(2026, 10, 18, 16, 0));
    });

    test('parses calendar: prefix and deadline keyword', () {
      final result = parser.parse('calendar: tax submission deadline tomorrow at 5pm');
      expect(result.hasProposal, true);
      final proposal = result.proposal!;
      expect(proposal.intent, NimmyIntent.createCalendarEvent);

      final input = proposal.input as CreateCalendarEventInput;
      expect(input.eventType, EventType.deadline);
      expect(input.startTime, DateTime(2026, 10, 19, 17, 0));
    });

    test('parses add event command with simple time', () {
      final result = parser.parse('add event Design Critique at 2pm');
      expect(result.hasProposal, true);
      final proposal = result.proposal!;
      expect(proposal.intent, NimmyIntent.createCalendarEvent);

      final input = proposal.input as CreateCalendarEventInput;
      expect(input.title, 'Design Critique');
      expect(input.startTime, DateTime(2026, 10, 18, 14, 0));
    });

    test('handles wake word with schedule command', () {
      final result = parser.parse('Nimmy, schedule Product Roadmap Review tomorrow at 10am');
      expect(result.hasProposal, true);
      final proposal = result.proposal!;
      expect(proposal.intent, NimmyIntent.createCalendarEvent);

      final input = proposal.input as CreateCalendarEventInput;
      expect(input.title, 'Product Roadmap Review');
      expect(input.startTime, DateTime(2026, 10, 19, 10, 0));
    });

    test('returns clarification on empty schedule command', () {
      final result = parser.parse('schedule');
      expect(result.hasProposal, false);
      expect(result.clarification, isNotNull);
      expect(result.clarification, contains('What event would you like me to schedule?'));
    });
  });
}
