import 'package:flutter/material.dart';
import '../models/task.dart';

class TaskItem extends StatelessWidget {
  final Task task;
  final VoidCallback onToggleDone;
  final VoidCallback onTap;
  final bool compact;

  const TaskItem({
    super.key,
    required this.task,
    required this.onToggleDone,
    required this.onTap,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateStr = task.dueDate != null
        ? '${task.dueDate!.day}/${task.dueDate!.month}'
        : null;
    final timeStr = task.timeOfDay != null
        ? '${task.timeOfDay!.hour.toString().padLeft(2, '0')}:${task.timeOfDay!.minute.toString().padLeft(2, '0')}'
        : null;

    return Card(
      color: task.done
          ? theme.colorScheme.secondaryContainer.withOpacity(0.6)
          : theme.colorScheme.surface,
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: ListTile(
        dense: compact,
        visualDensity: compact ? const VisualDensity(vertical: -2) : VisualDensity.standard,
        onTap: onTap,
        leading: Checkbox(
          value: task.done,
          onChanged: (_) => onToggleDone(),
          shape: const CircleBorder(),
          activeColor: theme.colorScheme.primary,
        ),
        title: Text(
          task.title,
          style: TextStyle(
            decoration: task.done ? TextDecoration.lineThrough : null,
            fontWeight: task.done ? FontWeight.w400 : FontWeight.w600,
          ),
        ),
        subtitle: (dateStr != null || timeStr != null)
            ? Row(
                children: [
                  if (dateStr != null) ...[
                    const Icon(Icons.event, size: 16),
                    const SizedBox(width: 4),
                    Text(dateStr),
                    const SizedBox(width: 12),
                  ],
                  if (timeStr != null) ...[
                    const Icon(Icons.schedule, size: 16),
                    const SizedBox(width: 4),
                    Text(timeStr),
                  ],
                ],
              )
            : null,
        trailing: Icon(
          task.favorite ? Icons.star : Icons.star_border,
          color: task.favorite ? Colors.amber : theme.iconTheme.color,
        ),
      ),
    );
  }
}
