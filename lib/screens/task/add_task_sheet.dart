import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/task.dart';
import '../../services/category_store.dart';
import '../../services/pro_manager.dart';
import '../../utils/upgrade_flow.dart';

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
  String? _customCategoryId;
  DateTime? _date;
  TimeOfDay? _time;
  Duration? _remind;
  RepeatRule _repeat = RepeatRule.none;
  final List<SubTask> _subs = [];
  final CategoryStore _categoryStore = CategoryStore.instance;

  @override
  void initState() {
    super.initState();
    final i = widget.initial;
    _title = TextEditingController(text: i?.title ?? '');
    _category = i?.category ?? TaskCategory.work;
    _customCategoryId = i?.customCategoryId;
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
    unawaited(_categoryStore.ensureLoaded());
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
                leading: CircleAvatar(backgroundColor: Color(cfg.color), radius: 8),
                title: Text(cfg.label),
                trailing: cfg.id == _customCategoryId ||
                        (_categoryStore.resolveSystem(cfg.id) == _category && _customCategoryId == null)
                    ? const Icon(Icons.check)
                    : null,
                onTap: () => Navigator.pop(context, cfg.id),
              ),
            ListTile(
              leading: const Icon(Icons.add),
              title: const Text('Tạo danh mục mới'),
              onTap: () async {
                final name = await _promptNewCategory();
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
    if (result == null) return;
    final system = _categoryStore.resolveSystem(result);
    setState(() {
      if (system != null) {
        _category = system;
        _customCategoryId = null;
      } else {
        _category = TaskCategory.none;
        _customCategoryId = result;
      }
    });
  }

  Future<String?> _promptNewCategory() async {
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

  String _currentCategoryLabel() {
    final temp = Task(
      id: 'preview',
      title: _title.text,
      category: _category,
      customCategoryId: _customCategoryId,
    );
    return resolveCategoryLabel(temp, _categoryStore.current);
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
              ActionChip(
                avatar: const Icon(Icons.label_outline, size: 18),
                label: Text(
                  _currentCategoryLabel(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                onPressed: _pickCategory,
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
                      _customCategoryId = value.customCategoryId;
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
          ValueListenableBuilder<bool>(
            valueListenable: ProManager.instance.isPro,
            builder: (_, isPro, __) {
              if (!isPro) {
                final scheme = Theme.of(context).colorScheme;
                final textTheme = Theme.of(context).textTheme;
                return Container(
                  padding: const EdgeInsets.all(16),
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: scheme.surfaceVariant.withOpacity(.4),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: scheme.outline.withOpacity(.2)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Nâng cấp để thêm nhiệm vụ phụ',
                          style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                      const SizedBox(height: 8),
                      Text(
                        'Tài khoản Pro mở khoá nhiệm vụ phụ và số lượng nhiệm vụ không giới hạn.',
                        style: textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 12),
                      FilledButton.icon(
                        onPressed: () async {
                          final upgraded = await UpgradeFlow.start(context);
                          if (upgraded && mounted) setState(() {});
                        },
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
                  Text('Nhiệm vụ phụ', style: theme.textTheme.titleMedium),
                  const SizedBox(height: 8),
                  Row(
                    children: [
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
                ],
              );
            },
          ),

          const SizedBox(height: 12),
          FilledButton(
            onPressed: () {
              if (_title.text.trim().isEmpty) return;
              final newTask = Task(
                id: UniqueKey().toString(),
                title: _title.text.trim(),
                category: _category,
                customCategoryId: _customCategoryId,
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
