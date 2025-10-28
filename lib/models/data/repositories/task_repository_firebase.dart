import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../domain/entities/task_entity.dart';
import 'task_repository.dart';

class TaskRepositoryFirebase implements TaskRepository {
  TaskRepositoryFirebase(this._firestore);

  final FirebaseFirestore _firestore;
  String? _userId;

  CollectionReference<Map<String, dynamic>> _collection([String? overrideUserId]) {
    final userId = overrideUserId ?? _userId;
    if (userId == null) {
      throw StateError('User ID is required to access tasks');
    }
    return _firestore.collection('users').doc(userId).collection('tasks');
  }

  // Set the current user ID
  void setUserId(String? userId) {
    _userId = userId;
  }

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
      'subtasks': task.subtasks.map((s) => s.toMap()).toList(),
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
      subtasks: (data['subtasks'] as List<dynamic>? ?? const [])
          .map((raw) {
            if (raw is Map<String, dynamic>) {
              return SubTaskEntity.fromMap(raw);
            }
            if (raw is Map) {
              return SubTaskEntity.fromMap(raw.map((key, value) => MapEntry(key.toString(), value)));
            }
            return null;
          })
          .whereType<SubTaskEntity>()
          .toList(),
      createdAt: (created ?? Timestamp.now()).toDate().toLocal(),
      updatedAt: (updated ?? Timestamp.now()).toDate().toLocal(),
    );
  }

  int _generateId() => DateTime.now().millisecondsSinceEpoch;

  @override
  Future<int> add(TaskEntity task) async {
    // Ensure we have a user before adding
    if (_userId == null) {
      await Future.delayed(const Duration(milliseconds: 100)); // Wait for auth state listener
      final auth = FirebaseAuth.instance;
      final user = auth.currentUser;
      if (user == null) {
        final userStream = auth.authStateChanges().firstWhere((u) => u != null);
        final user = await userStream;
        _userId = user!.uid;
      } else {
        _userId = user.uid;
      }
    }
    
    final id = task.id ?? _generateId();
    final doc = _collection().doc(id.toString());
    await doc.set({
      'id': id,
      'userId': _userId,
      ..._toMap(task.copyWith(id: id)),
    });
    return id;
  }

  @override
  Future<void> delete(int id) async {
    // Ensure we have a user before deleting
    if (_userId == null) {
      final user = await FirebaseAuth.instance.authStateChanges().firstWhere((u) => u != null);
      _userId = user!.uid;
    }
    
    await _collection().doc(id.toString()).delete();
  }

  @override
  Future<List<TaskEntity>> getAllOnce() async {
    if (_userId == null) {
      final user = await FirebaseAuth.instance.authStateChanges().firstWhere((u) => u != null);
      _userId = user!.uid;
    }
    final snapshot = await _collection().orderBy('dueAt', descending: false).limit(_defaultLimit).get();
    return snapshot.docs.map(_fromDoc).toList();
  }

  @override
  Future<void> update(TaskEntity task) async {
    // Ensure we have a user before updating
    if (_userId == null) {
      final user = await FirebaseAuth.instance.authStateChanges().firstWhere((u) => u != null);
      _userId = user!.uid;
    }
    
    final id = task.id ?? _generateId();
    await _collection().doc(id.toString()).set(
          {
            'id': id,
            'userId': _userId,
            ..._toMap(task.copyWith(id: id)),
          },
          SetOptions(merge: true),
        );
  }

  @override
  Stream<List<TaskEntity>> watchAll({int limit = _defaultLimit}) {
    if (_userId == null) {
      // Wait for first available user (anonymous or signed-in), then stream tasks
      return FirebaseAuth.instance
          .authStateChanges()
          .where((u) => u != null)
          .take(1)
          .asyncExpand((user) {
            _userId = user!.uid;
            return _collection()
                .orderBy('dueAt', descending: false)
                .limit(limit)
                .snapshots()
                .map((snapshot) => snapshot.docs.map(_fromDoc).toList());
          });
    }
    return _collection()
        .orderBy('dueAt', descending: false)
        .limit(limit)
        .snapshots()
        .map((snapshot) => snapshot.docs.map(_fromDoc).toList());
  }
}