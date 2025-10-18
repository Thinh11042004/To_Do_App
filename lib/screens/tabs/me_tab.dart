import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../models/task.dart';
import '../../services/pro_manager.dart';
import '../../services/auth_service.dart';
import '../../services/ai_insights_service.dart';
import '../../widgets/ai_insight_card.dart';
// Nếu bạn có service gọi GPT (ví dụ OpenRouter/ChatGPT), import ở đây:
// import '../../services/chat_gpt_service.dart';

class MeTab extends StatefulWidget {
  final List<Task> tasks;
  final VoidCallback onUpgrade;
  const MeTab({super.key, required this.tasks, required this.onUpgrade});

  @override
  State<MeTab> createState() => _MeTabState();
}

class _MeTabState extends State<MeTab> {
  int? _days = 30; // null = tất cả

  List<Task> get _rangeTasks {
    if (_days == null) return widget.tasks;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final end = today.add(Duration(days: _days!));
    return widget.tasks.where((t) {
      if (t.dueDate == null) return false;
      final d = DateTime(t.dueDate!.year, t.dueDate!.month, t.dueDate!.day);
      return (d.isAtSameMomentAs(today) || d.isAfter(today)) &&
          d.isBefore(end.add(const Duration(days: 1)));
    }).toList();
  }

  String get _rangeLabel => _days == null ? 'Toàn bộ' : 'Trong $_days ngày nữa';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    final insights = AiInsightsService.generate(widget.tasks);
    final filtered = _rangeTasks;

    final done = filtered.where((t) => t.done).length;
    final notDone = filtered.length - done;
    final dailyStats = _buildDailyCompletionStats(filtered);
    final hasChartData = dailyStats.any((t) => t.total > 0);

    final pendingSlices = _pendingSlices(filtered, scheme);
    final pendingTotal =
        pendingSlices.fold<int>(0, (sum, s) => sum + s.count);

    Widget pillTitle(String text) => Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Row(
            children: [
              Expanded(child: Text(text, style: textTheme.titleLarge)),
              _RangeDropdown(
                value: _days,
                onChanged: (v) => setState(() => _days = v),
              ),
            ],
          ),
        );

    Widget statCard(String title, String value) => Expanded(
          child: Card(
            color: scheme.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(22),
              side: BorderSide(color: scheme.primary.withOpacity(.12)),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 18),
              child: Column(
                children: [
                  Text(value,
                      style: textTheme.headlineMedium
                          ?.copyWith(color: scheme.primary)),
                  const SizedBox(height: 6),
                  Text(title,
                      textAlign: TextAlign.center,
                      style: textTheme.bodyMedium),
                ],
              ),
            ),
          ),
        );

    return Container(
      color: scheme.surface,
      child: ListView(
        padding: const EdgeInsets.only(bottom: 120),
        children: [
          // ===== Greeting / Status =====
          Container(
            margin: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [scheme.primary, scheme.primaryContainer.withOpacity(.9)],
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Chào mừng quay lại! 🎉',
                    style: textTheme.titleMedium?.copyWith(
                      color: scheme.onPrimary,
                      fontWeight: FontWeight.w700,
                    )),
                const SizedBox(height: 8),
                Text(
                  "Bạn đang ở chế độ ${ProManager.instance.isPro.value ? 'Pro' : 'thường'}. Hãy tiếp tục tạo những thói quen tốt!",
                  style: textTheme.bodyMedium
                      ?.copyWith(color: scheme.onPrimary.withOpacity(.88)),
                ),
              ],
            ),
          ),

          // ===== USER TILE =====
          StreamBuilder<User?>(
            stream: AuthService.instance.userChanges,
            builder: (context, snap) {
              final user = snap.data;
              final avatar = (user?.photoURL != null)
                  ? CircleAvatar(
                      radius: 28, backgroundImage: NetworkImage(user!.photoURL!))
                  : CircleAvatar(
                      radius: 28,
                      backgroundColor: scheme.secondaryContainer,
                      child: Icon(Icons.person,
                          color: scheme.onSecondaryContainer),
                    );
              return ListTile(
                leading: avatar,
                title: Text(user?.displayName ?? 'Bạn đã giữ theo kế hoạch cũ…'),
                subtitle: Text(user?.email ?? 'Bấm để đăng nhập'),
                onTap: () {
                  if (user == null) {
                    // Navigator.push(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
                    // nếu có màn login, mở ra ở đây
                  }
                },
                trailing: user != null
                    ? IconButton(
                        tooltip: 'Đăng xuất',
                        icon: const Icon(Icons.logout),
                        onPressed: () async {
                          await AuthService.instance.signOut();
                          await ProManager.instance.resetPro();
                        },
                      )
                    : null,
              );
            },
          ),

          // ===== PRO BANNER =====
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: ValueListenableBuilder<bool>(
              valueListenable: ProManager.instance.isPro,
              builder: (_, isPro, __) {
                if (isPro) return const SizedBox.shrink();
                return InkWell(
                  onTap: widget.onUpgrade,
                  borderRadius: BorderRadius.circular(18),
                  child: Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          scheme.secondary,
                          scheme.secondaryContainer.withOpacity(.9),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [
                        BoxShadow(
                          color: scheme.secondary.withOpacity(.22),
                          blurRadius: 22,
                          offset: const Offset(0, 14),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Nâng cấp lên Pro',
                                  style: textTheme.titleMedium?.copyWith(
                                    color: scheme.onSecondary,
                                    fontWeight: FontWeight.w700,
                                  )),
                              const SizedBox(height: 4),
                              Text('Mở khoá tất cả các tính năng PRO',
                                  style: textTheme.bodyMedium?.copyWith(
                                    color: scheme.onSecondary.withOpacity(.85),
                                  )),
                            ],
                          ),
                        ),
                        Icon(Icons.workspace_premium,
                            color: scheme.onSecondary, size: 32),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 16),

          // ===== AI Insights (từ local service) =====
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: AiInsightCard(summary: insights),
          ),

          const SizedBox(height: 12),

          // ===== STATS =====
          pillTitle('Tổng quan về Nhiệm vụ'),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                statCard('Đã hoàn thành ($_rangeLabel)', '$done'),
                const SizedBox(width: 12),
                statCard('Chưa hoàn thành ($_rangeLabel)', '$notDone'),
              ],
            ),
          ),

          // ===== Daily Completion Chart =====
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Card(
              color: scheme.surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
                side: BorderSide(color: scheme.primary.withOpacity(.08)),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                            child: Text('Hoàn thành nhiệm vụ hàng ngày',
                                style: textTheme.titleMedium)),
                        Text(_rangeLabel,
                            style: textTheme.bodyMedium
                                ?.copyWith(color: scheme.primary)),
                      ],
                    ),
                    const SizedBox(height: 16),
                    if (hasChartData)
                      _DailyCompletionChart(stats: dailyStats)
                    else
                      Container(
                        height: 160,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          color: scheme.surfaceVariant.withOpacity(.35),
                        ),
                        child: Text('Không có dữ liệu nhiệm vụ',
                            style: textTheme.bodyMedium?.copyWith(
                                color: scheme.onSurface.withOpacity(.7))),
                      ),
                  ],
                ),
              ),
            ),
          ),

          // ===== Upcoming =====
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text('Nhiệm vụ trong ${_days ?? 'tất cả'} ngày tới',
                style: textTheme.titleLarge),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Card(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24)),
              child: Column(children: _buildUpcomingList(context, filtered)),
            ),
          ),

          // ===== Breakdown (Donut) =====
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              children: [
                Expanded(
                    child: Text('Phân loại nhiệm vụ chưa hoàn thành',
                        style: textTheme.titleLarge)),
                _RangeDropdown(
                    value: _days, onChanged: (v) => setState(() => _days = v)),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Card(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 160,
                        height: 160,
                        child: CustomPaint(
                          painter: _DonutChartPainter(
                              pendingSlices,
                              scheme.surfaceVariant.withOpacity(.4)),
                          child: Center(
                            child: pendingTotal == 0
                                ? Text('Không có dữ liệu',
                                    textAlign: TextAlign.center,
                                    style: textTheme.bodySmall)
                                : Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text('$pendingTotal',
                                          style: textTheme.headlineSmall
                                              ?.copyWith(
                                                  color: scheme.primary,
                                                  fontWeight:
                                                      FontWeight.w700)),
                                      const SizedBox(height: 4),
                                      Text('Chưa hoàn thành',
                                          style: textTheme.bodySmall),
                                    ],
                                  ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (pendingSlices.isEmpty)
                              _legend(context, scheme.outline,
                                  'Không có dữ liệu', 0, 0)
                            else
                              ...pendingSlices.map(
                                (slice) => Padding(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 4),
                                  child: _legend(
                                      context,
                                      slice.color,
                                      slice.label,
                                      slice.count,
                                      pendingTotal),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ]),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ===== Helpers =====

  List<Widget> _buildUpcomingList(
      BuildContext context, List<Task> filtered) {
    final upcoming =
        filtered.where((t) => !t.done && t.dueDate != null).toList()
          ..sort((a, b) => a.dueDate!.compareTo(b.dueDate!));
    if (upcoming.isEmpty) {
      return const [
        SizedBox(height: 60, child: Center(child: Text('— Không có nhiệm vụ —')))
      ];
    }
    String fmtDate(DateTime d) => '${d.day}/${d.month}';
    String? fmtTime(TimeOfDay? t) =>
        t == null ? null : '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

    return upcoming.take(5).map((t) {
      final d = t.dueDate!;
      final time = fmtTime(t.timeOfDay);
      return ListTile(
        leading: const Icon(Icons.event_note),
        title: Text(t.title),
        subtitle: Text(time == null ? fmtDate(d) : '${fmtDate(d)} • $time'),
      );
    }).toList();
  }

  List<_DailyCompletionStat> _buildDailyCompletionStats(List<Task> tasks) {
    final today = DateTime.now();
    final start = DateTime(today.year, today.month, today.day);
    final range = (_days ?? 30).clamp(1, 60);
    return List.generate(range, (index) {
      final day = start.add(Duration(days: index));
      final dayTasks = tasks.where((t) {
        if (t.dueDate == null) return false;
        final due =
            DateTime(t.dueDate!.year, t.dueDate!.month, t.dueDate!.day);
        return DateUtils.isSameDay(due, day);
      }).toList();
      final total = dayTasks.length;
      final completed = dayTasks.where((t) => t.done).length;
      return _DailyCompletionStat(
          day: day, completed: completed, total: total);
    });
  }

  List<_CategorySlice> _pendingSlices(
      List<Task> tasks, ColorScheme scheme) {
    int work = 0, personal = 0, others = 0;
    for (final task in tasks) {
      if (task.done) continue;
      if (task.category == TaskCategory.work) {
        work++;
      } else if (task.category == TaskCategory.personal) {
        personal++;
      } else {
        others++;
      }
    }
    final slices = <_CategorySlice>[
      _CategorySlice(label: 'Công việc', count: work, color: scheme.primary),
      _CategorySlice(label: 'Cá nhân', count: personal, color: Colors.orange),
    ];
    if (others > 0) {
      slices.add(_CategorySlice(
          label: 'Khác', count: others, color: scheme.tertiary));
    }
    return slices;
  }

  Widget _legend(BuildContext ctx, Color color, String label, int count,
      int total) {
    final percent = total <= 0 ? 0 : (count / total * 100).round();
    final display =
        total <= 0 ? '$label  $count' : '$label  $count (${percent}%)';
    return Row(children: [
      Container(
          width: 12,
          height: 12,
          decoration:
              BoxDecoration(color: color, shape: BoxShape.circle)),
      const SizedBox(width: 8),
      Text(display),
    ]);
  }
}

// ===== Small UI widgets & painters =====

class _RangeDropdown extends StatelessWidget {
  final int? value; // null = Tất cả
  final ValueChanged<int?> onChanged;
  const _RangeDropdown({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final items = <(int?, String)>[
      (7, 'Trong 7 ngày nữa'),
      (30, 'Trong 30 ngày nữa'),
      (90, 'Trong 90 ngày nữa'),
      (null, 'Toàn bộ'),
    ];
    return DropdownButton<int?>(
      value: value,
      underline: const SizedBox(),
      alignment: Alignment.centerRight,
      borderRadius: BorderRadius.circular(12),
      items: items
          .map((e) =>
              DropdownMenuItem<int?>(value: e.$1, child: Text(e.$2)))
          .toList(),
      onChanged: onChanged,
    );
  }
}

class _DailyCompletionStat {
  final DateTime day;
  final int completed;
  final int total;
  const _DailyCompletionStat(
      {required this.day, required this.completed, required this.total});

  String get label =>
      '${day.day.toString().padLeft(2, '0')}/${day.month.toString().padLeft(2, '0')}';
}

class _DailyCompletionChart extends StatelessWidget {
  final List<_DailyCompletionStat> stats;
  const _DailyCompletionChart({required this.stats});

  @override
  Widget build(BuildContext context) {
    final visible = stats.length > 30 ? stats.sublist(0, 30) : stats;
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    const maxBarHeight = 160.0;

    if (visible.isEmpty) {
      return SizedBox(
        height: maxBarHeight,
        child: Center(
            child: Text('Không có dữ liệu', style: textTheme.bodyMedium)),
      );
    }

    final maxTotal =
        visible.fold<int>(0, (prev, s) => math.max(prev, s.total));
    if (maxTotal == 0) {
      return SizedBox(
        height: maxBarHeight,
        child: Center(
            child: Text('Không có dữ liệu', style: textTheme.bodyMedium)),
      );
    }

    const barWidth = 36.0;
    return SizedBox(
      height: maxBarHeight + 40,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            for (final stat in visible)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      height: maxBarHeight,
                      child: Stack(
                        alignment: Alignment.bottomCenter,
                        children: [
                          Container(
                            width: barWidth,
                            decoration: BoxDecoration(
                              color: scheme.surface,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                  color: scheme.outline.withOpacity(.12)),
                            ),
                          ),
                          if (stat.total > 0)
                            Align(
                              alignment: Alignment.bottomCenter,
                              child: Container(
                                width: barWidth,
                                height: maxBarHeight *
                                    (stat.total / maxTotal),
                                decoration: BoxDecoration(
                                  color: scheme.primary.withOpacity(.22),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          if (stat.completed > 0)
                            Align(
                              alignment: Alignment.bottomCenter,
                              child: Container(
                                width: barWidth,
                                height: maxBarHeight *
                                    (stat.completed / maxTotal),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      scheme.primary,
                                      scheme.secondary
                                    ],
                                    begin: Alignment.bottomCenter,
                                    end: Alignment.topCenter,
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(stat.label, style: textTheme.bodySmall),
                    Text('${stat.completed}/${stat.total}',
                        style: textTheme.labelSmall
                            ?.copyWith(color: scheme.primary)),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _CategorySlice {
  final String label;
  final int count;
  final Color color;
  const _CategorySlice(
      {required this.label, required this.count, required this.color});
}

class _DonutChartPainter extends CustomPainter {
  final List<_CategorySlice> slices;
  final Color backgroundColor;
  _DonutChartPainter(this.slices, this.backgroundColor);

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = math.min(size.width, size.height) / 2;
    final strokeWidth = radius * 0.45;

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final arcRect =
        Rect.fromCircle(center: center, radius: radius - strokeWidth / 2);

    // nền
    paint.color = backgroundColor;
    canvas.drawArc(arcRect, 0, 2 * math.pi, false, paint);

    final total = slices.fold<int>(
        0, (sum, s) => sum + (s.count > 0 ? s.count : 0));
    if (total <= 0) return;

    double startAngle = -math.pi / 2;
    for (final s in slices) {
      if (s.count <= 0) continue;
      final sweep = (s.count / total) * 2 * math.pi;
      paint.color = s.color;
      canvas.drawArc(arcRect, startAngle, sweep, false, paint);
      startAngle += sweep;
    }
  }

  @override
  bool shouldRepaint(covariant _DonutChartPainter old) {
    return old.backgroundColor != backgroundColor || old.slices != slices;
    }
}
