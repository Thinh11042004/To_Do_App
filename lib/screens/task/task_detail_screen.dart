import 'dart:async';

import 'package:flutter/material.dart';

import '../../models/task.dart';
import '../../services/category_store.dart';
import '../../services/pro_manager.dart';
import '../../utils/upgrade_flow.dart';

class TaskDetailScreen extends StatefulWidget {
  const TaskDetailScreen({super.key, required this.task});

  static const routeName = '/task-detail';

  final Task task;

  static PageRoute<Task> route(Task task) {
    return PageRouteBuilder<Task>(
      settings: const RouteSettings(name: routeName),
      transitionDuration: const Duration(milliseconds: 420),
      reverseTransitionDuration: const Duration(milliseconds: 320),
      pageBuilder: (_, __, ___) => TaskDetailScreen(task: task),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final curved = CurvedAnimation(parent: animation, curve: Curves.easeOutCubic);
        final offset = Tween<Offset>(begin: const Offset(0, 0.05), end: Offset.zero)
            .animate(curved);
        return FadeTransition(
          opacity: curved,
          child: SlideTransition(position: offset, child: child),
        );
      },
    );
  }

  @override
  State<TaskDetailScreen> createState() => _TaskDetailScreenState();
}

class _TaskDetailScreenState extends State<TaskDetailScreen> {
  late Task task;
  final _noteCtl = TextEditingController();
  final CategoryStore _categoryStore = CategoryStore.instance;

  @override
  void initState() {
    super.initState();
    task = widget.task.clone();
    _noteCtl.text = task.notes ?? '';
    unawaited(_categoryStore.ensureLoaded());
  }

  @override
  void dispose() {
    _noteCtl.dispose();
    super.dispose();
  }
  // —— pickers tái dùng ——
  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      firstDate: now.subtract(const Duration(days: 0)),
      lastDate: DateTime(now.year + 3),
      initialDate: task.dueDate ?? now,
    );
    if (picked != null) setState(() => task.dueDate = picked);
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: task.timeOfDay ?? TimeOfDay.now(),
    );
    if (picked != null) setState(() => task.timeOfDay = picked);
  }

  Future<void> _pickReminder() async {
    final picked = await showModalBottomSheet<Duration?>(
      context: context,
      showDragHandle: true,
      builder: (_) => SafeArea(
        child: Wrap(
          children: [
            ListTile(title: const Text('Không'), onTap: () => Navigator.pop(context, null)),
            for (final m in [5, 10, 30, 60])
              ListTile(
                title: Text('Nhắc trước $m phút'),
                onTap: () => Navigator.pop(context, Duration(minutes: m)),
              ),
          ],
        ),
      ),
    );
    setState(() => task.reminderBefore = picked);
  }

  Future<void> _pickRepeat() async {
    var temp = task.repeat;
    await showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (ctx) => StatefulBuilder(
        builder: (_, setBtm) => Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Wrap(
                spacing: 8,
                children: RepeatRule.values.map((r) {
                  final label = switch (r) {
                    RepeatRule.none => 'Không',
                    RepeatRule.hourly => 'Hàng giờ',
                    RepeatRule.daily => 'Hằng ngày',
                    RepeatRule.weekly => 'Hằng tuần',
                    RepeatRule.monthly => 'Hằng tháng',
                  };
                  return ChoiceChip(
                    label: Text(label),
                    selected: temp == r,
                    onSelected: (_) => setBtm(() => temp = r),
                  );
                }).toList(),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('HUỶ')),
                  FilledButton(
                    onPressed: () {
                      setState(() => task.repeat = temp);
                      Navigator.pop(ctx);
                    },
                    child: const Text('XONG'),
                  )
                ],
              )
            ],
          ),
        ),
      ),
    );
  }

  // —— Subtasks ——
  Future<void> _addSubtaskDialog() async {
    final ctl = TextEditingController();
    final title = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Thêm nhiệm vụ phụ'),
        content: TextField(
          controller: ctl,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'Nhập nội dung nhiệm vụ phụ'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('HUỶ')),
          FilledButton(onPressed: () => Navigator.pop(context, ctl.text.trim()), child: const Text('THÊM')),
        ],
      ),
    );
    if (title != null && title.isNotEmpty) {
      setState(() => task.subtasks.add(SubTask(title: title)));
    }
  }

  // —— trợ giúp hiển thị ——
  String _dateLabel() {
    final d = task.dueDate;
    if (d == null) return '—';
    final mm = d.month.toString().padLeft(2, '0');
    final dd = d.day.toString().padLeft(2, '0');
    return '${d.year}/$mm/$dd';
  }

  String _timeLabel(TimeOfDay? t) =>
      t == null ? '—' : '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  String _repeatLabel() => switch (task.repeat) {
        RepeatRule.none => 'Không',
        RepeatRule.hourly => 'Hàng giờ',
        RepeatRule.daily => 'Hằng ngày',
        RepeatRule.weekly => 'Hằng tuần',
        RepeatRule.monthly => 'Hằng tháng',
      };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    final categories = _categoryStore.current;
    final categoryLabel = resolveCategoryLabel(task, categories);

    return WillPopScope(
      onWillPop: () async {
        await _finishEditing();
        return false;
      },
      child: Scaffold(
        backgroundColor: scheme.surface,
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: _finishEditing,
          ),
          title: const Text('Chi tiết nhiệm vụ'),
          actions: [
            TextButton(onPressed: _finishEditing, child: const Text('LƯU')),
          ],
        ),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: ActionChip(
                avatar: const Icon(Icons.folder_outlined),
                label: Text(categoryLabel),
                onPressed: _pickCategory,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              task.title,
              style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            ValueListenableBuilder<bool>(
              valueListenable: ProManager.instance.isPro,
              builder: (_, isPro, __) {
                if (!isPro) {
                  return Container(
                    margin: const EdgeInsets.symmetric(vertical: 12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: scheme.surfaceVariant.withOpacity(.35),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: scheme.outline.withOpacity(.2)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Nhiệm vụ phụ dành cho tài khoản Pro',
                          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Nâng cấp để xem và quản lý nhiệm vụ phụ, đồng thời mở khoá số nhiệm vụ không giới hạn.',
                          style: theme.textTheme.bodyMedium,
                        ),
                        const SizedBox(height: 12),
                        FilledButton.icon(
                          onPressed: _handleUpgradeTap,
                          icon: const Icon(Icons.workspace_premium),
                          label: const Text('Nâng cấp Pro'),
                        ),
                      ],
                    ),
                  );
                }

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.water_drop, size: 36, color: scheme.secondary),
                    const SizedBox(height: 8),
                    TextButton.icon(
                      onPressed: _addSubtaskDialog,
                      icon: const Icon(Icons.add),
                      label: const Text('Thêm nhiệm vụ phụ'),
                    ),
                    if (task.subtasks.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      ...task.subtasks.asMap().entries.map((entry) {
                        final index = entry.key;
                        final subtask = entry.value;
                        return CheckboxListTile(
                          contentPadding: EdgeInsets.zero,
                          controlAffinity: ListTileControlAffinity.leading,
                          value: subtask.done,
                          onChanged: (v) => setState(() => subtask.done = v ?? false),
                          title: Text(
                            subtask.title,
                            style: TextStyle(
                              decoration: subtask.done ? TextDecoration.lineThrough : null,
                              color: subtask.done ? theme.disabledColor : null,
                            ),
                          ),
                          secondary: IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () => setState(() => task.subtasks.removeAt(index)),
                          ),
                        );
                      }),
                    ],
                  ],
                );
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.event_available_outlined),
              title: const Text('Ngày đến hạn'),
              trailing: _pill(_dateLabel()),
              onTap: _pickDate,
            ),
            ListTile(
              leading: const Icon(Icons.schedule_outlined),
              title: const Text('Thời gian & Lời nhắc'),
              trailing: _pill(_timeLabel(task.timeOfDay)),
              onTap: _pickTime,
            ),
            ListTile(
              contentPadding: const EdgeInsets.only(left: 72, right: 16),
              title: const Text('Nhắc nhở lúc'),
              trailing: _pill(_timeLabel(task.timeOfDay)),
              onTap: _pickReminder,
            ),
            ListTile(
              contentPadding: const EdgeInsets.only(left: 72, right: 16),
              title: const Text('Loại lời nhắc'),
              trailing: _pill(task.reminderBefore == null ? 'Thông báo' : 'Thông báo'),
            ),
            ListTile(
              leading: const Icon(Icons.repeat),
              title: const Text('Lặp lại nhiệm vụ'),
              trailing: _pill(_repeatLabel()),
              onTap: _pickRepeat,
            ),
            ListTile(
              leading: const Icon(Icons.notes_outlined),
              title: const Text('Ghi chú'),
              subtitle: task.notes == null || task.notes!.isEmpty
                  ? const Text('Chạm để thêm ghi chú')
                  : Text(task.notes!),
              onTap: () async {
                final text = await showDialog<String>(
                  context: context,
                  builder: (_) => AlertDialog(
                    title: const Text('Ghi chú'),
                    content: TextField(
                      controller: _noteCtl,
                      decoration: const InputDecoration(hintText: 'Nhập ghi chú...'),
                      maxLines: 5,
                    ),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(context), child: const Text('HUỶ')),
                      FilledButton(
                        onPressed: () => Navigator.pop(context, _noteCtl.text),
                        child: const Text('LƯU'),
                      ),
                    ],
                  ),
                );
                if (text != null) {
                  setState(() {
                    _noteCtl.text = text;
                    task.notes = text.trim().isEmpty ? null : text.trim();
                  });
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.attachment),
              title: const Text('Tập tin đính kèm'),
              trailing: _pill('THÊM'),
              onTap: () {},
            ),
          ],
        ),
      ),
    );
  }

  Widget _pill(String text) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: scheme.outline.withOpacity(.3)),
      ),
      child: Text(text, style: const TextStyle(fontWeight: FontWeight.w600)),
    );
  }

  void _applyNote() {
    task.notes = _noteCtl.text.trim().isEmpty ? null : _noteCtl.text.trim();
  }

  Future<void> _handleUpgradeTap() async {
    if (!mounted) return;
    final upgraded = await UpgradeFlow.start(context);
    if (!mounted) return;
    if (upgraded) {
      setState(() {});
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã mở khoá tính năng Pro.')),
      );
    }
  }

  Future<void> _finishEditing() async {
    _applyNote();
    if (mounted) {
      Navigator.pop(context, task);
    }
  }

  Future<void> _pickCategory() async {
    await _categoryStore.ensureLoaded();
    final configs = _categoryStore.current;
    final result = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Text('Chọn danh mục', style: Theme.of(context).textTheme.titleMedium),
            const Divider(),
            for (final cfg in configs)
              ListTile(
                leading: Icon(
                  _iconForCategory(cfg),
                  color: Color(cfg.color),
                ),
                title: Text(cfg.label),
                onTap: () => Navigator.pop(context, cfg.id),
              ),
            ListTile(
              leading: const Icon(Icons.add),
              title: const Text('Tạo danh mục mới'),
              onTap: () async {
                final name = await _promptForNewCategory();
                if (name != null && name.isNotEmpty) {
                  await _categoryStore.createCustom(name: name);
                  Navigator.pop(context, _categoryStore.current.last.id);
                }
              },
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );

    if (!mounted || result == null) return;
    final system = _categoryStore.resolveSystem(result);
    setState(() {
      if (system != null) {
        task
          ..category = system
          ..customCategoryId = null;
      } else {
        task
          ..category = TaskCategory.none
          ..customCategoryId = result;
      }
    });
  }

  IconData _iconForCategory(CategoryConfig cfg) {
    if (!cfg.isSystem) return Icons.folder_outlined;
    final system = _categoryStore.resolveSystem(cfg.id);
    switch (system) {
      case TaskCategory.work:
        return Icons.work_outline;
      case TaskCategory.personal:
        return Icons.self_improvement;
      case TaskCategory.favorites:
        return Icons.star_rounded;
      case TaskCategory.birthday:
        return Icons.cake_outlined;
      case TaskCategory.none:
      case null:
        return Icons.folder_outlined;
    }
  }

  Future<String?> _promptForNewCategory() async {
    final ctl = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Danh mục mới'),
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
  }
}

  