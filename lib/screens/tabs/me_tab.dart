import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/task.dart';
import '../../services/pro_manager.dart';
import '../Pay/upgrade_pro_demo_screen.dart';
import '../../services/auth_service.dart';
import '../auth/login_screen.dart';
import '../../services/ai_insights_service.dart';
import '../../widgets/ai_insight_card.dart';

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
      return (d.isAtSameMomentAs(today) || d.isAfter(today)) && d.isBefore(end.add(const Duration(days: 1)));
    }).toList();
  }

  String get _rangeLabel => _days == null ? 'Toàn bộ' : 'Trong $_days ngày nữa';

  @override
  Widget build(BuildContext context) {
    final insights = AiInsightsService.generate(widget.tasks);
    final filtered = _rangeTasks;
    final done = filtered.where((t) => t.done).length;
    final notDone = filtered.length - done;
    final workCnt = filtered.where((t) => !t.done && t.category == TaskCategory.work).length;
    final personalCnt = filtered.where((t) => !t.done && t.category == TaskCategory.personal).length;

    Widget pillTitle(String text) => Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Row(
        children: [
          Expanded(child: Text(text, style: Theme.of(context).textTheme.titleLarge)),
          _RangeDropdown(value: _days, onChanged: (v) => setState(() => _days = v)),
        ],
      ),
    );

    Widget statCard(String title, String value) => Expanded(
      child: Card(
        color: Theme.of(context).colorScheme.primaryContainer.withOpacity(.45),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 18),
          child: Column(
            children: [
              Text(value, style: Theme.of(context).textTheme.headlineMedium),
              const SizedBox(height: 6),
              Text(title, textAlign: TextAlign.center),
            ],
          ),
        ),
      ),
    );

    return ListView(
      padding: const EdgeInsets.only(bottom: 100),
      children: [
        // ===== USER TILE =====
        StreamBuilder<User?>(
          stream: AuthService.instance.userChanges,
          builder: (context, snap) {
            final user = snap.data;
            final avatar = (user?.photoURL != null)
                ? CircleAvatar(radius: 28, backgroundImage: NetworkImage(user!.photoURL!))
                : CircleAvatar(radius: 28, backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
                    child: Icon(Icons.person, color: Theme.of(context).colorScheme.onSecondaryContainer));
            return ListTile(
              leading: avatar,
              title: Text(user?.displayName ?? 'Bạn đã giữ theo kế hoạch cũ…'),
              subtitle: Text(user?.email ?? 'Bấm để đăng nhập'),
              onTap: () {
                if (user == null) {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
                }
              },
              trailing: user != null
                  ? IconButton(
                      tooltip: 'Đăng xuất',
                      icon: const Icon(Icons.logout),
                      onPressed: () => AuthService.instance.signOut(),
                    )
                  : null,
            );
          },
        ),

        // ===== PRO BANNER (ẩn khi đã Pro) =====
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: ValueListenableBuilder<bool>(
            valueListenable: ProManager.instance.isPro,
            builder: (_, isPro, __) {
              if (isPro) return const SizedBox.shrink();
              return InkWell(
                onTap: () => Navigator.push(
                  context, MaterialPageRoute(builder: (_) => const UpgradeProDemoScreen())),
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Theme.of(context).colorScheme.primary.withOpacity(.75),
                        Theme.of(context).colorScheme.primaryContainer,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: const [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Nâng cấp lên Pro',
                                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                            SizedBox(height: 4),
                            Text('Mở khoá tất cả các tính năng PRO',
                                style: TextStyle(color: Colors.white70)),
                          ],
                        ),
                      ),
                      Icon(Icons.workspace_premium, color: Colors.white, size: 32),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        
         const SizedBox(height: 16),
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

        // Chart placeholder
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: Card(
            color: Theme.of(context).colorScheme.primaryContainer.withOpacity(.45),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [const Expanded(child: Text('Hoàn thành nhiệm vụ hàng ngày')), Text(_rangeLabel)]),
                const SizedBox(height: 16),
                Container(height: 180, alignment: Alignment.center, child: const Text('Không có dữ liệu nhiệm vụ')),
              ]),
            ),
          ),
        ),

        // Upcoming
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Text('Nhiệm vụ trong ${_days ?? 'tất cả'} ngày tới', style: Theme.of(context).textTheme.titleLarge),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Card(child: Column(children: _buildUpcomingList(context, filtered))),
        ),

        // Breakdown
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Row(
            children: [
              Expanded(child: Text('Phân loại nhiệm vụ chưa hoàn thành', style: Theme.of(context).textTheme.titleLarge)),
              _RangeDropdown(value: _days, onChanged: (v) => setState(() => _days = v)),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
                SizedBox(
                  width: 160, height: 160,
                  child: Stack(alignment: Alignment.center, children: [
                    Container(
                      width: 140, height: 140,
                      decoration: BoxDecoration(shape: BoxShape.circle, color: Theme.of(context).colorScheme.primary.withOpacity(.15)),
                    ),
                    Container(width: 70, height: 70, decoration: BoxDecoration(shape: BoxShape.circle, color: Theme.of(context).colorScheme.surface)),
                  ]),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    _legend(context, Theme.of(context).colorScheme.primary, 'Công việc', workCnt),
                    const SizedBox(height: 8),
                    _legend(context, Colors.orange, 'Cá nhân', personalCnt),
                  ]),
                ),
              ]),
            ),
          ),
        ),
      ],
    );
  }

  List<Widget> _buildUpcomingList(BuildContext context, List<Task> filtered) {
    final upcoming = filtered.where((t) => !t.done && t.dueDate != null).toList()
      ..sort((a, b) => a.dueDate!.compareTo(b.dueDate!));
    if (upcoming.isEmpty) {
      return const [SizedBox(height: 60, child: Center(child: Text('— Không có nhiệm vụ —')))];
    }
    String fmtDate(DateTime d) => '${d.day}/${d.month}';
    String? fmtTime(TimeOfDay? t) => t == null ? null : '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
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

  Widget _legend(BuildContext ctx, Color color, String label, int count) {
    return Row(children: [
      Container(width: 12, height: 12, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
      const SizedBox(width: 8),
      Text('$label  $count'),
    ]);
  }
}

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
      value: value, underline: const SizedBox(), alignment: Alignment.centerRight, borderRadius: BorderRadius.circular(12),
      items: items.map((e) => DropdownMenuItem<int?>(value: e.$1, child: Text(e.$2))).toList(),
      onChanged: onChanged,
    );
  }
}
