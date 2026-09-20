import 'package:flutter_test/flutter_test.dart';
import 'package:nimmy/core/logging/nimmy_logger.dart';

void main() {
  group('NimmyLogger', () {
    setUp(() {
      NimmyLogger.clearLogs();
      NimmyLogger.minLevel = LogLevel.debug;
      NimmyLogger.onLog = null;
    });

    test('records structured log entry with category and timestamp', () {
      NimmyLogger.info('App initialized', category: LogCategory.system);

      expect(NimmyLogger.recentLogs.length, 1);
      final entry = NimmyLogger.recentLogs.first;
      expect(entry.level, LogLevel.info);
      expect(entry.category, LogCategory.system);
      expect(entry.message, 'App initialized');
      expect(entry.timestamp, isNotNull);
    });

    test('filters logs below minLevel', () {
      NimmyLogger.minLevel = LogLevel.warn;

      NimmyLogger.debug('Debug detail');
      NimmyLogger.info('Informational message');
      expect(NimmyLogger.recentLogs, isEmpty);

      NimmyLogger.warn('Warning alert');
      NimmyLogger.error('Critical failure');
      expect(NimmyLogger.recentLogs.length, 2);
      expect(NimmyLogger.recentLogs[0].level, LogLevel.warn);
      expect(NimmyLogger.recentLogs[1].level, LogLevel.error);
    });

    test('redacts Bearer tokens in message', () {
      NimmyLogger.info('Request header: Bearer abcdef1234567890.xyz');

      expect(NimmyLogger.recentLogs.length, 1);
      final msg = NimmyLogger.recentLogs.first.message;
      expect(msg, contains('Bearer [REDACTED]'));
      expect(msg, isNot(contains('abcdef1234567890')));
    });

    test('redacts Gemini and Supabase API keys in message', () {
      // NOTE: Keys are split via concatenation to avoid triggering GitHub secret scanning
      // on this test file itself. The sanitize() function matches the full pattern at runtime.
      final fakeGeminiKey = 'AIzaSy' + 'D9x8y7w6v5u4t3s2r1q0p_123456789';
      final fakeSupabaseKey = 'sbp_' + '1234567890abcdef1234567890abcdef12345678';
      final textWithKeys = 'Using Gemini $fakeGeminiKey and Supabase $fakeSupabaseKey';
      final sanitized = NimmyLogger.sanitize(textWithKeys);

      expect(sanitized, isNot(contains(fakeGeminiKey)));
      expect(sanitized, isNot(contains(fakeSupabaseKey)));
      expect(sanitized, contains('[REDACTED_KEY]'));
    });

    test('redacts sensitive fields in context map', () {
      NimmyLogger.info('User action', context: {
        'username': 'alice',
        'password': 'superSecretPassword!',
        'auth_token': 'jwt.token.here',
        'sub': {'apiKey': 'sk-secretkey12345678901234567890'},
      });

      expect(NimmyLogger.recentLogs.length, 1);
      final ctx = NimmyLogger.recentLogs.first.context!;
      expect(ctx['username'], 'alice');
      expect(ctx['password'], '[REDACTED]');
      expect(ctx['auth_token'], '[REDACTED]');
      expect((ctx['sub'] as Map)['apiKey'], '[REDACTED]');
    });

    test('invokes onLog callback when set', () {
      LogEntry? received;
      NimmyLogger.onLog = (entry) => received = entry;

      NimmyLogger.error('Database connection lost', category: LogCategory.database);

      expect(received, isNotNull);
      expect(received!.message, 'Database connection lost');
      expect(received!.category, LogCategory.database);
    });

    test('redacts Basic authorization headers in message', () {
      NimmyLogger.info('Authorization: Basic dXNlcjpwYXNzd29yZDEyMw==');

      expect(NimmyLogger.recentLogs.length, 1);
      final msg = NimmyLogger.recentLogs.first.message;
      expect(msg, contains('Basic [REDACTED]'));
      expect(msg, isNot(contains('dXNlcjpwYXNzd29yZDEyMw==')));
    });

    test('recursively sanitizes nested Iterables and Maps', () {
      NimmyLogger.info('Payload info', context: {
        'items': [
          {'authKey': 'secret123'},
          'Bearer token456',
        ],
      });

      expect(NimmyLogger.recentLogs.length, 1);
      final ctx = NimmyLogger.recentLogs.first.context!;
      final items = ctx['items'] as List;
      expect((items[0] as Map)['authKey'], '[REDACTED]');
      expect(items[1], 'Bearer [REDACTED]');
    });

    test('safe context serialization does not throw on non-encodable objects', () {
      final entry = LogEntry(
        timestamp: DateTime.utc(2026, 1, 1),
        level: LogLevel.info,
        category: LogCategory.system,
        message: 'Non-encodable test',
        context: {'custom': DateTime(2026, 1, 1)},
      );

      expect(() => entry.toString(), returnsNormally);
      expect(entry.toString(), contains('2026-01-01'));
    });

    test('maintains maximum buffer limit without leaking memory', () {
      for (int i = 0; i < 250; i++) {
        NimmyLogger.debug('Log message #$i');
      }

      expect(NimmyLogger.recentLogs.length, NimmyLogger.maxRecentLogs);
      expect(NimmyLogger.recentLogs.last.message, 'Log message #249');
    });
  });
}
