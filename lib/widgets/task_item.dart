import 'package:flutter/material.dart';
import '../models/task.dart';

class TaskItem extends StatelessWidget {
  final Task task;
  final VoidCallback onToggleDone;

  /// Secondary action (we use it for the ★ favorite button).
  final VoidCallback onTap;

  /// Tap the whole row to open detail.
  final VoidCallback? onEdit;
  final bool compact;

  const TaskItem({
    super.key,
    required this.task,
    required this.onToggleDone,
    required this.onTap,
    this.onEdit,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: Colors.transparent,
      child: ListTile(
        onTap: onEdit, // tap whole row -> open detail
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: InkWell(
          onTap: onToggleDone,
          customBorder: const CircleBorder(),
          child: Icon(
            task.done ? Icons.check_circle : Icons.circle_outlined,
            color:
                task.done ? theme.colorScheme.primary : theme.iconTheme.color,
          ),
        ),
        title: Text(
          task.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            decoration: task.done ? TextDecoration.lineThrough : null,
            fontWeight: task.done ? FontWeight.w400 : FontWeight.w600,
          ),
        ),
        // Subtitle omitted to avoid referencing unknown fields on Task.
        trailing: IconButton(
          icon: Icon(task.favorite ? Icons.star : Icons.star_border),
          color: task.favorite ? Colors.amber : theme.iconTheme.color,
          onPressed: onTap,
          tooltip: task.favorite ? 'Bỏ yêu thích' : 'Yêu thích',
        ),
      ),
    );
  }
}
