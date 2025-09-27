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
  DateTime? dueDate;
  TimeOfDay? timeOfDay;
  Duration? reminderBefore; // ví dụ: 5 phút trước
  RepeatRule repeat;
  bool done;
  bool favorite;
  List<SubTask> subtasks;

  Task({
    required this.id,
    required this.title,
    this.category = TaskCategory.work,
    this.dueDate,
    this.timeOfDay,
    this.reminderBefore,
    this.repeat = RepeatRule.none,
    this.done = false,
    this.favorite = false,
    List<SubTask>? subtasks,
  }) : subtasks = subtasks ?? [];
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
