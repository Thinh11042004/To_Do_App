import 'package:flutter/material.dart';
import '../models/task.dart';

class TaskItem extends StatelessWidget {
  final Task task;
  final String categoryName;
  final VoidCallback onToggleDone;
  final VoidCallback onOpenDetail;
  final VoidCallback onToggleFavorite;
  final VoidCallback? onEdit;
  final bool compact; // để bạn có thể bật chế độ gọn
  final Color? categoryColor;

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

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDone = task.done;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onOpenDetail,
        child: Padding(
          padding: EdgeInsets.all(compact ? 12 : 14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _CheckPill(done: isDone, onTap: onToggleDone),

              const SizedBox(width: 12),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Tiêu đề lớn, đậm – rõ ràng
                    Text(
                      task.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style:
                          (compact
                                  ? Theme.of(context).textTheme.titleMedium
                                  : Theme.of(context).textTheme.titleLarge)
                              ?.copyWith(
                                height: 1.06,
                                fontWeight: FontWeight.w800,
                                decoration: isDone
                                    ? TextDecoration.lineThrough
                                    : null,
                                color: isDone
                                    ? scheme.outline
                                    : scheme.onSurface,
                              ),
                    ),

                    SizedBox(height: compact ? 6 : 8),

                    // Nhóm chip: thể loại trước, rồi hạn/nhắc/lặp
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        _ChipDot(
                          label: categoryName,
                          color: categoryColor ?? scheme.primary,
                        ),

                        if (task.dueDate != null)
                          _Chip(
                            icon: Icons.calendar_month_rounded,
                            label: _formatDue(task.dueDate!),
                            color: scheme.secondaryContainer,
                            onColor: scheme.onSecondaryContainer,
                          ),

                        if (task.reminderBefore != null)
                          _Chip(
                            icon: Icons.notifications_active_rounded,
                            label:
                                'Nhắc trước ${_humanize(task.reminderBefore!)}',
                            color: scheme.primaryContainer,
                            onColor: scheme.onPrimaryContainer,
                          ),

                        if (task.repeat != null &&
                            task.repeat != RepeatRule.none)
                          _Chip(
                            icon: Icons.repeat_rounded,
                            label: _repeatLabel(task.repeat!),
                            color: scheme.tertiaryContainer,
                            onColor: scheme.onTertiaryContainer,
                          ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 6),

              // Bookmark
              IconButton(
                onPressed: onToggleFavorite,
                tooltip: 'Yêu thích',
                icon: Icon(
                  task.favorite
                      ? Icons.bookmark_rounded
                      : Icons.bookmark_outline_rounded,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDue(DateTime dt) {
    final now = DateTime.now();
    final isToday =
        dt.year == now.year && dt.month == now.month && dt.day == now.day;
    final hh = dt.hour.toString().padLeft(2, '0');
    final mm = dt.minute.toString().padLeft(2, '0');
    return isToday ? 'Hôm nay $hh:$mm' : '${dt.day}/${dt.month} $hh:$mm';
  }

  String _humanize(Duration d) {
    if (d.inDays >= 1) return '${d.inDays} ngày';
    if (d.inHours >= 1) return '${d.inHours} giờ';
    final m = d.inMinutes;
    return m > 0 ? '$m phút' : '${d.inSeconds}s';
  }

  String _repeatLabel(RepeatRule r) {
    switch (r) {
      case RepeatRule.none:
        return 'Không lặp';
      case RepeatRule.hourly:
        return 'Hàng giờ';
      case RepeatRule.daily:
        return 'Hằng ngày';
      case RepeatRule.weekly:
        return 'Hằng tuần';
      case RepeatRule.monthly:
        return 'Hằng tháng';
    }
  }
}

/// Checkbox dạng pill với logo rõ ràng
class _CheckPill extends StatelessWidget {
  final bool done;
  final VoidCallback onTap;
  const _CheckPill({required this.done, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return InkResponse(
      onTap: onTap,
      radius: 24,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        height: 36,
        width: 36,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          // viền – logo rõ hơn
          border: Border.all(
            color: done ? scheme.primary : scheme.outlineVariant,
            width: done ? 2 : 1.5,
          ),
          color: done ? scheme.primary : scheme.surfaceVariant,
          boxShadow: [
            if (done)
              BoxShadow(
                color: scheme.primary.withOpacity(0.25),
                blurRadius: 18,
                offset: const Offset(0, 6),
              ),
          ],
        ),
        child: Icon(
          done ? Icons.task_alt_rounded : Icons.radio_button_unchecked_rounded,
          size: done ? 20 : 18,
          color: done ? scheme.onPrimary : scheme.onSurfaceVariant,
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final Color onColor;
  const _Chip({
    required this.icon,
    required this.label,
    required this.color,
    required this.onColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: ShapeDecoration(color: color, shape: const StadiumBorder()),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: onColor),
          const SizedBox(width: 6),
          Text(
            label,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: onColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _ChipDot extends StatelessWidget {
  final String label;
  final Color color;
  const _ChipDot({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: ShapeDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(
          0.6,
        ), // phải là 0.6 (Dart không cho .6)
        shape: const StadiumBorder(),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
