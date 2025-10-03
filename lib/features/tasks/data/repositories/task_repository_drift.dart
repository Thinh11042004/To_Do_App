// AUTO-ADDED: Drift-backed repository implementation
import 'dart:convert';
import '../../domain/entities/task_entity.dart';
import '../local/app_database.dart';
import 'task_repository.dart';

class TaskRepositoryDrift implements TaskRepository {
  final AppDatabase db;
  final TaskDao dao;
  TaskRepositoryDrift(this.db) : dao = TaskDao(db);

  static List<String> _decodeTags(String s) {
    try {
      return (jsonDecode(s) as List).map((e) => e.toString()).toList();
    } catch (_) {
      return const [];
    }
  }

  //TaskEntity _mapRow(TasksData r) => TaskEntity(
  TaskEntity _mapRow(Task r) => TaskEntity(
    id: r.id,
    title: r.title,
    notes: r.notes,
    dueAt: r.dueAt != null
        ? DateTime.fromMillisecondsSinceEpoch(r.dueAt!)
        : null,
    remindAt: r.remindAt != null
        ? DateTime.fromMillisecondsSinceEpoch(r.remindAt!)
        : null,
    status: r.status,
    priority: r.priority,
    categoryId: r.categoryId,
    tags: _decodeTags(r.tagsJson),
    createdAt: DateTime.fromMillisecondsSinceEpoch(r.createdAt),
    updatedAt: DateTime.fromMillisecondsSinceEpoch(r.updatedAt),
  );

  @override
  Stream<List<TaskEntity>> watchAll({int limit = 500}) =>
      dao.watchAll(limit: limit).map((rows) => rows.map(_mapRow).toList());

  @override
  Future<List<TaskEntity>> getAllOnce() async =>
      (await dao.getAllOnce()).map(_mapRow).toList();

  @override
  Future<int> add(TaskEntity t) => dao.insertTask(
    title: t.title,
    notes: t.notes,
    dueAt: t.dueAt,
    remindAt: t.remindAt,
    status: t.status,
    priority: t.priority,
    categoryId: t.categoryId,
    tags: t.tags,
  );

  @override
  Future<void> update(TaskEntity t) {
    if (t.id == null) {
      throw StateError('Cannot update task without id');
    }
    return dao.updateTask(
      t.id!,
      title: t.title,
      notes: t.notes,
      dueAt: t.dueAt,
      remindAt: t.remindAt,
      status: t.status,
      priority: t.priority,
      categoryId: t.categoryId,
      tags: t.tags,
    );
  }

  @override
  Future<void> delete(int id) => dao.deleteTask(id);
}
