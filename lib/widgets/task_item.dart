import 'package:flutter/material.dart';
import '../models/task.dart'; // nhớ import đúng đường dẫn đến model của bạn

class TaskItem extends StatelessWidget {
  const TaskItem({
    super.key,
    required this.task,
    required this.onToggleDone,
    required this.onTap,
    this.onEdit,
    this.onToggleFavorite,
    this.compact = false,
  });

  final Task task;
  final VoidCallback onToggleDone;
  final VoidCallback onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onToggleFavorite;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final now = DateTime.now();

    DateTime? dueDate;
    if (task.dueDate != null) {
      if (task.timeOfDay != null) {
        dueDate = DateTime(
          task.dueDate!.year,
          task.dueDate!.month,
          task.dueDate!.day,
          task.timeOfDay!.hour,
          task.timeOfDay!.minute,
        );
      } else {
        dueDate = DateTime(task.dueDate!.year, task.dueDate!.month, task.dueDate!.day, 23, 59);
      }
    }

    final bool isOverdue = dueDate != null && dueDate.isBefore(now) && !task.done;
    final bool isToday = dueDate != null && DateUtils.isSameDay(dueDate, now);
    final bool isTomorrow = dueDate != null && DateUtils.isSameDay(dueDate, now.add(const Duration(days: 1)));

    String? dueLabel;
    if (dueDate != null) {
      if (isOverdue) {
        dueLabel = 'Quá hạn · ${_formatDate(dueDate)}';
      } else if (isToday) {
        dueLabel = 'Hôm nay${task.timeOfDay != null ? ' · ${_formatTime(task.timeOfDay!)}' : ''}';
      } else if (isTomorrow) {
        dueLabel = 'Ngày mai${task.timeOfDay != null ? ' · ${_formatTime(task.timeOfDay!)}' : ''}';
      } else {
        final dateText = _formatDate(dueDate);
        dueLabel = task.timeOfDay != null ? '$dateText · ${_formatTime(task.timeOfDay!)}' : dateText;
      }
    }

    final String? category = (task.category == TaskCategory.none) ? null : categoryLabel(task.category);
    final Duration? reminder = task.reminderBefore;

    final chips = <Widget>[];
    if (dueLabel != null) {
      chips.add(_MetaChip(
        label: dueLabel,
        icon: isOverdue ? Icons.error_outline : Icons.calendar_today,
        color: isOverdue ? scheme.error : scheme.primary,
      ));
    }
    if (category != null && category.isNotEmpty) {
      chips.add(_MetaChip(label: category, icon: Icons.folder_open, color: scheme.secondary));
    }
    if (reminder != null) {
      chips.add(_MetaChip(
        label: 'Nhắc trước ${_humanizeDuration(reminder)}',
        icon: Icons.notifications_active,
        color: scheme.tertiary,
      ));
    }

    final gradientStart = task.done ? scheme.surfaceVariant : scheme.primaryContainer.withOpacity(.75);
    final gradientEnd = scheme.surface;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: compact ? 4 : 8),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Ink(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: LinearGradient(
                colors: [gradientStart, gradientEnd],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                if (!task.done)
                  BoxShadow(
                    color: scheme.primary.withOpacity(.12),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
              ],
            ),
            child: Padding(
              padding: EdgeInsets.all(compact ? 12 : 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      IconButton(
                        onPressed: onToggleDone,
                        iconSize: compact ? 22 : 26,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        icon: Icon(
                          task.done ? Icons.check_circle : Icons.radio_button_unchecked,
                          color: task.done ? scheme.primary : scheme.onSurfaceVariant,
                        ),
                        tooltip: task.done ? 'Đánh dấu chưa xong' : 'Đánh dấu đã xong',
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              task.title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: task.done ? FontWeight.w500 : FontWeight.w700,
                                decoration: task.done ? TextDecoration.lineThrough : null,
                                color: task.done
                                    ? theme.textTheme.titleMedium?.color?.withOpacity(.7)
                                    : null,
                              ),
                            ),
                            if (chips.isNotEmpty) ...[
                              const SizedBox(height: 10),
                              Wrap(
                                spacing: 8,
                                runSpacing: 6,
                                children: chips,
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      IconButton(
                        icon: Icon(task.favorite ? Icons.star : Icons.star_border),
                        color: task.favorite ? Colors.amber : scheme.onSurfaceVariant,
                        onPressed: onToggleFavorite ?? onEdit ?? onTap,
                        tooltip: task.favorite ? 'Bỏ yêu thích' : 'Yêu thích',
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  const _MetaChip({required this.label, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(.12),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

String _formatDate(DateTime date) {
  final now = DateTime.now();
  final dd = date.day.toString().padLeft(2, '0');
  final mm = date.month.toString().padLeft(2, '0');
  if (date.year != now.year) return '$dd/$mm/${date.year.toString()}';
  return '$dd/$mm';
}

String _formatTime(TimeOfDay time) =>
    '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';

String _humanizeDuration(Duration duration) {
  if (duration.inMinutes < 60) {
    return '${duration.inMinutes} phút';
  }
  if (duration.inHours < 24) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;
    if (minutes == 0) return '$hours giờ';
    return '$hours giờ ${minutes} phút';
  }
  final days = duration.inDays;
  final hours = duration.inHours % 24;
  if (hours == 0) return '$days ngày';
  return '$days ngày ${hours} giờ';
}
