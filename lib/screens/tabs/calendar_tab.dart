import 'package:flutter/material.dart';
import '../../models/task.dart';
import '../../services/category_store.dart';

/// Calendar tab - Minimalism + Material You
/// - Không ô box mỗi ngày; nền sạch.
/// - Ngày có nhiệm vụ: dấu chấm dưới số ngày (màu primary).
/// - Ngày được chọn: vòng tròn tô màu (primary) – số là onPrimary.
/// - Hôm nay: số ngày màu primary nếu không phải ngày đang chọn.
/// - Nút "Hôm nay" góc phải để quay về today.
class CalendarTab extends StatefulWidget {
  final List<Task> tasks;
  final ValueChanged<Task> onOpenTask;
  final ValueChanged<DateTime> onCreateForDate;

  const CalendarTab({
    super.key,
    required this.tasks,
    required this.onOpenTask,
    required this.onCreateForDate,
  });

  @override
  State<CalendarTab> createState() => _CalendarTabState();
}

class _CalendarTabState extends State<CalendarTab> {
  DateTime _focused = DateTime.now();
  DateTime _selected = DateTime.now();
  final CategoryStore _categoryStore = CategoryStore.instance;

  @override
  Widget build(BuildContext context) {
    final days = _buildMonthDays(_focused);
    final dayTasks = widget.tasks
        .where((t) => _isSameDate(t.dueDate, _selected))
        .toList();

    return CustomScrollView(
      slivers: [
        // Header: chuyển tháng + Hôm nay
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(8, 4, 8, 8),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left_rounded),
                  onPressed: () => setState(
                    () =>
                        _focused = DateTime(_focused.year, _focused.month - 1),
                  ),
                ),
                Expanded(
                  child: Center(
                    child: Text(
                      _monthYear(_focused),
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
                TextButton(
                  onPressed: _jumpToToday,
                  child: const Text('Hôm nay'),
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right_rounded),
                  onPressed: () => setState(
                    () =>
                        _focused = DateTime(_focused.year, _focused.month + 1),
                  ),
                ),
              ],
            ),
          ),
        ),

        // Hàng thứ trong tuần
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: _weekHeader(context),
          ),
        ),

        // Lưới tháng – không hộp, chỉ số + chấm
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
            child: _monthGrid(context, days),
          ),
        ),

        // Thanh tiêu đề ngày + nút Thêm nhiệm vụ
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Row(
              children: [
                Text(
                  _dateLabel(_selected),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const Spacer(),
                FilledButton.icon(
                  onPressed: () => widget.onCreateForDate(_selected),
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Thêm nhiệm vụ'),
                  style: FilledButton.styleFrom(shape: const StadiumBorder()),
                ),
              ],
            ),
          ),
        ),

        // Danh sách nhiệm vụ của ngày
        if (dayTasks.isEmpty)
          SliverFillRemaining(
            hasScrollBody: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 110),
              child: _emptySchedule(context),
            ),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 110),
            sliver: SliverList.builder(
              itemCount: dayTasks.length,
              itemBuilder: (ctx, i) => _calendarTaskCard(context, dayTasks[i]),
            ),
          ),
      ],
    );
  }

  // ====== Controls ======
  void _jumpToToday() {
    final now = DateTime.now();
    setState(() {
      _focused = DateTime(now.year, now.month, 1);
      _selected = DateTime(now.year, now.month, now.day);
    });
  }

  Widget _weekHeader(BuildContext context) {
    const labels = ['S', 'M', 'T', 'W', 'T', 'F', 'S'];
    final style = Theme.of(context).textTheme.labelLarge;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        for (final s in labels)
          Expanded(
            child: Center(child: Text(s, style: style)),
          ),
      ],
    );
  }

  Widget _monthGrid(BuildContext context, List<DateTime> days) {
    return LayoutBuilder(
      builder: (ctx, cons) {
        final cellW = (cons.maxWidth - 6 * 6) / 7;
        return Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            for (final d in days)
              SizedBox(width: cellW, height: 48, child: _dayCell(context, d)),
          ],
        );
      },
    );
  }

  Widget _dayCell(BuildContext context, DateTime d) {
    final scheme = Theme.of(context).colorScheme;
    final isSelectedMonth = d.month == _focused.month;
    final isSelected = _isSameDate(d, _selected);
    final isToday = _isSameDate(d, DateTime.now());
    final hasTasks = widget.tasks.any((t) => _isSameDate(t.dueDate, d));

    final base = Theme.of(
      context,
    ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700);

    Color textColor = Theme.of(context).colorScheme.onSurfaceVariant;
    if (isSelected) {
      textColor = scheme.onPrimary;
    } else if (isToday) {
      textColor = scheme.primary;
    }

    final number = Text('${d.day}', style: base?.copyWith(color: textColor));

    final marker = hasTasks
        ? Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: scheme.primary,
              shape: BoxShape.circle,
            ),
          )
        : const SizedBox(height: 6);

    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: () => setState(() => _selected = d),
      child: Center(
        child: Opacity(
          opacity: isSelectedMonth ? 1 : 0.45,
          child: Stack(
            alignment: Alignment.center,
            children: [
              if (isSelected)
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: scheme.primary,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [number, const SizedBox(height: 4), marker],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ====== Task card ======
  Widget _calendarTaskCard(BuildContext context, Task t) {
    final scheme = Theme.of(context).colorScheme;
    final label = resolveCategoryLabel(t, _categoryStore.current);
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.05),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.task_alt_rounded, size: 20, color: scheme.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  t.title.isEmpty ? '(Không tiêu đề)' : t.title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    _chip(
                      context,
                      Icons.category_outlined,
                      label,
                      scheme.surfaceVariant,
                      scheme.onSurfaceVariant,
                    ),
                    if (t.timeOfDay != null)
                      _chip(
                        context,
                        Icons.schedule_rounded,
                        _formatTime(t.timeOfDay!),
                        scheme.secondaryContainer,
                        scheme.onSecondaryContainer,
                      ),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right_rounded),
            onPressed: () => widget.onOpenTask(t),
          ),
        ],
      ),
    );
  }

  Widget _chip(
    BuildContext context,
    IconData icon,
    String label,
    Color bg,
    Color fg,
  ) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    decoration: ShapeDecoration(color: bg, shape: const StadiumBorder()),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: fg),
        const SizedBox(width: 6),
        Text(
          label,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
            color: fg,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    ),
  );

  Widget _emptySchedule(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      Text(
        'Không có nhiệm vụ trong ngày',
        style: Theme.of(
          context,
        ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
      ),
      const SizedBox(height: 8),
      Text(
        'Hãy thêm nhiệm vụ cho ngày đã chọn.',
        style: Theme.of(context).textTheme.bodyMedium,
      ),
    ],
  );

  // ====== Utils ======
  List<DateTime> _buildMonthDays(DateTime month) {
    final first = DateTime(month.year, month.month, 1);
    final startWeekday = first.weekday % 7; // Mon=1..Sun=7 -> 0..6
    final start = first.subtract(Duration(days: startWeekday));
    final next = DateTime(month.year, month.month + 1, 1);
    final total = next.difference(start).inDays;
    return [for (int i = 0; i < total; i++) start.add(Duration(days: i))];
  }

  bool _isSameDate(DateTime? a, DateTime b) =>
      a != null && a.year == b.year && a.month == b.month && a.day == b.day;

  String _monthYear(DateTime d) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return '${months[d.month - 1]} ${d.year}';
  }

  String _dateLabel(DateTime d) => '${d.day}/${d.month}/${d.year}';

  String _formatTime(TimeOfDay t) {
    final hh = t.hour.toString().padLeft(2, '0');
    final mm = t.minute.toString().padLeft(2, '0');
    return '$hh:$mm';
  }
}
