import 'dart:convert';
import 'package:flutter/foundation.dart';

enum LogLevel {
  debug,
  info,
  warn,
  error;

  int get priority => switch (this) {
        debug => 0,
        info => 1,
        warn => 2,
        error => 3,
      };
}

enum LogCategory {
  system,
  ai,
  tool,
  database,
  sync,
  voice,
  ui,
  security,
}

class LogEntry {
  const LogEntry({
    required this.timestamp,
    required this.level,
    required this.category,
    required this.message,
    this.context,
    this.error,
    this.stackTrace,
  });

  final DateTime timestamp;
  final LogLevel level;
  final LogCategory category;
  final String message;
  final Map<String, dynamic>? context;
  final Object? error;
  final StackTrace? stackTrace;

  Map<String, dynamic> toJson() => {
        'timestamp': timestamp.toIso8601String(),
        'level': level.name.toUpperCase(),
        'category': category.name,
        'message': message,
        if (context != null && context!.isNotEmpty) 'context': context,
        if (error != null) 'error': error.toString(),
        if (stackTrace != null) 'stackTrace': stackTrace.toString(),
      };

  @override
  String toString() {
    final buffer = StringBuffer()
      ..write('[${timestamp.toIso8601String()}] ')
      ..write('[${level.name.toUpperCase()}] ')
      ..write('[${category.name}] ')
      ..write(message);
    if (context != null && context!.isNotEmpty) {
      String serializedContext;
      try {
        serializedContext = jsonEncode(context, toEncodable: (v) => v.toString());
      } catch (_) {
        serializedContext = context.toString();
      }
      buffer.write(' | context: $serializedContext');
    }
    if (error != null) {
      buffer.write(' | error: $error');
    }
    return buffer.toString();
  }
}

/// Production-grade structured logging for NIMMY.
/// Automatically redacts sensitive tokens, keys, passwords, and authorization headers.
class NimmyLogger {
  NimmyLogger._();

  static LogLevel minLevel = kReleaseMode ? LogLevel.info : LogLevel.debug;

  static final List<LogEntry> _recentLogs = [];
  static const int maxRecentLogs = 200;

  /// Custom log sink callback for testing or telemetry.
  static void Function(LogEntry entry)? onLog;

  static List<LogEntry> get recentLogs => List.unmodifiable(_recentLogs);

  static void clearLogs() {
    _recentLogs.clear();
  }

  // Regex patterns to redact secrets and credentials
  static final _authHeaderRegex = RegExp(r'(Bearer|Basic)\s+[A-Za-z0-9\-._~+/]+=*', caseSensitive: false);
  static final _apiKeyRegex = RegExp(r'(AIza[0-9A-Za-z\-_]{20,}|sbp_[a-zA-Z0-9]{20,}|sk-[a-zA-Z0-9]{20,})');
  static final _passwordJsonRegex = RegExp(
    r'("(?:password|secret|token|api[_-]?key|service[_-]?role)"\s*:\s*")([^"]+)(")',
    caseSensitive: false,
  );
  static final _kvSecretRegex = RegExp(
    r'((?:password|secret|token|apikey|apiKey)\s*[=:]\s*)([^\s,;]+)',
    caseSensitive: false,
  );

  /// Sanitize sensitive data from strings.
  static String sanitize(String text) {
    var sanitized = text;
    sanitized = sanitized.replaceAllMapped(_authHeaderRegex, (m) => '${m[1]} [REDACTED]');
    sanitized = sanitized.replaceAllMapped(_apiKeyRegex, (m) => '[REDACTED_KEY]');
    sanitized = sanitized.replaceAllMapped(_passwordJsonRegex, (m) => '${m[1]}[REDACTED]${m[3]}');
    sanitized = sanitized.replaceAllMapped(_kvSecretRegex, (m) => '${m[1]}[REDACTED]');
    return sanitized;
  }

  static dynamic _sanitizeValue(dynamic value) {
    if (value is String) {
      return sanitize(value);
    } else if (value is Map) {
      final clean = <String, dynamic>{};
      for (final entry in value.entries) {
        final keyStr = entry.key.toString();
        final keyLower = keyStr.toLowerCase();
        if (keyLower.contains('password') ||
            keyLower.contains('secret') ||
            keyLower.contains('token') ||
            keyLower.contains('key') ||
            keyLower.contains('auth')) {
          clean[keyStr] = '[REDACTED]';
        } else {
          clean[keyStr] = _sanitizeValue(entry.value);
        }
      }
      return clean;
    } else if (value is Iterable) {
      return value.map(_sanitizeValue).toList();
    }
    return value;
  }

  static Map<String, dynamic>? _sanitizeContext(Map<String, dynamic>? ctx) {
    if (ctx == null) return null;
    return _sanitizeValue(ctx) as Map<String, dynamic>;
  }

  static void log(
    LogLevel level,
    String message, {
    LogCategory category = LogCategory.system,
    Map<String, dynamic>? context,
    Object? error,
    StackTrace? stackTrace,
  }) {
    if (level.priority < minLevel.priority) return;

    final sanitizedMessage = sanitize(message);
    final sanitizedContext = _sanitizeContext(context);
    final sanitizedError = error != null ? sanitize(error.toString()) : null;

    final entry = LogEntry(
      timestamp: DateTime.now().toUtc(),
      level: level,
      category: category,
      message: sanitizedMessage,
      context: sanitizedContext,
      error: sanitizedError,
      stackTrace: stackTrace,
    );

    _recentLogs.add(entry);
    if (_recentLogs.length > maxRecentLogs) {
      _recentLogs.removeAt(0);
    }

    if (onLog != null) {
      onLog!(entry);
    } else {
      debugPrint(entry.toString());
    }
  }

  static void debug(
    String message, {
    LogCategory category = LogCategory.system,
    Map<String, dynamic>? context,
  }) {
    log(LogLevel.debug, message, category: category, context: context);
  }

  static void info(
    String message, {
    LogCategory category = LogCategory.system,
    Map<String, dynamic>? context,
  }) {
    log(LogLevel.info, message, category: category, context: context);
  }

  static void warn(
    String message, {
    LogCategory category = LogCategory.system,
    Map<String, dynamic>? context,
    Object? error,
  }) {
    log(LogLevel.warn, message, category: category, context: context, error: error);
  }

  static void error(
    String message, {
    LogCategory category = LogCategory.system,
    Map<String, dynamic>? context,
    Object? error,
    StackTrace? stackTrace,
  }) {
    log(
      LogLevel.error,
      message,
      category: category,
      context: context,
      error: error,
      stackTrace: stackTrace,
    );
  }
}
