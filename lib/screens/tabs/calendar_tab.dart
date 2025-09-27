import 'package:flutter/material.dart';
import '../../models/task.dart';

class CalendarTab extends StatefulWidget {
  final List<Task> tasks;
  const CalendarTab({super.key, required this.tasks});

  @override
  State<CalendarTab> createState() => _CalendarTabState();
}

class _CalendarTabState extends State<CalendarTab> {
  DateTime _selected = DateTime.now();

  bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  @override
  Widget build(BuildContext context) {
    final dayTasks =
        widget.tasks.where((t) => t.dueDate != null && _sameDay(t.dueDate!, _selected)).toList();

    return Column(
      children: [
        Container(
          color: Theme.of(context).colorScheme.primaryContainer.withOpacity(.35),
          child: CalendarDatePicker(
            initialDate: _selected,
            firstDate: DateTime(2000),
            lastDate: DateTime(2100),
            onDateChanged: (d) => setState(() => _selected = d),
          ),
        ),
        Expanded(
          child: dayTasks.isEmpty
              ? const SizedBox.shrink()
              : ListView.builder(
                  padding: const EdgeInsets.only(bottom: 90, top: 8),
                  itemCount: dayTasks.length,
                  itemBuilder: (ctx, i) => _calendarTaskCard(context, dayTasks[i]),
                ),
        ),
      ],
    );
  }

  Widget _calendarTaskCard(BuildContext context, Task t) {
    final time = t.timeOfDay == null
        ? null
        : '${t.timeOfDay!.hour.toString().padLeft(2, '0')}:${t.timeOfDay!.minute.toString().padLeft(2, '0')}';
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(.03), blurRadius: 6, offset: const Offset(0, 2))],
      ),
      child: Row(
        children: [
          Container(
            width: 6, height: 64,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary,
              borderRadius: const BorderRadius.only(topLeft: Radius.circular(14), bottomLeft: Radius.circular(14)),
            ),
          ),
          Expanded(
            child: ListTile(
              title: Text(t.title, style: const TextStyle(fontWeight: FontWeight.w700)),
              subtitle: Row(
                children: [
                  if (time != null) ...[
                    const SizedBox(width: 2),
                    Text(time, style: const TextStyle(color: Colors.red)),
                    const SizedBox(width: 8),
                  ],
                  const Icon(Icons.notifications_none, size: 16),
                  const SizedBox(width: 8),
                  const Icon(Icons.share_outlined, size: 16),
                ],
              ),
              trailing: const Icon(Icons.flag_outlined, color: Colors.grey),
            ),
          ),
        ],
      ),
    );
  }
}
