import 'package:flutter/material.dart';

class TaskListOverviewCard extends StatelessWidget {
  final int total;
  final int completed;
  final int pending;
  final int dueToday;
  final String? nextLabel;

  // Hàm dựng tile metric (được truyền từ màn chính)
  final Widget Function(
    BuildContext, {
    required String label,
    required int value,
    required IconData icon,
    required Color color,
    double? width,
  })
  metricStat;

  const TaskListOverviewCard({
    Key? key,
    required this.total,
    required this.completed,
    required this.pending,
    required this.dueToday,
    required this.nextLabel,
    required this.metricStat,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 10), // ↓ nhỏ margin
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            scheme.primaryContainer.withOpacity(0.22),
            scheme.surface.withOpacity(0.92),
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: BorderRadius.circular(22), // ↓ radius
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12), // ↓ padding
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Tổng quan hôm nay',
              style: theme.textTheme.titleMedium?.copyWith(
                // ↓ chữ nhỏ hơn
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 10), // ↓ spacing
            LayoutBuilder(
              builder: (context, constraints) {
                final isNarrow = constraints.maxWidth < 520;
                final tileWidth = isNarrow
                    ? (constraints.maxWidth - 8) /
                          1 // 1 cột trên màn hẹp
                    : (constraints.maxWidth - 24) / 3; // 3 cột trên màn rộng
                return Wrap(
                  spacing: 12,
                  runSpacing: 10,
                  children: [
                    metricStat(
                      context,
                      label: 'Đang mở',
                      value: pending,
                      icon: Icons.circle_outlined,
                      color: scheme.primary,
                      width: tileWidth,
                    ),
                    metricStat(
                      context,
                      label: 'Hoàn thành',
                      value: completed,
                      icon: Icons.check_circle_outline,
                      color: scheme.secondary,
                      width: tileWidth,
                    ),
                    metricStat(
                      context,
                      label: 'Đến hạn hôm nay',
                      value: dueToday,
                      icon: Icons.calendar_month_outlined,
                      color: scheme.tertiary,
                      width: tileWidth,
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 8), // ↓ spacing
            if (nextLabel != null && nextLabel!.isNotEmpty)
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                child: Text(
                  nextLabel ?? '',
                  key: ValueKey(nextLabel),
                  style: theme.textTheme.bodySmall?.copyWith(
                    // ↓ chữ nhỏ hơn
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
