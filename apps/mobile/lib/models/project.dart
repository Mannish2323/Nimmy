class NimmyProject {
  const NimmyProject({
    required this.id,
    required this.userId,
    required this.title,
    this.description,
    this.color = '#A855F7',
    this.icon,
    this.isArchived = false,
    this.sortOrder = 0,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String userId;
  final String title;
  final String? description;
  final String color;
  final String? icon;
  final bool isArchived;
  final int sortOrder;
  final DateTime createdAt;
  final DateTime updatedAt;

  NimmyProject copyWith({
    String? id,
    String? userId,
    String? title,
    String? description,
    String? color,
    String? icon,
    bool? isArchived,
    int? sortOrder,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return NimmyProject(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      description: description ?? this.description,
      color: color ?? this.color,
      icon: icon ?? this.icon,
      isArchived: isArchived ?? this.isArchived,
      sortOrder: sortOrder ?? this.sortOrder,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'title': title,
      'description': description,
      'color': color,
      'icon': icon,
      'is_archived': isArchived,
      'sort_order': sortOrder,
      'created_at': createdAt.toUtc().toIso8601String(),
      'updated_at': updatedAt.toUtc().toIso8601String(),
    };
  }

  factory NimmyProject.fromJson(Map<String, dynamic> json) {
    return NimmyProject(
      id: json['id'] as String,
      userId: json['user_id'] as String? ?? 'local-user',
      title: json['title'] as String,
      description: json['description'] as String?,
      color: json['color'] as String? ?? '#A855F7',
      icon: json['icon'] as String?,
      isArchived: json['is_archived'] as bool? ?? false,
      sortOrder: (json['sort_order'] as num?)?.toInt() ?? 0,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  @override
  String toString() => 'NimmyProject(id: $id, title: $title, color: $color)';
}
