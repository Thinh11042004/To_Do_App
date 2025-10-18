import 'package:flutter/material.dart';

class TaskListOverviewCard extends StatelessWidget {
  final int total;
  final int completed;
  final int pending;
  final int dueToday;
  final String? nextLabel;
  final Widget Function(BuildContext, {required String label, required int value, required IconData icon, required Color color, double? width}) metricStat;

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
    final today = DateTime.now();
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeOutCubic,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              scheme.primaryContainer.withOpacity(.75),
              scheme.surface,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: scheme.primary.withOpacity(.18),
              blurRadius: 28,
              offset: const Offset(0, 16),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Tổng quan hôm nay',
                style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 14),
              LayoutBuilder(
                builder: (context, constraints) {
                  final isCompact = constraints.maxWidth < 520;
                  final tileWidth = isCompact
                      ? constraints.maxWidth
                      : (constraints.maxWidth - 24) / 3;
                  return Wrap(
                    spacing: 12,
                    runSpacing: 12,
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
                        icon: Icons.check_circle,
                        color: scheme.secondary,
                        width: tileWidth,
                      ),
                      metricStat(
                        context,
                        label: 'Đến hạn hôm nay',
                        value: dueToday,
                        icon: Icons.today,
                        color: scheme.tertiary,
                        width: tileWidth,
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 16),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 350),
                transitionBuilder: (child, animation) => FadeTransition(
                  opacity: animation,
                  child: child,
                ),
                child: Text(
                  nextLabel ?? '',
                  key: ValueKey(nextLabel),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
