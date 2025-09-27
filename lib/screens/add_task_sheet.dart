import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/task.dart';

class AddTaskSheet extends StatefulWidget {
  final Task? initial; // dùng cho Template
  const AddTaskSheet({super.key, this.initial});

  @override
  State<AddTaskSheet> createState() => _AddTaskSheetState();
}

class _AddTaskSheetState extends State<AddTaskSheet> {
  late TextEditingController _title;
  final _subCtl = TextEditingController();

  final _focus = FocusNode(); // Focus cho ô nhập chính

  TaskCategory _category = TaskCategory.work;
  DateTime? _date;
  TimeOfDay? _time;
  Duration? _remind;
  RepeatRule _repeat = RepeatRule.none;
  final List<SubTask> _subs = [];

  @override
  void initState() {
    super.initState();
    final i = widget.initial;
    _title = TextEditingController(text: i?.title ?? '');
    _category = i?.category ?? TaskCategory.work;
    _date = i?.dueDate;
    _time = i?.timeOfDay;
    _remind = i?.reminderBefore;
    _repeat = i?.repeat ?? RepeatRule.none;
    _subs.addAll(i?.subtasks ?? []);

    // Sau khi render frame đầu tiên thì focus vào TextField + gọi IME
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      FocusScope.of(context).requestFocus(_focus);
      SystemChannels.textInput.invokeMethod('TextInput.show');
    });
  }

  @override
  void dispose() {
    _title.dispose();
    _subCtl.dispose();
    _focus.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      firstDate: now,
      lastDate: DateTime(now.year + 3),
      initialDate: _date ?? now,
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _time ?? TimeOfDay.now(),
    );
    if (picked != null) setState(() => _time = picked);
  }

  Future<void> _pickRepeat() async {
    RepeatRule temp = _repeat;
    await showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (ctx) => StatefulBuilder(
        builder: (_, setBtm) => Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SwitchListTile(
                title: const Text('Đặt làm tác vụ lặp lại'),
                value: temp != RepeatRule.none,
                onChanged: (v) {
                  setBtm(() => temp = v ? RepeatRule.daily : RepeatRule.none);
                },
              ),
              Wrap(
                spacing: 8,
                children: [
                  ChoiceChip(
                    label: const Text('Giờ'),
                    selected: temp == RepeatRule.hourly,
                    onSelected: (_) => setBtm(() => temp = RepeatRule.hourly),
                  ),
                  ChoiceChip(
                    label: const Text('hằng ngày'),
                    selected: temp == RepeatRule.daily,
                    onSelected: (_) => setBtm(() => temp = RepeatRule.daily),
                  ),
                  ChoiceChip(
                    label: const Text('Hằng tuần'),
                    selected: temp == RepeatRule.weekly,
                    onSelected: (_) => setBtm(() => temp = RepeatRule.weekly),
                  ),
                  ChoiceChip(
                    label: const Text('Hằng tháng'),
                    selected: temp == RepeatRule.monthly,
                    onSelected: (_) => setBtm(() => temp = RepeatRule.monthly),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('HỦY')),
                  FilledButton(
                    onPressed: () {
                      setState(() => _repeat = temp);
                      Navigator.pop(ctx);
                    },
                    child: const Text('XONG'),
                  ),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 12,
        bottom: 16 + MediaQuery.of(context).viewInsets.bottom,
      ),
      child: ListView(
        shrinkWrap: true,
        children: [
          TextField(
            controller: _title,
            focusNode: _focus, // tự focus
            autofocus: true,
            textInputAction: TextInputAction.done,
            decoration: const InputDecoration(
              hintText: 'Nhập nhiệm vụ mới tại đây',
              border: OutlineInputBorder(),
              filled: true,
            ),
          ),
          const SizedBox(height: 12),

          // ====== NHÓM CHIP 1: Danh mục – Hẹn ngày – Thời gian (dùng Wrap để tránh overflow) ======
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              PopupMenuButton<TaskCategory>(
                initialValue: _category,
                onSelected: (v) => setState(() => _category = v),
                itemBuilder: (ctx) => TaskCategory.values.map((c) {
                  return PopupMenuItem(
                    value: c,
                    child: Text(
                      categoryLabel(c),
                      style: c == _category
                          ? TextStyle(
                              color: theme.colorScheme.primary,
                              fontWeight: FontWeight.w600,
                            )
                          : null,
                    ),
                  );
                }).toList(),
                child: Chip(
                  avatar: const Icon(Icons.label_outline, size: 18),
                  label: Text(
                    categoryLabel(_category),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),

              ActionChip(
                avatar: const Icon(Icons.event),
                label: Text(_date != null
                    ? '${_date!.day}/${_date!.month}/${_date!.year}'
                    : 'Hẹn ngày'),
                onPressed: _pickDate,
              ),
              ActionChip(
                avatar: const Icon(Icons.schedule),
                label: Text(_time != null
                    ? '${_time!.hour.toString().padLeft(2, '0')}:${_time!.minute.toString().padLeft(2, '0')}'
                    : 'Thời gian'),
                onPressed: _pickTime,
              ),
            ],
          ),

          const SizedBox(height: 8),

          // ====== NHÓM CHIP 2: Lời nhắc – Lặp lại – Mẫu (Wrap + nút Mẫu bên phải) ======
          Row(
            children: [
              Expanded(
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    ActionChip(
                      avatar: const Icon(Icons.notifications_active_outlined),
                      label: Text(_remind != null
                          ? 'Nhắc trước ${_remind!.inMinutes}\''
                          : 'Lời nhắc'),
                      onPressed: () async {
                        final picked = await showModalBottomSheet<Duration>(
                          context: context,
                          showDragHandle: true,
                          builder: (_) => SafeArea(
                            child: Wrap(
                              children: [
                                ListTile(
                                  title: const Text('Không'),
                                  onTap: () => Navigator.pop(context, null),
                                ),
                                for (final m in [5, 10, 30, 60])
                                  ListTile(
                                    title: Text('Trước $m phút'),
                                    onTap: () => Navigator.pop(
                                        context, Duration(minutes: m)),
                                  ),
                              ],
                            ),
                          ),
                        );
                        if (mounted) setState(() => _remind = picked);
                      },
                    ),
                    ActionChip(
                      avatar: const Icon(Icons.repeat),
                      label: Text(
                          _repeat == RepeatRule.none ? 'Lặp lại' : _repeat.name),
                      onPressed: _pickRepeat,
                    ),
                  ],
                ),
              ),
              TextButton.icon(
                icon: const Icon(Icons.view_list),
                label: const Text('Mẫu'),
                onPressed: () => Navigator.of(context)
                    .pushNamed('/templates')
                    .then((value) {
                  if (value is Task) {
                    setState(() {
                      _title.text = value.title;
                      _category = value.category;
                      _date = value.dueDate;
                      _time = value.timeOfDay;
                      _repeat = value.repeat;
                    });
                  }
                }),
              ),
            ],
          ),

          const Divider(height: 24),

          // ====== NHIỆM VỤ PHỤ ======
          Row(
            children: [
              const Text('Nhiệm vụ phụ'),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _subCtl,
                  decoration: InputDecoration(
                    hintText: 'Nhập nhiệm vụ phụ',
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.add),
                      onPressed: () {
                        if (_subCtl.text.trim().isEmpty) return;
                        setState(() {
                          _subs.add(SubTask(title: _subCtl.text.trim()));
                          _subCtl.clear();
                        });
                      },
                    ),
                  ),
                ),
              ),
            ],
          ),
          Column(
            children: _subs.asMap().entries.map((e) {
              final i = e.key;
              final s = e.value;
              return CheckboxListTile(
                value: s.done,
                onChanged: (v) => setState(() => _subs[i].done = v ?? false),
                title: Text(s.title),
                secondary: IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => setState(() => _subs.removeAt(i)),
                ),
                controlAffinity: ListTileControlAffinity.leading,
                contentPadding: EdgeInsets.zero,
              );
            }).toList(),
          ),

          const SizedBox(height: 12),
          FilledButton(
            onPressed: () {
              if (_title.text.trim().isEmpty) return;
              final newTask = Task(
                id: UniqueKey().toString(),
                title: _title.text.trim(),
                category: _category,
                dueDate: _date,
                timeOfDay: _time,
                reminderBefore: _remind,
                repeat: _repeat,
                subtasks: _subs,
              );
              Navigator.pop(context, newTask);
            },
            child: const Text('THÊM NHIỆM VỤ'),
          ),
        ],
      ),
    );
  }
}
