import 'dart:async';

import 'package:flutter/material.dart';

import '../../models/task.dart';
import '../../services/category_store.dart';

class CategoryManagerScreen extends StatefulWidget {
  final List<Task> tasks;
  const CategoryManagerScreen({super.key, required this.tasks});

  @override
  State<CategoryManagerScreen> createState() => _CategoryManagerScreenState();
}

class _CategoryManagerScreenState extends State<CategoryManagerScreen> {
  final CategoryStore _store = CategoryStore.instance;

  @override
  void initState() {
    super.initState();
    unawaited(_store.ensureLoaded());
  }

  int _countTasks(CategoryConfig cfg) {
    if (cfg.isSystem) {
      final system = _store.resolveSystem(cfg.id);
      return widget.tasks.where((t) {
        if (t.customCategoryId != null) return false;
        return t.category == (system ?? TaskCategory.none);
      }).length;
    }
    return widget.tasks.where((t) => t.customCategoryId == cfg.id).length;
  }

  Future<void> _createCategory() async {
    final name = await _promptForName('Tạo danh mục mới');
    if (name == null || name.isEmpty) return;
    await _store.createCustom(name: name);
  }

  Future<void> _rename(CategoryConfig cfg) async {
    final name = await _promptForName('Đổi tên danh mục', initial: cfg.label);
    if (name == null || name.isEmpty || name == cfg.label) return;
    await _store.rename(cfg.id, name);
  }

  Future<String?> _promptForName(String title, {String? initial}) {
    final controller = TextEditingController(text: initial);
    return showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'Nhập tên danh mục'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('HUỶ')),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('LƯU'),
          ),
        ],
      ),
    );
  }

  Future<void> _toggleVisibility(CategoryConfig cfg) async {
    await _store.setVisibility(cfg.id, !cfg.visible);
  }

  Future<void> _delete(CategoryConfig cfg) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Xoá danh mục'),
        content: Text('Bạn có chắc muốn xoá "${cfg.label}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('HUỶ')),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.error),
            child: const Text('XOÁ'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await _store.delete(cfg.id);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Scaffold(
      backgroundColor: scheme.surface,
      appBar: AppBar(
        title: const Text('Quản lý Danh mục'),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _createCategory,
        icon: const Icon(Icons.add),
        label: const Text('Tạo danh mục'),
      ),
      body: ValueListenableBuilder<List<CategoryConfig>>(
        valueListenable: _store.listenable,
        builder: (context, categories, _) {
          if (categories.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }
          return Column(
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [scheme.primary.withOpacity(.82), scheme.secondary.withOpacity(.75)],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                ),
                child: Text(
                  'Các danh mục hiển thị trên trang chủ',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: scheme.onPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Expanded(
                child: ReorderableListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  itemCount: categories.length,
                  buildDefaultDragHandles: false,
                  onReorder: (oldIndex, newIndex) => _store.reorder(oldIndex, newIndex),
                  proxyDecorator: (child, index, animation) => Material(
                    elevation: 6,
                    borderRadius: BorderRadius.circular(16),
                    child: child,
                  ),
                  itemBuilder: (context, index) {
                    final cfg = categories[index];
                    final count = _countTasks(cfg);
                    return _CategoryTile(
                      index: index,
                      key: ValueKey(cfg.id),
                      config: cfg,
                      count: count,
                      onRename: () => _rename(cfg),
                      onToggleVisibility: () => _toggleVisibility(cfg),
                      onDelete: cfg.isSystem ? null : () => _delete(cfg),
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: scheme.primary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Kéo thả để sắp xếp thứ tự hiển thị. Các danh mục bị ẩn vẫn giữ nhiệm vụ đã gắn trước đó.',
                        style: theme.textTheme.bodySmall,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _CategoryTile extends StatelessWidget {
  const _CategoryTile({
    super.key,
    required this.index,
    required this.config,
    required this.count,
    required this.onRename,
    required this.onToggleVisibility,
    this.onDelete,
  });

  final int index;
  final CategoryConfig config;
  final int count;
  final VoidCallback onRename;
  final VoidCallback onToggleVisibility;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      key: key,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: ListTile(
        leading: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ReorderableDragStartListener(
              index: index,
              child: const Icon(Icons.drag_indicator_rounded),
            ),
            const SizedBox(width: 12),
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: Color(config.color),
                shape: BoxShape.circle,
              ),
            ),
          ],
        ),
        title: Text(config.label),
        subtitle: Text('$count nhiệm vụ'),
        trailing: PopupMenuButton<String>(
          onSelected: (value) {
            switch (value) {
              case 'rename':
                onRename();
                break;
              case 'toggle':
                onToggleVisibility();
                break;
              case 'delete':
                onDelete?.call();
                break;
            }
          },
          itemBuilder: (ctx) => [
            const PopupMenuItem(value: 'rename', child: Text('Đổi tên')),
            PopupMenuItem(
              value: 'toggle',
              child: Text(config.visible ? 'Ẩn khỏi trang chủ' : 'Hiển thị trên trang chủ'),
            ),
            if (onDelete != null)
              PopupMenuItem(
                value: 'delete',
                textStyle: TextStyle(color: scheme.error),
                child: const Text('Xoá'),
              ),
          ],
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    );
  }
}