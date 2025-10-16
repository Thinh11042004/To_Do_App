import 'package:flutter/material.dart';
import '../models/task.dart'; // nhớ import đúng đường dẫn đến model của bạn

class TaskItem extends StatelessWidget {
const TaskItem({
    super.key,
    required this.task,
    required this.categoryName,
    required this.onToggleDone,
    required this.onOpenDetail,
    required this.onToggleFavorite,
    this.onEdit,
    this.compact = false,
    this.categoryColor,
  });

  final Task task;
  final String? categoryName;
  final VoidCallback onToggleDone;
  final VoidCallback onOpenDetail;
  final VoidCallback onToggleFavorite;
  final VoidCallback? onEdit;
  final bool compact;
  final Color? categoryColor;

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

        final String? category = categoryName?.isNotEmpty == true
        ? categoryName
        : (task.category == TaskCategory.none ? null : categoryLabel(task.category));    final Duration? reminder = task.reminderBefore;

    final chips = <Widget>[];
    if (dueLabel != null) {
      chips.add(_MetaChip(
        label: dueLabel,
        icon: isOverdue ? Icons.error_outline : Icons.calendar_today,
        color: isOverdue ? scheme.error : scheme.primary,
      ));
    }
    if (category != null && category.isNotEmpty) {
      chips.add(_MetaChip(
              label: category,
              icon: Icons.folder_open,
              color: categoryColor ?? scheme.secondary,
            ));   
     }
    if (reminder != null) {
      chips.add(_MetaChip(
        label: 'Nhắc trước ${_humanizeDuration(reminder)}',
        icon: Icons.notifications_active,
        color: scheme.tertiary,
      ));
    }

    final gradientStart = task.done
        ? scheme.surfaceVariant
        : scheme.primary.withOpacity(.92);
    final gradientEnd = task.done
        ? scheme.surface
        : scheme.tertiaryContainer.withOpacity(.85);

   if (compact) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: Material(
          color: scheme.surface,
          borderRadius: BorderRadius.circular(16),
          elevation: 0,
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: onOpenDetail,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Row(
                children: [
                  InkResponse(
                    onTap: onToggleDone,
                    radius: 20,
                    child: Icon(
                      task.done ? Icons.check_circle : Icons.radio_button_unchecked,
                      color: task.done ? scheme.primary : scheme.outline,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          task.title,
                          style: theme.textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                            decoration: task.done ? TextDecoration.lineThrough : null,
                            color: task.done
                                ? theme.textTheme.bodyLarge?.color?.withOpacity(.6)
                                : theme.textTheme.bodyLarge?.color,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (dueLabel != null || category != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Row(
                              children: [
                                if (dueLabel != null)
                                  _CompactMeta(
                                    icon: isOverdue ? Icons.error_outline : Icons.calendar_today,
                                    label: dueLabel,
                                    color: isOverdue ? scheme.error : scheme.primary,
                                  ),
                                if (category != null) ...[
                                  if (dueLabel != null) const SizedBox(width: 8),
                                  _CompactMeta(
                                    icon: Icons.folder_open,
                                    label: category,
                                    color: categoryColor ?? scheme.secondary,
                                  ),
                                ],
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  IconButton(
                    tooltip: task.favorite ? 'Bỏ yêu thích' : 'Yêu thích',
                    icon: Icon(task.favorite ? Icons.star : Icons.star_border),
                    onPressed: onToggleFavorite,
                    color: task.favorite ? Colors.amber : scheme.outline,
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 420),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, (1 - value) * 12),
            child: child,
          ),
        );
      },
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: compact ? 4 : 8),
        child: Hero(
          tag: 'task-${task.id}',
          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(20),
            child: InkWell(
              onTap: onOpenDetail,
              onLongPress: onToggleFavorite,
              borderRadius: BorderRadius.circular(20),
              child: AnimatedContainer(
                  duration: const Duration(milliseconds: 320),
                  curve: Curves.easeOutCubic,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    gradient: LinearGradient(
                      colors: task.done
                          ? [gradientStart, gradientEnd]
                          : [gradientStart, gradientEnd],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      if (!task.done)
                        BoxShadow(
                          color: scheme.primary.withOpacity(.18),
                          blurRadius: 16,
                          offset: const Offset(0, 10),
                        ),
                    ],
                    border: task.favorite
                        ? Border.all(color: scheme.primary, width: 1.4)
                        : null,
                  ),
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
                            icon: AnimatedSwitcher(
                              duration: const Duration(milliseconds: 250),
                              transitionBuilder: (child, animation) => ScaleTransition(
                                scale: animation,
                                child: child,
                              ),
                              child: Icon(
                                task.done ? Icons.check_circle : Icons.radio_button_unchecked,
                                key: ValueKey(task.done),
                                color: task.done ? scheme.primary : scheme.onSurfaceVariant,
                              ),
                            ),
                            tooltip: task.done ? 'Đánh dấu chưa xong' : 'Đánh dấu đã xong',
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                AnimatedDefaultTextStyle(
                                  duration: const Duration(milliseconds: 260),
                                  style: theme.textTheme.titleMedium?.copyWith(
                                        fontWeight:
                                            task.done ? FontWeight.w500 : FontWeight.w700,
                                        decoration:
                                            task.done ? TextDecoration.lineThrough : null,
                                        color: task.done
                                            ? theme.textTheme.titleMedium?.color
                                                ?.withOpacity(.6)
                                            : theme.textTheme.titleMedium?.color,
                                      ) ??
                                      TextStyle(
                                        fontWeight:
                                            task.done ? FontWeight.w500 : FontWeight.w700,
                                      ),
                                  child: Text(
                                    task.title,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                if (chips.isNotEmpty) ...[
                                  const SizedBox(height: 10),
                                  AnimatedOpacity(
                                    duration: const Duration(milliseconds: 240),
                                    opacity: task.done ? .55 : 1,
                                    child: Wrap(
                                      spacing: 8,
                                      runSpacing: 6,
                                      children: chips,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          IconButton(
                            icon: AnimatedSwitcher(
                              duration: const Duration(milliseconds: 250),
                              transitionBuilder: (child, animation) => ScaleTransition(
                                scale: animation,
                                child: child,
                              ),
                              child: Icon(
                                task.favorite ? Icons.star : Icons.star_border,
                                key: ValueKey(task.favorite),
                              ),
                            ),
                            color: task.favorite ? Colors.amber : scheme.onSurfaceVariant,
                            onPressed: onToggleFavorite,
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
        color: color.withOpacity(.16),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(.35)),
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

class _CompactMeta extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _CompactMeta({required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            label,
            style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
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
