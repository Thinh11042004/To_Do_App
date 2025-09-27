import 'package:flutter/material.dart';
import '../models/task.dart';

class CategoryManagerScreen extends StatefulWidget {
  final List<Task> tasks;
  const CategoryManagerScreen({super.key, required this.tasks});

  @override
  State<CategoryManagerScreen> createState() => _CategoryManagerScreenState();
}

class _CategoryManagerScreenState extends State<CategoryManagerScreen> {
  final List<String> _custom = []; // danh mục người dùng tạo

  int _count(TaskCategory c) =>
      widget.tasks.where((t) => t.category == c).length;

  @override
  Widget build(BuildContext context) {
    final rows = <Widget>[
      _row('Công việc', _count(TaskCategory.work)),
      _row('Cá nhân', _count(TaskCategory.personal)),
      _row('Danh sách yêu thích', widget.tasks.where((t) => t.favorite).length),
      _row('Ngày sinh nhật', 0),
      for (final name in _custom) _row(name, 0, custom: true),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Quản lý Danh mục'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            color: Theme.of(context).colorScheme.primaryContainer.withOpacity(.4),
            child: const Text('Các danh mục hiển thị trên trang chủ'),
          ),
          ...rows,
          const SizedBox(height: 8),
          ListTile(
            leading: const Icon(Icons.add, color: Colors.blue),
            title: const Text('Tạo mới', style: TextStyle(color: Colors.blue)),
            onTap: _createCategory,
          ),
          const SizedBox(height: 16),
          const Center(child: Text('Nhấn và kéo để sắp xếp lại')),
        ],
      ),
    );
  }

  Widget _row(String name, int count, {bool custom = false}) {
    return ListTile(
      leading: const Icon(Icons.circle, size: 12, color: Colors.blue),
      title: Text(name),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('$count'),
          const SizedBox(width: 8),
          PopupMenuButton(
            itemBuilder: (ctx) => [
              const PopupMenuItem(value: 'edit', child: Text('Chỉnh sửa')),
              const PopupMenuItem(value: 'hide', child: Text('Ẩn giấu')),
              const PopupMenuItem(value: 'delete', child: Text('Xoá')),
            ],
            onSelected: (v) {
              if (v == 'delete' && custom) {
                setState(() => _custom.remove(name));
              }
            },
          ),
        ],
      ),
    );
  }

  Future<void> _createCategory() async {
    final ctl = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Tạo danh mục'),
        content: TextField(
          controller: ctl,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'Tên danh mục'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('HUỶ')),
          FilledButton(onPressed: () => Navigator.pop(context, ctl.text.trim()), child: const Text('TẠO')),
        ],
      ),
    );
    if (name != null && name.isNotEmpty) {
      setState(() => _custom.add(name));
    }
  }
}
