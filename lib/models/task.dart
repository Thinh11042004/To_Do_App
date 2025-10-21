import 'package:flutter/material.dart';

enum TaskCategory { none, work, personal, favorites, birthday }

enum RepeatRule { none, hourly, daily, weekly, monthly }

class SubTask {
  String title;
  bool done;
  SubTask({required this.title, this.done = false});
}

class Task {
  String id;
  String title;
  TaskCategory category;
  String? customCategoryId;
  DateTime? dueDate;
  TimeOfDay? timeOfDay;
  Duration? reminderBefore; // ví dụ: 5 phút trước
  RepeatRule repeat;
  bool done;
  bool favorite;
  List<SubTask> subtasks;
  List<String> tags;
  String? notes;
  DateTime createdAt;
  DateTime updatedAt;

  Task({
    required this.id,
    required this.title,
    this.category = TaskCategory.work,
    this.customCategoryId,
    this.dueDate,
    this.timeOfDay,
    this.reminderBefore,
    this.repeat = RepeatRule.none,
    this.done = false,
    this.favorite = false,
    List<SubTask>? subtasks,
    List<String>? tags,
    this.notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : subtasks = (subtasks ?? []).map((s) => SubTask(title: s.title, done: s.done)).toList(),
        tags = List<String>.from(tags ?? const []),
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? createdAt ?? DateTime.now();

    Task copyWith({
    String? id,
    String? title,
    TaskCategory? category,
    String? customCategoryId,
    DateTime? dueDate,
    TimeOfDay? timeOfDay,
    Duration? reminderBefore,
    RepeatRule? repeat,
    bool? done,
    bool? favorite,
    List<SubTask>? subtasks,
    List<String>? tags,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Task(
      id: id ?? this.id,
      title: title ?? this.title,
      category: category ?? this.category,
      customCategoryId: customCategoryId ?? this.customCategoryId,
      dueDate: dueDate ?? this.dueDate,
      timeOfDay: timeOfDay ?? this.timeOfDay,
      reminderBefore: reminderBefore ?? this.reminderBefore,
      repeat: repeat ?? this.repeat,
      done: done ?? this.done,
      favorite: favorite ?? this.favorite,
      subtasks: (subtasks ?? this.subtasks)
          .map((s) => SubTask(title: s.title, done: s.done))
          .toList(),
      tags: List<String>.from(tags ?? this.tags),
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Task clone() => copyWith();
}

String categoryLabel(TaskCategory c) {
  switch (c) {
    case TaskCategory.none: return 'không có thể loại';
    case TaskCategory.work: return 'Công việc';
    case TaskCategory.personal: return 'Cá nhân';
    case TaskCategory.favorites: return 'Danh sách yêu thích';
    case TaskCategory.birthday: return 'Ngày sinh nhật';
  }
}
