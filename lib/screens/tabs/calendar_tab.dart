import 'dart:async';

import 'package:flutter/material.dart';
import '../../models/task.dart';
import '../../services/category_store.dart';

class CalendarTab extends StatefulWidget {
  final List<Task> tasks;
  final ValueChanged<Task> onOpenTask;
  final ValueChanged<DateTime> onCreateForDate;
  const CalendarTab({super.key, required this.tasks, required this.onOpenTask, required this.onCreateForDate});

  @override
  State<CalendarTab> createState() => _CalendarTabState();
}

class _CalendarTabState extends State<CalendarTab> {
  DateTime _selected = DateTime.now();
  final CategoryStore _categoryStore = CategoryStore.instance;

  @override
  void initState() {
    super.initState();
    unawaited(_categoryStore.ensureLoaded());
  }

  bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  @override
  Widget build(BuildContext context) {
    final dayTasks = widget.tasks
        .where((t) => t.dueDate != null && _sameDay(t.dueDate!, _selected))
        .toList()
      ..sort((a, b) {
        final at = a.timeOfDay;
        final bt = b.timeOfDay;
        if (at == null && bt == null) return a.title.compareTo(b.title);
        if (at == null) return 1;
        if (bt == null) return -1;
        return at.hour != bt.hour ? at.hour.compareTo(bt.hour) : at.minute.compareTo(bt.minute);
      });

    final scheme = Theme.of(context).colorScheme;

    return Container(
      color: scheme.surface,
      child: Column(
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  scheme.primary.withOpacity(.85),
                  scheme.secondary.withOpacity(.75),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: CalendarDatePicker(
              initialDate: _selected,
              firstDate: DateTime(2000),
              lastDate: DateTime(2100),
              onDateChanged: (d) => setState(() => _selected = d),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Ngày ${_selected.day}/${_selected.month}/${_selected.year}',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                  ),
                ),
                FilledButton.icon(
                  onPressed: () => widget.onCreateForDate(_selected),
                  icon: const Icon(Icons.add),
                  label: const Text('Thêm nhiệm vụ'),
                ),
              ],
            ),
          ),
          Expanded(
            child: dayTasks.isEmpty
                ? _emptySchedule(context)
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 110),
                    itemCount: dayTasks.length,
                    itemBuilder: (ctx, i) => _calendarTaskCard(context, dayTasks[i]),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _emptySchedule(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.calendar_today_outlined, size: 56, color: Colors.grey),
          const SizedBox(height: 12),
          Text('Chưa có nhiệm vụ nào trong ngày', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Text('Thêm nhiệm vụ để bắt đầu kế hoạch cho ngày này.',
              style: Theme.of(context).textTheme.bodyMedium, textAlign: TextAlign.center),
        ],
      ),
    );
  }

  Widget _calendarTaskCard(BuildContext context, Task t) {
    final scheme = Theme.of(context).colorScheme;
    final label = resolveCategoryLabel(t, _categoryStore.current);
    final timeLabel = t.timeOfDay == null
        ? 'Cả ngày'
        : '${t.timeOfDay!.hour.toString().padLeft(2, '0')}:${t.timeOfDay!.minute.toString().padLeft(2, '0')}';

    return InkWell(
      onTap: () => widget.onOpenTask(t),
      borderRadius: BorderRadius.circular(24),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: LinearGradient(
            colors: [scheme.primaryContainer.withOpacity(.85), scheme.surface],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(color: scheme.primary.withOpacity(.12), blurRadius: 16, offset: const Offset(0, 10)),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              children: [
                Text(timeLabel, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                Icon(t.done ? Icons.check_circle : Icons.radio_button_unchecked,
                    color: t.done ? scheme.primary : scheme.outline),
              ],
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    t.title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      Chip(
                        visualDensity: VisualDensity.compact,
                        label: Text(label),
                        avatar: const Icon(Icons.folder_outlined, size: 16),
                      ),
                      if (t.reminderBefore != null)
                        Chip(
                          visualDensity: VisualDensity.compact,
                          label: Text('Nhắc trước ${t.reminderBefore!.inMinutes} phút'),
                          avatar: const Icon(Icons.notifications_active, size: 16),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}