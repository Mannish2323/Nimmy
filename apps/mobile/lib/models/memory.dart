import 'reminder.dart';

enum MemoryCategory {
  preference,
  goal,
  project,
  person,
  decision,
  reminderContext,
  note,
  other,
}

enum MemoryImportance { low, normal, high }

class NimmyMemory {
  const NimmyMemory({
    required this.id,
    required this.userId,
    required this.requestId,
    required this.content,
    required this.category,
    required this.importance,
    required this.source,
    required this.createdAt,
    required this.updatedAt,
    this.sourceReference,
  });

  final String id;
  final String userId;
  final String requestId;
  final String content;
  final MemoryCategory category;
  final MemoryImportance importance;
  final InteractionSource source;
  final String? sourceReference;
  final DateTime createdAt;
  final DateTime updatedAt;

  String get categoryLabel {
    if (category == MemoryCategory.reminderContext) return 'Reminder context';
    final name = category.name;
    return '${name[0].toUpperCase()}${name.substring(1)}';
  }

  NimmyMemory copyWith({
    String? content,
    MemoryCategory? category,
    MemoryImportance? importance,
    String? sourceReference,
    DateTime? updatedAt,
  }) {
    return NimmyMemory(
      id: id,
      userId: userId,
      requestId: requestId,
      content: content ?? this.content,
      category: category ?? this.category,
      importance: importance ?? this.importance,
      source: source,
      sourceReference: sourceReference ?? this.sourceReference,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'user_id': userId,
        'request_id': requestId,
        'content': content,
        'category': category.name,
        'importance': importance.name,
        'source': source.name,
        'source_reference': sourceReference,
        'created_at': createdAt.toUtc().toIso8601String(),
        'updated_at': updatedAt.toUtc().toIso8601String(),
      };

  factory NimmyMemory.fromJson(Map<String, dynamic> json) {
    return NimmyMemory(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      requestId: json['request_id'] as String,
      content: json['content'] as String,
      category: MemoryCategory.values.byName(json['category'] as String),
      importance:
          MemoryImportance.values.byName(json['importance'] as String),
      source: InteractionSource.values.byName(json['source'] as String),
      sourceReference: json['source_reference'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }
}
