import 'package:flutter/material.dart';
import '../models/task.dart';

class TaskDetailScreen extends StatefulWidget {
  const TaskDetailScreen({super.key});

  @override
  State<TaskDetailScreen> createState() => _TaskDetailScreenState();
}

class _TaskDetailScreenState extends State<TaskDetailScreen> {
  late Task task;
  final _noteCtl = TextEditingController();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    task = ModalRoute.of(context)!.settings.arguments as Task;
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
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          // Quay lại danh sách và loại bỏ toàn bộ stack
          onPressed: () => Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false),
        ),
        title: const Text(''),
        actions: [
          PopupMenuButton(
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'delete', child: Text('Xoá')),
              PopupMenuItem(value: 'share', child: Text('Chia sẻ')),
            ],
          )
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          // Category chip
          Align(
            alignment: Alignment.centerLeft,
            child: PopupMenuButton<TaskCategory>(
              initialValue: task.category,
              onSelected: (v) => setState(() => task.category = v),
              itemBuilder: (ctx) => TaskCategory.values
                  .map((c) => PopupMenuItem(value: c, child: Text(categoryLabel(c))))
                  .toList(),
              child: Chip(
                label: Text(categoryLabel(task.category)),
                backgroundColor: scheme.secondaryContainer,
                labelStyle: TextStyle(color: scheme.onSecondaryContainer),
              ),
            ),
          ),
          const SizedBox(height: 8),

          // Tiêu đề
          Text(
            task.title,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),

          Icon(Icons.water_drop, size: 36, color: scheme.secondary),

          // —— SUBTASK SECTION ——
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: _addSubtaskDialog,
            icon: const Icon(Icons.add),
            label: const Text('Thêm nhiệm vụ phụ'),
          ),
          if (task.subtasks.isNotEmpty) ...[
            const SizedBox(height: 4),
            ...task.subtasks.asMap().entries.map((e) {
              final i = e.key;
              final s = e.value;
              return CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
                value: s.done,
                onChanged: (v) => setState(() => s.done = v ?? false),
                title: Text(
                  s.title,
                  style: TextStyle(
                    decoration: s.done ? TextDecoration.lineThrough : null,
                    color: s.done ? Theme.of(context).disabledColor : null,
                  ),
                ),
                secondary: IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => setState(() => task.subtasks.removeAt(i)),
                ),
              );
            }).toList(),
          ],
          const Divider(),

          // Ngày đến hạn
          ListTile(
            leading: const Icon(Icons.event_available_outlined),
            title: const Text('Ngày đến hạn'),
            trailing: _pill(_dateLabel()),
            onTap: _pickDate,
          ),

          // Thời gian & Lời nhắc
          ListTile(
            leading: const Icon(Icons.schedule_outlined),
            title: const Text('Thời gian & Lời nhắc'),
            trailing: _pill(_timeLabel(task.timeOfDay)),
            onTap: _pickTime,
          ),
          ListTile(
            contentPadding: const EdgeInsets.only(left: 72, right: 16),
            title: const Text('Nhắc nhở lúc'),
            trailing: _pill(_timeLabel(task.timeOfDay)), // có thể tính từ reminderBefore nếu muốn
            onTap: _pickReminder,
          ),
          ListTile(
            contentPadding: const EdgeInsets.only(left: 72, right: 16),
            title: const Text('Loại lời nhắc'),
            trailing: _pill(task.reminderBefore == null ? 'Thông báo' : 'Thông báo'),
          ),

          // Lặp lại
          ListTile(
            leading: const Icon(Icons.repeat),
            title: const Text('Lặp lại nhiệm vụ'),
            trailing: _pill(_repeatLabel()),
            onTap: _pickRepeat,
          ),

          // Ghi chú
          ListTile(
            leading: const Icon(Icons.notes_outlined),
            title: const Text('Ghi chú'),
            trailing: _pill(_noteCtl.text.isEmpty ? 'THÊM' : 'SỬA'),
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
                    FilledButton(onPressed: () => Navigator.pop(context, _noteCtl.text), child: const Text('LƯU')),
                  ],
                ),
              );
              if (text != null) setState(() {});
            },
          ),

          // Tệp đính kèm
          ListTile(
            leading: const Icon(Icons.attachment),
            title: const Text('Tập tin đính kèm'),
            trailing: _pill('THÊM'),
            onTap: () {},
          ),
        ],
      ),
    );
  }

  // Tag tròn viền như ảnh 2
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
}
