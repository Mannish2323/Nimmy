import 'reminder.dart';

enum AuditStatus { proposed, confirmed, executed, failed, cancelled }

class AuditEvent {
  const AuditEvent({
    required this.id,
    required this.userId,
    required this.actionType,
    required this.toolName,
    required this.requestId,
    required this.source,
    required this.status,
    required this.createdAt,
    this.executedAt,
    this.metadata = const {},
    this.errorCode,
  });

  final String id;
  final String userId;
  final String actionType;
  final String toolName;
  final String requestId;
  final InteractionSource source;
  final AuditStatus status;
  final DateTime createdAt;
  final DateTime? executedAt;
  final Map<String, dynamic> metadata;
  final String? errorCode;

  Map<String, dynamic> toJson() => {
        'id': id,
        'user_id': userId,
        'action_type': actionType,
        'tool_name': toolName,
        'request_id': requestId,
        'source': source.name,
        'status': status.name,
        'created_at': createdAt.toUtc().toIso8601String(),
        'executed_at': executedAt?.toUtc().toIso8601String(),
        'metadata': metadata,
        'error_code': errorCode,
      };

  factory AuditEvent.fromJson(Map<String, dynamic> json) {
    return AuditEvent(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      actionType: json['action_type'] as String,
      toolName: json['tool_name'] as String,
      requestId: json['request_id'] as String,
      source: InteractionSource.values.byName(json['source'] as String),
      status: AuditStatus.values.byName(json['status'] as String),
      createdAt: DateTime.parse(json['created_at'] as String),
      executedAt: json['executed_at'] == null
          ? null
          : DateTime.parse(json['executed_at'] as String),
      metadata: Map<String, dynamic>.from(
        json['metadata'] as Map? ?? const <String, dynamic>{},
      ),
      errorCode: json['error_code'] as String?,
    );
  }
}
