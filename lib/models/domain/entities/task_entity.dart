// AUTO-ADDED: Domain entity for a Task
class TaskEntity {
  final int? id;
  final String title;
  final String? notes;
  final DateTime? dueAt;
  final DateTime? remindAt;
  final String status;   // todo|doing|done
  final String priority; // low|normal|high|urgent
  final String? categoryId;
  final List<String> tags;
  final bool favorite;
  final DateTime createdAt;
  final DateTime updatedAt;

  const TaskEntity({
    this.id,
    required this.title,
    this.notes,
    this.dueAt,
    this.remindAt,
    this.status = 'todo',
    this.priority = 'normal',
    this.categoryId,
    this.tags = const [],
    this.favorite = false,
    required this.createdAt,
    required this.updatedAt,
  });

  TaskEntity copyWith({
    int? id,
    String? title,
    String? notes,
    DateTime? dueAt,
    DateTime? remindAt,
    String? status,
    String? priority,
    String? categoryId,
    List<String>? tags,
    bool? favorite,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return TaskEntity(
      id: id ?? this.id,
      title: title ?? this.title,
      notes: notes ?? this.notes,
      dueAt: dueAt ?? this.dueAt,
      remindAt: remindAt ?? this.remindAt,
      status: status ?? this.status,
      priority: priority ?? this.priority,
      categoryId: categoryId ?? this.categoryId,
      tags: tags ?? this.tags,
      favorite: favorite ?? this.favorite,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
