import '../../models/task.dart';
import '../../models/domain/entities/task_entity.dart';
import '../../models/data/repositories/task_repository.dart';
import '../../services/db_service.dart';
import '../../services/notification_service.dart';
import '../../services/category_store.dart';
import 'package:flutter/material.dart';
import 'dart:async';

class TaskListController {
  final TaskRepository repo = DbService.tasks;
  final List<Task> items = [];
  StreamSubscription<List<TaskEntity>>? subscription;
  final CategoryStore categoryStore = CategoryStore.instance;

  TaskCategory? categoryFromId(String? id) {
    switch (id) {
      case 'work':
        return TaskCategory.work;
      case 'personal':
        return TaskCategory.personal;
      case 'favorite':
        return TaskCategory.favorites;
      case 'birthday':
        return TaskCategory.birthday;
      case 'none':
        return TaskCategory.none;
      default:
        return null;
    }
  }

  String? categoryToId(TaskCategory category) {
    switch (category) {
      case TaskCategory.work:
        return 'work';
      case TaskCategory.personal:
        return 'personal';
      case TaskCategory.favorites:
        return 'favorite';
      case TaskCategory.birthday:
        return 'birthday';
      case TaskCategory.none:
        return null;
    }
  }

  Task fromEntity(TaskEntity e) {
    final due = e.dueAt?.toLocal();
    Duration? remindBefore;
    if (e.remindAt != null && due != null) {
      final diff = due.millisecondsSinceEpoch - e.remindAt!.millisecondsSinceEpoch;
      if (diff > 0) remindBefore = Duration(milliseconds: diff);
    }
    TimeOfDay? timeOfDay;
    if (due != null && (due.hour != 0 || due.minute != 0)) {
      timeOfDay = TimeOfDay(hour: due.hour, minute: due.minute);
    }
    final categoryId = e.categoryId;
    final TaskCategory? category = categoryFromId(categoryId);
    final String? customCategoryId = category == null ? categoryId : null;
    return Task(
      id: (e.id ?? 0).toString(),
      title: e.title,
      category: category ?? TaskCategory.none,
      customCategoryId: customCategoryId,
      dueDate: due,
      timeOfDay: timeOfDay,
      reminderBefore: remindBefore,
      repeat: RepeatRule.none,
      subtasks: e.subtasks
          .map((s) => SubTask(title: s.title, done: s.done))
          .toList(),
      done: e.status == 'done',
      favorite: e.favorite,
      notes: e.notes,
      createdAt: e.createdAt.toLocal(),
      updatedAt: e.updatedAt.toLocal(),
    );
  }

  TaskEntity toEntity(Task t) {
    DateTime? due;
    if (t.dueDate != null && t.timeOfDay != null) {
      due = DateTime(
        t.dueDate!.year,
        t.dueDate!.month,
        t.dueDate!.day,
        t.timeOfDay!.hour,
        t.timeOfDay!.minute,
      );
    } else {
      due = t.dueDate;
    }
    final int? remindAtMs = (due != null && t.reminderBefore != null)
        ? due.millisecondsSinceEpoch - t.reminderBefore!.inMilliseconds
        : null;
    return TaskEntity(
      id: int.tryParse(t.id),
      title: t.title,
      notes: t.notes,
      dueAt: due,
      remindAt: remindAtMs != null ? DateTime.fromMillisecondsSinceEpoch(remindAtMs) : null,
      status: t.done ? 'done' : 'todo',
      priority: 'normal',
      categoryId: t.customCategoryId ?? categoryToId(t.category),
      tags: const [],
      subtasks: t.subtasks
          .map((s) => SubTaskEntity(title: s.title, done: s.done))
          .toList(),
      favorite: t.favorite,
      createdAt: t.createdAt.toUtc(),
      updatedAt: t.updatedAt.toUtc(),
    );
  }
  Future<int> addTask(Task newTask) async {
    final now = DateTime.now();
    newTask
      ..createdAt = now
      ..updatedAt = now;
    final entity = toEntity(newTask);
    final id = await repo.add(entity);
    newTask.id = id.toString();
    if (!newTask.done) {
      await NotificationService.instance.scheduleForTask(entity.copyWith(id: id));
    }
    return id;
  }

  Future<void> updateTask(Task t) async {
    t.updatedAt = DateTime.now();
    final id = int.tryParse(t.id);
    if (id == null) return;
    final entity = toEntity(t).copyWith(id: id);
    await repo.update(entity);
    if (t.done) {
      await NotificationService.instance.cancelReminder(id);
    } else {
      await NotificationService.instance.scheduleForTask(entity);
    }
  }

  Future<void> deleteTaskById(String? id) async {
    final intId = int.tryParse(id ?? '');
    if (intId != null) {
      await repo.delete(intId);
      await NotificationService.instance.cancelReminder(intId);
    }
  }
}
