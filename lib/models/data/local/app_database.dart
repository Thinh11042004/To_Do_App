// Drift (SQLite) database for Tasks
import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

part 'app_database.g.dart';

class Tasks extends Table {
  IntColumn get id => integer().autoIncrement()();

  TextColumn get title => text()();
  TextColumn get notes => text().nullable()();

  // Lưu DateTime dạng epoch millis
  IntColumn get dueAt => integer().nullable()();
  IntColumn get remindAt => integer().nullable()();

  // todo | doing | done
  TextColumn get status => text().withDefault(const Constant('todo'))();

  // low | normal | high | urgent
  TextColumn get priority => text().withDefault(const Constant('normal'))();

  TextColumn get categoryId => text().nullable()();

  // ["work","school"] dạng JSON chuỗi
  TextColumn get tagsJson => text().withDefault(const Constant('[]'))();

  IntColumn get createdAt => integer()(); // epoch millis
  IntColumn get updatedAt => integer()();
}

// Data class do Drift sinh ra có tên số ít: Task
typedef TaskRow = Task;

@DriftAccessor(tables: [Tasks])
class TaskDao extends DatabaseAccessor<AppDatabase> with _$TaskDaoMixin {
  TaskDao(AppDatabase db) : super(db);

  Future<int> insertTask({
    required String title,
    String? notes,
    DateTime? dueAt,
    DateTime? remindAt,
    String status = 'todo',
    String priority = 'normal',
    String? categoryId,
    List<String> tags = const [],
  }) {
    final now = DateTime.now().millisecondsSinceEpoch;
    return into(tasks).insert(
      TasksCompanion.insert(
        title: title,
        notes: Value(notes),
        dueAt: Value(dueAt?.millisecondsSinceEpoch),
        remindAt: Value(remindAt?.millisecondsSinceEpoch),
        status: Value(status),
        priority: Value(priority),
        categoryId: Value(categoryId),
        tagsJson: Value(jsonEncode(tags)),
        createdAt: now,
        updatedAt: now,
      ),
    );
  }

  Future<void> updateTask(
    int id, {
    String? title,
    String? notes,
    DateTime? dueAt,
    DateTime? remindAt,
    String? status,
    String? priority,
    String? categoryId,
    List<String>? tags,
  }) {
    final now = DateTime.now().millisecondsSinceEpoch;
    return (update(tasks)..where((t) => t.id.equals(id))).write(
      TasksCompanion(
        title: title != null ? Value(title) : const Value.absent(),
        notes: notes != null ? Value(notes) : const Value.absent(),
        dueAt: dueAt != null
            ? Value(dueAt.millisecondsSinceEpoch)
            : const Value.absent(),
        remindAt: remindAt != null
            ? Value(remindAt.millisecondsSinceEpoch)
            : const Value.absent(),
        status: status != null ? Value(status) : const Value.absent(),
        priority: priority != null ? Value(priority) : const Value.absent(),
        categoryId: categoryId != null
            ? Value(categoryId)
            : const Value.absent(),
        tagsJson: tags != null ? Value(jsonEncode(tags)) : const Value.absent(),
        updatedAt: Value(now),
      ),
    );
  }

  Future<void> deleteTask(int id) =>
      (delete(tasks)..where((t) => t.id.equals(id))).go();

  // Stream để bind UI
  Stream<List<TaskRow>> watchAll({int limit = 500}) {
    final q = (select(tasks)
      ..orderBy([
        (t) => OrderingTerm(expression: t.dueAt, mode: OrderingMode.asc),
        (t) => OrderingTerm(expression: t.createdAt, mode: OrderingMode.desc),
      ])
      ..limit(limit));
    return q.watch();
  }

  Future<List<TaskRow>> getAllOnce() => select(tasks).get();
}

@DriftDatabase(tables: [Tasks], daos: [TaskDao])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  // Tăng version để áp dụng tạo index cho DB đã tồn tại
  @override
  int get schemaVersion => 2; // giữ v2

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) async {
      await m.createAll();
      // Tạo INDEX sau khi tạo bảng (dùng SQL thuần)
      await customStatement(
        'CREATE INDEX IF NOT EXISTS idx_tasks_due_at ON tasks(due_at)',
      );
      await customStatement(
        'CREATE INDEX IF NOT EXISTS idx_tasks_status ON tasks(status)',
      );
      await customStatement(
        'CREATE INDEX IF NOT EXISTS idx_tasks_priority ON tasks(priority)',
      );
    },
    onUpgrade: (m, from, to) async {
      if (from < 2) {
        await customStatement(
          'CREATE INDEX IF NOT EXISTS idx_tasks_due_at ON tasks(due_at)',
        );
        await customStatement(
          'CREATE INDEX IF NOT EXISTS idx_tasks_status ON tasks(status)',
        );
        await customStatement(
          'CREATE INDEX IF NOT EXISTS idx_tasks_priority ON tasks(priority)',
        );
      }
    },
  );
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File(p.join(dir.path, 'todo_app.db'));
    return NativeDatabase.createInBackground(file);
  });
}
