// AUTO-ADDED: Quick demo screen for SQLite/Drift tasks
import 'package:flutter/material.dart';
import '../features/tasks/data/local/app_database.dart';
import '../features/tasks/data/repositories/task_repository_drift.dart';
import '../features/tasks/domain/entities/task_entity.dart';

class SqliteDemoScreen extends StatefulWidget {
  const SqliteDemoScreen({super.key});

  @override
  State<SqliteDemoScreen> createState() => _SqliteDemoScreenState();
}

class _SqliteDemoScreenState extends State<SqliteDemoScreen> {
  late final AppDatabase _db;
  late final TaskRepositoryDrift _repo;

  final _titleCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _db = AppDatabase();
    _repo = TaskRepositoryDrift(_db);
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _db.close();
    super.dispose();
  }

  Future<void> _addQuick() async {
    final text = _titleCtrl.text.trim().isEmpty
        ? 'Việc mới lúc ${DateTime.now().hour}:${DateTime.now().minute}'
        : _titleCtrl.text.trim();
    final now = DateTime.now();
    await _repo.add(TaskEntity(
      title: text,
      notes: null,
      dueAt: now.add(const Duration(hours: 1)),
      remindAt: null,
      status: 'todo',
      priority: 'normal',
      categoryId: null,
      tags: const [],
      createdAt: now,
      updatedAt: now,
    ));
    _titleCtrl.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('SQLite (Drift) Demo')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _titleCtrl,
                    decoration: const InputDecoration(
                      hintText: 'Nhập tiêu đề công việc...',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _addQuick,
                  child: const Text('Thêm'),
                )
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: StreamBuilder<List<TaskEntity>>(
              stream: _repo.watchAll(),
              builder: (context, snap) {
                if (snap.hasError) {
                  return Center(child: Text('Lỗi: ${snap.error}'));
                }
                if (!snap.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final items = snap.data!;
                if (items.isEmpty) {
                  return const Center(child: Text('Chưa có công việc nào'));
                }
                return ListView.separated(
                  itemCount: items.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (_, i) {
                    final t = items[i];
                    return ListTile(
                      title: Text(t.title),
                      subtitle: Text('${t.priority} • ${t.status}'
                          '${t.dueAt != null ? ' • due ${t.dueAt}' : ''}'),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete),
                        onPressed: () => _repo.delete(t.id!),
                      ),
                      onTap: () =>
                          _repo.update(t.copyWith(status: 'done', updatedAt: DateTime.now())),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
