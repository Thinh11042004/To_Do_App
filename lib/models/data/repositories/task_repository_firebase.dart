import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/task_entity.dart';
import 'task_repository.dart';

class TaskRepositoryFirebase implements TaskRepository {
  TaskRepositoryFirebase(FirebaseFirestore firestore)
      : _firestore = firestore,
        _collection = firestore.collection('tasks');

  final FirebaseFirestore _firestore;
  final CollectionReference<Map<String, dynamic>> _collection;

  static const _defaultLimit = 500;

  Map<String, dynamic> _toMap(TaskEntity task) {
    return {
      'title': task.title,
      'notes': task.notes,
      'dueAt': task.dueAt == null ? null : Timestamp.fromDate(task.dueAt!.toUtc()),
      'remindAt': task.remindAt == null ? null : Timestamp.fromDate(task.remindAt!.toUtc()),
      'status': task.status,
      'priority': task.priority,
      'categoryId': task.categoryId,
      'tags': task.tags,
      'favorite': task.favorite,
      'createdAt': Timestamp.fromDate(task.createdAt.toUtc()),
      'updatedAt': Timestamp.fromDate(task.updatedAt.toUtc()),
    };
  }

  TaskEntity _fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? <String, dynamic>{};
    final Timestamp? due = data['dueAt'] as Timestamp?;
    final Timestamp? remind = data['remindAt'] as Timestamp?;
    final Timestamp? created = data['createdAt'] as Timestamp?;
    final Timestamp? updated = data['updatedAt'] as Timestamp?;

    return TaskEntity(
      id: int.tryParse(data['id']?.toString() ?? doc.id),
      title: data['title'] as String? ?? 'Không có tiêu đề',
      notes: data['notes'] as String?,
      dueAt: due?.toDate().toLocal(),
      remindAt: remind?.toDate().toLocal(),
      status: data['status'] as String? ?? 'todo',
      priority: data['priority'] as String? ?? 'normal',
      categoryId: data['categoryId'] as String?,
      tags: (data['tags'] as List<dynamic>? ?? const []).cast<String>(),
      favorite: data['favorite'] as bool? ?? false,
      createdAt: (created ?? Timestamp.now()).toDate().toLocal(),
      updatedAt: (updated ?? Timestamp.now()).toDate().toLocal(),
    );
  }

  int _generateId() => DateTime.now().millisecondsSinceEpoch;

  @override
  Future<int> add(TaskEntity task) async {
    final id = task.id ?? _generateId();
    final doc = _collection.doc(id.toString());
    await doc.set({
      'id': id,
      ..._toMap(task.copyWith(id: id)),
    });
    return id;
  }

  @override
  Future<void> delete(int id) async {
    await _collection.doc(id.toString()).delete();
  }

  @override
  Future<List<TaskEntity>> getAllOnce() async {
    final snapshot = await _collection.orderBy('dueAt', descending: false).limit(_defaultLimit).get();
    return snapshot.docs.map(_fromDoc).toList();
  }

  @override
  Future<void> update(TaskEntity task) async {
    final id = task.id ?? _generateId();
    await _collection.doc(id.toString()).set(
          {
            'id': id,
            ..._toMap(task.copyWith(id: id)),
          },
          SetOptions(merge: true),
        );
  }

  @override
  Stream<List<TaskEntity>> watchAll({int limit = _defaultLimit}) {
    return _collection
        .orderBy('dueAt', descending: false)
        .limit(limit)
        .snapshots()
        .map((snapshot) => snapshot.docs.map(_fromDoc).toList());
  }
}